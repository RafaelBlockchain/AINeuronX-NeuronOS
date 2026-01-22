`timescale 1ns/1ps

module aineuronx_core_vector #(
    parameter int DATA_WIDTH = 16,
    parameter int LANES      = 4,
    parameter int PIPELINE_DEPTH = 3
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     valid_in,
    input  logic                     select_precision,
    input  logic                     prefetch_enable,
    input  logic [DATA_WIDTH*LANES-1:0] input_a,
    input  logic [DATA_WIDTH*LANES-1:0] input_b,
    output logic                     ready_out,
    output logic [DATA_WIDTH*LANES-1:0] output_data
);

    // ==================================================
    // Pipeline registers
    // ==================================================
    logic [DATA_WIDTH*LANES-1:0] pipe_data [PIPELINE_DEPTH-1:0];
    logic                        pipe_valid[PIPELINE_DEPTH-1:0];

    // ==================================================
    // Inicialización
    // ==================================================
    integer i;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < PIPELINE_DEPTH; i=i+1) begin
                pipe_data[i]  <= '0;
                pipe_valid[i] <= 0;
            end
            output_data <= '0;
            ready_out   <= 0;
        end else begin
            // ------------------------------------------------
            // Shift pipeline
            // ------------------------------------------------
            for (i = PIPELINE_DEPTH-1; i > 0; i=i-1) begin
                pipe_data[i]  <= pipe_data[i-1];
                pipe_valid[i] <= pipe_valid[i-1];
            end

            // ------------------------------------------------
            // Entrada nueva
            // ------------------------------------------------
            if (valid_in && prefetch_enable) begin
                for (int l = 0; l < LANES; l++) begin
                    logic [DATA_WIDTH-1:0] a = input_a[l*DATA_WIDTH +: DATA_WIDTH];
                    logic [DATA_WIDTH-1:0] b = input_b[l*DATA_WIDTH +: DATA_WIDTH];

                    if (select_precision)
                        pipe_data[0][l*DATA_WIDTH +: DATA_WIDTH] <= a + b;
                    else
                        pipe_data[0][l*DATA_WIDTH +: DATA_WIDTH] <= a - b;
                end
                pipe_valid[0] <= 1;
            end else begin
                pipe_valid[0] <= 0;
                pipe_data[0]  <= '0;
            end

            // ------------------------------------------------
            // Salida
            // ------------------------------------------------
            output_data <= pipe_data[PIPELINE_DEPTH-1];
            ready_out   <= pipe_valid[PIPELINE_DEPTH-1];
        end
    end

endmodule

