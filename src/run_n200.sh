#!/bin/bash
# ==================================================
# Script Verilator – AINeuronX N200 PRO industrial
# ==================================================

echo "▸ Cleaning previous build..."
rm -rf obj_dir

echo "► Verilating RTL + TB..."
verilator -Wall --cc \
    --exe \
    --build \
    -I./src \
    src/aineuronx_n200_core.sv \
    src/aineuronx_n200_tb.sv \
    --trace

SIM_BINARY=./obj_dir/Vaineuronx_n200_tb

if [ -f "$SIM_BINARY" ]; then
    echo "► Running simulation..."
    $SIM_BINARY
    echo "✔ Simulation finished"
    echo "✔ Waveform generated: obj_dir/waves.fst"
else
    echo "❌ Simulation binary not found"
fi
