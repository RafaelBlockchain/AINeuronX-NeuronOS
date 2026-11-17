`timescale 1ns/1ps

module systolic_ctrl #(
    parameter int ROWS  = 8,
    parameter int COLS  = 8,
    parameter int K_DIM = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,

    output logic clear_acc,
    output logic feed_enable,
    output logic busy,
    output logic done,
    output logic [31:0] cycle_count
);

    localparam int FEED_CYCLES = K_DIM + ROWS + COLS - 2;

    typedef enum logic [2:0] {
        IDLE,
        CLEAR,
        FEED,
        DRAIN,
        FINISH
    } state_t;

    state_t state;
    logic [15:0] feed_count;
    logic        clear_cnt;
    logic [1:0]  drain_cnt;

    always_comb begin
        clear_acc   = 1'b0;
        feed_enable = 1'b0;
        busy        = 1'b0;
        done        = 1'b0;

        case (state)
            IDLE:   busy = 1'b0;
            CLEAR:  begin clear_acc = (clear_cnt == 1'b0); busy = 1'b1; end
            FEED:   begin feed_enable = 1'b1; busy = 1'b1; end
            DRAIN:  busy = 1'b1;
            FINISH: done = 1'b1;
            default: busy = 1'b0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            feed_count  <= 16'd0;
            cycle_count <= 32'd0;
            clear_cnt   <= 1'b0;
            drain_cnt   <= 2'd0;
        end else begin
            case (state)
                IDLE: begin
                    feed_count  <= 16'd0;
                    cycle_count <= 32'd0;
                    clear_cnt   <= 1'b0;
                    drain_cnt   <= 2'd0;
                    if (start) state <= CLEAR;
                end

                CLEAR: begin
                    feed_count  <= 16'd0;
                    cycle_count <= 32'd0;
                    drain_cnt   <= 2'd0;
                    if (clear_cnt == 1'b1) begin
                        clear_cnt <= 1'b0;
                        state     <= FEED;
                    end else begin
                        clear_cnt <= 1'b1;
                    end
                end

                FEED: begin
                    cycle_count <= cycle_count + 32'd1;
                    if (feed_count == FEED_CYCLES - 1) begin
                        drain_cnt <= 2'd0;
                        state     <= DRAIN;
                    end else begin
                        feed_count <= feed_count + 16'd1;
                    end
                end

                DRAIN: begin
                    cycle_count <= cycle_count + 32'd1;
                    if (drain_cnt == 2'd2) begin
                        state <= FINISH;
                    end else begin
                        drain_cnt <= drain_cnt + 2'd1;
                    end
                end

                FINISH: state <= IDLE;

                default: begin
                    state       <= IDLE;
                    feed_count  <= 16'd0;
                    cycle_count <= 32'd0;
                    clear_cnt   <= 1'b0;
                    drain_cnt   <= 2'd0;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    initial begin
        if (ROWS < 1 || COLS < 1 || K_DIM < 1)
            $fatal(1, "Invalid systolic_ctrl parameters");
    end
`endif

endmodule
