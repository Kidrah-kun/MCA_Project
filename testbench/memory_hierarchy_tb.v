// ============================================================
// Testbench: Memory Hierarchy System
// Project: Instruction and Data Memory Hierarchy
// Author:  Ayush Tiwari
// Role:    Testbench & Integration
// ============================================================

`timescale 1ns / 1ps

module memory_hierarchy_tb;

    // ------- Clock & Reset -------
    reg        clk, rst;

    // ------- I-Cache interface -------
    reg  [7:0]  if_addr;
    wire [31:0] if_instr;
    wire        if_stall;
    wire        icache_hit, icache_miss;

    // ------- D-Cache interface -------
    reg  [7:0]  d_addr;
    reg         d_we;
    reg  [31:0] d_wr_data;
    wire [31:0] d_rd_data;
    wire        d_stall;
    wire        dcache_hit, dcache_miss;

    // ------- DUT instantiation -------
    memory_hierarchy_top dut (
        .clk        (clk),
        .rst        (rst),
        .if_addr    (if_addr),
        .if_instr   (if_instr),
        .if_stall   (if_stall),
        .d_we       (d_we),
        .d_addr     (d_addr),
        .d_wr_data  (d_wr_data),
        .d_rd_data  (d_rd_data),
        .d_stall    (d_stall),
        .icache_hit (icache_hit),
        .icache_miss(icache_miss),
        .dcache_hit (dcache_hit),
        .dcache_miss(dcache_miss)
    );

    // ------- 100 MHz clock (10ns period) -------
    initial clk = 0;
    always #5 clk = ~clk;

    // ------- VCD waveform dump -------
    initial begin
        $dumpfile("sim/waveforms/dump.vcd");
        $dumpvars(0, memory_hierarchy_tb);
    end

    // ------- Pass / Fail checker -------
    integer pass_count = 0, fail_count = 0;
    task check;
        input [31:0] got, expected;
        input [7:0]  tid;
        begin
            if (got === expected) begin
                $display("[PASS] Test %0d: 0x%08X", tid, got);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: expected 0x%08X, got 0x%08X", tid, expected, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ------- Main stimulus -------
    integer cycle;
    initial begin
        $display("=== Memory Hierarchy Testbench ===");

        // Reset sequence
        rst = 1; d_we = 0; if_addr = 0; d_addr = 0; d_wr_data = 0;
        repeat(2) @(posedge clk); #1;
        rst = 0;

        // ---- T1: I-Cache first fetch addr=0 — expect MISS (cold cache) ----
        if_addr = 8'd0; d_we = 0; d_addr = 8'd5;
        repeat(6) @(posedge clk); #1;
        $display("[T1] ICache fetch addr=0: instr=0x%08X stall=%b hit=%b miss=%b",
                  if_instr, if_stall, icache_hit, icache_miss);

        // ---- T2: I-Cache same addr=0 again — expect HIT, no stall ----
        @(posedge clk); #1;
        $display("[T2] ICache fetch addr=0 again: hit=%b miss=%b", icache_hit, icache_miss);

        // ---- T3: D-Cache read miss (addr=5, expect 0x0000000A) ----
        d_addr = 8'd5; d_we = 0;
        repeat(6) @(posedge clk); #1;
        $display("[T3] DCache read addr=5: data=0x%08X hit=%b miss=%b",
                  d_rd_data, dcache_hit, dcache_miss);

        // ---- T4: D-Cache read hit (same addr=5 again) ----
        @(posedge clk); #1;
        $display("[T4] DCache read addr=5 (hit): hit=%b miss=%b", dcache_hit, dcache_miss);

        // ---- T5: D-Cache write addr=2, data=0xBEEFCAFE (write-through) ----
        d_we = 1; d_addr = 8'd2; d_wr_data = 32'hBEEFCAFE;
        @(posedge clk); #1;
        d_we = 0;
        $display("[T5] DCache write addr=2: 0xBEEFCAFE");

        // ---- T6: Read back addr=2 — verify write-through worked ----
        d_addr = 8'd2;
        @(posedge clk); #1;
        $display("[T6] DCache read addr=2 after write: data=0x%08X hit=%b", d_rd_data, dcache_hit);
        check(d_rd_data, 32'hBEEFCAFE, 6);

        // ---- T7: I-Cache fetch new addr=1 — expect MISS ----
        if_addr = 8'd1;
        repeat(6) @(posedge clk); #1;
        $display("[T7] ICache fetch addr=1: instr=0x%08X miss=%b", if_instr, icache_miss);

        #20;
        $display("=== Done: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        $finish;
    end

endmodule
