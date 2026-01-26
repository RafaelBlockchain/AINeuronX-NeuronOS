module tensor_top (
    input  logic        clk,
    input  logic        rst_n,

    // Scheduler
    input  logic        op_valid,
    output logic        op_ready,
    input  logic [3:0]  op_opcode,
    input  logic [2:0]  op_fmt,
    input  logic [7:0]  op_tile_cfg,

    // Memory
    output logic        mem_req_valid,
    input  logic        mem_req_ready,
    output logic [63:0] mem_addr,
    input  logic [255:0] mem_rdata,

    // Writeback / NoC
    output logic        wb_valid,
    input  logic        wb_ready,
    output logic [63:0] wb_addr,
    output logic [255:0] wb_data,

    // Status
    output logic        done,
    output logic        stall
);

    // ---------------- Pipeline Registers ----------------
    logic v_c0, v_c1, v_c2, v_c3, v_c4, v_c5;
    logic v_c6, v_c7, v_c8, v_c9, v_c10, v_c11, v_c12, v_c13;

    // Example register block
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_c0 <= 1'b0;
            // reset all stages
        end else if (!stall) begin
            v_c0 <= op_valid & op_ready;
            v_c1 <= v_c0;
            v_c2 <= v_c1;
            // ... hasta v_c13
        end
    end

    // ---------------- Backpressure ----------------
    assign stall = v_c13 & ~wb_ready;
    assign op_ready = ~stall;

    assign wb_valid = v_c13;
    assign done     = v_c13 & wb_ready;

endmodule
