set_units -time ns -capacitance pF -current mA

# Reloj principal: 10.0 ns (100 MHz) para baseline en 55nm
create_clock -name clk -period 10.0 [get_ports clk]
   
# Incertidumbre y transición del reloj ajustadas a 55nm
set_clock_uncertainty 0.15 [get_clocks clk]
set_clock_transition 0.10 [get_clocks clk]

# Excluir el puerto de reloj de los retardos de entrada
set non_clk_inputs [remove_from_collection [all_inputs] [get_ports clk]]

# Retardos de I/O (20% del periodo de reloj)
set_input_delay  2.0 -clock clk $non_clk_inputs
set_output_delay 2.0 -clock clk [all_outputs]
   
# Transición de entrada y carga de salida típicas para bloques internos en 55nm
set_input_transition 0.15 $non_clk_inputs
set_load 0.03 [all_outputs]

# Fanout alineado con config.json
set_max_fanout 8 [current_design]
