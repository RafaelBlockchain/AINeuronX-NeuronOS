
// =====================================================
// AINEURONX_CORE_VECTOR.SV
// Pipeline vectorizado + ready/backpressure + prefetch
// =====================================================
`timescale 1ns/1ps

module aineuronx_core_vector #(
    parameter int DATA_WIDTH = 16,
    parameter int LANES      = 4
)(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    valid_in,
    input  logic                    select_precision,
    input  logic                    prefetch_enable,

    input  logic [DATA_WIDTH-1:0]   input_a [LANES],
    input  logic [DATA_WIDTH-1:0]   input_b [LANES],

    output logic                    ready_out,
    output logic [DATA_WIDTH-1:0]   output_data [LANES]
);

    logic valid_d;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_d     <= 1'b0;
            ready_out   <= 1'b0;
            for (int i = 0; i < LANES; i++) output_data[i] <= '0;
        end else begin
            valid_d   <= valid_in && prefetch_enable;
            ready_out <= valid_d;

            if (valid_d) begin
                for (int i = 0; i < LANES; i++) begin
                    if (select_precision)
                        output_data[i] <= input_a[i] + input_b[i];
                    else
                        output_data[i] <= input_a[i] - input_b[i];
                end
            end
        end
    end

endmodule
