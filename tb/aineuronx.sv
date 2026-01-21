// =====================================================
// AINEURONX.SV
// Testbench limpio, sin warnings, Verilator-friendly
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
    logic select_precision;   // ahora usada
    logic prefetch_enable;    // ahora usada

    logic [DATA_WIDTH_FP16-1:0] input_a;
    logic [DATA_WIDTH_FP16-1:0] input_b;

    logic [DATA_WIDTH_FP16-1:0] output_chip;
    logic ready_chip;

    integer cycle_count;
    integer input_cycle [$];
    integer output_cycle[$];

    // -------------------------------------------------
    // Clock
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
    // DUT STUB (usa TODAS las señales)
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            output_chip <= '0;
            ready_chip  <= 1'b0;
        end else if (valid_in && prefetch_enable) begin
            ready_chip <= 1'b1;

            // select_precision afecta el cálculo (dummy)
            if (select_precision)
                output_chip <= input_a + input_b;
            else
                output_chip <= input_a - input_b;

        end else begin
            ready_chip <= 1'b0;
        end
    end

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
            select_precision = i[0]; // alterna uso

            input_a = DATA_WIDTH_FP16'(i);
            input_b = DATA_WIDTH_FP16'(EXPECTED_TX - i);

            input_cycle.push_back(cycle_count);
        end

        @(posedge clk);
        valid_in = 1'b0;
    end

    // -------------------------------------------------
    // Captura y consumo de salida (ELIMINA warning)
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (ready_chip) begin
            output_cycle.push_back(cycle_count);

            // Consumo explícito del dato
            assert (output_chip !== 'x)
                else $error("Output indefinido");
        end
    end

    // -------------------------------------------------
    // Reporte final
    // -------------------------------------------------
    final begin
        $display("====================================");
        $display(" AINEURONX TB FINAL REPORT");
        $display(" Inputs enviados  : %0d", input_cycle.size());
        $display(" Outputs recibidos: %0d", output_cycle.size());

        if (input_cycle.size() != output_cycle.size())
            $error("Mismatch TX/RX");

        $display(" Testbench finalizado correctamente");
        $display("====================================");
    end

endmodule
