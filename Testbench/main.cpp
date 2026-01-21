#include "Vaineuronx.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Instancia del top-level (testbench SV)
    Vaineuronx* top = new Vaineuronx;

    while (!Verilated::gotFinish()) {
        top->eval();
    }

    delete top;
    return 0;
}
