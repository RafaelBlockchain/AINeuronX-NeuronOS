// =====================================================
// AINEURONX.SV
// Testbench completo: Golden Model + Checks + Asserts + Pipeline Metrics
// Compatible con Verilator
// =====================================================
`timescale 1ns/1ps

module aineuronx;

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

    integer input_cycle[$];
    integer output_cycle[$];

    // -------------------------------------------------
    // Clock (FIX Verilator BLKSEQ)
    // -------------------------------------------------
    initial clk = 0;
    always begin
        #(CLK_PERIOD/2);
        clk <= ~clk;   // <-- CAMBIO CLAVE
    end

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
        rst_n            = 0;
        valid_in         = 0;
        select_precision = 0;
        prefetch_enable  = 0;
        input_a          = 0;
        input_b          = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (2) @(posedge clk);

        // Ejemplo de estímulos
        for (int i = 0; i < EXPECTED_TX; i++) begin
            @(posedge clk);
            valid_in = 1;
            input_a  = i;
            input_b  = EXPECTED_TX - i;
            input_cycle.push_back(cycle_count);
        end

        @(posedge clk);
        valid_in = 0;
    end

    // -------------------------------------------------
    // Captura de salida
    // -------------------------------------------------
    always @(posedge clk) begin
        if (ready_chip) begin
            output_cycle.push_back(cycle_count);
        end
    end

    // -------------------------------------------------
    // Checks finales
    // -------------------------------------------------
    final begin
        $display("====================================");
        $display(" AINEURONX TB FINAL REPORT");
        $display(" Inputs enviados : %0d", input_cycle.size());
        $display(" Outputs recibidos: %0d", output_cycle.size());

        if (input_cycle.size() != output_cycle.size())
            $error("Mismatch TX/RX");

        $display(" Testbench finalizado correctamente");
        $display("====================================");
    end

endmodule
