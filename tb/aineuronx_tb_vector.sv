// =====================================================
// AINEURONX_TB_VECTOR.SV
// TB industrial + pipeline vectorizado + golden model
// =====================================================
`timescale 1ns/1ps

module aineuronx_tb_vector;

    parameter int DATA_WIDTH = 16;
    parameter int LANES      = 4;
    parameter int CLK_PERIOD = 10;
    localparam int EXPECTED_TX = 20;

    // ---------------- Signals ----------------
    logic clk, rst_n, valid_in, select_precision, prefetch_enable;
    logic [DATA_WIDTH-1:0] input_a[LANES], input_b[LANES];
    logic [DATA_WIDTH-1:0] output_chip[LANES];
    logic ready_chip;

    integer cycle_count;
    integer input_cycle [$];
    integer output_cycle[$];

    typedef struct {
        logic [DATA_WIDTH-1:0] a[LANES];
        logic [DATA_WIDTH-1:0] b[LANES];
        logic select;
        int cycle_in;
    } golden_t;

    golden_t golden_queue[$];

    // ---------------- Clock ----------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------- Cycle counter ----------------
    always_ff @(posedge clk)
        cycle_count <= (!rst_n) ? 0 : cycle_count + 1;

    // ---------------- DUT ----------------
    aineuronx_core_vector #(
        .DATA_WIDTH(DATA_WIDTH),
        .LANES(LANES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .select_precision(select_precision),
        .prefetch_enable(prefetch_enable),
        .input_a(input_a),
        .input_b(input_b),
        .ready_out(ready_chip),
        .output_data(output_chip)
    );

    // ---------------- Stimuli ----------------
    initial begin
        rst_n = 0; valid_in = 0; select_precision = 0; prefetch_enable = 0;
        for (int i = 0; i < LANES; i++) input_a[i] = '0; input_b[i] = '0;

        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);
        prefetch_enable = 1;

        for (int tx = 0; tx < EXPECTED_TX; tx++) begin
            @(posedge clk);
            valid_in = 1;
            select_precision = tx[0];

            for (int i = 0; i < LANES; i++) begin
                input_a[i] = tx + i;
                input_b[i] = EXPECTED_TX - tx + i;
            end

            // Push golden result
            golden_t g;
            for (int i = 0; i < LANES; i++) begin
                g.a[i] = input_a[i];
                g.b[i] = input_b[i];
            end
            g.select = select_precision;
            g.cycle_in = cycle_count;
            golden_queue.push_back(g);

            input_cycle.push_back(cycle_count);
        end

        @(posedge clk); valid_in = 0;
        wait (output_cycle.size() == input_cycle.size());
        repeat (2) @(posedge clk);
        $finish;
    end

    // ---------------- Capture output + verify ----------------
    always_ff @(posedge clk) begin
        if (ready_chip) begin
            output_cycle.push_back(cycle_count);

            golden_t g = golden_queue.pop_front();
            int latency = cycle_count - g.cycle_in;
            assert(latency == 3) else $fatal("❌ Latencia incorrecta: %0d", latency);

            for (int i = 0; i < LANES; i++) begin
                int expected = g.select ? (g.a[i]+g.b[i]) : (g.a[i]-g.b[i]);
                assert(output_chip[i] === expected) else
                    $fatal("❌ Output[%0d]=%0d | Esperado=%0d | Ciclo=%0d", i, output_chip[i], expected, cycle_count);
            end
        end
    end

    // ---------------- Report ----------------
    final begin
        $display("====================================");
        $display(" AINEURONX TB VECTOR FINAL REPORT");
        $display(" Inputs enviados  : %0d", input_cycle.size());
        $display(" Outputs recibidos: %0d", output_cycle.size());
        $display(" Testbench OK – Core vectorizado validado");
        $display("====================================");
    end

endmodule
