`timescale 1ns / 1ps

module serial_to_parallel_tb;

    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;

    reg                    clk;
    reg                    rst_n;
    reg                    serial_in;
    reg                    shift_en;
    wire [DATA_WIDTH-1:0]  parallel_out;
    wire                   data_valid;

    serial_to_parallel #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .serial_in(serial_in),
        .shift_en(shift_en), .parallel_out(parallel_out), .data_valid(data_valid)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer i;
    reg [DATA_WIDTH-1:0] captured;

    // Task: send DATA_WIDTH bits serially MSB-first
    task send_serial;
        input [DATA_WIDTH-1:0] data;
        begin
            #1;
            serial_in = 1'b0;
            shift_en  = 1'b1;
            for (i = DATA_WIDTH-1; i >= 0; i = i - 1) begin
                serial_in = (data >> i) & 1'b1;
                @(posedge clk); #1;
            end
            shift_en  = 1'b0;
            serial_in = 1'b0;
        end
    endtask

    // Task: check and report
    task check_result;
        input [DATA_WIDTH-1:0] expected;
        input [DATA_WIDTH-1:0] received;
        input integer          test_num;
        begin
            if (received === expected) begin
                $display("  [PASS] Test %0d: expected=0x%02X  got=0x%02X", test_num, expected, received);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] Test %0d: expected=0x%02X  got=0x%02X <-- ERROR", test_num, expected, received);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("serial_to_parallel.vcd");
        $dumpvars(0, serial_to_parallel_tb);

        pass_count = 0; fail_count = 0;
        rst_n = 0; serial_in = 0; shift_en = 0;

        $display("==============================================");
        $display(" Serial-to-Parallel Converter Testbench     ");
        $display(" DATA_WIDTH = %0d bits                      ", DATA_WIDTH);
        $display("==============================================");

        repeat(3) @(posedge clk); #1; rst_n = 1;
        $display("[INFO] Reset released. Simulation start.\n");

        // Test 1: 0xA5
        $display("--- Test 1: 0xA5 (10100101) MSB first ---");
        send_serial(8'hA5);
        @(posedge clk); #1; captured = parallel_out;
        check_result(8'hA5, captured, 1);
        repeat(2) @(posedge clk);

        // Test 2: 0xFF
        $display("\n--- Test 2: 0xFF (11111111) ---");
        send_serial(8'hFF);
        @(posedge clk); #1; captured = parallel_out;
        check_result(8'hFF, captured, 2);
        repeat(2) @(posedge clk);

        // Test 3: 0x3C
        $display("\n--- Test 3: 0x3C (00111100) ---");
        send_serial(8'h3C);
        @(posedge clk); #1; captured = parallel_out;
        check_result(8'h3C, captured, 3);
        repeat(2) @(posedge clk);

        // Test 4: 0x00
        $display("\n--- Test 4: 0x00 (00000000) ---");
        send_serial(8'h00);
        @(posedge clk); #1; captured = parallel_out;
        check_result(8'h00, captured, 4);
        repeat(2) @(posedge clk);

        // Test 5: 0x69
        $display("\n--- Test 5: 0x69 (01101001) ---");
        send_serial(8'h69);
        @(posedge clk); #1; captured = parallel_out;
        check_result(8'h69, captured, 5);
        repeat(2) @(posedge clk);

        // Test 6: Mid-stream reset recovery
        $display("\n--- Test 6: Mid-stream reset, then send 0x55 ---");
        #1; shift_en = 1; serial_in = 1;
        repeat(4) @(posedge clk);
        #1; rst_n = 0;
        repeat(2) @(posedge clk);
        #1; rst_n = 1; shift_en = 0;
        $display("  [INFO] Reset re-asserted and released");
        send_serial(8'h55);
        @(posedge clk); #1; captured = parallel_out;
        check_result(8'h55, captured, 6);
        repeat(2) @(posedge clk);

        // Test 7: shift_en=0 holds output stable
        $display("\n--- Test 7: shift_en=0, output must stay 0x55 ---");
        #1; shift_en = 0; serial_in = 1;
        repeat(12) @(posedge clk); #1; captured = parallel_out;
        check_result(8'h55, captured, 7);

        $display("\n==============================================");
        $display(" RESULTS: %0d PASS  /  %0d FAIL", pass_count, fail_count);
        $display("==============================================");
        if (fail_count == 0) $display(" ALL TESTS PASSED!\n");
        else $display(" SOME TESTS FAILED.\n");

        $finish;
    end

    initial begin #20000; $display("[TIMEOUT]"); $finish; end

endmodule
