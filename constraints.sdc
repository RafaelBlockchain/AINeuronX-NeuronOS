# Definir el reloj principal clk_main a 250 MHz (periodo de 4.0 ns)
create_clock -name clk_main -period 4.0 [get_ports clk_main]
   
# Margen de seguridad (jitter) simulando un PLL real en 40 nm
set_clock_uncertainty 0.25 [get_clocks clk_main]

# Aplicar retrasos de entrada a todos los puertos EXCEPTO clk_main
set_input_delay 0.8 -clock clk_main [remove_from_collection [all_inputs] [get_ports clk_main]]

# Aplicar retrasos de salida a todos los puertos de salida
set_output_delay 0.8 -clock clk_main [all_outputs]
