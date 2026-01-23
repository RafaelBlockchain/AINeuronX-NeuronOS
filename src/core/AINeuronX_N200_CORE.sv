`timescale 1ns/1ps

module AINeuronX_N200_CORE #(
    parameter int DW  = 16,
    parameter int OPW = 4
)(
    input  logic              clk,
    input  logic              rst_n,

    input  logic              in_valid,
    output logic              in_ready,
    input  logic [DW-1:0]     a,
    input  logic [DW-1:0]     b,
    input  logic [OPW-1:0]    op,

    output logic              out_valid,
    input  logic              out_ready,
    output logic [DW-1:0]     result
);

    // ================= Pipeline registers =================
    logic [DW-1:0] a_d, b_d;
    logic          valid_d;

    /* verilator lint_off UNUSEDSIGNAL */
    logic [OPW-1:0] op_d;   // reservado para futuras operaciones
    /* verilator lint_on UNUSEDSIGNAL */

    // ================= Handshake =================
    assign in_ready  = !valid_d || out_ready;
    assign out_valid = valid_d;

    // ================= Sequential =================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d     <= '0;
            b_d     <= '0;
            op_d    <= '0;
            valid_d <= 1'b0;
        end else if (in_valid && in_ready) begin
            a_d     <= a;
            b_d     <= b;
            op_d    <= op;
            valid_d <= 1'b1;
        end else if (out_ready) begin
            valid_d <= 1'b0;
        end
    end

    // ================= Compute =================
    always_comb begin
        result = a_d + b_d; // operación base (ADD)
    end

endmodule
