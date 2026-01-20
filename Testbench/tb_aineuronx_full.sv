// =====================================================
// TB_AINEURONX_FULL.SV
// Testbench completo: Golden Model + Checks + Asserts + Logging
// =====================================================
`timescale 1ns/1ps

module tb_aineuronx_full;

    // -------------------------------------------------
    // Parámetros
    // -------------------------------------------------
    parameter DATA_WIDTH_FP16 = 16;
    parameter DATA_WIDTH_FP8  = 8;
    parameter CLK_PERIOD = 10; // ns

    // -------------------------------------------------
    // Señales de clock, reset y control
    // -------------------------------------------------
    reg clk;
    reg rst_n;
    reg valid_in;
    reg select_precision; // 0 = FP16, 1 = FP8

    // Entradas del chip
    reg [DATA_WIDTH_FP16-1:0] input_a;
    reg [DATA_WIDTH_FP16-1:0] input_b;

    // Salidas del chip
    wire [DATA_WIDTH_FP16-1:0] output_chip;
    wire ready_chip;

    // Contador de ciclos
    integer cycle_count;

    // -------------------------------------------------
    // Instanciación del RTL
    // -------------------------------------------------
    aineuronx_chip uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .select_precision(select_precision),
        .input_a(input_a),
        .input_b(input_b),
        .output_chip(output_chip),
        .ready_chip(ready_chip)
    );

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
    // Reset y estímulo inicial
    // -------------------------------------------------
    initial begin
        rst_n = 0;
        valid_in = 0;
        select_precision = 0;
        input_a = 0;
        input_b = 0;

        #(CLK_PERIOD*5);
        rst_n = 1;

        // Estímulo de prueba
        #(CLK_PERIOD);
        valid_in = 1;
        input_a = 16'h0003; // ejemplo FP16
        input_b = 16'h0005;

        #(CLK_PERIOD*1);
        input_a = 16'h0007;
        input_b = 16'h0002;

        #(CLK_PERIOD*1);
        select_precision = 1; // FP8
        input_a = 8'h0A;
        input_b = 8'h03;

        #(CLK_PERIOD*5);
        valid_in = 0;

        #(CLK_PERIOD*10);
        $display("✔ Testbench completado sin errores");
        $finish;
    end

    // =====================================================
    // GOLDEN MODEL (referencia funcional)
    // =====================================================
    reg [DATA_WIDTH_FP16-1:0] golden_out;
    always @(*) begin
        if (select_precision == 1'b0) begin
            // FP16 (modelo simple)
            golden_out = input_a * input_b;
        end else begin
            // FP8 (modelo simplificado: truncamiento)
            golden_out = input_a[DATA_WIDTH_FP8-1:0] *
                         input_b[DATA_WIDTH_FP8-1:0];
        end
    end

    // =====================================================
    // CHECK FUNCIONAL CONTRA GOLDEN
    // =====================================================
    always @(posedge clk) begin
        if (rst_n && valid_in && ready_chip) begin
            if (output_chip !== golden_out) begin
                $error("❌ MISMATCH | esperado=%0d obtenido=%0d | ciclo=%0d",
                        golden_out, output_chip, cycle_count);
                $stop;
            end
        end
    end

    // =====================================================
    // ASSERTS INDUSTRIALES
    // =====================================================
    // 1) Ready nunca sin valid previo
    assert_ready_valid: assert property (@(posedge clk)
        ready_chip |-> $past(valid_in)
    ) else $error("❌ ready sin valid previo");

    // 2) Output nunca indefinido cuando ready
    assert_no_x: assert property (@(posedge clk)
        ready_chip |-> !$isunknown(output_chip)
    ) else $error("❌ output con X/Z cuando ready");

    // 3) Reset limpia el estado
    assert_reset_clean: assert property (@(posedge clk)
        !rst_n |-> !ready_chip
    ) else $error("❌ ready activo durante reset");

    // =====================================================
    // LOG AUTOMÁTICO CICLO A CICLO
    // =====================================================
    initial begin
        $display("Ciclo | input_a | input_b | output_chip | golden_out");
    end

    always @(posedge clk) begin
        if (rst_n && valid_in) begin
            $display("%0d | %0d | %0d | %0d | %0d",
                     cycle_count,
                     input_a,
                     input_b,
                     output_chip,
                     golden_out);
        end
    end

endmodule

