#include "Vtb_aineuronx_full_pipeline.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Instancia del testbench top-level
    Vtb_aineuronx_full_pipeline* top =
        new Vtb_aineuronx_full_pipeline;

    // El testbench SV controla clock, reset y finalización
    while (!Verilated::gotFinish()) {
        top->eval();
    }

    delete top;
    return 0;
}
