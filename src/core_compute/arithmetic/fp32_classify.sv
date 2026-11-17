
`timescale 1ns/1ps

module fp32_classify (
    input  logic [31:0] x,

    output logic        sign,
    output logic [7:0]  exponent,
    output logic [22:0] fraction,

    output logic        is_zero,
    output logic        is_subnormal,
    output logic        is_normal,
    output logic        is_infinity,
    output logic        is_nan,

    output logic        is_quiet_nan,
    output logic        is_signaling_nan
);

    always_comb begin

        // Extract IEEE 754 binary32 fields.
        sign     = x[31];
        exponent = x[30:23];
        fraction = x[22:0];

        // Default classifications.
        is_zero           = 1'b0;
        is_subnormal      = 1'b0;
        is_normal         = 1'b0;
        is_infinity       = 1'b0;
        is_nan            = 1'b0;
        is_quiet_nan      = 1'b0;
        is_signaling_nan  = 1'b0;

        // Classification.
        if (exponent == 8'h00) begin

            if (fraction == 23'd0) begin
                is_zero = 1'b1;
            end
            else begin
                is_subnormal = 1'b1;
            end

        end
        else if (exponent == 8'hFF) begin

            if (fraction == 23'd0) begin
                is_infinity = 1'b1;
            end
            else begin
                is_nan = 1'b1;

                // IEEE 754 quiet/signaling convention:
                // Most significant fraction bit = 1 -> quiet NaN.
                // Most significant fraction bit = 0 -> signaling NaN.
                if (fraction[22])
                    is_quiet_nan = 1'b1;
                else
                    is_signaling_nan = 1'b1;
            end

        end
        else begin
            is_normal = 1'b1;
        end

    end

endmodule
