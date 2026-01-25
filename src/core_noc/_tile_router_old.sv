`timescale 1ns/1ps
module tile_router #(
    parameter DW = 8,
    parameter PORTS = 5,   // N, S, E, W, L
    parameter X_ID = 0,
    parameter Y_ID = 0
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [DW-1:0] n_data, s_data, e_data, w_data, l_data,
    input  logic n_valid, s_valid, e_valid, w_valid, l_valid,
    output logic [DW-1:0] n_out, s_out, e_out, w_out, l_out,
    output logic n_ready, s_ready, e_ready, w_ready, l_ready,
    input  logic tile_active
);

    // ===== Clock/Power gating =====
    logic clk_gated;
    Tile_Power pg(
        .clk_in(clk),
        .rst_n(rst_n),
        .tile_active(tile_active),
        .clk_out(clk_gated)
    );

    // ===== Arbiter =====
    logic [PORTS-1:0] req, grant;
    assign req = {l_valid, w_valid, e_valid, s_valid, n_valid};
    Tile_Arbiter arb(
        .clk(clk_gated),
        .rst_n(rst_n),
        .req(req),
        .grant(grant)
    );

    // ===== FIFOs =====
    logic [DW-1:0] fifo_dout [PORTS-1:0];
    logic fifo_empty [PORTS-1:0], fifo_full [PORTS-1:0];

    Tile_FIFO #( .DW(DW) ) fifoN(.clk(clk_gated), .rst_n(rst_n), .push(n_valid), .pop(grant[4]),
                                 .din(n_data), .dout(fifo_dout[4]), .empty(fifo_empty[4]), .full(fifo_full[4]));
    Tile_FIFO #( .DW(DW) ) fifoS(.clk(clk_gated), .rst_n(rst_n), .push(s_valid), .pop(grant[3]),
                                 .din(s_data), .dout(fifo_dout[3]), .empty(fifo_empty[3]), .full(fifo_full[3]));
    Tile_FIFO #( .DW(DW) ) fifoE(.clk(clk_gated), .rst_n(rst_n), .push(e_valid), .pop(grant[2]),
                                 .din(e_data), .dout(fifo_dout[2]), .empty(fifo_empty[2]), .full(fifo_full[2]));
    Tile_FIFO #( .DW(DW) ) fifoW(.clk(clk_gated), .rst_n(rst_n), .push(w_valid), .pop(grant[1]),
                                 .din(w_data), .dout(fifo_dout[1]), .empty(fifo_empty[1]), .full(fifo_full[1]));
    Tile_FIFO #( .DW(DW) ) fifol(.clk(clk_gated), .rst_n(rst_n), .push(l_valid), .pop(grant[0]),
                                 .din(l_data), .dout(fifo_dout[0]), .empty(fifo_empty[0]), .full(fifo_full[0]));

    // ===== Ready signals =====
    assign {n_ready, s_ready, e_ready, w_ready, l_ready} = grant & ~fifo_full;

    // ===== Outputs =====
    assign n_out = fifo_dout[4];
    assign s_out = fifo_dout[3];
    assign e_out = fifo_dout[2];
    assign w_out = fifo_dout[1];
    assign l_out = fifo_dout[0];

    // ===== Metrics integration =====
    Tile_Metrics metrics(
        .clk(clk_gated),
        .rst_n(rst_n),
        .mac_fire(grant),   // ejemplo simple
        .noc_send(grant),
        .stall(fifo_full)
    );

endmodule
