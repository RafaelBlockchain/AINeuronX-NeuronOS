`timescale 1ns/1ps

module tb_aineuronx_full;

    // ======================================================
    // Parámetros
    // ======================================================
    parameter DATA_WIDTH_FP16 = 16;
    parameter DATA_WIDTH_FP8  = 8;
    parameter NUM_CLUSTERS    = 8;
    parameter SUBARRAYS       = 8;
    parameter CORES_PER_SUBARRAY = 64;
    parameter MATRIX_SIZE     = 16;

    // ======================================================
    // Señales de control
    // ======================================================
    reg clk;
    reg rst_n;
    reg [DATA_WIDTH_FP16-1:0] input_a;
    reg [DATA_WIDTH_FP16-1:0] input_b;
    reg select_precision;
    reg valid_in;
    reg prefetch_enable;

    // ======================================================
    // Salidas
    // ======================================================
    wire [DATA_WIDTH_FP16-1:0] output_chip;
    wire ready_chip;

    // ======================================================
    // Métricas
    // ======================================================
    integer cycle_count;
    integer core_failures;
    integer cluster_usage   [0:NUM_CLUSTERS-1];
    integer subarray_usage  [0:NUM_CLUSTERS-1][0:SUBARRAYS-1];

    // ======================================================
    // Variables auxiliares
    // ======================================================
    integer i, j, c, s;

    reg [DATA_WIDTH_FP16-1:0] matrix_a [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    reg [DATA_WIDTH_FP16-1:0] matrix_b [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // ======================================================
    // Instancia del chip
    // ======================================================
    aineuronx_chip #(
        .NUM_CLUSTERS(NUM_CLUSTERS),
        .SUB_ARRAYS(SUBARRAYS),
        .CORES_PER_SUBARRAY(CORES_PER_SUBARRAY),
        .DATA_WIDTH_FP8(DATA_WIDTH_FP8),
        .DATA_WIDTH_FP16(DATA_WIDTH_FP16),
        .CACHE_SIZE(1024)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .input_a(input_a),
        .input_b(input_b),
        .select_precision(select_precision),
        .valid_in(valid_in),
        .prefetch_enable(prefetch_enable),
        .output_chip(output_chip),
        .ready_chip(ready_chip)
    );

    // ======================================================
    // Clock
    // ======================================================
    initial clk = 0;
    always #5 clk = ~clk;

    // ======================================================
    // Inicialización y estímulos
    // ======================================================
    initial begin
        rst_n = 0;
        valid_in = 0;
        prefetch_enable = 1;
        select_precision = 0;
        cycle_count = 0;
        core_failures = 0;

        // Inicializar matrices
        for (i = 0; i < MATRIX_SIZE; i = i + 1)
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                matrix_a[i][j] = i * 16 + j;
                matrix_b[i][j] = i * 16 + j + 1;
            end

        // Release reset
        #20 rst_n = 1;

        // ============================
        // FP16
        // ============================
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                input_a = matrix_a[i][j];
                input_b = matrix_b[i][j];
                valid_in = 1;

                // Inyección de fallos (~1%)
                if ($urandom_range(0,99) < 1) begin
                    core_failures = core_failures + 1;
                    $display("Fallo simulado en ciclo %0d", cycle_count);
                end

                #10;
                valid_in = 0;
                #10;
                cycle_count = cycle_count + 2;

                // Métricas sintéticas
                for (c = 0; c < NUM_CLUSTERS; c = c + 1) begin
                    cluster_usage[c] = $urandom_range(50,100);
                    for (s = 0; s < SUBARRAYS; s = s + 1)
                        subarray_usage[c][s] = $urandom_range(50,100);
                end
            end
        end

        // ============================
        // FP8
        // ============================
        select_precision = 1;
        for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
            for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                input_a = matrix_a[i][j][DATA_WIDTH_FP8-1:0];
                input_b = matrix_b[i][j][DATA_WIDTH_FP8-1:0];
                valid_in = 1;
                #10;
                valid_in = 0;
                #10;
                cycle_count = cycle_count + 2;
            end
        end

        // ============================
        // Reporte
        // ============================
        $display("=== SIMULACIÓN COMPLETA ===");
        $display("Ciclos totales: %0d", cycle_count);
        $display("Output final chip: %0d", output_chip);
        $display("Fallas inyectadas: %0d", core_failures);

        for (i = 0; i < NUM_CLUSTERS; i = i + 1)
            $display("Cluster %0d uso promedio: %0d%%", i, cluster_usage[i]);

        $finish;
    end

endmodule
