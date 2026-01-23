`timescale 1ns/1ps
module AINeuronX_ARRAY_2x2_TB;

  parameter DW = 16;

  // Señales de clock y reset
  logic clk;
  logic rst_n;
  logic in_valid;

  // Entradas y salidas del ARRAY 2x2
  logic [DW-1:0] a [0:3];
  logic [DW-1:0] b [0:3];
  logic out_valid;
  logic [DW-1:0] result [0:3];

  // Señales dummy para cores (previenen warnings UNDRIVEN/UNOPTFLAT)
  logic [DW-1:0] core_dummy_op [0:3];       // ahora 16 bits
  logic core_dummy_ready [0:3];             // listo para cada core

  // Instancia del ARRAY 2x2
  AINeuronX_ARRAY_2x2 dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .a(a),
    .b(b),
    .out_valid(out_valid),
    .result(result),
    .core_op(core_dummy_op),       // conectando 16 bits
    .core_ready(core_dummy_ready)
  );

  // Generador de reloj: 10 ns periodo
  initial clk = 0;
  always #5 clk = ~clk;

  // Testbench principal
  initial begin
    // Inicialización
    rst_n = 0;
    in_valid = 0;
    a[0] = 0; a[1] = 0; a[2] = 0; a[3] = 0;
    b[0] = 0; b[1] = 0; b[2] = 0; b[3] = 0;
    core_dummy_op[0] = 0; core_dummy_op[1] = 0; core_dummy_op[2] = 0; core_dummy_op[3] = 0;
    core_dummy_ready[0] = 0; core_dummy_ready[1] = 0; core_dummy_ready[2] = 0; core_dummy_ready[3] = 0;

    // Reset activo durante 2 ciclos de reloj
    @(posedge clk);
    @(posedge clk);
    rst_n = 1;

    // Esperar un ciclo
    @(posedge clk);

    // Estímulos de prueba
    a[0] = 1; b[0] = 2;
    a[1] = 3; b[1] = 4;
    a[2] = 5; b[2] = 6;
    a[3] = 7; b[3] = 8;

    // Activar in_valid un ciclo
    in_valid = 1;
    @(posedge clk);
    in_valid = 0;

    // Esperar hasta que el array indique salida válida
    wait(out_valid == 1);

    // Mostrar resultados
    $display("ARRAY RESULTS:");
    $display("%0d %0d %0d %0d",
             result[0], result[1], result[2], result[3]);

    // Finalizar simulación
    @(posedge clk);
    $finish;
  end

endmodule
