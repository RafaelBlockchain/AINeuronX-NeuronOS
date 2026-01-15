//===========================================================
// AINeuronX L1 Cache Adaptativa (RTL inicial)
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
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg  hit,
    output reg  ready_out
);
    reg [DATA_WIDTH-1:0] cache_mem [CACHE_SIZE-1:0];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= 0;
            hit <= 0;
            ready_out <= 0;
            for(i=0; i<CACHE_SIZE; i=i+1)
                cache_mem[i] <= 0;
        end else begin
            ready_out <= 0;
            if(read_en) begin
                data_out <= cache_mem[addr];
                hit <= 1;
                ready_out <= 1;
                if(prefetch_enable && (addr < CACHE_SIZE-1))
                    cache_mem[addr+1] <= cache_mem[addr+1];
            end else if(write_en) begin
                cache_mem[addr] <= data_in;
                ready_out <= 1;
            end
        end
    end
endmodule

