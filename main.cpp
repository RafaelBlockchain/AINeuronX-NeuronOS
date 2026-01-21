#include "Vaineuronx.h"
#include "verilated.h"
#include "verilated_fst_c.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vaineuronx* top = new Vaineuronx;

    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace(tfp, 99);
    tfp->open("waves.fst");

    while (!Verilated::gotFinish()) {
        top->eval();

        // 🔴 ESTA LÍNEA ERA LA QUE FALTABA
        tfp->dump(main_time);

        main_time++;
        Verilated::timeInc(1);
    }

    tfp->close();
    delete tfp;
    delete top;
    return 0;
}
