// ============================================================
// Testbench: Memory Hierarchy System
// Project: Instruction and Data Memory Hierarchy
// Member: Member 5
// ============================================================

`timescale 1ns / 1ps

module memory_hierarchy_tb;

    reg        clk, rst;
    reg [7:0]  if_addr, d_addr;
    reg        d_we;
    reg [31:0] d_wr_data;

    wire [31:0] if_instr, d_rd_data;
    wire        if_stall, d_stall;
    wire        icache_hit, icache_miss, dcache_hit, dcache_miss;

    memory_hierarchy_top dut (
        .clk        (clk),       .rst        (rst),
        .if_addr    (if_addr),   .if_instr   (if_instr),
        .if_stall   (if_stall),
        .d_we       (d_we),      .d_addr     (d_addr),
        .d_wr_data  (d_wr_data), .d_rd_data  (d_rd_data),
        .d_stall    (d_stall),
        .icache_hit (icache_hit), .icache_miss(icache_miss),
        .dcache_hit (dcache_hit), .dcache_miss(dcache_miss)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/waveforms/dump.vcd");
        $dumpvars(0, memory_hierarchy_tb);
    end

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

    integer cycle;
    initial begin
        $display("=== Memory Hierarchy Testbench ===");
        rst = 1; d_we = 0; if_addr = 0; d_addr = 0; d_wr_data = 0;
        repeat(2) @(posedge clk); #1;
        rst = 0;

        // Test 1: I-Cache miss on first fetch (addr=0, expect 0xDEADBEEF from mem)
        if_addr = 8'd0; d_we = 0; d_addr = 8'd5;
        repeat(6) @(posedge clk); #1;
        $display("[T1] ICache fetch addr=0: instr=0x%08X stall=%b hit=%b miss=%b",
                  if_instr, if_stall, icache_hit, icache_miss);

        // Test 2: I-Cache hit on same address
        @(posedge clk); #1;
        $display("[T2] ICache fetch addr=0 again: hit=%b miss=%b", icache_hit, icache_miss);

        // Test 3: D-Cache read miss (addr=5, expect 0x0000000A)
        d_addr = 8'd5; d_we = 0;
        repeat(6) @(posedge clk); #1;
        $display("[T3] DCache read addr=5: data=0x%08X hit=%b miss=%b",
                  d_rd_data, dcache_hit, dcache_miss);

        // Test 4: D-Cache read hit (same address again)
        @(posedge clk); #1;
        $display("[T4] DCache read addr=5 (hit): hit=%b miss=%b", dcache_hit, dcache_miss);

        // Test 5: D-Cache write (addr=2, data=0xBEEFCAFE)
        d_we = 1; d_addr = 8'd2; d_wr_data = 32'hBEEFCAFE;
        @(posedge clk); #1;
        d_we = 0;
        $display("[T5] DCache write addr=2: 0xBEEFCAFE");

        // Test 6: Read back — should hit in D-Cache
        d_addr = 8'd2;
        @(posedge clk); #1;
        $display("[T6] DCache read addr=2 after write: data=0x%08X hit=%b", d_rd_data, dcache_hit);
        check(d_rd_data, 32'hBEEFCAFE, 6);

        // Test 7: Different I-Cache addr (miss expected)
        if_addr = 8'd1;
        repeat(6) @(posedge clk); #1;
        $display("[T7] ICache fetch addr=1: instr=0x%08X miss=%b", if_instr, icache_miss);

        #20;
        $display("=== Done: %0d PASS, %0d FAIL ===", pass_count, fail_count);
        $finish;
    end

endmodule
