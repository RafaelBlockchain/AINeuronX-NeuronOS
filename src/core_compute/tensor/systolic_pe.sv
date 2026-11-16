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
    input  logic valid_a_in,
    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic valid_a_out,

    // Operand B path
    input  logic signed [DATA_WIDTH-1:0] b_in,
    input  logic valid_b_in,
    output logic signed [DATA_WIDTH-1:0] b_out,
    output logic valid_b_out,

    // Accumulator status
    output logic signed [ACC_WIDTH-1:0] acc_out,
    output logic valid_out
);

    localparam int PRODUCT_WIDTH = 2 * DATA_WIDTH;

    // Stage 1: Combinational signed multiplication
    logic signed [PRODUCT_WIDTH-1:0] product_comb;

    // Stage 1 -> Stage 2: Pipeline register for product and valid flag
    logic signed [PRODUCT_WIDTH-1:0] product_reg;
    logic                            mac_valid_d1;

    // Stage 2: Sign-extended product and accumulator
    logic signed [ACC_WIDTH-1:0] product_ext;
    logic signed [ACC_WIDTH-1:0] acc_reg;

    // Stage 1 multiplication
    always_comb begin
        product_comb = $signed(a_in) * $signed(b_in);
    end

    // Stage 2 sign extension
    always_comb begin
        product_ext = {
            {(ACC_WIDTH-PRODUCT_WIDTH){product_reg[PRODUCT_WIDTH-1]}},
            product_reg
        };
    end

    // Operand propagation (1 cycle) and pipelined MAC (2 cycles total)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out        <= '0;
            b_out        <= '0;
            valid_a_out  <= 1'b0;
            valid_b_out  <= 1'b0;

            product_reg  <= '0;
            mac_valid_d1 <= 1'b0;

            acc_reg      <= '0;
            valid_out    <= 1'b0;
        end else begin
            // Propagate operands to neighboring PEs without extra stall
            a_out       <= a_in;
            b_out       <= b_in;
            valid_a_out <= valid_a_in;
            valid_b_out <= valid_b_in;

            // Pipeline Stage 1: Latch product when both inputs are valid
            mac_valid_d1 <= valid_a_in && valid_b_in;
            if (valid_a_in && valid_b_in) begin
                product_reg <= product_comb;
            end else begin
                product_reg <= '0;
            end

            // Pipeline Stage 2: Accumulate latched product
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
