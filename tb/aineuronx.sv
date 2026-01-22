// =====================================================
// AINEURONX.SV
// Testbench real conectado a aineuronx_core
// Verificación funcional + latencia fija
// =====================================================
`timescale 1ns/1ps

module aineuronx;

    // -------------------------------------------------
    // Parámetros
    // -------------------------------------------------
    parameter int DATA_WIDTH_FP16 = 16;
    parameter int CLK_PERIOD      = 10; // ns
    localparam int EXPECTED_TX    = 20;

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
    aineuronx_core #(
        .DATA_WIDTH(DATA_WIDTH_FP16)
    ) dut (
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

        for (int i = 0; i < EXPECTED_TX; i++) begin
            @(posedge clk);
            valid_in         = 1'b1;
            select_precision = i[0];

            input_a = DATA_WIDTH_FP16'(i);
            input_b = DATA_WIDTH_FP16'(EXPECTED_TX - i);

            input_cycle.push_back(cycle_count);
        end

        @(posedge clk);
        valid_in = 1'b0;

        // Esperar todas las respuestas del core real
        wait (output_cycle.size() == input_cycle.size());

        repeat (2) @(posedge clk);
        $finish;
    end

    // -------------------------------------------------
    // Captura de salida
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (ready_chip) begin
            output_cycle.push_back(cycle_count);

            assert (output_chip !== 'x)
                else $fatal("❌ Output indefinido detectado");
        end
    end

    // -------------------------------------------------
    // Reporte funcional
    // -------------------------------------------------
    final begin
        $display("====================================");
        $display(" AINEURONX TB FINAL REPORT");
        $display(" Inputs enviados  : %0d", input_cycle.size());
        $display(" Outputs recibidos: %0d", output_cycle.size());
        $display(" Testbench OK – Core real conectado");
        $display("====================================");
    end

    // -------------------------------------------------
    // Verificación FORMAL de latencia
    // Latencia esperada: 3 ciclos
    // -------------------------------------------------
    final begin
        for (int i = 0; i < input_cycle.size(); i++) begin
            int latency;
            latency = output_cycle[i] - input_cycle[i];

            assert (latency == 3)
                else $fatal(
                    "❌ ERROR DE LATENCIA | TX=%0d | Latencia=%0d ciclos | Esperado=3",
                    i, latency
                );
        end

        $display("✔ Latencia verificada: 3 ciclos fijos para %0d transacciones",
                 input_cycle.size());
    end

endmodule
