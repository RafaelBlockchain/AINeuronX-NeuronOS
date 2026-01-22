// =====================================================
// AINeuronX_N200_CORE.SV
// Core vectorizado – pipeline profundo, V lanes
// Prefetch dinámico + backpressure industrial
// =====================================================
`timescale 1ns/1ps

module aineuronx_n200_core #(
    parameter int DATA_WIDTH   = 16,
    parameter int VECTOR_LANES = 4,
    parameter int PIPE_DEPTH   = 3   // pipeline profundo
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        valid_in,
    input  logic                        prefetch_enable,
    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_a,
    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_b,
    output logic                        ready_out,
    output logic [DATA_WIDTH*VECTOR_LANES-1:0] output_data
);

    // -------------------------------------------------
    // Pipeline interno por lane
    // -------------------------------------------------
    logic [DATA_WIDTH-1:0] a_lanes     [VECTOR_LANES-1:0];
    logic [DATA_WIDTH-1:0] b_lanes     [VECTOR_LANES-1:0];
    logic [DATA_WIDTH-1:0] out_lanes   [VECTOR_LANES-1:0];
    logic                   valid_pipe [PIPE_DEPTH-1:0];

    // -------------------------------------------------
    // Inicialización
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int l=0; l<VECTOR_LANES; l++) begin
                out_lanes[l] <= '0;
            end
            for (int p=0; p<PIPE_DEPTH; p++)
                valid_pipe[p] <= 1'b0;
            ready_out <= 1'b0;
            output_data <= '0;
        end else begin
            // Shift pipeline
            valid_pipe[0] <= valid_in && prefetch_enable;
            for (int p=1; p<PIPE_DEPTH; p++)
                valid_pipe[p] <= valid_pipe[p-1];

            ready_out <= !valid_pipe[PIPE_DEPTH-1]; // backpressure real

            // Cargar lanes solo si hay entrada válida
            if (valid_pipe[0]) begin
                for (int l=0; l<VECTOR_LANES; l++) begin
                    a_lanes[l] <= input_a[l*DATA_WIDTH +: DATA_WIDTH];
                    b_lanes[l] <= input_b[l*DATA_WIDTH +: DATA_WIDTH];
                end
            end

            // Calcular salida pipeline profunda
            if (valid_pipe[PIPE_DEPTH-1]) begin
                for (int l=0; l<VECTOR_LANES; l++) begin
                    out_lanes[l] <= a_lanes[l] + b_lanes[l]; // operación vector
                end

                // Reconstruir output_data
                for (int l=0; l<VECTOR_LANES; l++)
                    output_data[l*DATA_WIDTH +: DATA_WIDTH] <= out_lanes[l];
            end
        end
    end

endmodule
