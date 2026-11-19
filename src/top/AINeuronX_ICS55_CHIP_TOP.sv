module AINeuronX_ICS55_CHIP_TOP (
    // Pines físicos externos del encapsulado QFN-48 (3.3 V)
    inout  wire        pad_clk_main,
    inout  wire        pad_rst_n,
    inout  wire        pad_global_enable,

    inout  wire        pad_in_valid,
    inout  wire [15:0] pad_in_data,
    inout  wire        pad_in_ready,

    inout  wire        pad_out_valid,
    inout  wire [15:0] pad_out_data,
    inout  wire        pad_out_ready
);

    // Señales internas de 1.2 V conectadas al núcleo 8x8
    wire        core_clk_main;
    wire        core_rst_n;
    wire        core_global_enable;

    wire        core_in_valid;
    wire [15:0] core_in_data;
    wire        core_in_ready;

    wire        core_out_valid;
    wire [15:0] core_out_data;
    wire        core_out_ready;

    // ---------------------------------------------------------
    // 1. PADS DE ALIMENTACIÓN (Núcleo 1.2V y Anillo I/O 3.3V)
    // ---------------------------------------------------------
    PVDD1CDG  u_pad_vdd   (); // VDD Core 1.2V
    PVSS1CDG  u_pad_vss   (); // VSS Core
    PVDD2CDG  u_pad_iovdd (); // IOVDD 3.3V
    PVSS2CDG  u_pad_iovss (); // IOVSS

    // ---------------------------------------------------------
    // 2. PADS DE ENTRADA (3.3 V externo -> 1.2 V interno)
    // ---------------------------------------------------------
    PDDW16SDGZ u_pad_clk    (.PAD(pad_clk_main),      .C(core_clk_main),      .I(1'b0), .OEN(1'b1), .REN(1'b0));
    PDDW16SDGZ u_pad_rst    (.PAD(pad_rst_n),         .C(core_rst_n),         .I(1'b0), .OEN(1'b1), .REN(1'b0));
    PDDW16SDGZ u_pad_en     (.PAD(pad_global_enable), .C(core_global_enable), .I(1'b0), .OEN(1'b1), .REN(1'b0));
    PDDW16SDGZ u_pad_ivalid (.PAD(pad_in_valid),      .C(core_in_valid),      .I(1'b0), .OEN(1'b1), .REN(1'b0));
    PDDW16SDGZ u_pad_oready (.PAD(pad_out_ready),     .C(core_out_ready),     .I(1'b0), .OEN(1'b1), .REN(1'b0));

    PDDW16SDGZ u_pad_idata [15:0] (
        .PAD(pad_in_data),
        .C  (core_in_data),
        .I  (1'b0),
        .OEN(1'b1),
        .REN(1'b0)
    );

    // ---------------------------------------------------------
    // 3. PADS DE SALIDA (1.2 V interno -> 3.3 V externo, 16 mA)
    // ---------------------------------------------------------
    PDDW16SDGZ u_pad_iready (.PAD(pad_in_ready),  .C(), .I(core_in_ready),  .OEN(1'b0), .REN(1'b0));
    PDDW16SDGZ u_pad_ovalid (.PAD(pad_out_valid), .C(), .I(core_out_valid), .OEN(1'b0), .REN(1'b0));

    PDDW16SDGZ u_pad_odata [15:0] (
        .PAD(pad_out_data),
        .C  (),
        .I  (core_out_data),
        .OEN(1'b0),
        .REN(1'b0)
    );

    // ---------------------------------------------------------
    // 4. NÚCLEO DIGITAL AINeuronX N200 8x8 (64 Cores Vectoriales)
    // ---------------------------------------------------------
    AINeuronX_N200_8x8_TOP #(
        .DW(16)
    ) u_core_8x8 (
        .clk_main     (core_clk_main),
        .rst_n        (core_rst_n),
        .global_enable(core_global_enable),

        .in_valid     (core_in_valid),
        .in_data      (core_in_data),
        .in_ready     (core_in_ready),

        .out_valid    (core_out_valid),
        .out_data     (core_out_data),
        .out_ready    (core_out_ready)
    );

endmodule
