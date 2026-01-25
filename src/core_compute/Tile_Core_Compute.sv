`timescale 1ns/1ps

module Tile_Core_Compute #(
    parameter FLIT_W = 64,
    parameter TX_COUNT = 16
)(
    input  wire clk,
    input  wire rst_n,

    // TX hacia NoC
    output reg  [FLIT_W-1:0] noc_tx_flit,
    output reg               noc_tx_valid,
    input  wire              noc_tx_ready,

    // RX desde NoC
    input  wire [FLIT_W-1:0] noc_rx_flit,
    input  wire              noc_rx_valid,
    output reg               noc_rx_ready
);

    reg [31:0] tx_cnt;
    reg [31:0] rx_cnt;

    // -------------------------
    // TX logic
    // -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt       <= 0;
            noc_tx_valid <= 0;
            noc_tx_flit  <= 0;
        end else begin
            if (tx_cnt < TX_COUNT) begin
                noc_tx_valid <= 1'b1;
                if (noc_tx_ready) begin
                    noc_tx_flit <= tx_cnt;
                    tx_cnt <= tx_cnt + 1;
                end
            end else begin
                noc_tx_valid <= 1'b0;
            end
        end
    end

    // -------------------------
    // RX logic
    // -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt       <= 0;
            noc_rx_ready <= 1'b1;
        end else begin
            if (noc_rx_valid && noc_rx_ready) begin
                rx_cnt <= rx_cnt + 1;
                $display("[%0t] RX flit = %0d", $time, noc_rx_flit);
            end
        end
    end

    // -------------------------
    // Report
    // -------------------------
    always @(posedge clk) begin
        if (tx_cnt == TX_COUNT && rx_cnt == TX_COUNT) begin
            $display("==================================");
            $display(" NoC TEST PASSED");
            $display(" TX = %0d  RX = %0d", tx_cnt, rx_cnt);
            $display("==================================");
            $finish;
        end
    end

endmodule
