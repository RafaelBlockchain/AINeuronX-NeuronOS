#include "Vaineuronx.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Instancia del testbench top-level
    Vaineuronx* top =
        new Vaineuronx;

    // El testbench SV controla clock, reset y finalización
    while (!Verilated::gotFinish()) {
        top->eval();
    }

    delete top;
    return 0;
}
