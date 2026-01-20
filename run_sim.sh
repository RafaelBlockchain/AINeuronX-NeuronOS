#!/bin/bash
set -e

# =====================================================
# run_sim.sh
# Compila RTL + Testbench y ejecuta la simulación
# =====================================================

echo "▶ Cleaning previous build..."
rm -rf obj_dir

echo "▶ Verilating RTL + TB..."
verilator -Wall --cc rtl/*.sv \
  --exe tb/tb_aineuronx_full_pipeline.sv \
  --top-module aineuronx_chip \
  --timing

echo "▶ Compiling C++ simulation..."
make -C obj_dir -f Vaineuronx_chip.mk

echo "▶ Running simulation..."
./obj_dir/Vaineuronx_chip

echo "✔ Simulation finished"
