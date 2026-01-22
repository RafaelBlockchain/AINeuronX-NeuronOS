// =====================================================
// AINEURONX_CORE_VECTOR.SV
// Core vectorizado – pipeline 1 ciclo por dato, V lanes
// =====================================================
`timescale 1ns/1ps

module aineuronx_core_vector #(
    parameter int DATA_WIDTH = 16,
    parameter int VECTOR_LANES = 4
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        valid_in,
    input  logic                        prefetch_enable,
    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_a,
    input  logic [DATA_WIDTH*VECTOR_LANES-1:0] input_b,
    output logic                        ready_out,
    output logic [DATA_WIDTH*VECTOR_LANES-1:0] output_data
);

    // -------------------------------------------------
    // Señales internas
    // -------------------------------------------------
    logic [DATA_WIDTH-1:0] a_lanes [VECTOR_LANES-1:0];
    logic [DATA_WIDTH-1:0] b_lanes [VECTOR_LANES-1:0];
    logic [DATA_WIDTH-1:0] out_lanes [VECTOR_LANES-1:0];

    logic valid_d;

    // -------------------------------------------------
    // Pipeline 1 ciclo
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_d <= 1'b0;
            ready_out <= 1'b0;
            output_data <= '0;
        end else begin
            valid_d <= valid_in && prefetch_enable;
            ready_out <= valid_d;

            // Extraer datos de vectores
            for (int l=0; l<VECTOR_LANES; l++) begin
                a_lanes[l] = input_a[l*DATA_WIDTH +: DATA_WIDTH];
                b_lanes[l] = input_b[l*DATA_WIDTH +: DATA_WIDTH];
            end

            // Operación vectorizada
            if (valid_d) begin
                for (int l=0; l<VECTOR_LANES; l++) begin
                    out_lanes[l] = a_lanes[l] + b_lanes[l]; // vector suma
                end

                // Reconstruir output_data
                for (int l=0; l<VECTOR_LANES; l++) begin
                    output_data[l*DATA_WIDTH +: DATA_WIDTH] = out_lanes[l];
                end
            end
        end
    end

endmodule
