// ============================================================
// Testbench: Memory Hierarchy System
// Project: Instruction and Data Memory Hierarchy
// Description: Exercises the full memory hierarchy — instruction
//              fetch, cache reads (hit & miss), cache writes
//              (write-through), and verifies correct data flow.
//              Dumps waveforms to sim/waveforms/dump.vcd
// ============================================================

`timescale 1ns / 1ps

module memory_hierarchy_tb;

    // ---- Inputs ----
    reg        clk;
    reg        rst;
    reg [7:0]  if_addr;
    reg        d_we;
    reg [7:0]  d_addr;
    reg [31:0] d_wr_data;

    // ---- Outputs ----
    wire [31:0] if_instr;
    wire [31:0] d_rd_data;
    wire        cache_hit;
    wire        cache_miss;

    // ---- Instantiate DUT ----
    memory_hierarchy_top dut (
        .clk        (clk),
        .rst        (rst),
        .if_addr    (if_addr),
        .if_instr   (if_instr),
        .d_we       (d_we),
        .d_addr     (d_addr),
        .d_wr_data  (d_wr_data),
        .d_rd_data  (d_rd_data),
        .cache_hit  (cache_hit),
        .cache_miss (cache_miss)
    );

    // ---- Clock Generation: 10ns period ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Waveform Dump ----
    initial begin
        $dumpfile("sim/waveforms/dump.vcd");
        $dumpvars(0, memory_hierarchy_tb);
    end

    // ---- Test Sequence ----
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [31:0] got;
        input [31:0] expected;
        input [63:0] test_id;  // just a number label
        begin
            if (got === expected) begin
                $display("[PASS] Test %0d: got 0x%08X", test_id, got);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: expected 0x%08X, got 0x%08X", test_id, expected, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== Memory Hierarchy Testbench Starting ===");

        // --- Reset ---
        rst = 1; d_we = 0; if_addr = 0; d_addr = 0; d_wr_data = 0;
        @(posedge clk); #1;
        rst = 0;

        // =========================================================
        // TEST 1: Instruction Fetch — address 0
        // =========================================================
        if_addr = 8'd0;
        @(posedge clk); #1;
        $display("[INFO] Instruction at addr 0: 0x%08X", if_instr);

        // =========================================================
        // TEST 2: Cache READ MISS — addr 0 (not yet in cache)
        // =========================================================
        d_we = 0; d_addr = 8'd0;
        @(posedge clk); #1;
        $display("[INFO] Cache READ addr=0: data=0x%08X, HIT=%b, MISS=%b",
                  d_rd_data, cache_hit, cache_miss);

        // =========================================================
        // TEST 3: Cache READ HIT — addr 0 (now in cache)
        // =========================================================
        @(posedge clk); #1;
        $display("[INFO] Cache READ addr=0 (again): data=0x%08X, HIT=%b, MISS=%b",
                  d_rd_data, cache_hit, cache_miss);

        // =========================================================
        // TEST 4: Cache READ MISS — addr 1
        // =========================================================
        d_addr = 8'd1;
        @(posedge clk); #1;
        $display("[INFO] Cache READ addr=1: data=0x%08X, HIT=%b, MISS=%b",
                  d_rd_data, cache_hit, cache_miss);

        // =========================================================
        // TEST 5: Cache WRITE (write-through) — addr 2
        // =========================================================
        d_we = 1; d_addr = 8'd2; d_wr_data = 32'hBEEFCAFE;
        @(posedge clk); #1;
        d_we = 0;
        $display("[INFO] Cache WRITE addr=2: wrote 0xBEEFCAFE");

        // =========================================================
        // TEST 6: Read back written value — should HIT in cache
        // =========================================================
        d_addr = 8'd2;
        @(posedge clk); #1;
        $display("[INFO] Cache READ addr=2 after write: data=0x%08X, HIT=%b",
                  d_rd_data, cache_hit);
        check(d_rd_data, 32'hBEEFCAFE, 6);

        // =========================================================
        // TEST 7: Instruction Fetch — address 3
        // =========================================================
        if_addr = 8'd3;
        @(posedge clk); #1;
        $display("[INFO] Instruction at addr 3: 0x%08X", if_instr);

        // =========================================================
        // Summary
        // =========================================================
        #10;
        $display("=== Simulation Complete: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        $finish;
    end

endmodule
