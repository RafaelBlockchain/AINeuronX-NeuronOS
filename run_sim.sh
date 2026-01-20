#!/bin/bash
set -e

rm -rf obj_dir

verilator -Wall --cc \
  rtl/*.sv \
  tb/tb_aineuronx_full_pipeline.sv \
  --top-module tb_aineuronx_full_pipeline \
  --exe tb/main.cpp \
  --timing

make -C obj_dir -f Vtb_aineuronx_full_pipeline.mk

./obj_dir/Vtb_aineuronx_full_pipeline
