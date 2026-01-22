#!/bin/bash
# =====================================================
# run_vector_tb.sh
# Compila y ejecuta el TB vectorizado con Verilator
# =====================================================
rm -rf obj_dir Vaineuronx* *.o *.a waves.fst

verilator -Wall --cc --exe --trace \
    aineuronx_tb_vector.sv \
    aineuronx_core_vector.sv \
    --build -j 8 main.cpp

./obj_dir/Vaineuronx_tb_vector
