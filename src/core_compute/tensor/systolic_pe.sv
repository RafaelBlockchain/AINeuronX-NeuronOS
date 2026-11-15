`timescale 1ns/1ps

module systolic_pe #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32
)(
    input  logic clk,
    input  logic rst_n,

    // Control
    input  logic valid_in,
    input  logic clear_acc,

    // Systolic inputs
    input  logic signed [DATA_WIDTH-1:0] a_in,
    input  logic signed [DATA_WIDTH-1:0] b_in,

    // Systolic outputs
    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic signed [DATA_WIDTH-1:0] b_ou
