#include "Vaineuronx_chip.h"
#include "verilated.h"

vluint64_t sim_time = 0;
const vluint64_t MAX_TIME = 20000000;

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vaineuronx_chip *top = new Vaineuronx_chip;

    // Reset inicial (si lo usas)
    top->rst_n = 0;
    for (int i = 0; i < 5; i++) {
        top->clk = 0; top->eval(); sim_time++;
        top->clk = 1; top->eval(); sim_time++;
    }
    top->rst_n = 1;

    // === LOOP CORRECTO ===
    while (!Verilated::gotFinish()) {

        top->clk = 0;
        top->eval();
        sim_time++;

        top->clk = 1;
        top->eval();
        sim_time++;

        if (sim_time >= MAX_TIME) {
            printf("Simulation stopped by MAX_TIME\n");
            break;
        }
    }

    printf("✔ Simulation finished successfully\n");

    delete top;
    return 0;
}
