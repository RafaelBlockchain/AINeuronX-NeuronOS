`timescale 1ns/1ps

module tb_aineuronx_full();

    // Parámetros de simulación
    parameter DATA_WIDTH_FP16 = 16;
    parameter DATA_WIDTH_FP8  = 8;
    parameter NUM_CLUSTERS = 8;
    parameter SUBARRAYS = 8;
    parameter CORES_PER_SUBARRAY = 64;
    parameter MATRIX_SIZE = 16; // Tamaño reducido para simulación rápida

    // Señales de control
    reg clk;
    reg rst_n;
    reg [DATA_WIDTH_FP16-1:0] input_a;
    reg [DATA_WIDTH_FP16-1:0] input_b;
    reg select_precision;
    reg valid_in;
    reg prefetch_enable;

    // Salidas del chip
    wire [DATA_WIDTH_FP16-1:0] output_chip;
    wire ready_chip;

    // Instanciación del chip completo
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

    // Generación de reloj
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // Variables de simulación
    integer i,j;
    integer cycle_count;
    reg [DATA_WIDTH_FP16-1:0] matrix_a [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    reg [DATA_WIDTH_FP16-1:0] matrix_b [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    // Inicialización
    initial begin
        rst_n = 0;
        valid_in = 0;
        prefetch_enable = 1;
        select_precision = 0; // FP16 inicial
        cycle_count = 0;

        // Inicializar matrices con valores de prueba
        for(i=0;i<MATRIX_SIZE;i=i+1) begin
            for(j=0;j<MATRIX_SIZE;j=j+1) begin
                matrix_a[i][j] = i*16 + j;
                matrix_b[i][j] = i*16 + j + 1;
            end
        end

        // Release reset
        #20 rst_n = 1;

        // Simulación FP16
        for(i=0;i<MATRIX_SIZE;i=i+1) begin
            for(j=0;j<MATRIX_SIZE;j=j+1) begin
                input_a = matrix_a[i][j];
                input_b = matrix_b[i][j];
                valid_in = 1;
                #10; // ciclo de reloj
                valid_in = 0;
                #10;
                cycle_count = cycle_count + 2;
            end
        end

        // Simulación FP8
        select_precision = 1;
        for(i=0;i<MATRIX_SIZE;i=i+1) begin
            for(j=0;j<MATRIX_SIZE;j=j+1) begin
                input_a = matrix_a[i][j][DATA_WIDTH_FP8-1:0];
                input_b = matrix_b[i][j][DATA_WIDTH_FP8-1:0];
                valid_in = 1;
                #10;
                valid_in = 0;
                #10;
                cycle_count = cycle_count + 2;
            end
        end

        // Reporte final
        $display("Simulación FULL completada. Ciclos totales: %0d", cycle_count);
        $display("Output final del chip: %0d", output_chip);
        $stop;
    end

endmodule

