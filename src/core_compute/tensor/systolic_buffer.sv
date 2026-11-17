`timescale 1ns / 1ps

module systolic_buffer #(
    parameter int DATA_WIDTH = 16,
    parameter int ROWS       = 8,
    parameter int COLS       = 8,
    parameter int K_DIM      = 8
) (
    input  logic clk,
    input  logic rst_n,

    input  logic load,
    input  logic feed_enable,

    input  logic [ROWS*K_DIM*DATA_WIDTH-1:0] matrix_a,
    input  logic [K_DIM*COLS*DATA_WIDTH-1:0] matrix_b,

    input  logic [31:0] cycle_count,

    output logic [ROWS*DATA_WIDTH-1:0] a_feed,
    output logic [ROWS-1:0]            valid_a,
    output logic [COLS*DATA_WIDTH-1:0] b_feed,
    output logic [COLS-1:0]            valid_b
);

    localparam int K_IDX_W = (K_DIM > 1) ? $clog2(K_DIM) : 1;

    logic signed [DATA_WIDTH-1:0] a_mem [0:ROWS-1][0:K_DIM-1];
    logic signed [DATA_WIDTH-1:0] b_mem [0:K_DIM-1][0:COLS-1];

    logic [ROWS*DATA_WIDTH-1:0] a_feed_next;
    logic [ROWS-1:0]            valid_a_next;
    logic [COLS*DATA_WIDTH-1:0] b_feed_next;
    logic [COLS-1:0]            valid_b_next;

    logic signed [9:0] cycle_short;
    assign cycle_short = $signed(cycle_count[9:0]);

    always_comb begin
        logic signed [9:0]  a_k;
        logic signed [9:0]  b_k;
        logic [K_IDX_W-1:0] a_idx;
        logic [K_IDX_W-1:0] b_idx;

        a_k          = 10'sd0;
        b_k          = 10'sd0;
        a_idx        = '0;
        b_idx        = '0;
        a_feed_next  = a_feed;
        b_feed_next  = b_feed;
        valid_a_next = '0;
        valid_b_next = '0;

        if (feed_enable) begin
            for (int r = 0; r < ROWS; r++) begin
                a_k = cycle_short - 10'(r);
                if ((a_k >= 10'sd0) && (a_k < 10'(K_DIM))) begin
                    a_idx = a_k[K_IDX_W-1:0];
                    a_feed_next[r*DATA_WIDTH +: DATA_WIDTH] = a_mem[r][a_idx];
                    valid_a_next[r] = 1'b1;
                end
            end

            for (int c = 0; c < COLS; c++) begin
                b_k = cycle_short - 10'(c);
                if ((b_k >= 10'sd0) && (b_k < 10'(K_DIM))) begin
                    b_idx = b_k[K_IDX_W-1:0];
                    b_feed_next[c*DATA_WIDTH +: DATA_WIDTH] = b_mem[b_idx][c];
                    valid_b_next[c] = 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_feed  <= '0;
            valid_a <= '0;
            b_feed  <= '0;
            valid_b <= '0;
        end else begin
            valid_a <= valid_a_next;
            valid_b <= valid_b_next;
            if (feed_enable) begin
                a_feed <= a_feed_next;
                b_feed <= b_feed_next;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int r = 0; r < ROWS; r++) begin
                for (int k = 0; k < K_DIM; k++) begin
                    a_mem[r][k] <= '0;
                end
            end
            for (int k = 0; k < K_DIM; k++) begin
                for (int c = 0; c < COLS; c++) begin
                    b_mem[k][c] <= '0;
                end
            end
        end else if (load) begin
            for (int r = 0; r < ROWS; r++) begin
                for (int k = 0; k < K_DIM; k++) begin
                    a_mem[r][k] <= $signed(
                        matrix_a[(r*K_DIM+k)*DATA_WIDTH +: DATA_WIDTH]
                    );
                end
            end
            for (int k = 0; k < K_DIM; k++) begin
                for (int c = 0; c < COLS; c++) begin
                    b_mem[k][c] <= $signed(
                        matrix_b[(k*COLS+c)*DATA_WIDTH +: DATA_WIDTH]
                    );
                end
            end
        end
    end

`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1 || ROWS < 1 || COLS < 1 || K_DIM < 1 ||
            ROWS > 256 || COLS > 256 || K_DIM > 256)
            $fatal(1, "Invalid systolic_buffer parameters");
    end
`endif

endmodule
