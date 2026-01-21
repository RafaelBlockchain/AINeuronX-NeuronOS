#include "Vaineuronx.h"
#include "verilated.h"

vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vaineuronx* top = new Vaineuronx;

    while (!Verilated::gotFinish()) {
        top->eval();
        main_time++;                 // ⬅ AVANCE DE TIEMPO
        Verilated::timeInc(1);       // ⬅ CRÍTICO CON --timing
    }

    delete top;
    return 0;
}
