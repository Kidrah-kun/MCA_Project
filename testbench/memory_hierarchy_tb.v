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

    // ------- Main stimulus -------
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

        // TODO: Add D-Cache tests

        #20;
        $display("=== Testbench complete ===");
        $finish;
    end

endmodule
