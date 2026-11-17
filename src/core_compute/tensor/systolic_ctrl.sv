`timescale 1ns/1ps

module systolic_ctrl #(
    parameter int ROWS  = 4,   // Sincronizar con systolic_array
    parameter int COLS  = 4,   // Sincronizar con systolic_array
    parameter int K_DIM = 4    // Dimensión interna de multiplicación
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

    // Total number of feed cycles: K_DIM + ROWS + COLS - 2
    localparam int FEED_CYCLES = K_DIM + ROWS + COLS - 2;
    localparam int CNT_WIDTH   = (FEED_CYCLES > 1) ? $clog2(FEED_CYCLES + 1) : 1;

    typedef enum logic [2:0] {
        IDLE,
        CLEAR,
        FEED,
        DRAIN,
        FINISH
    } state_t;

    state_t state;

    logic [CNT_WIDTH-1:0] feed_count;
    logic                 clear_cnt; // 2 ciclos para compensar el pipeline de clear_acc_row
    logic [1:0]           drain_cnt; // 3 ciclos de drenaje (1 ciclo buffer + 2 etapas del PE)

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
                // Solo afirma clear_acc en el primer ciclo; el segundo espera la propagación
                clear_acc = (clear_cnt == 1'b0);
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
            clear_cnt   <= 1'b0;
            drain_cnt   <= 2'd0;
        end else begin
            case (state)
                IDLE: begin
                    feed_count  <= '0;
                    cycle_count <= '0;
                    clear_cnt   <= 1'b0;
                    drain_cnt   <= 2'd0;

                    if (start) begin
                        state <= CLEAR;
                    end
                end

                CLEAR: begin
                    feed_count  <= '0;
                    cycle_count <= '0;
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

                    if (feed_count == CNT_WIDTH'(FEED_CYCLES - 1)) begin
                        drain_cnt <= 2'd0;
                        state     <= DRAIN;
                    end else begin
                        feed_count <= feed_count + CNT_WIDTH'(1);
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

                FINISH: begin
                    state <= IDLE;
                end

                default: begin
                    state       <= IDLE;
                    feed_count  <= '0;
                    cycle_count <= '0;
                    clear_cnt   <= 1'b0;
                    drain_cnt   <= 2'd0;
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
