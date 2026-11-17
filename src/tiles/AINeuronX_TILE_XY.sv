module AINeuronX_TILE_XY #(
    parameter DW = 16,
    parameter X_ID = 0,
    parameter Y_ID = 0
)(
    input  logic clk,
    input  logic rst_n,
    input  logic enable,

    input  logic          n_valid, s_valid, e_valid, w_valid,
    input  logic [DW-1:0] n_data,  s_data,  e_data,  w_data,
    output logic          n_ready, s_ready, e_ready, w_ready,

    output logic          out_valid,
    output logic [DW-1:0] out_data
);

    // Señales internas del Core Vectorial (4 carriles x 16 bits = 64 bits)
    logic        core_in_valid;
    logic        core_ready;
    logic [63:0] vec_in_a;
    logic [63:0] vec_in_b;
    logic [63:0] vec_out;
    logic [DW-1:0] core_reduced_data;

    // Empaquetar tráfico Norte/Oeste como Vector A y Sur/Este como Vector B
    assign core_in_valid = enable & (n_valid | w_valid | s_valid | e_valid);
    assign vec_in_a = {n_data, w_data, n_data ^ {X_ID[3:0], Y_ID[3:0], 8'h55}, w_data};
    assign vec_in_b = {s_data, e_data, s_data ^ {Y_ID[3:0], X_ID[3:0], 8'hAA}, e_data};

    // Instancia real del núcleo vectorial AINeuronX_N200_CORE
    AINeuronX_N200_CORE #(
        .DATA_WIDTH(DW),
        .VECTOR_LANES(4)
    ) u_core (
        .clk             (clk),
        .rst_n           (rst_n),
        .valid_in        (core_in_valid),
        .prefetch_enable (enable),
        .input_a         (vec_in_a),
        .input_b         (vec_in_b),
        .ready_out       (core_ready),
        .output_data     (vec_out)
    );

    // Reducción de los 4 carriles vectoriales (64 bits) a 1 palabra de red (16 bits)
    assign core_reduced_data = vec_out[15:0] + vec_out[31:16] + vec_out[47:32] + vec_out[63:48];

    // Router XY de 16 bits
    AINeuronX_NOC_ROUTER_XY #(
        .DW(DW),
        .X_ID(X_ID),
        .Y_ID(Y_ID)
    ) router (
        .clk(clk),
        .rst_n(rst_n),

        .l_valid(core_ready),
        .l_data(core_reduced_data),
        .l_ready(),

        .n_valid(n_valid), .n_data(n_data), .n_ready(n_ready),
        .s_valid(s_valid), .s_data(s_data), .s_ready(s_ready),
        .e_valid(e_valid), .e_data(e_data), .e_ready(e_ready),
        .w_valid(w_valid), .w_data(w_data), .w_ready(w_ready),

        .out_valid(out_valid),
        .out_data(out_data)
    );

endmodule
