// ============================================================
// Module   : memory_hierarchy_e2e_tb
// Project  : Instruction and Data Memory Hierarchy (MCA Project)
// Purpose  : Comprehensive End-to-End (E2E) System Verification Testbench
//
// Test Matrix:
//   E2E-01: Power-on Reset & Interface State Verification
//   E2E-02: Simultaneous Dual-Cache Cold Miss & Arbiter Priority (D-Cache before I-Cache)
//   E2E-03: Single-Cycle L1 I-Cache Hit & Zero-Stall Pipeline Operation
//   E2E-04: Single-Cycle L1 D-Cache Hit & Zero-Stall Pipeline Operation
//   E2E-05: Concurrent Dual-Cache Single-Cycle Hits (Harvard Independence)
//   E2E-06: D-Cache Write-Through Operation to Backing DRAM
//   E2E-07: Immediate Read-After-Write Cache Hit
//   E2E-08: D-Cache Conflict Eviction (Same Index, Different Tag)
//   E2E-09: End-to-End Coherence: DRAM Readback of Evicted Write-Through Data
//   E2E-10: I-Cache Conflict Eviction & DRAM Re-fetch
//   E2E-11: Back-to-Back Consecutive Data Stores to Different Lines
//   E2E-12: Full System Data Integrity & Memory Persistence Check
// ============================================================

