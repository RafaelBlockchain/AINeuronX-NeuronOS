#!/bin/bash
rm -rf obj_dir Vaineuronx_tb_vector
mkdir -p obj_dir

verilator -Wall --cc --exe --trace \
    src/aineuronx_tb_vector.sv \
    src/aineuronx_core_vector.sv \
    --build -j 8 main.cpp

./obj_dir/Vaineuronx_tb_vector
