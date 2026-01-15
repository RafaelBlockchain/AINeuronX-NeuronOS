`timescale 1ns/1ps
module tb_aineuronx_chip();
    parameter DATA_WIDTH_FP8  = 8;
    parameter DATA_WIDTH_FP16 = 16;
    parameter MATRIX_SIZE = 64;

    reg clk, rst_n;
    reg [DATA_WIDTH_FP16-1:0] input_a, input_b;
    reg select_precision, valid_in, prefetch_enable;

    wire [DATA_WIDTH_FP16-1:0] output_chip;
    wire ready_chip;

    aineuronx_chip uut (
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

    initial clk = 0;
    always #5 clk = ~clk;

    integer i,j,cycle_count;
    reg [DATA_WIDTH_FP16-1:0] matrix_a [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];
    reg [DATA_WIDTH_FP16-1:0] matrix_b [0:MATRIX_SIZE-1][0:MATRIX_SIZE-1];

    initial begin
        rst_n = 0; valid_in = 0; prefetch_enable = 1; select_precision = 0; cycle_count = 0;
        for(i=0;i<MATRIX_SIZE;i=i+1)
            for(j=0;j<MATRIX_SIZE;j=j+1) begin
                matrix_a[i][j] = i*16+j; matrix_b[i][j] = i*16+j+1;
            end
        #20; rst_n = 1;
        for(i=0;i<MATRIX_SIZE;i=i+1)
            for(j=0;j<MATRIX_SIZE;j=j+1) begin
                input_a = matrix_a[i][j]; input_b = matrix_b[i][j]; valid_in = 1; #10; valid_in = 0; #10;
                cycle_count = cycle_count + 2;
            end
        select_precision = 1;
        for(i=0;i<MATRIX_SIZE;i=i+1)
            for(j=0;j<MATRIX_SIZE;j=j+1) begin
                input_a = matrix_a[i][j][DATA_WIDTH_FP8-1:0]; input_b = matrix_b[i][j][DATA_WIDTH_FP8-1:0];
                valid_in = 1; #10; valid_in = 0; #10; cycle_count = cycle_count + 2;
            end
        $display("Simulación completada. Ciclos totales: %0d", cycle_count);
        $display("Output final del chip: %0d", output_chip);
        $stop;
    end
endmodule