`timescale 1ns / 1ps

module memory_hierarchy_e2e_tb;

    // ------- Clock & Reset -------
    reg        clk;
    reg        rst;

    // ------- CPU Instruction Fetch Interface -------
    reg  [7:0]  if_addr;
    wire [31:0] if_instr;
    wire        if_stall;
    wire        icache_hit;
    wire        icache_miss;

    // ------- CPU Data Memory Interface -------
    reg  [7:0]  d_addr;
    reg         d_we;
    reg  [31:0] d_wr_data;
    wire [31:0] d_rd_data;
    wire        d_stall;
    wire        dcache_hit;
    wire        dcache_miss;

    // ------- Device Under Test (DUT) Instantiation -------
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

    // 100 MHz System Clock (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Waveform Dump
    initial begin
        $dumpfile("sim/waveforms/e2e_dump.vcd");
        $dumpvars(0, memory_hierarchy_e2e_tb);
    end

    // Test Assertions & Counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task assert_val;
        input [31:0] got;
        input [31:0] expected;
        input [511:0] test_name;
        begin
            test_num = test_num + 1;
            if (got === expected) begin
                $display("  [PASS #%02d] %0s | Value: 0x%08X", test_num, test_name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL #%02d] %0s | Expected: 0x%08X, Got: 0x%08X", test_num, test_name, expected, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task assert_cond;
        input condition;
        input [511:0] test_name;
        begin
            test_num = test_num + 1;
            if (condition) begin
                $display("  [PASS #%02d] %0s", test_num, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL #%02d] %0s | Condition evaluated to FALSE", test_num, test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Main Test Execution Flow
    initial begin
        $display("======================================================================");
        $display("🚀 STARTING FULL END-TO-END (E2E) MEMORY HIERARCHY VERIFICATION SUITE");
        $display("======================================================================\n");

        // -----------------------------------------------------------------
        // E2E-01: Power-on Reset & Interface State Verification
        // -----------------------------------------------------------------
        $display("[E2E-01] Testing System Reset Behavior...");
        rst = 1;
        d_we = 0;
        if_addr = 8'd0;
        d_addr = 8'd5;
        d_wr_data = 32'd0;
        repeat(2) @(posedge clk);
        #1;
        assert_cond(if_stall == 0 && d_stall == 0, "Pipeline stalls deasserted on reset");
        rst = 0;

        // -----------------------------------------------------------------
        // E2E-02: Simultaneous Dual-Cache Cold Miss & Arbiter Priority
        // Both I-Cache (addr 0) and D-Cache (addr 5) request main memory simultaneously.
        // D-Cache must be serviced first by arbiter, followed by I-Cache.
        // -----------------------------------------------------------------
        $display("\n[E2E-02] Testing Simultaneous Dual-Cache Cold Miss & Arbiter Priority...");
        @(posedge clk); #1;
        assert_cond(if_stall == 1 && d_stall == 1, "Both caches stall pipeline on dual miss");

        @(posedge clk); #1;
        assert_cond(dut.ctrl.state == 2'b01, "Arbiter correctly transitions to SERVE_D first (D-Priority)");

        // Wait for D-Cache to complete using hardware stall handshake
        while (d_stall) @(posedge clk);
        #1;
        assert_val(d_rd_data, 32'h0000000A, "D-Cache received correct data (0x0A)");
        assert_cond(d_stall == 0, "D-Cache stall released after fill");
        assert_cond(if_stall == 1, "I-Cache remains stalled waiting for arbiter");

        // Wait for I-Cache to be serviced in SERVE_I state
        while (if_stall) @(posedge clk);
        #1;
        assert_val(if_instr, 32'hDEADBEEF, "I-Cache received correct instruction (0xDEADBEEF)");
        assert_cond(if_stall == 0, "I-Cache stall released after fill");

        // -----------------------------------------------------------------
        // E2E-03: Single-Cycle L1 I-Cache Hit
        // Reading previously cached address 0 must return within 1 cycle without stall.
        // -----------------------------------------------------------------
        $display("\n[E2E-03] Testing Single-Cycle L1 I-Cache Hit...");
        if_addr = 8'd0;
        @(posedge clk); #1;
        assert_cond(icache_hit == 1 && icache_miss == 0, "I-Cache asserts hit strobe");
        assert_cond(if_stall == 0, "Zero-cycle pipeline stall on I-Cache hit");
        assert_val(if_instr, 32'hDEADBEEF, "I-Cache returns cached 0xDEADBEEF immediately");

        // -----------------------------------------------------------------
        // E2E-04: Single-Cycle L1 D-Cache Hit
        // Reading previously cached address 5 must return within 1 cycle without stall.
        // -----------------------------------------------------------------
        $display("\n[E2E-04] Testing Single-Cycle L1 D-Cache Hit...");
        d_addr = 8'd5;
        d_we   = 0;
        @(posedge clk); #1;
        assert_cond(dcache_hit == 1 && dcache_miss == 0, "D-Cache asserts hit strobe");
        assert_cond(d_stall == 0, "Zero-cycle pipeline stall on D-Cache hit");
        assert_val(d_rd_data, 32'h0000000A, "D-Cache returns cached 0x0000000A immediately");

        // -----------------------------------------------------------------
        // E2E-05: Concurrent Dual-Cache Single-Cycle Hits (Harvard Independence)
        // I-Cache and D-Cache both hit simultaneously in the same clock cycle.
        // -----------------------------------------------------------------
        $display("\n[E2E-05] Testing Concurrent Dual-Cache Single-Cycle Hits (Harvard Arch)...");
        if_addr = 8'd0;
        d_addr  = 8'd5;
        d_we    = 0;
        @(posedge clk); #1;
        assert_cond(icache_hit == 1 && dcache_hit == 1, "Concurrent L1 I-Cache and D-Cache hits");
        assert_cond(if_stall == 0 && d_stall == 0, "Zero stalls on concurrent hits");
        assert_val(if_instr, 32'hDEADBEEF, "Simultaneous instruction fetch valid");
        assert_val(d_rd_data, 32'h0000000A, "Simultaneous data load valid");

        // -----------------------------------------------------------------
        // E2E-06: D-Cache Write-Through Operation to Backing DRAM
        // Store 0xCAFEB0BA to address 2. Must update D-Cache AND write to DRAM.
        // -----------------------------------------------------------------
        $display("\n[E2E-06] Testing D-Cache Write-Through to DRAM...");
        d_addr    = 8'd2;
        d_wr_data = 32'hCAFEB0BA;
        d_we      = 1;
        @(posedge clk); #1;
        d_we      = 0;
        // Wait 4 cycles for DRAM write latency to complete
        repeat(4) @(posedge clk); #1;
        assert_val(dut.mmem.mem[2], 32'hCAFEB0BA, "DRAM backing store updated with written word");

        // -----------------------------------------------------------------
        // E2E-07: Immediate Read-After-Write Cache Hit
        // Read back addr 2 directly from D-Cache.
        // -----------------------------------------------------------------
        $display("\n[E2E-07] Testing Immediate Read-After-Write Cache Hit...");
        d_addr = 8'd2;
        d_we   = 0;
        @(posedge clk); #1;
        assert_cond(dcache_hit == 1, "D-Cache HIT on recently written address");
        assert_val(d_rd_data, 32'hCAFEB0BA, "Data matches written value 0xCAFEB0BA");

        // -----------------------------------------------------------------
        // E2E-08: D-Cache Conflict Eviction (Same Index, Different Tag)
        // Addr 2: tag=000, index=000.
        // Addr 34 (0x22): tag=001, index=000.
        // Accessing addr 34 must evict addr 2 from D-Cache line 0.
        // -----------------------------------------------------------------
        $display("\n[E2E-08] Testing D-Cache Conflict Eviction (Index Conflict)...");
        // Initialize mem[34] with known pattern
        dut.mmem.mem[34] = 32'h55AA55AA;
        d_addr = 8'd34;
        d_we   = 0;
        @(posedge clk); #1;
        while (d_stall) @(posedge clk);
        #1;
        assert_val(d_rd_data, 32'h55AA55AA, "D-Cache filled line 0 with conflicting addr 34 data");
        assert_cond(dut.dcache.cache_tag[0] == 3'b001, "Cache line 0 tag updated to 001 (evicting tag 000)");

        // -----------------------------------------------------------------
        // E2E-09: End-to-End Coherence: DRAM Readback of Evicted Write-Through Data
        // Now read back addr 2. Since it was evicted, it must trigger a D-Cache MISS,
        // fetch from DRAM, and recover the 0xCAFEB0BA write-through value!
        // -----------------------------------------------------------------
        $display("\n[E2E-09] Testing E2E Coherence: Readback of Evicted Write-Through Data from DRAM...");
        d_addr = 8'd2;
        d_we   = 0;
        @(posedge clk); #1;
        while (d_stall) @(posedge clk);
        #1;
        assert_val(d_rd_data, 32'hCAFEB0BA, "Evicted write-through data successfully recovered from DRAM");
        assert_cond(dut.dcache.cache_tag[0] == 3'b000, "Cache line 0 tag re-populated with 000");

        // -----------------------------------------------------------------
        // E2E-10: I-Cache Conflict Eviction & DRAM Re-fetch
        // Addr 0: tag=000, index=000 (currently cached: 0xDEADBEEF).
        // Addr 32: tag=001, index=000.
        // -----------------------------------------------------------------
        $display("\n[E2E-10] Testing I-Cache Conflict Eviction & DRAM Re-fetch...");
        dut.mmem.mem[32] = 32'hFEEDFACE;
        if_addr = 8'd32;
        @(posedge clk); #1;
        while (if_stall) @(posedge clk);
        #1;
        assert_val(if_instr, 32'hFEEDFACE, "I-Cache filled with conflicting addr 32 instruction");
        assert_cond(dut.icache.cache_tag[0] == 3'b001, "I-Cache line 0 tag replaced by 001");

        // Re-fetch original addr 0 -> must miss and re-fetch 0xDEADBEEF
        if_addr = 8'd0;
        @(posedge clk); #1;
        while (if_stall) @(posedge clk);
        #1;
        assert_val(if_instr, 32'hDEADBEEF, "I-Cache successfully re-fetched original addr 0 instruction");

        // -----------------------------------------------------------------
        // E2E-11: Back-to-Back Consecutive Data Stores to Different Lines
        // Store to line 1 (addr 4 -> 0x11112222) and line 2 (addr 8 -> 0x33334444).
        // -----------------------------------------------------------------
        $display("\n[E2E-11] Testing Back-to-Back Consecutive Data Stores to Different Lines...");
        d_addr    = 8'd4; // index = 1
        d_wr_data = 32'h11112222;
        d_we      = 1;
        @(posedge clk); #1;
        d_we      = 0;
        repeat(4) @(posedge clk); #1;

        d_addr    = 8'd8; // index = 2
        d_wr_data = 32'h33334444;
        d_we      = 1;
        @(posedge clk); #1;
        d_we      = 0;
        repeat(4) @(posedge clk); #1;

        assert_val(dut.mmem.mem[4], 32'h11112222, "DRAM addr 4 contains first store");
        assert_val(dut.mmem.mem[8], 32'h33334444, "DRAM addr 8 contains second store");

        // -----------------------------------------------------------------
        // E2E-12: Full System Data Integrity & Memory Persistence Check
        // Read back both stores directly from D-Cache.
        // -----------------------------------------------------------------
        $display("\n[E2E-12] Testing Cache Integrity & Persistence...");
        d_addr = 8'd4;
        d_we   = 0;
        @(posedge clk); #1;
        assert_cond(dcache_hit == 1, "D-Cache HIT on addr 4");
        assert_val(d_rd_data, 32'h11112222, "Addr 4 data intact in L1 D-Cache");

        d_addr = 8'd8;
        d_we   = 0;
        @(posedge clk); #1;
        assert_cond(dcache_hit == 1, "D-Cache HIT on addr 8");
        assert_val(d_rd_data, 32'h33334444, "Addr 8 data intact in L1 D-Cache");

        // -----------------------------------------------------------------
        // Final Summary
        // -----------------------------------------------------------------
        #20;
        $display("\n======================================================================");
        $display("🏁 END-TO-END TEST RESULTS: %0d PASSED, %0d FAILED (TOTAL CHECKS: %0d)",
                 pass_count, fail_count, test_num);
        $display("======================================================================");

        if (fail_count == 0) begin
            $display("🎉 ALL END-TO-END VERIFICATION CHECKS PASSED PERFECTLY!");
        end else begin
            $display("❌ VERIFICATION SUITE FAILED WITH %0d ERRORS!", fail_count);
        end

        $finish;
    end

endmodule
