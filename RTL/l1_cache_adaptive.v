
//===========================================================
// AINeuronX L1 Cache Adaptativa (ASIC-grade, limpia)
// Modelo de latencia / control (sin datapath)
//===========================================================
module l1_cache_adaptive #(
    parameter CACHE_SIZE = 1024,
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [9:0] addr,
    input  wire read_en,
    input  wire write_en,
    input  wire prefetch_enable,
    output reg  ready_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_out <= 1'b0;
        end else begin
            // Modelo simple: 1 ciclo de latencia cuando hay acceso
            if (read_en || write_en)
                ready_out <= 1'b1;
            else
                ready_out <= 1'b0;
        end
    end

endmodule
