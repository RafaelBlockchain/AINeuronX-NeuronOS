`timescale 1ns / 1ps

module N200_Top #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32,
    parameter int LANES      = 4,
    parameter int ROWS       = 8,
    parameter int COLS       = 8,
    parameter int K_DIM      = 8
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        bus_valid,
    input  logic        bus_we,
    input  logic [7:0]  bus_addr,
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,
    output logic        irq_done
);

    // Cantidad de palabras de 32 bits necesarias para cada matriz de 16 bits
    localparam int MAT_A_WORDS = (ROWS * K_DIM * DATA_WIDTH) / 32; // 32 palabras para 8x8
    localparam int MAT_B_WORDS = (K_DIM * COLS * DATA_WIDTH) / 32; // 32 palabras para 8x8

    logic [31:0] reg_vector_a [0:1];
    logic [31:0] reg_vector_b [0:1];
    logic [31:0] reg_matrix_a [0:MAT_A_WORDS-1];
    logic [31:0] reg_matrix_b [0:MAT_B_WORDS-1];

    logic        vector_start;
    logic [1:0]  vector_opcode;
    logic        vector_clear_acc;
    logic        tensor_load;
    logic        tensor_start;

    logic [LANES*ACC_WIDTH-1:0]     vector_result;
    logic                           vector_busy;
    logic                           vector_done;
    logic [ROWS*COLS*ACC_WIDTH-1:0] tensor_accumulators;
    logic [ROWS*COLS-1:0]           tensor_valid;
    logic                           tensor_busy;
    logic                           tensor_done;

    logic [LANES*DATA_WIDTH-1:0]      flat_vector_a;
    logic [LANES*DATA_WIDTH-1:0]      flat_vector_b;
    logic [ROWS*K_DIM*DATA_WIDTH-1:0] flat_matrix_a;
    logic [K_DIM*COLS*DATA_WIDTH-1:0] flat_matrix_b;

    logic [31:0] bus_rdata_next;

    assign flat_vector_a = {reg_vector_a[1], reg_vector_a[0]};
    assign flat_vector_b = {reg_vector_b[1], reg_vector_b[0]};

    genvar i;
    generate
        for (i = 0; i < MAT_A_WORDS; i = i + 1) begin : gen_mat_a_pack
            assign flat_matrix_a[i*32 +: 32] = reg_matrix_a[i];
        end
        for (i = 0; i < MAT_B_WORDS; i = i + 1) begin : gen_mat_b_pack
            assign flat_matrix_b[i*32 +: 32] = reg_matrix_b[i];
        end
    endgenerate

    // Decodificador de lectura (Bus de direcciones de 8 bits)
    always_comb begin
        bus_rdata_next = 32'd0;

        if (bus_addr == 8'h01) begin
            bus_rdata_next = {28'd0, tensor_done, tensor_busy, vector_done, vector_busy};
        end else if (bus_addr == 8'h02) begin
            bus_rdata_next = tensor_valid[31:0];
        end else if (bus_addr == 8'h03) begin
            bus_rdata_next = tensor_valid[63:32];
        end else if ((bus_addr >= 8'h18) && (bus_addr <= 8'h1B)) begin
            bus_rdata_next = vector_result[bus_addr[1:0]*32 +: 32];
        end else if ((bus_addr >= 8'h80) && (bus_addr <= 8'hBF)) begin
            // 64 acumuladores de 32 bits mapeados de 0x80 a 0xBF
            bus_rdata_next = tensor_accumulators[bus_addr[5:0]*32 +: 32];
        end
    end

    // Lógica de escritura y control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ready        <= 1'b0;
            bus_rdata        <= 32'd0;
            irq_done         <= 1'b0;
            vector_start     <= 1'b0;
            vector_opcode    <= 2'b00;
            vector_clear_acc <= 1'b0;
            tensor_load      <= 1'b0;
            tensor_start     <= 1'b0;
            reg_vector_a[0]  <= 32'd0;
            reg_vector_a[1]  <= 32'd0;
            reg_vector_b[0]  <= 32'd0;
            reg_vector_b[1]  <= 32'd0;

            for (int k = 0; k < MAT_A_WORDS; k++) begin
                reg_matrix_a[k] <= 32'd0;
            end
            for (int k = 0; k < MAT_B_WORDS; k++) begin
                reg_matrix_b[k] <= 32'd0;
            end
        end else begin
            vector_start     <= 1'b0;
            vector_clear_acc <= 1'b0;
            tensor_load      <= 1'b0;
            tensor_start     <= 1'b0;

            bus_ready        <= bus_valid;
            irq_done         <= vector_done || tensor_done;

            if (bus_valid && !bus_we) begin
                bus_rdata <= bus_rdata_next;
            end

            if (bus_valid && bus_we) begin
                if (bus_addr == 8'h00) begin
                    vector_start     <= bus_wdata[0];
                    vector_clear_acc <= bus_wdata[1];
                    vector_opcode    <= bus_wdata[3:2];
                    tensor_load      <= bus_wdata[4];
                    tensor_start     <= bus_wdata[5];
                end else if (bus_addr == 8'h04) begin
                    reg_vector_a[0] <= bus_wdata;
                end else if (bus_addr == 8'h05) begin
                    reg_vector_a[1] <= bus_wdata;
                end else if (bus_addr == 8'h06) begin
                    reg_vector_b[0] <= bus_wdata;
                end else if (bus_addr == 8'h07) begin
                    reg_vector_b[1] <= bus_wdata;
                end else if ((bus_addr >= 8'h20) && (bus_addr <= 8'h3F)) begin
                    // 32 palabras para Matrix A (0x20 a 0x3F)
                    reg_matrix_a[bus_addr[4:0]] <= bus_wdata;
                end else if ((bus_addr >= 8'h40) && (bus_addr <= 8'h5F)) begin
                    // 32 palabras para Matrix B (0x40 a 0x5F)
                    reg_matrix_b[bus_addr[4:0]] <= bus_wdata;
                end
            end
        end
    end

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
