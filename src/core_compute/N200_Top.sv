`timescale 1ns / 1ps

module N200_Top #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32,
    parameter int LANES      = 4,
    parameter int ROWS       = 4,
    parameter int COLS       = 4,
    parameter int K_DIM      = 4
) (
    input  logic        clk,
    input  logic        rst_n,

    // Interfaz de Bus Simple de 32 bits (76 pines totales con clk/rst/irq)
    input  logic        bus_valid,
    input  logic        bus_we,
    input  logic [5:0]  bus_addr,   // 64 registros de 32 bits (0x00 a 0x3F)
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,
    output logic        irq_done    // Interrupción al finalizar cómputo
);

    // Registros de almacenamiento mapeados en memoria
    logic [31:0] reg_vector_a [0:1]; // 4 lanes x 16 bits = 64 bits (2 palabras)
    logic [31:0] reg_vector_b [0:1]; // 4 lanes x 16 bits = 64 bits (2 palabras)
    logic [31:0] reg_matrix_a [0:7]; // 4x4 x 16 bits = 256 bits (8 palabras)
    logic [31:0] reg_matrix_b [0:7]; // 4x4 x 16 bits = 256 bits (8 palabras)

    // Pulsos y control
    logic        vector_start;
    logic [1:0]  vector_opcode;
    logic        vector_clear_acc;
    logic        tensor_load;
    logic        tensor_start;

    // Salidas del núcleo
    logic [LANES*ACC_WIDTH-1:0]     vector_result;
    logic                           vector_busy;
    logic                           vector_done;
    logic [ROWS*COLS*ACC_WIDTH-1:0] tensor_accumulators;
    logic [ROWS*COLS-1:0]           tensor_valid;
    logic                           tensor_busy;
    logic                           tensor_done;

    // Empaquetado de buses hacia Tile_Core_Compute
    logic [LANES*DATA_WIDTH-1:0]      flat_vector_a;
    logic [LANES*DATA_WIDTH-1:0]      flat_vector_b;
    logic [ROWS*K_DIM*DATA_WIDTH-1:0] flat_matrix_a;
    logic [K_DIM*COLS*DATA_WIDTH-1:0] flat_matrix_b;

    assign flat_vector_a = {reg_vector_a[1], reg_vector_a[0]};
    assign flat_vector_b = {reg_vector_b[1], reg_vector_b[0]};

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : gen_mat_pack
            assign flat_matrix_a[i*32 +: 32] = reg_matrix_a[i];
            assign flat_matrix_b[i*32 +: 32] = reg_matrix_b[i];
        end
    endgenerate

    assign irq_done = vector_done || tensor_done;

    // Escritura y pulsos de control desde el bus de 32 bits
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ready        <= 1'b0;
            vector_start     <= 1'b0;
            vector_opcode    <= 2'b00;
            vector_clear_acc <= 1'b0;
            tensor_load      <= 1'b0;
            tensor_start     <= 1'b0;
            for (int k = 0; k < 2; k++) begin
                reg_vector_a[k] <= 32'd0;
                reg_vector_b[k] <= 32'd0;
            end
            for (int k = 0; k < 8; k++) begin
                reg_matrix_a[k] <= 32'd0;
                reg_matrix_b[k] <= 32'd0;
            end
        end else begin
            // Pulsos de un solo ciclo se limpian automáticamente
            vector_start     <= 1'b0;
            vector_clear_acc <= 1'b0;
            tensor_load      <= 1'b0;
            tensor_start     <= 1'b0;
            bus_ready        <= bus_valid;

            if (bus_valid && bus_we) begin
                case (bus_addr)
                    // 0x00: Registro de Control
                    6'h00: begin
                        vector_start     <= bus_wdata[0];
                        vector_clear_acc <= bus_wdata[1];
                        vector_opcode    <= bus_wdata[3:2];
                        tensor_load      <= bus_wdata[4];
                        tensor_start     <= bus_wdata[5];
                    end
                    // 0x04 - 0x05: Vector A
                    6'h04: reg_vector_a[0] <= bus_wdata;
                    6'h05: reg_vector_a[1] <= bus_wdata;
                    // 0x06 - 0x07: Vector B
                    6'h06: reg_vector_b[0] <= bus_wdata;
                    6'h07: reg_vector_b[1] <= bus_wdata;
                    // 0x08 - 0x0F: Matrix A (8 palabras de 32 bits)
                    6'h08, 6'h09, 6'h0A, 6'h0B,
                    6'h0C, 6'h0D, 6'h0E, 6'h0F:
                        reg_matrix_a[bus_addr[2:0]] <= bus_wdata;
                    // 0x10 - 0x17: Matrix B (8 palabras de 32 bits)
                    6'h10, 6'h11, 6'h12, 6'h13,
                    6'h14, 6'h15, 6'h16, 6'h17:
                        reg_matrix_b[bus_addr[2:0]] <= bus_wdata;
                    default: ;
                endcase
            end
        end
    end

    // Lectura de estado y resultados hacia el bus de 32 bits
    always_comb begin
        bus_rdata = 32'd0;
        case (bus_addr)
            // 0x01: Registro de Estado
            6'h01: bus_rdata = {14'd0, tensor_valid, tensor_done, tensor_busy, vector_done, vector_busy};
            // 0x18 - 0x1B: Resultados Vectoriales (4 x 32 bits)
            6'h18, 6'h19, 6'h1A, 6'h1B:
                bus_rdata = vector_result[bus_addr[1:0]*32 +: 32];
            // 0x20 - 0x2F: Acumuladores Tensoriales (16 x 32 bits)
            6'h20, 6'h21, 6'h22, 6'h23,
            6'h24, 6'h25, 6'h26, 6'h27,
            6'h28, 6'h29, 6'h2A, 6'h2B,
            6'h2C, 6'h2D, 6'h2E, 6'h2F:
                bus_rdata = tensor_accumulators[bus_addr[3:0]*32 +: 32];
            default: bus_rdata = 32'd0;
        endcase
    end

    // Instancia del núcleo N200 (4x4x4)
    Tile_Core_Compute #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH),
        .LANES     (LANES),
        .ROWS      (ROWS),
        .COLS      (COLS),
        .K_DIM     (K_DIM)
    ) u_tile_core (
        .clk                 (clk),
        .rst_n               (rst_n),
        .vector_start        (vector_start),
        .vector_opcode       (vector_opcode),
        .vector_clear_acc    (vector_clear_acc),
        .vector_a            (flat_vector_a),
        .vector_b            (flat_vector_b),
        .vector_result       (vector_result),
        .vector_busy         (vector_busy),
        .vector_done         (vector_done),
        .tensor_load         (tensor_load),
        .tensor_start        (tensor_start),
        .matrix_a            (flat_matrix_a),
        .matrix_b            (flat_matrix_b),
        .tensor_accumulators (tensor_accumulators),
        .tensor_valid        (tensor_valid),
        .tensor_busy         (tensor_busy),
        .tensor_done         (tensor_done)
    );

endmodule
