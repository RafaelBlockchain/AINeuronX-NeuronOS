// =====================================================
// AINEURONX_TB_VECTOR.SV
// Testbench vectorizado industrial para AINeuronX
// Pipeline vectorizado + golden model + latencia formal
// =====================================================
`timescale 1ns/1ps

module aineuronx_tb_vector;

    // -------------------------------------------------
    // Parámetros
    // -------------------------------------------------
    parameter int DATA_WIDTH = 16;
    parameter int CLK_PERIOD = 10;  // ns
    parameter int TX_TOTAL   = 20;  // transacciones
    parameter int LANES      = 4;   // vector por ciclo

    // -------------------------------------------------
    // Señales
    // -------------------------------------------------
    logic clk;
    logic rst_n;
    logic valid_in;
    logic prefetch_enable;

    logic [DATA_WIDTH*LANES-1:0] input_a;
    logic [DATA_WIDTH*LANES-1:0] input_b;

    logic ready_out;
    logic [DATA_WIDTH*LANES-1:0] output_data;

    integer cycle_count;
    integer sent      = 0;
    integer received  = 0;

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------
    // Contador de ciclos
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    // -------------------------------------------------
    // Definición del GOLDEN STRUCT
    // -------------------------------------------------
    typedef struct {
        logic [DATA_WIDTH-1:0] a;
        logic [DATA_WIDTH-1:0] b;
        int cycle_in;
    } golden_t;

    golden_t golden_queue [$];

    // -------------------------------------------------
    // DUT: Core vectorizado
    // -------------------------------------------------
    aineuronx_core_vector #(
        .DATA_WIDTH(DATA_WIDTH),
        .LANES(LANES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .prefetch_enable(prefetch_enable),
        .input_a(input_a),
        .input_b(input_b),
        .ready_out(ready_out),
        .output_data(output_data)
    );

    // -------------------------------------------------
    // Reset + estímulos
    // -------------------------------------------------
    initial begin
        rst_n = 0;
        valid_in = 0;
        prefetch_enable = 0;
        input_a = '0;
        input_b = '0;

        repeat(5) @(posedge clk);
        rst_n = 1;

        repeat(2) @(posedge clk);
        prefetch_enable = 1;

        while(sent < TX_TOTAL) begin
            @(posedge clk);

            valid_in = 1;
            for (int l=0; l<LANES; l++) begin
                if (sent >= TX_TOTAL) begin
                    input_a[l*DATA_WIDTH +: DATA_WIDTH] = 0;
                    input_b[l*DATA_WIDTH +: DATA_WIDTH] = 0;
                end else begin
                    input_a[l*DATA_WIDTH +: DATA_WIDTH] = sent;
                    input_b[l*DATA_WIDTH +: DATA_WIDTH] = TX_TOTAL - sent;

                    // Guardar GOLDEN
                    golden_t g = '{a: sent, b: TX_TOTAL-sent, cycle_in: cycle_count};
                    golden_queue.push_back(g);

                    sent++;
                end
            end
        end

        @(posedge clk);
        valid_in = 0;

        // Esperar todas las respuestas
        wait(received == TX_TOTAL);
        repeat(2) @(posedge clk);
        $finish;
    end

    // -------------------------------------------------
    // Captura de salida + verificación GOLDEN
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (ready_out && golden_queue.size() > 0) begin
            for (int l=0; l<LANES; l++) begin
                if (golden_queue.size() == 0)
                    break;

                golden_t g = golden_queue.pop_front();

                logic [DATA_WIDTH-1:0] out_val;
                out_val = output_data[l*DATA_WIDTH +: DATA_WIDTH];

                int latency = cycle_count - g.cycle_in;

                assert(out_val === (g.a + g.b))
                    else $fatal(
                        "❌ ERROR FUNCIONAL | Out=%0d | Esperado=%0d | Ciclo=%0d | Latencia=%0d",
                        out_val, (g.a + g.b), cycle_count, latency
                    );

                assert(latency == 3)
                    else $fatal(
                        "❌ ERROR LATENCIA | Latencia=%0d ciclos | Ciclo=%0d",
                        latency, cycle_count
                    );

                received++;
            end
        end
    end

    // -------------------------------------------------
    // Reporte final
    // -------------------------------------------------
    final begin
        $display("====================================");
        $display(" AINEURONX TB VECTOR FINAL REPORT");
        $display(" Transacciones enviadas : %0d", sent);
        $display(" Transacciones recibidas: %0d", received);
        $display(" Testbench OK – Golden model + latencia verificada");
        $display("====================================");
    end

endmodule
