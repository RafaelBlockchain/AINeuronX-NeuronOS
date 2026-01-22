`timescale 1ns/1ps

module aineuronx_tb_vector;

    // ==================================================
    // Parámetros
    // ==================================================
    parameter int DATA_WIDTH    = 16;
    parameter int LANES         = 4;       // lanes vectorizadas
    parameter int TX_TOTAL      = 10;      // transacciones por lane
    parameter int CLK_PERIOD    = 10;      // ns
    parameter int PIPELINE_DEPTH = 3;      // latencia pipeline

    // ==================================================
    // Señales
    // ==================================================
    logic clk;
    logic rst_n;
    logic valid_in;
    logic select_precision;
    logic prefetch_enable;

    logic [DATA_WIDTH*LANES-1:0] input_a;
    logic [DATA_WIDTH*LANES-1:0] input_b;
    logic [DATA_WIDTH*LANES-1:0] output_data;
    logic ready_chip;

    integer cycle_count;

    // ==================================================
    // Struct Golden Model
    // ==================================================
    typedef struct packed {
        logic [DATA_WIDTH-1:0] a;
        logic [DATA_WIDTH-1:0] b;
        int cycle_in;
    } golden_t;

    golden_t golden_queue [$];

    // ==================================================
    // Clock
    // ==================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ==================================================
    // Contador de ciclos
    // ==================================================
    always_ff @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // ==================================================
    // DUT: Core vectorizado
    // ==================================================
    aineuronx_core_vector dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .select_precision(select_precision),
        .prefetch_enable(prefetch_enable),
        .input_a(input_a),
        .input_b(input_b),
        .ready_out(ready_chip),
        .output_data(output_data)
    );

    // ==================================================
    // Reset + estímulos
    // ==================================================
    initial begin
        rst_n            = 0;
        valid_in         = 0;
        select_precision = 0;
        prefetch_enable  = 0;
        input_a          = '0;
        input_b          = '0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        repeat (2) @(posedge clk);
        prefetch_enable = 1;

        for (int tx = 0; tx < TX_TOTAL; tx++) begin
            valid_in = 1;
            select_precision = tx[0]; // alterna suma/resta

            // Generar datos por lanes y guardar golden model
            for (int l = 0; l < LANES; l++) begin
                logic [DATA_WIDTH-1:0] sent_a = tx*LANES + l;
                logic [DATA_WIDTH-1:0] sent_b = TX_TOTAL*LANES - sent_a;

                input_a[l*DATA_WIDTH +: DATA_WIDTH] = sent_a;
                input_b[l*DATA_WIDTH +: DATA_WIDTH] = sent_b;

                golden_t g;
                g.a = sent_a;
                g.b = sent_b;
                g.cycle_in = cycle_count;
                golden_queue.push_back(g);
            end

            @(posedge clk);
        end

        valid_in = 0;

        // Esperar a que todas las respuestas salgan
        wait (golden_queue.size() == 0);

        repeat (2) @(posedge clk);
        $finish;
    end

    // ==================================================
    // Captura de salida + verificación
    // ==================================================
    always_ff @(posedge clk) begin
        if (ready_chip && golden_queue.size() > 0) begin
            for (int l = 0; l < LANES; l++) begin
                golden_t g = golden_queue.pop_front();
                logic [DATA_WIDTH-1:0] out_val = output_data[l*DATA_WIDTH +: DATA_WIDTH];
                logic [DATA_WIDTH-1:0] expected = select_precision ? g.a + g.b : g.a - g.b;

                assert (out_val === expected)
                    else $fatal("❌ ERROR FUNCIONAL | Out=%0d | Exp=%0d | Ciclo=%0d | Lane=%0d",
                                out_val, expected, cycle_count, l);

                // Latencia formal
                int latency = cycle_count - g.cycle_in;
                assert (latency == PIPELINE_DEPTH)
                    else $fatal("❌ ERROR DE LATENCIA | Ciclo=%0d | Latencia=%0d | Esperado=%0d",
                                cycle_count, latency, PIPELINE_DEPTH);
            end
        end
    end

    // ==================================================
    // Reporte final
    // ==================================================
    final begin
        $display("====================================");
        $display(" AINEURONX TB VECTOR FINAL REPORT");
        $display(" Golden model verificado, latencia %0d ciclos, lanes %0d", PIPELINE_DEPTH, LANES);
        $display("====================================");
    end

endmodule
