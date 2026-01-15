//===========================================================
// AINeuronX Tensor Core Array (RTL inicial)
// 512 Tensor Cores divididos en sub-arrays de 64 cores
// Soporte FP8 y FP16, pipeline de multiplicación de matrices
// Control de acceso a cache L1
//===========================================================
module tensor_core_array #(
    parameter SUB_ARRAYS = 8,
    parameter CORES_PER_SUBARRAY = 64,
    parameter DATA_WIDTH_FP8 = 8,
    parameter DATA_WIDTH_FP16 = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH_FP16-1:0] input_a,
    input  wire [DATA_WIDTH_FP16-1:0] input_b,
    input  wire select_precision, // 0 = FP16, 1 = FP8
    input  wire valid_in,
    output wire [DATA_WIDTH_FP16-1:0] output_c,
    output wire ready_out
);
    genvar i;
    wire [DATA_WIDTH_FP16-1:0] subarray_out [SUB_ARRAYS-1:0];
    wire sub_ready [SUB_ARRAYS-1:0];

    generate
        for(i = 0; i < SUB_ARRAYS; i = i + 1) begin : SUBARRAYS
            tensor_subarray #(
                .CORES(CORES_PER_SUBARRAY),
                .DATA_WIDTH_FP8(DATA_WIDTH_FP8),
                .DATA_WIDTH_FP16(DATA_WIDTH_FP16)
            ) subarray_inst (
                .clk(clk),
                .rst_n(rst_n),
                .input_a(input_a),
                .input_b(input_b),
                .select_precision(select_precision),
                .valid_in(valid_in),
                .output_c(subarray_out[i]),
                .ready_out(sub_ready[i])
            );
        end
    endgenerate

    assign output_c = subarray_out[0] + subarray_out[1] + subarray_out[2] + subarray_out[3] +
                      subarray_out[4] + subarray_out[5] + subarray_out[6] + subarray_out[7];

    assign ready_out = &sub_ready;
endmodule

