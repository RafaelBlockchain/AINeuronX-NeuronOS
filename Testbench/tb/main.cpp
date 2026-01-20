#include "Vaineuronx_chip.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vaineuronx_chip* top = new Vaineuronx_chip;

    while (!Verilated::gotFinish()) {
        top->clk ^= 1;
        top->eval();
    }

    delete top;
    return 0;
}
