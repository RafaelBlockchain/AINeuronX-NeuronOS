#!/bin/bash
# =====================================================
# run_vector_tb.sh
# Compila y ejecuta el testbench vectorizado de AINeuronX
# =====================================================

# Limpiar build previo
echo "▸ Cleaning previous build..."
rm -rf obj_dir Vaineuronx_tb_vector

# Crear carpeta de objetos
mkdir -p obj_dir

# Compilar con Verilator
echo "► Verilating RTL + TB..."
verilator -Wall --cc --exe --trace \
    src/aineuronx_tb_vector.sv \
    src/aineuronx_core_vector.sv \
    --build -j 8 main.cpp

# Ejecutar simulación
echo "► Running simulation..."
./obj_dir/Vaineuronx_tb_vector

echo "✔ Simulation finished"
echo "✔ Waveform generated: obj_dir/waves.fst"
