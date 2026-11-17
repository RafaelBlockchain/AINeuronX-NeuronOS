
`timescale 1ns/1ps

module fp32_multiplier (

    input  logic        clk,
    input  logic        rst_n,

    input  logic        valid_in,

    input  logic [31:0] a,
    input  logic [31:0] b,

    output logic        valid_out,

    output logic        sign_out,
    output logic signed [10:0] exponent_out,

    output logic [47:0] product_out,

    output logic        a_is_zero,
    output logic        b_is_zero,

    output logic        a_is_subnormal,
    output logic        b_is_subnormal,

    output logic        a_is_infinity,
    output logic        b_is_infinity,

    output logic        a_is_nan,
    output logic        b_is_nan

);

    logic [23:0] significand_a;
    logic [23:0] significand_b;

    logic [47:0] product_comb;

    logic signed [10:0] exponent_a;
    logic signed [10:0] exponent_b;
    logic signed [10:0] exponent_comb;

    logic sign_comb;

    logic a_zero_comb;
    logic b_zero_comb;

    logic a_subnormal_comb;
    logic b_subnormal_comb;

    logic a_infinity_comb;
    logic b_infinity_comb;

    logic a_nan_comb;
    logic b_nan_comb;

    logic [7:0] exp_a;
    logic [7:0] exp_b;

    // ------------------------------------------------
    // Operand decoding and classification.
    // ------------------------------------------------

    always_comb begin

        exp_a = a[30:23];
        exp_b = b[30:23];

        // Implicit leading bit for normal values.
        if (exp_a == 8'd0)
            significand_a = {1'b0, a[22:0]};
        else
            significand_a = {1'b1, a[22:0]};

        if (exp_b == 8'd0)
            significand_b = {1'b0, b[22:0]};
        else
            significand_b = {1'b1, b[22:0]};

        // Effective exponents.
        if (exp_a == 8'd0)
            exponent_a = -11'sd126;
        else
            exponent_a = $signed({3'b000, exp_a}) - 11'sd127;

        if (exp_b == 8'd0)
            exponent_b = -11'sd126;
        else
            exponent_b = $signed({3'b000, exp_b}) - 11'sd127;

        exponent_comb = exponent_a + exponent_b;

        sign_comb = a[31] ^ b[31];

        a_zero_comb =
            (exp_a == 0) && (a[22:0] == 0);

        b_zero_comb =
            (exp_b == 0) && (b[22:0] == 0);

        a_subnormal_comb =
            (exp_a == 0) && (a[22:0] != 0);

        b_subnormal_comb =
            (exp_b == 0) && (b[22:0] != 0);

        a_infinity_comb =
            (exp_a == 8'hFF) && (a[22:0] == 0);

        b_infinity_comb =
            (exp_b == 8'hFF) && (b[22:0] == 0);

        a_nan_comb =
            (exp_a == 8'hFF) && (a[22:0] != 0);

        b_nan_comb =
            (exp_b == 8'hFF) && (b[22:0] != 0);

        product_comb =
            significand_a * significand_b;

    end

    // ------------------------------------------------
    // Registered output.
    // ------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            valid_out <= 1'b0;

            sign_out <= 1'b0;
            exponent_out <= '0;
            product_out <= '0;

            a_is_zero <= 1'b0;
            b_is_zero <= 1'b0;

            a_is_subnormal <= 1'b0;
            b_is_subnormal <= 1'b0;

            a_is_infinity <= 1'b0;
            b_is_infinity <= 1'b0;

            a_is_nan <= 1'b0;
            b_is_nan <= 1'b0;

        end
        else begin

            valid_out <= valid_in;

            if (valid_in) begin

                sign_out <= sign_comb;
                exponent_out <= exponent_comb;
                product_out <= product_comb;

                a_is_zero <= a_zero_comb;
                b_is_zero <= b_zero_comb;

                a_is_subnormal <= a_subnormal_comb;
                b_is_subnormal <= b_subnormal_comb;

                a_is_infinity <= a_infinity_comb;
                b_is_infinity <= b_infinity_comb;

                a_is_nan <= a_nan_comb;
                b_is_nan <= b_nan_comb;

            end

        end

    end

endmodule
