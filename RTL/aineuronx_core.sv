// =====================================================
// AINEURONX_CORE.SV
// Core de cómputo pipelineado (latencia fija = 3 ciclos)
// =====================================================
`timescale 1ns/1ps

module aineuronx_core (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        valid_in,
    input  logic        prefetch_enable,
    input  logic        select_precision,

    input  logic [15:0] input_a,
    input  logic [15:0] input_b,

    output logic        ready_out,
    output logic [15:0] output_data
);

    // -------------------------------
    // Pipeline registers
    // -------------------------------
    logic        vld_s0, vld_s1, vld_s2;
    logic        prec_s0, prec_s1;
    logic [15:0] a_s0, b_s0;
    logic [15:0] alu_s1;
    logic [15:0] out_s2;

    // -------------------------------
    // Stage 0 — Input latch
    // -------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            vld_s0 <= 1'b0;
        end else begin
            vld_s0 <= valid_in && prefetch_enable;
            if (valid_in && prefetch_enable) begin
                a_s0    <= input_a;
                b_s0    <= input_b;
                prec_s0 <= select_precision;
            end
        end
    end

    // -------------------------------
    // Stage 1 — Execute
    // -------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            vld_s1 <= 1'b0;
        end else begin
            vld_s1 <= vld_s0;
            prec_s1 <= prec_s0;

            if (vld_s0) begin
                if (prec_s0)
                    alu_s1 <= a_s0 + b_s0;
                else
                    alu_s1 <= a_s0 - b_s0;
            end
        end
    end

    // -------------------------------
    // Stage 2 — Writeback
    // -------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            vld_s2 <= 1'b0;
        end else begin
            vld_s2 <= vld_s1;
            if (vld_s1)
                out_s2 <= alu_s1;
        end
    end

    // -------------------------------
    // Outputs
    // -------------------------------
    assign ready_out  = vld_s2;
    assign output_data = out_s2;

endmodule
