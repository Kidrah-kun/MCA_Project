// ============================================================
// Module: Memory Hierarchy Top-Level + Testbench
// Project: Instruction and Data Memory Hierarchy
// Member: Member 5
//
// Description: Integrates L1 I-Cache, L1 D-Cache, Cache
//   Controller, and Main Memory into a complete hierarchy.
// ============================================================

module memory_hierarchy_top (
    input  wire        clk,
    input  wire        rst,

    // Instruction fetch (CPU side)
    input  wire [7:0]  if_addr,
    output wire [31:0] if_instr,
    output wire        if_stall,

    // Data access (CPU side)
    input  wire        d_we,
    input  wire [7:0]  d_addr,
    input  wire [31:0] d_wr_data,
    output wire [31:0] d_rd_data,
    output wire        d_stall,

    // Observable status
    output wire        icache_hit,
    output wire        icache_miss,
    output wire        dcache_hit,
    output wire        dcache_miss
);

    // ---- Wires: I-Cache <-> Controller ----
    wire        icache_req;
    wire [7:0]  icache_mem_addr;
    wire [31:0] icache_mem_data;
    wire        icache_mem_ready;

    // ---- Wires: D-Cache <-> Controller ----
    wire        dcache_req;
    wire        dcache_mem_we;
    wire [7:0]  dcache_mem_addr;
    wire [31:0] dcache_mem_wr_data;
    wire [31:0] dcache_mem_data;
    wire        dcache_mem_ready;

    // ---- Wires: Controller <-> Main Memory ----
    wire [7:0]  mem_addr;
    wire        mem_we;
    wire [31:0] mem_wr_data;
    wire [31:0] mem_rd_data;
    wire        mem_ready;
    wire        mem_req;

    // ---- L1 Instruction Cache ----
    l1_icache icache (
        .clk       (clk),
        .rst       (rst),
        .cpu_addr  (if_addr),
        .cpu_instr (if_instr),
        .cpu_stall (if_stall),
        .mem_data  (icache_mem_data),
        .mem_ready (icache_mem_ready),
        .mem_addr  (icache_mem_addr),
        .mem_req   (icache_req),
        .hit       (icache_hit),
        .miss      (icache_miss)
    );

    // ---- L1 Data Cache ----
    l1_dcache dcache (
        .clk        (clk),
        .rst        (rst),
        .cpu_we     (d_we),
        .cpu_addr   (d_addr),
        .cpu_wr_data(d_wr_data),
        .cpu_rd_data(d_rd_data),
        .cpu_stall  (d_stall),
        .mem_data   (dcache_mem_data),
        .mem_ready  (dcache_mem_ready),
        .mem_addr   (dcache_mem_addr),
        .mem_we     (dcache_mem_we),
        .mem_wr_data(dcache_mem_wr_data),
        .mem_req    (dcache_req),
        .hit        (dcache_hit),
        .miss       (dcache_miss)
    );

    // ---- Cache Controller (Arbiter) ----
    cache_controller ctrl (
        .clk           (clk),
        .rst           (rst),
        .icache_req    (icache_req),
        .icache_addr   (icache_mem_addr),
        .icache_data   (icache_mem_data),
        .icache_ready  (icache_mem_ready),
        .dcache_req    (dcache_req),
        .dcache_we     (dcache_mem_we),
        .dcache_addr   (dcache_mem_addr),
        .dcache_wr_data(dcache_mem_wr_data),
        .dcache_data   (dcache_mem_data),
        .dcache_ready  (dcache_mem_ready),
        .mem_addr      (mem_addr),
        .mem_we        (mem_we),
        .mem_wr_data   (mem_wr_data),
        .mem_rd_data   (mem_rd_data),
        .mem_ready     (mem_ready)
    );

    // ---- Main Memory ----
    main_memory mmem (
        .clk     (clk),
        .rst     (rst),
        .addr    (mem_addr),
        .we      (mem_we),
        .wr_data (mem_wr_data),
        .req     (mem_we | (icache_req | dcache_req)),
        .rd_data (mem_rd_data),
        .ready   (mem_ready)
    );

endmodule
