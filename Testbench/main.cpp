#include "Vtb_aineuronx_full_pipeline.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instancia del testbench (NO del chip)
    Vtb_aineuronx_full_pipeline* tb =
        new Vtb_aineuronx_full_pipeline;

    // El clock, reset y $finish los controla el TB en SV
    while (!Verilated::gotFinish()) {
        tb->eval();
    }

    // Mensaje final único y correcto
    printf("✔ Simulation finished successfully\n");

    delete tb;
    return 0;
}
