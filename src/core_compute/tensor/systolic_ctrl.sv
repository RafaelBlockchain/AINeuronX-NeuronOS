`timescale 1ns/1ps

module systolic_ctrl #(
    parameter int ROWS  = 2,
    parameter int COLS  = 2,
    parameter int K_DIM = 2
) (
    input  logic clk,
    input  logic rst_n,

    // Command
    input  logic start,

    // Control outputs
    output logic clear_acc,
    output logic feed_enable,
    output logic busy,
    output logic done,

    // Timing information
    output logic [31:0] cycle_count
);

    // Total number of feed cycles:
    // K_DIM + ROWS + COLS - 2
    localparam int FEED_CYCLES =
        K_DIM + ROWS + COLS - 2;

    typedef enum logic [2:0] {
        IDLE,
        CLEAR,
        FEED,
        DRAIN,
        FINISH
    } state_t;

    state_t state;

    logic [31:0] feed_count;
    logic        drain_cnt; // 2 ciclos de drenaje para el pipeline de 2 etapas del PE

    always_comb begin
        clear_acc   = 1'b0;
        feed_enable = 1'b0;
        busy        = 1'b0;
        done        = 1'b0;

        case (state)

            IDLE: begin
                busy = 1'b0;
            end

            CLEAR: begin
                clear_acc = 1'b1;
                busy      = 1'b1;
            end

            FEED: begin
                feed_enable = 1'b1;
                busy        = 1'b1;
            end

            DRAIN: begin
                busy = 1'b1;
            end

            FINISH: begin
                done = 1'b1;
            end

            default: begin
                busy = 1'b0;
            end

        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state       <= IDLE;
            feed_count  <= '0;
            cycle_count <= '0;
            drain_cnt   <= 1'b0;

        end else begin

            case (state)

                IDLE: begin
                    feed_count  <= '0;
                    cycle_count <= '0;
                    drain_cnt   <= 1'b0;

                    if (start) begin
                        state <= CLEAR;
                    end
                end

                CLEAR: begin
                    feed_count  <= '0;
                    cycle_count <= '0;
                    drain_cnt   <= 1'b0;
                    state       <= FEED;
                end

                FEED: begin

                    cycle_count <= cycle_count + 1'b1;

                    if (feed_count == FEED_CYCLES - 1) begin
                        drain_cnt <= 1'b0;
                        state     <= DRAIN;
                    end else begin
                        feed_count <= feed_count + 1'b1;
                    end

                end

                DRAIN: begin
                    if (drain_cnt == 1'b1) begin
                        state <= FINISH;
                    end else begin
                        drain_cnt <= 1'b1;
                    end
                end

                FINISH: begin
                    state <= IDLE;
                end

                default: begin
                    state       <= IDLE;
                    feed_count  <= '0;
                    cycle_count <= '0;
                    drain_cnt   <= 1'b0;
                end

            endcase
        end
    end

`ifndef SYNTHESIS
    initial begin

        if (ROWS < 1)
            $fatal(1, "ROWS must be >= 1");

        if (COLS < 1)
            $fatal(1, "COLS must be >= 1");

        if (K_DIM < 1)
            $fatal(1, "K_DIM must be >= 1");

    end
`endif

endmodule
