// =====================================================
// GOLDEN MODEL (referencia funcional)
// =====================================================
reg [DATA_WIDTH_FP16-1:0] golden_out;

always @(*) begin
    if (select_precision == 1'b0) begin
        // FP16 (modelo simple)
        golden_out = input_a * input_b;
    end else begin
        // FP8 (modelo simplificado: truncamiento)
        golden_out =
            (input_a[DATA_WIDTH_FP8-1:0] *
             input_b[DATA_WIDTH_FP8-1:0]);
    end
end

// =====================================================
// CHECK FUNCIONAL CONTRA GOLDEN
// =====================================================
always @(posedge clk) begin
    if (rst_n && valid_in && ready_chip) begin
        if (output_chip !== golden_out) begin
            $error("❌ MISMATCH | esperado=%0d obtenido=%0d | ciclo=%0d",
                   golden_out, output_chip, cycle_count);
            $stop;
        end
    end
end
