module AINeuronX_ARRAY_2x2 #(
    parameter DW = 16
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              in_valid,
    input  logic [DW-1:0]     a [0:3],
    input  logic [DW-1:0]     b [0:3],
    output logic              out_valid,
    output logic [DW-1:0]     result [0:3]
);

    // Señales internas de cada core
    logic [3:0] core_out_valid;

    // Dummy signals para conectar pines no usados de cada core
    logic dummy_in_ready [0:3];
    logic dummy_out_ready [0:3];
    logic [DW-1:0] dummy_op [0:3];

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : CORE_GEN
            AINeuronX_N200_CORE core (
                .clk       (clk),
                .rst_n     (rst_n),
                .in_valid  (in_valid),
                .a         (a[i]),
                .b         (b[i]),
                .out_valid (core_out_valid[i]),
                .result    (result[i]),
                // Pines no usados conectados a dummy signals
                .in_ready  (dummy_in_ready[i]),
                .out_ready (dummy_out_ready[i]),
                .op        (dummy_op[i])
            );
        end
    endgenerate

    // out_valid solo cuando todos los cores tienen salida válida
    assign out_valid = &core_out_valid;

endmodule
