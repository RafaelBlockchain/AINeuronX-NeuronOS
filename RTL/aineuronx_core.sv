// =====================================================
// AINEURONX_CORE.SV
// Core mínimo funcional – pipeline 1 ciclo
// =====================================================
`timescale 1ns/1ps

module aineuronx_core #(
    parameter int DATA_WIDTH = 16
)(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    valid_in,
    input  logic                    select_precision,
    input  logic                    prefetch_enable,

    input  logic [DATA_WIDTH-1:0]   input_a,
    input  logic [DATA_WIDTH-1:0]   input_b,

    output logic                    ready_out,
    output logic [DATA_WIDTH-1:0]   output_data
);

    logic valid_d;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_d     <= 1'b0;
            ready_out   <= 1'b0;
            output_data <= '0;
        end else begin
            valid_d   <= valid_in && prefetch_enable;
            ready_out <= valid_d;

            if (valid_d) begin
                if (select_precision)
                    output_data <= input_a + input_b;
                else
                    output_data <= input_a - input_b;
            end
        end
    end

endmodule
