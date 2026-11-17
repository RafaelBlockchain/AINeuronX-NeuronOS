`timescale 1ns/1ps

module systolic_pe #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,

    // Control
    input  logic clear_acc,

    // Operand A path
    input  logic signed [DATA_WIDTH-1:0] a_in,
    input  logic                         valid_a_in,
    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic                         valid_a_out,

    // Operand B path
    input  logic signed [DATA_WIDTH-1:0] b_in,
    input  logic                         valid_b_in,
    output logic signed [DATA_WIDTH-1:0] b_out,
    output logic                         valid_b_out,

    // Accumulator status
    output logic signed [ACC_WIDTH-1:0]  acc_out,
    output logic                         valid_out
);

    localparam int PRODUCT_WIDTH = 2 * DATA_WIDTH;

    // Señales de activación y aislamiento de energía (Operand Isolation)
    logic                            mac_active;
    logic signed [DATA_WIDTH-1:0]    a_gated;
    logic signed [DATA_WIDTH-1:0]    b_gated;

    // Stage 1: Combinational signed multiplication
    logic signed [PRODUCT_WIDTH-1:0] product_comb;

    // Stage 1 -> Stage 2: Pipeline register for product and valid flag
    logic signed [PRODUCT_WIDTH-1:0] product_reg;
    logic                            mac_valid_d1;

    // Stage 2: Sign-extended product and accumulator
    logic signed [ACC_WIDTH-1:0]     product_ext;
    logic signed [ACC_WIDTH-1:0]     acc_reg;

    // Aislamiento de operandos: congela entradas del multiplicador si no son válidas
    assign mac_active = valid_a_in && valid_b_in;
    assign a_gated    = mac_active ? a_in : '0;
    assign b_gated    = mac_active ? b_in : '0;

    // Stage 1 multiplication (solo conmuta cuando mac_active == 1)
    always_comb begin
        product_comb = a_gated * b_gated;
    end

    // Stage 2 sign extension nativa en SystemVerilog
    assign product_ext = ACC_WIDTH'(product_reg);

    // Propagación de operandos con Clock Gating inferido (solo actualiza si valid == 1)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out       <= '0;
            valid_a_out <= 1'b0;
        end else begin
            valid_a_out <= valid_a_in;
            if (valid_a_in) begin
                a_out <= a_in;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_out       <= '0;
            valid_b_out <= 1'b0;
        end else begin
            valid_b_out <= valid_b_in;
            if (valid_b_in) begin
                b_out <= b_in;
            end
        end
    end

    // Pipeline Stage 1 & Stage 2: MAC de 2 ciclos con gating en registros
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg  <= '0;
            mac_valid_d1 <= 1'b0;
            acc_reg      <= '0;
            valid_out    <= 1'b0;
        end else begin
            // Stage 1: Latch del producto solo cuando ambos operandos son válidos
            mac_valid_d1 <= mac_active;
            if (mac_active) begin
                product_reg <= product_comb;
            end

            // Stage 2: Acumulación solo cuando clear_acc o mac_valid_d1 están activos
            valid_out <= mac_valid_d1;
            if (clear_acc) begin
                acc_reg <= '0;
            end else if (mac_valid_d1) begin
                acc_reg <= acc_reg + product_ext;
            end
        end
    end

    assign acc_out = acc_reg;

`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1)
            $fatal(1, "DATA_WIDTH must be greater than zero");

        if (ACC_WIDTH < PRODUCT_WIDTH)
            $fatal(1, "ACC_WIDTH must be >= 2*DATA_WIDTH");
    end
`endif

endmodule
