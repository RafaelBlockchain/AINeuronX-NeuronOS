// =====================================================
// AINeuronX_N200_CORE.SV
// Core vectorizado – Pipeline formal de 3 etapas
// Latencia fija: 3 ciclos
// Listo para golden model + tape-out mindset
// =====================================================
`timescale 1ns/1ps

module AINeuronX_N200_CORE #(
    parameter int DATA_WIDTH   = 16,
    parameter int VECTOR_LANES = 4
)(
    input  logic clk,
    input  logic rst_n,

    input  logic valid_in,
    input  logic prefetch_enable,

    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_a,
    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_b,

    output logic ready_out,
    output logic [DATA_WIDTH*VECTOR_LANES-1:0] output_data
);

    // =================================================
    // STAGE 0 — CAPTURE
    // =================================================
    logic valid_s0;
    logic [DATA_WIDTH-1:0] a_s0 [VECTOR_LANES-1:0];
    logic [DATA_WIDTH-1:0] b_s0 [VECTOR_LANES-1:0];

    // =================================================
    // STAGE 1 — EXECUTE
    // =================================================
    logic valid_s1;
    logic [DATA_WIDTH-1:0] sum_s1 [VECTOR_LANES-1:0];

    // =================================================
    // STAGE 2 — COMMIT
    // =================================================
    logic valid_s2;
    logic [DATA_WIDTH-1:0] out_s2 [VECTOR_LANES-1:0];

    // =================================================
    // PIPELINE
    // =================================================
always_ff @(posedge clk) begin
    if (ready_out) begin
        for (int l=0; l<VECTOR_LANES; l++) begin
            golden_t g = golden_queue.pop_front();
            logic [DATA_WIDTH-1:0] out_val;
            int latency;

            out_val = output_data[l*DATA_WIDTH +: DATA_WIDTH];
            latency = cycle_count - g.cycle_in;

            assert (out_val == g.a + g.b)
                else $fatal("❌ ERROR FUNCIONAL | Output=%0d | Expected a+b | Latency=%0d | Lane=%0d | Cycle=%0d",
                            out_val, latency, l, cycle_count);

            assert (latency == 3)
                else $fatal("❌ ERROR DE LATENCIA | Latency=%0d | Lane=%0d | Cycle=%0d",
                            latency, l, cycle_count);
        end
    end
end

endmodule
