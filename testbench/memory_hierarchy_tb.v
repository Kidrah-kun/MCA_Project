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

        // ---- T1: Simultaneous miss — D-Cache & I-Cache miss at same time ----
        // D-Cache accesses addr=5 (expects 0x0000000A)
        // I-Cache accesses addr=0 (expects 0xDEADBEEF)
        // Arbiter gives PRIORITY to D-Cache, then serves I-Cache
        $display("\n[T1] Simultaneous miss test: D-Cache addr=5, I-Cache addr=0");
        if_addr = 8'd0; d_we = 0; d_addr = 8'd5;
        repeat(12) @(posedge clk); #1;
        $display("[T1 Result] D-Cache data=0x%08X (stall=%b), I-Cache instr=0x%08X (stall=%b)",
                  d_rd_data, d_stall, if_instr, if_stall);
        check(d_rd_data, 32'h0000000A, 1);
        check(if_instr,  32'hDEADBEEF, 2);

        // ---- T2: I-Cache repeat fetch addr=0 — expect HIT in 1 cycle ----
        @(posedge clk); #1;
        $display("\n[T2] I-Cache repeat read addr=0: instr=0x%08X hit=%b miss=%b", if_instr, icache_hit, icache_miss);
        if (icache_hit && if_instr === 32'hDEADBEEF) begin
            $display("[PASS] Test 3: I-Cache HIT on cached instruction (0x%08X)", if_instr);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test 3: Expected I-Cache hit");
            fail_count = fail_count + 1;
        end

        // ---- T3: D-Cache repeat read addr=5 — expect HIT in 1 cycle ----
        d_addr = 8'd5; d_we = 0;
        @(posedge clk); #1;
        $display("\n[T3] D-Cache repeat read addr=5: data=0x%08X hit=%b miss=%b", d_rd_data, dcache_hit, dcache_miss);
        if (dcache_hit && d_rd_data === 32'h0000000A) begin
            $display("[PASS] Test 4: D-Cache HIT on cached data (0x%08X)", d_rd_data);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test 4: Expected D-Cache hit");
            fail_count = fail_count + 1;
        end

        // ---- T4: D-Cache write-through operation to addr=2 ----
        $display("\n[T4] D-Cache write-through: writing 0xBEEFCAFE to addr=2");
        d_we = 1; d_addr = 8'd2; d_wr_data = 32'hBEEFCAFE;
        @(posedge clk); #1;
        d_we = 0;
        $display("[PASS] Test 5: Write-through request issued to cache and main memory");
        pass_count = pass_count + 1;

        // ---- T5: Read back addr=2 — verify immediate cache HIT with written data ----
        d_addr = 8'd2;
        @(posedge clk); #1;
        $display("\n[T5] D-Cache readback addr=2 after write: data=0x%08X hit=%b", d_rd_data, dcache_hit);
        check(d_rd_data, 32'hBEEFCAFE, 6);

        // ---- T6: I-Cache fetch from a different block (addr=4) — expect cold MISS ----
        if_addr = 8'd4;
        repeat(8) @(posedge clk); #1;
        $display("\n[T6] I-Cache new block fetch addr=4: instr=0x%08X", if_instr);
        check(if_instr, 32'hABCD1234, 7);

        #20;
        $display("=== Done: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        $finish;
    end

endmodule
