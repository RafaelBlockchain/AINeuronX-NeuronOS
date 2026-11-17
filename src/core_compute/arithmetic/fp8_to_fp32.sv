
`timescale 1ns/1ps

module fp8_to_fp32 (
    input  logic [7:0]  fp8,
    input  logic        fp8_format,

    output logic [31:0] fp32
);

    logic        sign;
    logic [4:0]  exponent;
    logic [2:0]  fraction;

    logic [7:0]  exponent32;
    logic [22:0] fraction32;

    integer bias;
    integer frac_bits;
    integer highest_bit;
    integer i;
    integer unbiased_exp;

    logic is_e4m3fn;

    always_comb begin

        sign        = fp8[7];
        exponent    = 5'd0;
        fraction    = 3'd0;

        exponent32  = 8'd0;
        fraction32  = 23'd0;

        bias        = 15;
        frac_bits   = 2;
        highest_bit = -1;
        unbiased_exp = 0;

        is_e4m3fn = (fp8_format == 1'b0);

        if (is_e4m3fn) begin
            exponent = {1'b0, fp8[6:3]};
            fraction = {1'b0, fp8[2:0]};
            bias     = 7;
            frac_bits = 3;
        end
        else begin
            exponent = fp8[6:2];
            fraction = {1'b0, fp8[1:0]};
            bias     = 15;
            frac_bits = 2;
        end

        // ------------------------------------------------
        // ZERO AND SUBNORMAL
        // ------------------------------------------------

        if (exponent == 0) begin

            if (fraction == 0) begin
                // Signed zero.
                exponent32 = 0;
                fraction32 = 0;
            end
            else begin

                // Find highest set bit in fraction.
                for (i = 2; i >= 0; i = i - 1) begin
                    if (fraction[i] && highest_bit == -1)
                        highest_bit = i;
                end

                // Normalize subnormal.
                unbiased_exp = 1 - bias - frac_bits + highest_bit;

                exponent32 = unbiased_exp + 127;

                fraction32 =
                    (fraction << (23 - highest_bit))
                    & 23'h7FFFFF;

            end

        end

        // ------------------------------------------------
        // SPECIAL VALUES: E4M3FN
        // ------------------------------------------------

        else if (is_e4m3fn &&
                 exponent == 5'd15 &&
                 fraction == 3'd7) begin

            // E4M3FN canonical NaN.
            exponent32 = 8'hFF;
            fraction32 = 23'h400000;

        end

        // ------------------------------------------------
        // SPECIAL VALUES: E5M2
        // ------------------------------------------------

        else if (!is_e4m3fn && exponent == 5'd31) begin

            exponent32 = 8'hFF;

            if (fraction == 0) begin
                // Infinity.
                fraction32 = 23'd0;
            end
            else begin
                // NaN.
                fraction32 = {fraction[1:0], 21'd0};
            end

        end

        // ------------------------------------------------
        // NORMAL FINITE VALUES
        // ------------------------------------------------

        else begin

            unbiased_exp = exponent - bias;

            exponent32 = unbiased_exp + 127;

            if (is_e4m3fn)
                fraction32 = {fraction[2:0], 20'd0};
            else
                fraction32 = {fraction[1:0], 21'd0};

        end

        fp32 = {
            sign,
            exponent32,
            fraction32
        };

    end

endmodule
