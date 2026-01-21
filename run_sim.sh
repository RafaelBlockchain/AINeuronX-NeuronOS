#!/bin/bash
set -e

echo "▸ Cleaning previous build..."
rm -rf obj_dir

echo "► Verilating RTL + TB..."
verilator -Wall --cc \
  rtl/*.sv \
  tb/aineuronx.sv \
  --top-module aineuronx \
  --exe main.cpp \
  --timing

echo "► Building simulation..."
make -C obj_dir -f Vaineuronx.mk

echo "► Running simulation..."
./obj_dir/Vaineuronx
