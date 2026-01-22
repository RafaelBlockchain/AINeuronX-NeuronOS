verilator -Wall --cc --exe --trace --no-timing \
    src/aineuronx_tb_vector.sv \
    src/aineuronx_core_vector.sv \
    --build main.cpp -j 8

./obj_dir/Vaineuronx_tb_vector
