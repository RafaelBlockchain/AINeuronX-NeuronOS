// =====================================================
// AINEURONX_TB_MULTI_CORE_FULL.SV
// Testbench industrial – 16 cores x 8 lanes
// Golden model + latencia formal
// =====================================================
`timescale 1ns/1ps

module aineuronx_tb_multi_core_full;

    parameter int DATA_WIDTH   = 16;
    parameter int VECTOR_LANES = 8;
    parameter int PIPE_DEPTH   = 3;
    parameter int NUM_CORES    = 16;
    parameter int CLK_PERIOD   = 10;
    localparam int TX_TOTAL    = 20;

    logic clk;
    logic rst_n;
    logic valid_in;
    logic prefetch_enable;

    logic [DATA_WIDTH*VECTOR_LANES*NUM_CORES-1:0] input_a;
    logic [DATA_WIDTH*VECTOR_LANES*NUM_CORES-1:0] input_b;
    logic ready_out;
    logic [DATA_WIDTH*VECTOR_LANES*NUM_CORES-1:0] output_data;

    integer cycle_count;

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    always_ff @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // DUT full industrial
    aineuronx_multi_core_full #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_LANES(VECTOR_LANES),
        .PIPE_DEPTH(PIPE_DEPTH),
        .NUM_CORES(NUM_CORES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .prefetch_enable(prefetch_enable),
        .input_a(input_a),
        .input_b(input_b),
        .ready_out(ready_out),
        .output_data(output_data)
    );

    // Golden model
    typedef struct packed {
        logic [DATA_WIDTH-1:0] a;
        logic [DATA_WIDTH-1:0] b;
        int cycle_in;
    } golden_t;

    golden_t golden_queue[$];

    initial begin
        rst_n = 0;
        valid_in = 0;
        prefetch_enable = 0;
        input_a = '0;
        input_b = '0;

        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);
        prefetch_enable = 1'b1;

        for (int tx=0; tx<TX_TOTAL; tx++) begin
            @(posedge clk);
            valid_in = 1'b1;

            for (int c=0; c<NUM_CORES; c++) begin
                for (int l=0; l<VECTOR_LANES; l++) begin
                    logic [DATA_WIDTH-1:0] sent = tx + l + c*VECTOR_LANES;
                    input_a[c*VECTOR_LANES*DATA_WIDTH + l*DATA_WIDTH +: DATA_WIDTH] = sent;
                    input_b[c*VECTOR_LANES*DATA_WIDTH + l*DATA_WIDTH +: DATA_WIDTH] = TX_TOTAL - sent;

                    golden_t g = '{a: sent, b: TX_TOTAL-sent, cycle_in: cycle_count};
                    golden_queue.push_back(g);
                end
            end
        end

        @(posedge clk);
        valid_in = 0;
        wait (golden_queue.size() == 0);
        repeat (2) @(posedge clk);
        $finish;
    end

    always_ff @(posedge clk) begin
        if (ready_out) begin
            for (int c=0; c<NUM_CORES; c++) begin
                for (int l=0; l<VECTOR_LANES; l++) begin
                    golden_t g = golden_queue.pop_front();
                    logic [DATA_WIDTH-1:0] out_val = output_data[c*VECTOR_LANES*DATA_WIDTH + l*DATA_WIDTH +: DATA_WIDTH];
                    int latency = cycle_count - g.cycle_in;

                    assert (out_val == (g.a + g.b))
                        else $fatal("❌ ERROR FUNCIONAL | Out=%0d | Lane=%0d | Core=%0d | Cycle=%0d", out_val, l, c, cycle_count);

                    assert (latency == PIPE_DEPTH)
                        else $fatal("❌ ERROR DE LATENCIA | Latency=%0d | Lane=%0d | Core=%0d | Cycle=%0d", latency, l, c, cycle_count);
                end
            end
        end
    end

    final begin
        $display("====================================");
        $display(" AINEURONX TB FULL INDUSTRIAL REPORT");
        $display(" NUM_CORES          : %0d", NUM_CORES);
        $display(" VECTOR_LANES       : %0d", VECTOR_LANES);
        $display(" PIPE_DEPTH         : %0d", PIPE_DEPTH);
        $display(" TX_TOTAL           : %0d", TX_TOTAL);
        $display(" Golden model + Latencia ✅");
        $display("====================================");
    end

endmodule
