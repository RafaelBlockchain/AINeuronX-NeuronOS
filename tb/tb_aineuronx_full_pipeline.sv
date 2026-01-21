// =====================================================
// TB_AINEURONX_FULL_PIPELINE.SV
// Testbench completo: Golden Model + Checks + Asserts
// + Pipeline Metrics
// Compatible con Verilator
// =====================================================
`timescale 1ns/1ps

module tb_aineuronx_full_pipeline;

    // -------------------------------------------------
    // Parámetros
    // -------------------------------------------------
    parameter int DATA_WIDTH_FP16 = 16;
    parameter int DATA_WIDTH_FP8  = 8;
    parameter int CLK_PERIOD      = 10; // ns
    localparam int EXPECTED_TX    = 20;

    // -------------------------------------------------
    // Señales
    // -------------------------------------------------
    reg clk;
    reg rst_n;
    reg valid_in;
    reg select_precision; // 0 = FP16, 1 = FP8
    reg prefetch_enable;

    reg  [DATA_WIDTH_FP16-1:0] input_a;
    reg  [DATA_WIDTH_FP16-1:0] input_b;

    wire [DATA_WIDTH_FP16-1:0] output_chip;
    wire ready_chip;

    integer cycle_count;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    aineuronx_chip uut (
        .clk(clk),
        .rst_n(rst_n),
        .prefetch_enable(prefetch_enable),
        .valid_in(valid_in),
        .select_precision(select_precision),
        .input_a(input_a),
        .input_b(input_b),
        .output_chip(output_chip),
        .ready_chip(ready_chip)
    );

    // -------------------------------------------------
    // Métricas
    // -------------------------------------------------
    integer total_mismatches;
    integer total_stalls;
    integer total_backpressure;
    integer min_lat;
    integer max_lat;
    integer sum_lat;
    integer lat;
    integer i;

    integer input_cycle[$];
    integer output_cycle[$];

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------
    // Contador de ciclos
    // -------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // -------------------------------------------------
    // Reset + estímulos
    // -------------------------------------------------
    initial begin
        rst_n             = 0;
        valid_in          = 0;
        select_precision  = 0;
        prefetch_enable   = 1'b1;
        input_a           = '0;
        input_b           = '0;

        total_mismatches  = 0;
        total_stalls      = 0;
        total_backpressure= 0;
        min_lat           = 32'h7fffffff;
        max_lat           = 0;
        sum_lat           = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        for (i = 0; i < EXPECTED_TX; i = i + 1) begin
            @(posedge clk);
            valid_in         = 1'b1;
            input_a          = DATA_WIDTH_FP16'($urandom_range(1,100));
            input_b          = DATA_WIDTH_FP16'($urandom_range(1,100));
            select_precision = 1'($urandom_range(0,1));

            @(posedge clk);
            valid_in         = 1'b0;
        end
    end

    // -------------------------------------------------
    // Golden Model
    // -------------------------------------------------
    reg [DATA_WIDTH_FP16-1:0] golden_out;

    always @(*) begin
        if (select_precision == 1'b0)
            golden_out = input_a * input_b;
        else
            golden_out =
                input_a[DATA_WIDTH_FP8-1:0] *
                input_b[DATA_WIDTH_FP8-1:0];
    end

    // -------------------------------------------------
    // Check funcional
    // -------------------------------------------------
    always @(posedge clk) begin
        if (rst_n && valid_in && ready_chip) begin
            if (output_chip !== golden_out) begin
                $display(
                    "❌ MISMATCH | ciclo=%0d | A=%0d B=%0d | golden=%0d got=%0d",
                    cycle_count, input_a, input_b,
                    golden_out, output_chip
                );
                total_mismatches <= total_mismatches + 1;
            end
        end
    end

    // -------------------------------------------------
    // Asserts
    // -------------------------------------------------
    assert_ready_valid: assert property (@(posedge clk)
        ready_chip |-> $past(valid_in)
    ) else $error("❌ ready sin valid previo");

    assert_no_x: assert property (@(posedge clk)
        ready_chip |-> !$isunknown(output_chip)
    ) else $error("❌ output con X/Z");

    assert_reset_clean: assert property (@(posedge clk)
        !rst_n |-> !ready_chip
    ) else $error("❌ ready activo durante reset");

    // -------------------------------------------------
    // Pipeline metrics
    // -------------------------------------------------
    always @(posedge clk) begin
        if (valid_in)
            input_cycle.push_back(cycle_count);

        if (valid_in && !ready_chip)
            total_stalls <= total_stalls + 1;

        if (ready_chip)
            output_cycle.push_back(cycle_count);

        if (ready_chip && !valid_in)
            total_backpressure <= total_backpressure + 1;
    end

    // -------------------------------------------------
    // Resumen final
    // -------------------------------------------------
    initial begin
        wait (output_cycle.size() == EXPECTED_TX);
        repeat (5) @(posedge clk);

        for (i = 0; i < EXPECTED_TX; i = i + 1) begin
            lat = output_cycle[i] - input_cycle[i];
            sum_lat += lat;
            if (lat < min_lat) min_lat = lat;
            if (lat > max_lat) max_lat = lat;
        end

        $display("===================================");
        $display("SIMULATION PIPELINE METRICS SUMMARY");
        $display("Total ciclos simulados     : %0d", cycle_count);
        $display("Total mismatches           : %0d", total_mismatches);
        $display("Total stalls               : %0d", total_stalls);
        $display("Total backpressure         : %0d", total_backpressure);
        $display("Latencia mínima            : %0d ciclos", min_lat);
        $display("Latencia máxima            : %0d ciclos", max_lat);
        $display("Latencia promedio          : %0.2f ciclos",
                 sum_lat * 1.0 / EXPECTED_TX);
        $display("===================================");
        $display("✔ Simulation finished successfully");

        $finish;
    end

endmodule
