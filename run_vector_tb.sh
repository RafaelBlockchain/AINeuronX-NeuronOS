#!/bin/bash

# -------------------------------------------------
# Limpieza
# -------------------------------------------------
echo "▸ Cleaning previous build..."
rm -rf obj_dir
rm -f waves.fst

# -------------------------------------------------
# Compilación Verilator
# -------------------------------------------------
echo "► Verilating RTL + TB..."
verilator \
    --cc \
    --exe \
    --build \
    --Wall \
    --timing \
    -I./src \
    src/aineuronx_core_vector.sv \
    src/aineuronx_tb_vector.sv \
    -CFLAGS "-O2 -g" \
    --trace

# -------------------------------------------------
# Ejecutar simulación
# -------------------------------------------------
echo "► Running simulation..."
./obj_dir/Vaineuronx_tb_vector

echo "✔ Simulation finished"
echo "✔ Waveform generated: waves.fst"
