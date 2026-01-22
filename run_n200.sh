#!/bin/bash
# ==================================================
# Script de compilación y simulación Verilator
# para AINeuronX_N200 core vectorizado + TB industrial
# ==================================================

# Limpiar compilaciones anteriores
echo "▸ Cleaning previous build..."
rm -rf obj_dir

# Verilating RTL + TB
echo "► Verilating RTL + TB..."
verilator -Wall --cc --exe --build -I./src \
    src/AINeuronX_N200_CORE.SV \
    src/AINeuronX_N200_TB.SV \
    --trace

# Verilated binary
SIM_BINARY=./obj_dir/VAINeuronX_N200_TB

# Ejecutar simulación
if [ -f "$SIM_BINARY" ]; then
    echo "► Running simulation..."
    $SIM_BINARY
    echo "✔ Simulation finished"
    echo "✔ Waveform generated: obj_dir/waves.fst"
else
    echo "❌ Simulation binary not found"
fi
