`timescale 1ns/1ps

module vector_unit #(
    parameter int LANES      = 4,
    parameter int DATA_WIDTH = 16,
    parameter int ACC_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,

    // Command interface
    input  logic       start,
    input  logic [1:0] opcode,
    input  logic       clear_acc,

    // Packed vector operands
    input  logic [LANES*DATA_WIDTH-1:0] vector_a,
    input  logic [LANES*DATA_WIDTH-1:0] vector_b,

    // Packed vector results
    output logic [LANES*ACC_WIDTH-1:0] result,

    // Execution status
    output logic busy,
    output logic done
);

    // Operation codes
    localparam logic [1:0] OP_ADD = 2'b00;
    localparam logic [1:0] OP_MUL = 2'b01;
    localparam logic [1:0] OP_MAC = 2'b10;

    localparam int PRODUCT_WIDTH = 2 * DATA_WIDTH;

    // Internal control
    typedef enum logic {
        IDLE,
        EXECUTE
    } state_t;

    state_t state;

    logic [1:0] opcode_reg;

    logic [LANES*DATA_WIDTH-1:0] vector_a_reg;
    logic [LANES*DATA_WIDTH-1:0] vector_b_reg;

    // Per-lane arithmetic signals
    logic signed [DATA_WIDTH-1:0] a_lane [0:LANES-1];
    logic signed [DATA_WIDTH-1:0] b_lane [0:LANES-1];

    logic signed [PRODUCT_WIDTH-1:0] product_lane [0:LANES-1];

    logic signed [ACC_WIDTH-1:0] a_ext [0:LANES-1];
    logic signed [ACC_WIDTH-1:0] b_ext [0:LANES-1];
    logic signed [ACC_WIDTH-1:0] product_ext [0:LANES-1];

    logic signed [ACC_WIDTH-1:0] accumulator [0:LANES-1];
    logic signed [ACC_WIDTH-1:0] result_calc [0:LANES-1];

    logic [LANES*ACC_WIDTH-1:0] result_reg;

    // --------------------------------------------------
    // Lane arithmetic
    // --------------------------------------------------

    always_comb begin
        for (int i = 0; i < LANES; i++) begin

            // Extract signed operands
            a_lane[i] = $signed(
                vector_a_reg[i*DATA_WIDTH +: DATA_WIDTH]
            );

            b_lane[i] = $signed(
                vector_b_reg[i*DATA_WIDTH +: DATA_WIDTH]
            );

            // Sign extension
            a_ext[i] = {
                {(ACC_WIDTH-DATA_WIDTH){a_lane[i][DATA_WIDTH-1]}},
                a_lane[i]
            };

            b_ext[i] = {
                {(ACC_WIDTH-DATA_WIDTH){b_lane[i][DATA_WIDTH-1]}},
                b_lane[i]
            };

            // Full signed multiplication
            product_lane[i] = a_lane[i] * b_lane[i];

            // Extend product to accumulator width
            product_ext[i] = {
                {(ACC_WIDTH-PRODUCT_WIDTH){
                    product_lane[i][PRODUCT_WIDTH-1]
                }},
                product_lane[i]
            };

            // Default result
            result_calc[i] = '0;

            case (opcode_reg)

                OP_ADD: begin
                    result_calc[i] = a_ext[i] + b_ext[i];
                end

                OP_MUL: begin
                    result_calc[i] = product_ext[i];
                end

                OP_MAC: begin
                    result_calc[i] =
                        accumulator[i] + product_ext[i];
                end

                default: begin
                    result_calc[i] = '0;
                end

            endcase
        end
    end

    // --------------------------------------------------
    // Sequential execution control
    // --------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state          <= IDLE;
            opcode_reg     <= OP_ADD;
            vector_a_reg   <= '0;
            vector_b_reg   <= '0;
            result_reg     <= '0;
            done           <= 1'b0;

            for (int i = 0; i < LANES; i++) begin
                accumulator[i] <= '0;
            end

        end else begin

            // Default: done is a one-cycle pulse
            done <= 1'b0;

            case (state)

                IDLE: begin

                    if (clear_acc) begin
                        for (int i = 0; i < LANES; i++) begin
                            accumulator[i] <= '0;
                        end
                    end else if (start) begin

                        // Capture command and operands
                        opcode_reg   <= opcode;
                        vector_a_reg <= vector_a;
                        vector_b_reg <= vector_b;

                        state <= EXECUTE;
                    end

                end

                EXECUTE: begin

                    // Publish one result per lane
                    for (int i = 0; i < LANES; i++) begin

                        result_reg[i*ACC_WIDTH +: ACC_WIDTH]
                            <= result_calc[i];

                        // MAC updates the lane accumulator
                        if (opcode_reg == OP_MAC) begin
                            accumulator[i] <= result_calc[i];
                        end

                    end

                    done  <= 1'b1;
                    state <= IDLE;

                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

    // --------------------------------------------------
    // Outputs
    // --------------------------------------------------

    assign result = result_reg;
    assign busy   = (state == EXECUTE);

    // --------------------------------------------------
    // Parameter validation
    // --------------------------------------------------

    initial begin

        if (LANES < 1)
            $fatal(1, "LANES must be >= 1");

        if (DATA_WIDTH < 1)
            $fatal(1, "DATA_WIDTH must be >= 1");

        if (ACC_WIDTH < PRODUCT_WIDTH)
            $fatal(1, "ACC_WIDTH must be >= 2*DATA_WIDTH");

    end

endmodule

