`timescale 1ns / 1ps

module systolic_buffer #(
    parameter int DATA_WIDTH = 16,
    parameter int ROWS       = 2,
    parameter int COLS       = 2,
    parameter int K_DIM      = 2
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

    logic signed [DATA_WIDTH-1:0] a_mem [0:ROWS-1][0:K_DIM-1];
    logic signed [DATA_WIDTH-1:0] b_mem [0:K_DIM-1][0:COLS-1];

    always_comb begin
        a_feed  = '0;
        b_feed  = '0;
        valid_a = '0;
        valid_b = '0;

        if (feed_enable) begin
            // A: skew por fila.
            for (int r = 0; r < ROWS; r++) begin
                automatic int a_k = $signed(cycle_count) - r;
                if ((a_k >= 0) && (a_k < K_DIM)) begin
                    a_feed[r*DATA_WIDTH +: DATA_WIDTH] = a_mem[r][a_k];
                    valid_a[r] = 1'b1;
                end
            end

            // B: skew por columna.
            for (int c = 0; c < COLS; c++) begin
                automatic int b_k = $signed(cycle_count) - c;
                if ((b_k >= 0) && (b_k < K_DIM)) begin
                    b_feed[c*DATA_WIDTH +: DATA_WIDTH] = b_mem[b_k][c];
                    valid_b[c] = 1'b1;
                end
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
        end
        else if (load) begin
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
        if (DATA_WIDTH < 1 ||
            ROWS < 1 ||
            COLS < 1 ||
            K_DIM < 1) begin
            $fatal(1, "Invalid systolic_buffer parameters");
        end
    end
`endif

endmodule
