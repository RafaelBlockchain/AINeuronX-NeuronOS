# Definir el reloj principal clk_main a 250 MHz (periodo de 4.0 ns)
create_clock -name clk_main -period 4.0 [get_ports clk_main]

# Margen de seguridad (jitter) simulando un PLL real en 40 nm
set_clock_uncertainty 0.25 [get_clocks clk_main]

# Retrasos estimados en puertos de entrada y salida
set_input_delay  0.8 -clock clk_main [all_inputs]
set_output_delay 0.8 -clock clk_main [all_outputs]

# Excluir el reloj de los retrasos de datos
remove_input_delay [get_ports clk_main]
