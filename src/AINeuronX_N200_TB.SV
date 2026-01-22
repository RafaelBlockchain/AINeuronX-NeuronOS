`timescale 1ns/1ps

module AINeuronX_N200_TB;

    parameter int DATA_WIDTH   = 16;
    parameter int VECTOR_LANES = 4;
    parameter int CLK_PERIOD   = 10;
    localparam int TX_TOTAL    = 10;
    localparam int MAX_TX      = TX_TOTAL * VECTOR_LANES;

    logic clk;
    logic rst_n;
    logic valid_in;
    logic prefetch_enable;
    logic [DATA_WIDTH*VECTOR_LANES-1:0] input_a;
    logic [DATA_WIDTH*VECTOR_LANES-1:0] input_b;
    logic ready_out;
    logic [DATA_WIDTH*VECTOR_LANES-1:0] output_data;
    int cycle_count;

    // Golden storage
    logic [DATA_WIDTH-1:0] golden_a   [0:MAX_TX-1];
    logic [DATA_WIDTH-1:0] golden_b   [0:MAX_TX-1];
    int                    golden_cyc [0:MAX_TX-1];
    int wr_ptr;
    int rd_ptr;

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Cycle counter
    always_ff @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // DUT
    AINeuronX_N200_CORE dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .prefetch_enable(prefetch_enable),
        .input_a(input_a),
        .input_b(input_b),
        .ready_out(ready_out),
        .output_data(output_data)
    );

    // Stimulus
    initial begin
        rst_n = 0;
        valid_in = 0;
        prefetch_enable = 0;
        input_a = '0;
        input_b = '0;
        wr_ptr = 0;
        rd_ptr = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (2) @(posedge clk);
        prefetch_enable = 1'b1;

        for (int tx = 0; tx < TX_TOTAL; tx++) begin
            @(posedge clk);
            valid_in = 1'b1;

            for (int l = 0; l < VECTOR_LANES; l++) begin
                logic [DATA_WIDTH-1:0] s;
                s = logic'(tx + l);

                input_a[l*DATA_WIDTH +: DATA_WIDTH] = s;
                input_b[l*DATA_WIDTH +: DATA_WIDTH] = logic'(TX_TOTAL) - s;

                golden_a[wr_ptr]   = s;
                golden_b[wr_ptr]   = logic'(TX_TOTAL) - s;
                golden_cyc[wr_ptr] = cycle_count;
                wr_ptr++;
            end
        end

        @(posedge clk);
        valid_in = 0;

        wait (rd_ptr == wr_ptr);
        repeat (2) @(posedge clk);
        $finish;
    end

    // Check
    always_ff @(posedge clk) begin
        if (ready_out) begin
            for (int l = 0; l < VECTOR_LANES; l++) begin
                logic [DATA_WIDTH-1:0] outv;
                int latency;

                outv = output_data[l*DATA_WIDTH +: DATA_WIDTH];
                latency = cycle_count - golden_cyc[rd_ptr];

                assert (outv == golden_a[rd_ptr] + golden_b[rd_ptr]);
                assert (latency == 3);

                rd_ptr++;
            end
        end
    end

endmodule
