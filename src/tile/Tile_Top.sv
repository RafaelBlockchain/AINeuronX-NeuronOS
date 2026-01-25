`timescale 1ns/1ps
import noc_types::*;

module Tile_Top #(
    parameter int X_ID = 0,
    parameter int Y_ID = 0
)(
    input  logic clk,
    input  logic rst_n,
    input  logic tile_active,

    // === Mesh ports ===
    input  flit_t n_in_flit, s_in_flit, e_in_flit, w_in_flit,
    input  logic  n_in_valid, s_in_valid, e_in_valid, w_in_valid,
    output logic  n_in_ready, s_in_ready, e_in_ready, w_in_ready,

    output flit_t n_out_flit, s_out_flit, e_out_flit, w_out_flit,
    output logic  n_out_valid, s_out_valid, e_out_valid, w_out_valid,
    input  logic  n_out_ready, s_out_ready, e_out_ready, w_out_ready
);

    // =========================
    // Internal signals
    // =========================
    flit_t router_in_flit  [4:0];
    logic  router_in_valid [4:0];
    logic  router_in_ready [4:0];

    flit_t router_out_flit [4:0];
    logic  router_out_valid[4:0];
    logic  router_out_ready[4:0];

    // =========================
    // Core <-> Adapter signals
    // =========================
    flit_t core_tx_flit, core_rx_flit;
    logic  core_tx_valid, core_tx_ready;
    logic  core_rx_valid, core_rx_ready;

    // =========================
    // Core
    // =========================
    Tile_Core core (
        .clk(clk),
        .rst_n(rst_n),
        .noc_tx_flit(core_tx_flit),
        .noc_tx_valid(core_tx_valid),
        .noc_tx_ready(core_tx_ready),
        .noc_rx_flit(core_rx_flit),
        .noc_rx_valid(core_rx_valid),
        .noc_rx_ready(core_rx_ready),
        .core_active(tile_active)
    );

    // =========================
    // NoC Adapter (LOCAL port)
    // =========================
    Tile_NOC_Adapter adapter (
        .clk(clk),
        .rst_n(rst_n),

        .core_tx_flit(core_tx_flit),
        .core_tx_valid(core_tx_valid),
        .core_tx_ready(core_tx_ready),

        .core_rx_flit(core_rx_flit),
        .core_rx_valid(core_rx_valid),
        .core_rx_ready(core_rx_ready),

        .noc_in_flit(router_in_flit[0]),
        .noc_in_valid(router_in_valid[0]),
        .noc_in_ready(router_in_ready[0]),

        .noc_out_flit(router_out_flit[0]),
        .noc_out_valid(router_out_valid[0]),
        .noc_out_ready(router_out_ready[0])
    );

    // =========================
    // Router
    // =========================
    Tile_Router #(
        .X_ID(X_ID),
        .Y_ID(Y_ID)
    ) router (
        .clk(clk),
        .rst_n(rst_n),

        .in_flit (router_in_flit),
        .in_valid(router_in_valid),
        .in_ready(router_in_ready),

        .out_flit (router_out_flit),
        .out_valid(router_out_valid),
        .out_ready(router_out_ready),

        .tile_active(tile_active)
    );

    // =========================
    // Mesh wiring (N,S,E,W)
    // =========================
    assign router_in_flit [1] = n_in_flit;
    assign router_in_valid[1] = n_in_valid;
    assign n_in_ready          = router_in_ready[1];

    assign router_in_flit [2] = s_in_flit;
    assign router_in_valid[2] = s_in_valid;
    assign s_in_ready          = router_in_ready[2];

    assign router_in_flit [3] = e_in_flit;
    assign router_in_valid[3] = e_in_valid;
    assign e_in_ready          = router_in_ready[3];

    assign router_in_flit [4] = w_in_flit;
    assign router_in_valid[4] = w_in_valid;
    assign w_in_ready          = router_in_ready[4];

    assign n_out_flit  = router_out_flit [1];
    assign n_out_valid = router_out_valid[1];
    assign router_out_ready[1] = n_out_ready;

    assign s_out_flit  = router_out_flit [2];
    assign s_out_valid = router_out_valid[2];
    assign router_out_ready[2] = s_out_ready;

    assign e_out_flit  = router_out_flit [3];
    assign e_out_valid = router_out_valid[3];
    assign router_out_ready[3] = e_out_ready;

    assign w_out_flit  = router_out_flit [4];
    assign w_out_valid = router_out_valid[4];
    assign router_out_ready[4] = w_out_ready;

endmodule
