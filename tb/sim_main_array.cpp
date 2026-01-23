#include "verilated.h"
#include "verilated_vcd_c.h"
#include "VAINeuronX_ARRAY_2x2_TB.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Crear instancia del TB
    VAINeuronX_ARRAY_2x2_TB* tb = new VAINeuronX_ARRAY_2x2_TB;

    // Habilitar tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    tb->trace(tfp, 99);
    tfp->open("wave_array_2x2.vcd");

    // Inicialización de señales en TB
    tb->eval(); // eval inicial
    vluint64_t sim_time = 0;

    // Simulación hasta $finish
    while (!Verilated::gotFinish()) {
        tb->eval();          // evaluar el DUT
        tfp->dump(sim_time); // guardar waveform
        Verilated::timeInc(1); // avanzar tiempo
        sim_time++;
    }

    tfp->close();
    delete tb;
    delete tfp;

    printf("✔ Simulation finished (ARRAY 2x2)\n");
    return 0;
}
