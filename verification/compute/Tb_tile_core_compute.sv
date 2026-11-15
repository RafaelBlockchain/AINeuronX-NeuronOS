
`timescale 1ns/1ps

module tb_tile_core_compute;

    localparam int DATA_WIDTH = 16;
    localparam int ACC_WIDTH  = 32;
    localparam int LANES      = 4;
    localparam int ROWS       = 2;
    localparam int COLS       = 2;
    localparam int K_DIM      = 2;

    logic clk;
    logic rst_n;

    // Vector interface
    logic vector_start;
    logic [1:0] vector_opcode;
    logic vector_clear_acc;

    logic [LANES*DATA_WIDTH-1:0] vector_a;
    logic [LANES*DATA_WIDTH-1:0] vector_b;

    logic [LANES*ACC_WIDTH-1:0] vector_result;
    logic vector_busy;
    logic vector_done;

    // Tensor interface
    logic tensor_load;
    logic tensor_start;

    logic [ROWS*K_DIM*DATA_WIDTH-1:0] matrix_a;
    logic [K_DIM*COLS*DATA_WIDTH-1:0] matrix_b;

    logic [ROWS*COLS*ACC_WIDTH-1:0] tensor_accumulators;
    logic [ROWS*COLS-1:0] tensor_valid;

    logic tensor_busy;
    logic tensor_done;

    int errors;

    // DUT
    Tile_Core_Compute #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .LANES(LANES),
        .ROWS(ROWS),
        .COLS(COLS),
        .K_DIM(K_DIM)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .vector_start(vector_start),
        .vector_opcode(vector_opcode),
        .vector_clear_acc(vector_clear_acc),
        .vector_a(vector_a),
        .vector_b(vector_b),
        .vector_result(vector_result),
        .vector_busy(vector_busy),
        .vector_done(vector_done),

        .tensor_load(tensor_load),
        .tensor_start(tensor_start),
        .matrix_a(matrix_a),
        .matrix_b(matrix_b),
        .tensor_accumulators(tensor_accumulators),
        .tensor_valid(tensor_valid),
        .tensor_busy(tensor_busy),
        .tensor_done(tensor_done)
    );

    // Clock: 100 MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Vector lane helper
    task automatic set_vector_lane(
        input int lane,
        input logic signed [DATA_WIDTH-1:0] a,
        input logic signed [DATA_WIDTH-1:0] b
    );
        vector_a[lane*DATA_WIDTH +: DATA_WIDTH] = a;
        vector_b[lane*DATA_WIDTH +: DATA_WIDTH] = b;
    endtask

    task automatic check_vector_lane(
        input int lane,
        input logic signed [ACC_WIDTH-1:0] expected,
        input string test_name
    );
        logic signed [ACC_WIDTH-1:0] actual;
        begin
            actual = vector_result[lane*ACC_WIDTH +: ACC_WIDTH];

            if (actual !== expected) begin
                $error(
                    "%s lane %0d: expected %0d, got %0d",
                    test_name, lane, expected, actual
                );
                errors++;
            end
            else begin
                $display(
                    "PASS: %s lane %0d = %0d",
                    test_name, lane, actual
                );
            end
        end
    endtask

    task automatic run_vector(
        input logic [1:0] opcode,
        input string test_name
    );
        begin
            @(negedge clk);
            vector_opcode = opcode;
            vector_start = 1'b1;

            @(negedge clk);
            vector_start = 1'b0;

            wait (vector_done === 1'b1);
            @(negedge clk);

            $display("Completed vector test: %s", test_name);
        end
    endtask

    task automatic check_tensor(
        input int row,
        input int col,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        logic signed [ACC_WIDTH-1:0] actual;
        int index;
        begin
            index = row*COLS + col;

            actual =
                tensor_accumulators[index*ACC_WIDTH +: ACC_WIDTH];

            if (actual !== expected) begin
                $error(
                    "Tensor [%0d][%0d]: expected %0d, got %0d",
                    row, col, expected, actual
                );
                errors++;
            end
            else begin
                $display(
                    "PASS: Tensor [%0d][%0d] = %0d",
                    row, col, actual
                );
            end
        end
    endtask

    initial begin
        errors = 0;

        rst_n = 1'b0;

        vector_start = 1'b0;
        vector_opcode = 2'b00;
        vector_clear_acc = 1'b0;
        vector_a = '0;
        vector_b = '0;

        tensor_load = 1'b0;
        tensor_start = 1'b0;
        matrix_a = '0;
        matrix_b = '0;

        // -------------------------
        // Reset
        // -------------------------
        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        repeat (2) @(negedge clk);

        $display("Starting AINeuronX N200 tile tests");

        // -------------------------
        // Vector ADD
        // -------------------------
        set_vector_lane(0, 16'sd10, 16'sd5);
        set_vector_lane(1, -16'sd3, 16'sd8);
        set_vector_lane(2, 16'sd100, -16'sd20);
        set_vector_lane(3, 16'sd7, 16'sd9);

        run_vector(2'b00, "ADD");

        check_vector_lane(0, 32'sd15, "ADD");
        check_vector_lane(1, 32'sd5, "ADD");
        check_vector_lane(2, 32'sd80, "ADD");
        check_vector_lane(3, 32'sd16, "ADD");

        // -------------------------
        // Vector MUL
        // -------------------------
        run_vector(2'b01, "MUL");

        check_vector_lane(0, 32'sd50, "MUL");
        check_vector_lane(1, -32'sd24, "MUL");
        check_vector_lane(2, -32'sd2000, "MUL");
        check_vector_lane(3, 32'sd63, "MUL");

        // -------------------------
        // Vector MAC
        // -------------------------
        vector_clear_acc = 1'b1;
        @(negedge clk);
        vector_clear_acc = 1'b0;

        run_vector(2'b10, "MAC");

        check_vector_lane(0, 32'sd50, "MAC");
        check_vector_lane(1, -32'sd24, "MAC");
        check_vector_lane(2, -32'sd2000, "MAC");
        check_vector_lane(3, 32'sd63, "MAC");

        // -------------------------
        // Tensor matrix load
        //
        // A = [1 2]
        //     [3 4]
        //
        // B = [5 6]
        //     [7 8]
        // -------------------------
        @(negedge clk);

        matrix_a[0*DATA_WIDTH +: DATA_WIDTH] = 16'sd1;
        matrix_a[1*DATA_WIDTH +: DATA_WIDTH] = 16'sd2;
        matrix_a[2*DATA_WIDTH +: DATA_WIDTH] = 16'sd3;
        matrix_a[3*DATA_WIDTH +: DATA_WIDTH] = 16'sd4;

        matrix_b[0*DATA_WIDTH +: DATA_WIDTH] = 16'sd5;
        matrix_b[1*DATA_WIDTH +: DATA_WIDTH] = 16'sd6;
        matrix_b[2*DATA_WIDTH +: DATA_WIDTH] = 16'sd7;
        matrix_b[3*DATA_WIDTH +: DATA_WIDTH] = 16'sd8;

        tensor_load = 1'b1;

        @(negedge clk);
        tensor_load = 1'b0;

        // -------------------------
        // Tensor execution
        // -------------------------
        tensor_start = 1'b1;

        @(negedge clk);
        tensor_start = 1'b0;

        fork
            begin
                wait (tensor_done === 1'b1);
            end
            begin
                repeat (30) @(negedge clk);
                $fatal(1, "Tensor execution timeout");
            end
        join_any

        disable fork;

        @(negedge clk);

        // Expected A x B:
        //
        // [19 22]
        // [43 50]
        //
        check_tensor(0, 0, 32'sd19);
        check_tensor(0, 1, 32'sd22);
        check_tensor(1, 0, 32'sd43);
        check_tensor(1, 1, 32'sd50);

        // -------------------------
        // Final report
        // -------------------------
        if (errors == 0) begin
            $display("--------------------------------");
            $display("ALL TESTS PASSED");
            $display("AINeuronX N200 tile functional TB");
            $display("--------------------------------");
        end
        else begin
            $fatal(
                1,
                "TESTBENCH FAILED: %0d errors",
                errors
            );
        end

        $finish;
    end

          endmodule
          
