#!/bin/bash
set -e

echo "▸ Cleaning previous build..."
rm -rf obj_dir

echo "▸ Verilating RTL + TB..."
verilator -Wall \
  --cc rtl/*.sv \
  tb/tb_aineuronx_full_pipeline.sv \
  --top-module tb_aineuronx_full_pipeline \
  --exe tb/main.cpp \
  --timing \
  --build

echo "▸ Running simulation..."
./obj_dir/Vtb_aineuronx_full_pipeline
