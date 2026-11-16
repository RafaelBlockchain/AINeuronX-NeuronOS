`timescale 1ns/1ps

module Tile_Core_Compute #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32,
    parameter int LANES      = 4,
    parameter int ROWS       = 2,
    parameter int COLS       = 2,
    parameter int K_DIM      = 2
) (
    input logic clk,
    input logic rst_n,

    // -------------------------
    // Vector unit interface
    // -------------------------
    input logic vector_start,
    input logic [1:0] vector_opcode,
    input logic vector_clear_acc,

    input logic [LANES*DATA_WIDTH-1:0] vector_a,
    input logic [LANES*DATA_WIDTH-1:0] vector_b,

    output logic [LANES*ACC_WIDTH-1:0] vector_result,
    output logic vector_busy,
    output logic vector_done,

    // -------------------------
    // Tensor unit interface
    // -------------------------
    input logic tensor_load,
    input logic tensor_start,

    input logic [ROWS*K_DIM*DATA_WIDTH-1:0] matrix_a,
    input logic [K_DIM*COLS*DATA_WIDTH-1:0] matrix_b,

    output logic [ROWS*COLS*ACC_WIDTH-1:0]
        tensor_accumulators,

    output logic [ROWS*COLS-1:0]
        tensor_valid,

    output logic tensor_busy,
    output logic tensor_done
);

    // -------------------------
    // Tensor control signals
    // -------------------------
    logic clear_acc;
    logic feed_enable;
    logic [31:0] cycle_count;

    // -------------------------
    // Systolic buffer signals
    // -------------------------
    logic [ROWS*DATA_WIDTH-1:0] a_feed;
    logic [ROWS-1:0] valid_a;

    logic [COLS*DATA_WIDTH-1:0] b_feed;
    logic [COLS-1:0] valid_b;

    // Prevent loading matrices while tensor execution is active.
    logic buffer_load;

    assign buffer_load = tensor_load && !tensor_busy;

    // -------------------------
    // Vector unit
    // -------------------------
    vector_unit #(
        .LANES(LANES),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_vector_unit (
        .clk(clk),
        .rst_n(rst_n),
        .start(vector_start),
        .opcode(vector_opcode),
        .clear_acc(vector_clear_acc),
        .vector_a(vector_a),
        .vector_b(vector_b),
        .result(vector_result),
        .busy(vector_busy),
        .done(vector_done)
    );

    // -------------------------
    // Tensor controller
    // -------------------------
    systolic_ctrl #(
        .ROWS(ROWS),
        .COLS(COLS),
        .K_DIM(K_DIM)
    ) u_systolic_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(tensor_start),
        .clear_acc(clear_acc),
        .feed_enable(feed_enable),
        .busy(tensor_busy),
        .done(tensor_done),
        .cycle_count(cycle_count)
    );

    // -------------------------
    // Matrix input buffer
    // -------------------------
    systolic_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROWS(ROWS),
        .COLS(COLS),
        .K_DIM(K_DIM)
    ) u_systolic_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .load(buffer_load),
        .feed_enable(feed_enable),
        .matrix_a(matrix_a),
        .matrix_b(matrix_b),
        .cycle_count(cycle_count),
        .a_feed(a_feed),
        .valid_a(valid_a),
        .b_feed(b_feed),
        .valid_b(valid_b)
    );

    // -------------------------
    // Systolic processing array
    // -------------------------
    systolic_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .ROWS(ROWS),
        .COLS(COLS)
    ) u_systolic_array (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .a_feed(a_feed),
        .valid_a(valid_a),
        .b_feed(b_feed),
        .valid_b(valid_b),
        .accumulators(tensor_accumulators),
        .valid_out(tensor_valid)
    );

    // -------------------------
    // Parameter validation
    // -------------------------
`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1 ||
            ACC_WIDTH < 2*DATA_WIDTH ||
            LANES < 1 ||
            ROWS < 1 ||
            COLS < 1 ||
            K_DIM < 1) begin
            $fatal(1, "Invalid Tile_Core_Compute parameters");
        end
    end
`endif

endmodule
