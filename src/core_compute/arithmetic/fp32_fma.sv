module fp32_fma (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,

    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,

    output logic        valid_out,
    output logic [31:0] result
);
