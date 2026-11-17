
`timescale 1ns/1ps

module fp32_round_rne (

    input  logic               valid_in,
    input  logic               sign_in,
    input  logic signed [10:0] exponent_in,

    input  logic [23:0]        significand_in,

    input  logic               guard_in,
    input  logic               round_in,
    input  logic               sticky_in,

    input  logic               is_zero_in,

    output logic               valid_out,
    output logic [31:0]        fp32_out

);

    logic [26:0] extended_sig;
    logic [26:0] shifted_sig;

    logic [23:0] rounded_sig;

    logic [7:0] exponent_field;

    logic guard_bit;
    logic round_bit;
    logic sticky_bit;

    logic round_increment;

    integer signed adjusted_exponent;
    integer shift_amount;
    integer i;

    logic sticky_acc;

    // ------------------------------------------------
    // Right shift with sticky preservation.
    // ------------------------------------------------

    function automatic [26:0] shift_right_jam (
        input logic [26:0] value,
        input integer amount
    );

        logic sticky;
        logic [26:0] shifted;
        integer j;

        begin
            sticky = 1'b0;

            if (amount <= 0) begin
                shift_right_jam = value;
            end
            else if (amount >= 27) begin
                shift_right_jam = {
                    26'd0,
                    (|value)
                };
            end
            else begin

                shifted = value >> amount;

                for (j = 0; j < 27; j = j + 1) begin
                    if (j < amount)
                        sticky = sticky | value[j];
                end

                shifted[0] = shifted[0] | sticky;

                shift_right_jam = shifted;

            end
        end

    endfunction

    // ------------------------------------------------
    // RNE rounding and IEEE 754 binary32 packing.
    // ------------------------------------------------

    always_comb begin

        valid_out = valid_in;
        fp32_out  = 32'd0;

        extended_sig = {
            significand_in,
            guard_in,
            round_in,
            sticky_in
        };

        shifted_sig = extended_sig;

        rounded_sig = 24'd0;

        exponent_field = 8'd0;

        guard_bit  = 1'b0;
        round_bit  = 1'b0;
        sticky_bit = 1'b0;

        round_increment = 1'b0;

        adjusted_exponent = $signed(exponent_in);
        shift_amount = 0;

        sticky_acc = 1'b0;

        if (valid_in) begin

            if (is_zero_in || significand_in == 24'd0) begin

                // Preserve signed zero.
                fp32_out = {sign_in, 31'd0};

            end
            else begin

                // ------------------------------------------------
                // Convert normal-range exponent to subnormal
                // representation when exponent < -126.
                // ------------------------------------------------

                if (adjusted_exponent < -126) begin

                    shift_amount = -126 - adjusted_exponent;

                    shifted_sig = shift_right_jam(
                        extended_sig,
                        shift_amount
                    );

                    adjusted_exponent = -126;

                end

                // ------------------------------------------------
                // Extract significand and GRS bits.
                // ------------------------------------------------

                rounded_sig = shifted_sig[26:3];

                guard_bit  = shifted_sig[2];
                round_bit  = shifted_sig[1];
                sticky_bit = shifted_sig[0];

                // ------------------------------------------------
                // Round to nearest, ties to even.
                //
                // Increment when:
                // 1. Guard = 1 and either lower bit is nonzero.
                // 2. Exact halfway case and retained LSB is odd.
                // ------------------------------------------------

                round_increment =
                    guard_bit &&
                    (round_bit || sticky_bit || rounded_sig[0]);

                if (round_increment)
                    rounded_sig = rounded_sig + 24'd1;

                // ------------------------------------------------
                // Handle carry from rounding.
                // ------------------------------------------------

                if (adjusted_exponent == -126 &&
                    rounded_sig[23]) begin

                    // Minimum normal or a normal value.
                    exponent_field = 8'd1;

                end
                else if (rounded_sig[23]) begin

                    // Normal result.
                    exponent_field = adjusted_exponent + 127;

                end
                else begin

                    // Subnormal result.
                    exponent_field = 8'd0;

                end

                // ------------------------------------------------
                // Overflow after rounding.
                // ------------------------------------------------

                if (exponent_field >= 8'hFF ||
                    adjusted_exponent > 127) begin

                    fp32_out = {
                        sign_in,
                        8'hFF,
                        23'd0
                    };

                end
                else begin

                    fp32_out = {
                        sign_in,
                        exponent_field,
                        rounded_sig[22:0]
                    };

                end

            end

        end

    end

endmodule
