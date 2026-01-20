#include "Vaineuronx_chip.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vaineuronx_chip* top = new Vaineuronx_chip;

    // Inicialización explícita
    top->clk = 0;
    top->rst_n = 0;

    // Simulación acotada (seguridad)
    const vluint64_t MAX_TIME = 20000000;

    while (!Verilated::gotFinish() && main_time < MAX_TIME) {

        // Toggle clock cada 5 ns → período 10 ns
        if ((main_time % 5) == 0) {
            top->clk = !top->clk;
        }

        top->eval();
        main_time++;
    }

    top->final();
    delete top;

    if (main_time >= MAX_TIME) {
        VL_PRINTF("⚠ Simulation stopped by MAX_TIME\n");
    }

    return 0;
}
