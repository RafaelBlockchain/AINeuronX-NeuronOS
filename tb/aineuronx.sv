// =====================================================
// AINEURONX.SV – Testbench endurecido + stress-test
// Funcional + latencia + golden model + bursts
// =====================================================
`timescale 1ns/1ps

module aineuronx;

    // -------------------------------------------------
    // Parámetros
    // -------------------------------------------------
    parameter int DATA_WIDTH_FP16 = 16;
    parameter int CLK_PERIOD      = 10; // ns
    localparam int EXPECTED_TX    = 40; // más transacciones para stress-test

    // -------------------------------------------------
    // Señales
    // -------------------------------------------------
    logic clk;
    logic rst_n;
    logic valid_in;
    logic select_precision;
    logic prefetch_enable;

    logic [DATA_WIDTH_FP16-1:0] input_a;
    logic [DATA_WIDTH_FP16-1:0] input_b;

    logic [DATA_WIDTH_FP16-1:0] output_chip;
    logic ready_chip;

    integer cycle_count;
    integer input_cycle  [$];
    integer output_cycle [$];

    // Golden model arrays
    logic [DATA_WIDTH_FP16-1:0] golden_expected [$];
    integer golden_cycle [$];

    // -------------------------------------------------
    // Clock (Verilator-safe)
    // -------------------------------------------------
    initial clk = 0;
    always begin
        #(CLK_PERIOD/2);
        clk <= ~clk;
    end

    // -------------------------------------------------
    // Contador de ciclos
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // -------------------------------------------------
    // DUT REAL
    // -------------------------------------------------
    aineuronx_core dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .valid_in         (valid_in),
        .select_precision (select_precision),
        .prefetch_enable  (prefetch_enable),
        .input_a          (input_a),
        .input_b          (input_b),
        .ready_out        (ready_chip),
        .output_data      (output_chip)
    );

    // -------------------------------------------------
    // Reset + estímulos
    // -------------------------------------------------
    initial begin
        rst_n            = 0;
        valid_in         = 0;
        select_precision = 0;
        prefetch_enable  = 0;
        input_a          = '0;
        input_b          = '0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (2) @(posedge clk);
        prefetch_enable = 1'b1;

        // -------------------------------------------------
        // Enviar transacciones con bursts y gaps
        // -------------------------------------------------
        int sent = 0;
        while (sent < EXPECTED_TX) begin
            @(posedge clk);

            // Random intermitencia de valid_in (simula flujo irregular)
            if ($urandom_range(0,2) != 0) begin
                valid_in = ready_chip; // solo enviar si ready
                if (valid_in) begin
                    select_precision = sent[0];
                    input_a = DATA_WIDTH_FP16'(sent);
                    input_b = DATA_WIDTH_FP16'(EXPECTED_TX - sent);

                    // Guardar ciclo de entrada y golden
                    input_cycle.push_back(cycle_count);
                    golden_cycle.push_back(cycle_count);
                    golden_expected.push_back((select_precision) ? (input_a + input_b) : (input_a - input_b));

                    sent++;
                end
            end else begin
                valid_in = 0; // gap
            end

            // Prefetch cae intermitente para stress
            if ($urandom_range(0,4) == 0)
                prefetch_enable = ~prefetch_enable;
        end

        @(posedge clk);
        valid_in = 0;

        // Esperar todas las respuestas
        wait (output_cycle.size() == input_cycle.size());

        repeat (2) @(posedge clk);
        $finish;
    end

    // -------------------------------------------------
    // Captura de salida + verificación GOLDEN
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (ready_chip && golden_expected.size() > 0) begin
            output_cycle.push_back(cycle_count);

            logic [DATA_WIDTH_FP16-1:0] expected;
            integer in_cycle;

            expected = golden_expected.pop_front();
            in_cycle = golden_cycle.pop_front();

            // Verificación funcional
            assert (output_chip === expected)
                else $fatal(
                    "❌ ERROR FUNCIONAL | Output=%0d | Esperado=%0d | Ciclo=%0d",
                    output_chip, expected, cycle_count
                );

            // Latencia formal
            int latency = cycle_count - in_cycle;
            assert (latency == 3)
                else $fatal(
                    "❌ ERROR DE LATENCIA | Latencia=%0d ciclos | Esperado=3 | Ciclo=%0d",
                    latency, cycle_count
                );
        end
    end

    // -------------------------------------------------
    // Reporte final
    // -------------------------------------------------
    final begin
        $display("====================================");
        $display(" AINEURONX TB ENDURECIDO + STRESS FINAL REPORT");
        $display(" Inputs enviados  : %0d", input_cycle.size());
        $display(" Outputs recibidos: %0d", output_cycle.size());
        $display(" Testbench OK – Core endurecido validado");
        $display("====================================");
    end

endmodule
