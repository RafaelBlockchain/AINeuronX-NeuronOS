
`timescale 1ns/1ps

module int16_mac (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    clear_acc,
    input  logic                    valid_in,

    input  logic signed [15:0]      a,
    input  logic signed [15:0]      b,

    input  logic signed [34:0]      acc_in,

    output logic signed [34:0]      acc_out,
    output logic                    valid_out
);

    // Producto signed INT16 x INT16 = INT32.
    logic signed [31:0] product_comb;

    // Producto extendido con signo a INT35.
    logic signed [34:0] product_ext;

    // Resultado combinacional de la operación MAC.
    logic signed [34:0] mac_result;

    always_comb begin
        product_comb = $signed(a) * $signed(b);

        product_ext = {
            {3{product_comb[31]}},
            product_comb
        };

        mac_result = $signed(acc_in) + $signed(product_ext);
    end

    // Registro de salida: latencia de un ciclo.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_out   <= '0;
            valid_out <= 1'b0;
        end
        else if (clear_acc) begin
            acc_out   <= '0;
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= valid_in;

            if (valid_in) begin
                acc_out <= mac_result;
            end
        end
    end

endmodule
