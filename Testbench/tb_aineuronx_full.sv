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

