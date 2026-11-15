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

    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] product_ext;
    logic signed [ACC_WIDTH-1:0] acc_reg;

    // Signed multiplication
    always_comb begin
        product = $signed(a_in) * $signed(b_in);

        // Sign extension to accumulator width
        product_ext = {
            {(ACC_WIDTH-PRODUCT_WIDTH){product[PRODUCT_WIDTH-1]}},
            product
        };
    end

    // Operand propagation and accumulation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out       <= '0;
            b_out       <= '0;

            valid_a_out <= 1'b0;
            valid_b_out <= 1'b0;
            valid_out   <= 1'b0;

            acc_reg     <= '0;
        end else begin

            // Propagate operands independently
            a_out       <= a_in;
            b_out       <= b_in;

            valid_a_out <= valid_a_in;
            valid_b_out <= valid_b_in;

            // Indicates a valid multiply-accumulate event
            valid_out <= valid_a_in && valid_b_in;

            // Accumulator control
            if (clear_acc) begin
                acc_reg <= '0;
            end else if (valid_a_in && valid_b_in) begin
                acc_reg <= acc_reg + product_ext;
            end
        end
    end

    assign acc_out = acc_reg;

    // Parameter validation
    initial begin
        if (DATA_WIDTH < 1)
            $fatal(1, "DATA_WIDTH must be greater than zero");

        if (ACC_WIDTH < PRODUCT_WIDTH)
            $fatal(1, "ACC_WIDTH must be >= 2*DATA_WIDTH");
    end

endmodule
  
