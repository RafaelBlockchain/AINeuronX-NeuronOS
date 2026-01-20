#include "Vtb_aineuronx_full_pipeline.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vtb_aineuronx_full_pipeline* top =
        new Vtb_aineuronx_full_pipeline;

    // El testbench controla clock, reset y finalización
    while (!Verilated::gotFinish()) {
        top->eval();
    }

    printf("✔ Simulation finished successfully\n");

    delete top;
    return 0;
}
