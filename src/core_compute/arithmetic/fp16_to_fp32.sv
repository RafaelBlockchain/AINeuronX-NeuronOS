
`timescale 1ns/1ps

module fp16_to_fp32 (
    input  logic [15:0] fp16,
    output logic [31:0] fp32
);

    logic        sign;
    logic [4:0]  exponent;
    logic [9:0]  fraction;

    logic [7:0]  exponent32;
    logic [22:0] fraction32;

    integer i;
    integer highest_bit;

    always_comb begin

        sign        = fp16[15];
        exponent    = fp16[14:10];
        fraction    = fp16[9:0];

        exponent32  = 8'd0;
        fraction32  = 23'd0;
        highest_bit = -1;

        if (exponent == 5'd0) begin

            if (fraction == 10'd0) begin
                // Positive or negative zero.
                exponent32 = 8'd0;
                fraction32 = 23'd0;
            end
            else begin
                // Normalize FP16 subnormal.
                for (i = 9; i >= 0; i = i - 1) begin
                    if (fraction[i] && highest_bit == -1)
                        highest_bit = i;
                end

                // FP32 exponent = highest_bit + 103.
                exponent32 = highest_bit + 103;

                // Remove implicit leading one and align fraction.
                fraction32 =
                    ({13'd0, fraction} << (23 - highest_bit))
                    & 23'h7FFFFF;
            end

        end
        else if (exponent == 5'b11111) begin

            // Infinity or NaN.
            exponent32 = 8'hFF;

            // Preserve the available FP16 payload bits.
            fraction32 = {fraction, 13'd0};

        end
        else begin

            // Normal FP16 -> normal FP32.
            exponent32 = exponent + 8'd112;
            fraction32 = {fraction, 13'd0};

        end

        fp32 = {
            sign,
            exponent32,
            fraction32
        };

    end

endmodule
