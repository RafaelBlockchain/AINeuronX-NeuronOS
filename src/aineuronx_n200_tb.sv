// =====================================================
// AINeuronX_N200_TB.SV
// Testbench vectorizado industrial PRO
// Prefetch dinámico, backpressure, pipeline profundo
// =====================================================
`timescale 1ns/1ps

module aineuronx_n200_tb;

    parameter int DATA_WIDTH   = 16;
    parameter int VECTOR_LANES = 4;
    parameter int PIPE_DEPTH   = 3;
    parameter int CLK_PERIOD   = 10;
    localparam int TX_TOTAL     = 20;

    logic clk;
    logic rst_n;
    logic valid_in;
    logic prefetch_enable;
    logic [DATA_WIDTH*VECTOR_LANES-1:0] input_a;
    logic [DATA_WIDTH*VECTOR_LANES-1:0] input_b;

    logic ready_out;
    logic [DATA_WIDTH*VECTOR_LANES-1:0] output_data;

    integer cycle_count;

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    always_ff @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    aineuronx_n200_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_LANES(VECTOR_LANES),
        .PIPE_DEPTH(PIPE_DEPTH)
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

    // -------------------------------------------------
    // Struct golden
    // -------------------------------------------------
    typedef struct packed {
        logic [DATA_WIDTH-1:0] a;
        logic [DATA_WIDTH-1:0] b;
        int cycle_in;
    } golden_t;

    golden_t golden_queue[$];

    // -------------------------------------------------
    // Estímulos vectorizados con prefetch dinámico
    // -------------------------------------------------
    initial begin
        rst_n = 0;
        valid_in = 0;
        prefetch_enable = 0;
        input_a = 0;
        input_b = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (2) @(posedge clk);
        prefetch_enable = 1'b1;

        for (int tx=0; tx<TX_TOTAL; tx++) begin
            // Esperar backpressure
            wait (ready_out);

            @(posedge clk);
            valid_in = 1'b1;

            for (int l=0; l<VECTOR_LANES; l++) begin
                logic [DATA_WIDTH-1:0] sent;
                sent = tx + l;

                input_a[l*DATA_WIDTH +: DATA_WIDTH] = sent;
                input_b[l*DATA_WIDTH +: DATA_WIDTH] = TX_TOTAL - sent;

                golden_t g;
                g.a = sent;
                g.b = TX_TOTAL - sent;
                g.cycle_in = cycle_count;
                golden_queue.push_back(g);
            end
        end

        @(posedge clk);
        valid_in = 0;

        // Esperar salida completa
        wait (golden_queue.size() == 0);
        repeat (2) @(posedge clk);
        $finish;
    end

    // -------------------------------------------------
    // Captura + verificación golden
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (ready_out) begin
            for (int l=0; l<VECTOR_LANES; l++) begin
                if (golden_queue.size() > 0) begin
                    golden_t g = golden_queue.pop_front();
                    logic [DATA_WIDTH-1:0] out_val;
                    out_val = output_data[l*DATA_WIDTH +: DATA_WIDTH];

                    int latency;
                    latency = cycle_count - g.cycle_in;

                    assert (out_val == g.a + g.b)
                        else $fatal("❌ ERROR FUNCIONAL | Output=%0d | Expected=%0d | Latency=%0d | Lane=%0d | Cycle=%0d",
                                    out_val, g.a+g.b, latency, l, cycle_count);

                    assert (latency == PIPE_DEPTH)
                        else $fatal("❌ ERROR LATENCIA | Latency=%0d | Lane=%0d | Cycle=%0d",
                                    latency, l, cycle_count);
                end
            end
        end
    end

    // -------------------------------------------------
    // Reporte final
    // -------------------------------------------------
    final begin
        $display("====================================");
        $display("AINeuronX N200 PRO TB FINAL REPORT");
        $display("Golden model + Latencia verificada");
        $display("Pipeline vectorizado: %0d lanes", VECTOR_LANES);
        $display("Pipeline profundo: %0d ciclos", PIPE_DEPTH);
        $display("Total TX         : %0d", TX_TOTAL);
        $display("====================================");
    end

endmodule
