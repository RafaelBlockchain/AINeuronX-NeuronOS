//===========================================================
// AINeuronX Top-Level RTL (Chip completo)
//===========================================================
module aineuronx_chip #(
    parameter NUM_CLUSTERS = 8,
    parameter SUB_ARRAYS = 8,
    parameter CORES_PER_SUBARRAY = 64,
    parameter DATA_WIDTH_FP8 = 8,
    parameter DATA_WIDTH_FP16 = 16,
    parameter CACHE_SIZE = 1024
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH_FP16-1:0] input_a,
    input  wire [DATA_WIDTH_FP16-1:0] input_b,
    input  wire select_precision,
    input  wire valid_in,
    input  wire prefetch_enable,
    output wire [DATA_WIDTH_FP16-1:0] output_chip,
    output wire ready_chip
);
    wire [DATA_WIDTH_FP16-1:0] cluster_out [NUM_CLUSTERS-1:0];
    wire [NUM_CLUSTERS-1:0] cluster_ready;
    genvar i;
    generate
        for(i=0; i<NUM_CLUSTERS; i=i+1) begin : CLUSTERS
            compute_cluster #(
                .SUB_ARRAYS(SUB_ARRAYS),
                .CORES_PER_SUBARRAY(CORES_PER_SUBARRAY),
                .DATA_WIDTH_FP8(DATA_WIDTH_FP8),
                .DATA_WIDTH_FP16(DATA_WIDTH_FP16),
                .CACHE_SIZE(CACHE_SIZE)
            ) cluster_inst (
                .clk(clk),
                .rst_n(rst_n),
                .input_a(input_a),
                .input_b(input_b),
                .select_precision(select_precision),
                .valid_in(valid_in),
                .prefetch_enable(prefetch_enable),
                .output_c(cluster_out[i]),
                .ready_out(cluster_ready[i])
            );
        end
    endgenerate

    assign output_chip = cluster_out[0]+cluster_out[1]+cluster_out[2]+cluster_out[3]+
                         cluster_out[4]+cluster_out[5]+cluster_out[6]+cluster_out[7];
    assign ready_chip = &cluster_ready;
endmodule

