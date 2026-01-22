// =====================================================
// AINeuronX_N200_CORE.SV
// Core vectorizado – Pipeline formal de 3 etapas
// Latencia fija: 3 ciclos
// =====================================================
`timescale 1ns/1ps

module AINeuronX_N200_CORE #(
    parameter int DATA_WIDTH   = 16,
    parameter int VECTOR_LANES = 4
)(
    input  logic clk,
    input  logic rst_n,

    input  logic valid_in,
    input  logic prefetch_enable,

    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_a,
    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_b,

    output logic ready_out,
    output logic [DATA_WIDTH*VECTOR_LANES-1:0] output_data
);

    // -------------------------
    // Stage 0
    // -------------------------
    logic valid_s0;
    logic [DATA_WIDTH-1:0] a_s0 [0:VECTOR_LANES-1];
    logic [DATA_WIDTH-1:0] b_s0 [0:VECTOR_LANES-1];

    // -------------------------
    // Stage 1
    // -------------------------
    logic valid_s1;
    logic [DATA_WIDTH-1:0] sum_s1 [0:VECTOR_LANES-1];

    // -------------------------
    // Stage 2
    // -------------------------
    logic valid_s2;
    logic [DATA_WIDTH-1:0] out_s2 [0:VECTOR_LANES-1];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_s0   <= 1'b0;
            valid_s1   <= 1'b0;
            valid_s2   <= 1'b0;
            ready_out  <= 1'b0;
            output_data <= '0;
        end else begin
            // -------- Stage 0 --------
            valid_s0 <= valid_in && prefetch_enable;
            for (int l = 0; l < VECTOR_LANES; l++) begin
                a_s0[l] <= input_a[l*DATA_WIDTH +: DATA_WIDTH];
                b_s0[l] <= input_b[l*DATA_WIDTH +: DATA_WIDTH];
            end

            // -------- Stage 1 --------
            valid_s1 <= valid_s0;
            for (int l = 0; l < VECTOR_LANES; l++) begin
                sum_s1[l] <= a_s0[l] + b_s0[l];
            end

            // -------- Stage 2 --------
            valid_s2  <= valid_s1;
            ready_out <= valid_s2;

            for (int l = 0; l < VECTOR_LANES; l++) begin
                out_s2[l] <= sum_s1[l];
                output_data[l*DATA_WIDTH +: DATA_WIDTH] <= out_s2[l];
            end
        end
    end

endmodule
