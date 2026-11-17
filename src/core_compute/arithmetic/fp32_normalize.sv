
`timescale 1ns/1ps

module fp32_normalize (

    input  logic signed [52:0] sum_in,
    input  logic signed [10:0] exponent_in,
    input  logic               sign_in,
    input  logic               valid_in,

    output logic               valid_out,
    output logic               sign_out,

    output logic signed [10:0] exponent_out,

    // 24-bit significand, including the implicit bit.
    output logic [23:0] significand_out,

    // Guard, round and sticky bits.
    output logic        guard_out,
    output logic        round_out,
    output logic        sticky_out,

    output logic        is_zero_out,
    output logic        is_subnormal_out
);

    logic [52:0] magnitude;

    integer highest_bit;
    integer shift_amount;
    integer i;

    integer signed adjusted_exponent;

    logic [52:0] shifted_magnitude;

    always_comb begin

        // Defaults.
        magnitude          = 53'd0;
        highest_bit        = -1;
        shift_amount       = 0;
        adjusted_exponent  = 0;

        shifted_magnitude  = 53'd0;

        valid_out          = valid_in;
        sign_out           = sign_in;

        exponent_out       = 11'sd0;
        significand_out    = 24'd0;

        guard_out          = 1'b0;
        round_out          = 1'b0;
        sticky_out         = 1'b0;

        is_zero_out        = 1'b0;
        is_subnormal_out   = 1'b0;

        // ------------------------------------------------
        // Absolute magnitude.
        // ------------------------------------------------

        if (sum_in[52])
            magnitude = $unsigned(-sum_in);
        else
            magnitude = $unsigned(sum_in);

        // ------------------------------------------------
        // Detect zero.
        // ------------------------------------------------

        if (magnitude == 0) begin

            is_zero_out = 1'b1;

        end
        else begin

            // ------------------------------------------------
            // Find highest significant bit.
            // ------------------------------------------------

            for (i = 52; i >= 0; i = i - 1) begin

                if (magnitude[i] && highest_bit == -1)
                    highest_bit = i;

            end

            // ------------------------------------------------
            // Normalize to bit position 26.
            //
            // [26] = leading significand bit
            // [25:3] = remaining significand bits
            // [2] = guard
            // [1] = round
            // [0] = sticky
            // ------------------------------------------------

            shift_amount = highest_bit - 26;

            if (shift_amount > 0)
                shifted_magnitude = magnitude >> shift_amount;
            else
                shifted_magnitude = magnitude << (-shift_amount);

            adjusted_exponent =
                $signed(exponent_in) + shift_amount;

            exponent_out = adjusted_exponent;

            significand_out = {
                shifted_magnitude[26],
                shifted_magnitude[25:3]
            };

            guard_out  = shifted_magnitude[2];
            round_out  = shifted_magnitude[1];
            sticky_out = shifted_magnitude[0];

            // ------------------------------------------------
            // Determine subnormal result.
            // ------------------------------------------------

            if (adjusted_exponent < -126) begin

                is_subnormal_out = 1'b1;

            end

        end

    end

endmodule
