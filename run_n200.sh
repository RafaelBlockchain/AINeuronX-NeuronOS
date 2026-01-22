#!/bin/bash
# ==================================================
# Build & simulate AINeuronX_N200 with Verilator
# ==================================================

set -e

echo "▸ Cleaning previous build..."
rm -rf obj_dir

echo "► Verilating RTL + TB..."
verilator -Wall --cc --exe --build \
    src/AINeuronX_N200_CORE.SV \
    src/AINeuronX_N200_TB.SV \
    --trace

SIM=./obj_dir/VAINeuronX_N200_TB

if [ -f "$SIM" ]; then
    echo "► Running simulation..."
    $SIM
    echo "✔ Simulation finished"
    echo "✔ Waveform: obj_dir/waves.fst"
else
    echo "❌ Simulation binary not found"
fi
