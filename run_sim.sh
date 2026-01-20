#!/bin/bash
# =====================================================
# run_sim.sh
# Compila RTL + Testbench y ejecuta la simulación
# =====================================================

# Limpieza opcional previa
rm -rf obj_dir

# -----------------------------------------------------
# Paso 1: Generar C++ a partir de RTL + TB
# -----------------------------------------------------
verilator -Wall --cc rtl/*.v \
  --exe tb/tb_aineuronx_full_pipeline.sv \
  --top-module aineuronx_chip \
  --timing

# -----------------------------------------------------
# Paso 2: Compilar el ejecutable
# -----------------------------------------------------
make -C obj_dir -f Vaineuronx_chip.mk

# -----------------------------------------------------
# Paso 3: Ejecutar la simulación
# -----------------------------------------------------
./obj_dir/Vaineuronx_chip
