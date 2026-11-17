`timescale 1ns/1ps

module systolic_array #(
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32,
    parameter int ROWS       = 8,
    parameter int COLS       = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic clear_acc,

    input  logic [ROWS*DATA_WIDTH-1:0] a_feed,
    input  logic [ROWS-1:0]            valid_a,

    input  logic [COLS*DATA_WIDTH-1:0] b_feed,
    input  logic [COLS-1:0]            valid_b,

    output logic [ROWS*COLS*ACC_WIDTH-1:0] accumulators,
    output logic [ROWS*COLS-1:0]           valid_out
);

    logic signed [DATA_WIDTH-1:0] a_bus       [0:ROWS-1][0:COLS];
    logic signed [DATA_WIDTH-1:0] b_bus       [0:ROWS][0:COLS-1];
    logic [ROWS-1:0]              valid_a_bus [0:COLS];
    logic [COLS-1:0]              valid_b_bus [0:ROWS];

    logic [ROWS-1:0] clear_acc_row;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clear_acc_row <= '0;
        end else begin
            clear_acc_row <= {ROWS{clear_acc}};
        end
    end

    genvar r;
    genvar c;

    generate
        for (r = 0; r < ROWS; r = r + 1) begin : GEN_A_INPUT
            assign a_bus[r][0]      = $signed(a_feed[r*DATA_WIDTH +: DATA_WIDTH]);
            assign valid_a_bus[0][r] = valid_a[r];
        end
    endgenerate

    generate
        for (c = 0; c < COLS; c = c + 1) begin : GEN_B_INPUT
            assign b_bus[0][c]      = $signed(b_feed[c*DATA_WIDTH +: DATA_WIDTH]);
            assign valid_b_bus[0][c] = valid_b[c];
        end
    endgenerate

    generate
        for (r = 0; r < ROWS; r = r + 1) begin : GEN_ROW
            for (c = 0; c < COLS; c = c + 1) begin : GEN_COL

                logic [ACC_WIDTH-1:0] pe_acc;
                logic                 pe_valid;

                systolic_pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH (ACC_WIDTH)
                ) u_pe (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .clear_acc  (clear_acc_row[r]),

                    .a_in       (a_bus[r][c]),
                    .valid_a_in (valid_a_bus[c][r]),
                    .a_out      (a_bus[r][c+1]),
                    .valid_a_out(valid_a_bus[c+1][r]),

                    .b_in       (b_bus[r][c]),
                    .valid_b_in (valid_b_bus[r][c]),
                    .b_out      (b_bus[r+1][c]),
                    .valid_b_out(valid_b_bus[r+1][c]),

                    .acc_out    (pe_acc),
                    .valid_out  (pe_valid)
                );

                assign accumulators[(r*COLS+c)*ACC_WIDTH +: ACC_WIDTH] = pe_acc;
                assign valid_out[r*COLS+c]                             = pe_valid;

            end
        end
    endgenerate

`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1 || ACC_WIDTH < 2*DATA_WIDTH || ROWS < 1 || COLS < 1)
            $fatal(1, "Invalid systolic_array parameters");
    end
`endif

endmodule
