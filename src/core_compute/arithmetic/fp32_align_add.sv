
`timescale 1ns/1ps

module fp32_align_add (

    input  logic                 valid_in,

    // Product from fp32_multiplier.
    input  logic                 product_sign,
    input  logic signed [10:0]   product_exponent,
    input  logic [47:0]          product,

    // Third operand C (FP32).
    input  logic [31:0]          c,

    output logic                 valid_out,

    // Common exponent after alignment.
    output logic signed [10:0]   exponent_out,

    // Signed aligned sum, including guard/round/sticky
    // information in its three least significant positions.
    output logic signed [52:0]   sum_out,

    output logic                 result_sign
);

    logic [7:0]  c_exponent_field;
    logic [22:0] c_fraction;

    logic [23:0] c_significand;
    logic signed [10:0] c_exponent;

    logic [10:0] common_exponent;
    logic [10:0] product_shift;
    logic [10:0] c_shift;

    logic [52:0] product_extended;
    logic [52:0] c_extended;

    logic [52:0] product_aligned;
    logic [52:0] c_aligned;

    logic [52:0] magnitude_sum;
    logic [52:0] magnitude_product;
    logic [52:0] magnitude_c;

    logic [52:0] shifted_product;
    logic [52:0] shifted_c;

    logic c_sign;

    // ------------------------------------------------
    // Right shift with sticky-bit preservation.
    // ------------------------------------------------

    function automatic [52:0] shift_right_jam (
        input logic [52:0] value,
        input integer shift_amount
    );

        logic sticky;
        logic [52:0] shifted;
        integer i;

        begin
            sticky = 1'b0;

            if (shift_amount <= 0) begin
                shift_right_jam = value;
            end
            else if (shift_amount >= 53) begin
                shift_right_jam = {
                    52'd0,
                    (|value)
                };
            end
            else begin

                shifted = value >> shift_amount;

                for (i = 0; i < 53; i = i + 1) begin
                    if (i < shift_amount)
                        sticky = sticky | value[i];
                end

                shifted[0] = shifted[0] | sticky;

                shift_right_jam = shifted;

            end
        end

    endfunction

    // ------------------------------------------------
    // Decode finite operand C.
    // Special values must be handled by the FMA
    // special-case control path, not this arithmetic path.
    // ------------------------------------------------

    always_comb begin

        c_exponent_field = c[30:23];
        c_fraction       = c[22:0];
        c_sign           = c[31];

        if (c_exponent_field == 8'd0) begin

            c_significand = {1'b0, c_fraction};
            c_exponent = -11'sd126;

        end
        else begin

            c_significand = {1'b1, c_fraction};
            c_exponent =
                $signed({3'b000, c_exponent_field})
                - 11'sd127;

        end

    end

    // ------------------------------------------------
    // Align product and C to a common exponent.
    //
    // Product:
    // product * 2^(product_exponent - 46)
    //
    // C:
    // c_significand * 2^(c_exponent - 23)
    //
    // Three low bits are reserved for GRS information.
    // ------------------------------------------------

    always_comb begin

        if (product_exponent >= c_exponent)
            common_exponent = product_exponent;
        else
            common_exponent = c_exponent;

        // Product significand: 48 bits + 3 GRS positions.
        product_extended = {
            2'b00,
            product,
            3'b000
        };

        // C significand: 24 bits shifted into the same
        // fixed-point representation.
        c_extended = {
            3'b000,
            c_significand,
            26'b0
        };

        product_shift = common_exponent - product_exponent;
        c_shift       = common_exponent - c_exponent;

        shifted_product = shift_right_jam(
            product_extended,
            product_shift
        );

        shifted_c = shift_right_jam(
            c_extended,
            c_shift
        );

        product_aligned = shifted_product;
        c_aligned       = shifted_c;

        magnitude_product = product_aligned;
        magnitude_c       = c_aligned;

        magnitude_sum = 53'd0;

        exponent_out = $signed(common_exponent);

        // ------------------------------------------------
        // Signed magnitude addition/subtraction.
        // ------------------------------------------------

        if (product_sign == c_sign) begin

            magnitude_sum =
                magnitude_product + magnitude_c;

            result_sign = product_sign;

        end
        else begin

            if (magnitude_product >= magnitude_c) begin

                magnitude_sum =
                    magnitude_product - magnitude_c;

                result_sign = product_sign;

            end
            else begin

                magnitude_sum =
                    magnitude_c - magnitude_product;

                result_sign = c_sign;

            end

        end

        // Convert magnitude to signed two's complement.
        if (result_sign)
            sum_out = -$signed(magnitude_sum);
        else
            sum_out = $signed(magnitude_sum);

        valid_out = valid_in;

    end

endmodule
