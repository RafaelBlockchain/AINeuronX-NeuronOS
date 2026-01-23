module AINeuronX_NOC_ROUTER(
    input logic clk, rst,
    input logic in_valid,
    output logic in_ready,
    output logic out_valid,
    input logic out_ready
);
    assign out_valid = in_valid;
    assign in_ready  = out_ready;
endmodule
