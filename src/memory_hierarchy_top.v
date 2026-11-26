// ============================================================
// Module: memory_hierarchy_top
// Project: Instruction and Data Memory Hierarchy (MCA Project)
// Author: Akshith Kumar (Group Member 4)
// Role: Main Memory + Top-level Integration
//
// Description: Top-level integration module combining L1 I-Cache,
//   L1 D-Cache, Cache Controller (Arbiter FSM), and Main Memory (DRAM).
//   Provides unified interfaces to the CPU for instruction fetch
//   and data memory access with full stall and observability signals.
//
// ============================================================
// Signal Flow & Hierarchy Architecture:
//
//      +-------------------------------------------------------+
//      |                       CPU Core                        |
//      +---------------------------+---------------------------+
//            | if_addr             ^ if_instr        | d_addr, d_we, d_wr_data
//            |                     | if_stall        v ^ d_rd_data, d_stall
//            v                     |                   |
//      +---------------------------+----+        +-----+--------------------+
//      |         L1 I-Cache             |        |        L1 D-Cache        |
//      |    (Direct-Mapped, Read-Only)  |        | (Direct-Mapped, Wr-Thru) |
//      +-----------------+--------------+        +-----+--------------------+
//                        | icache_req, addr            | dcache_req, addr,
//                        | icache_data, ready          | wr_data, we, ready
//                        v                             v
//      +--------------------------------------------------------------------+
//      |                 Cache Controller (Arbiter FSM)                     |
//      |             Prioritizes D-Cache misses over I-Cache                |
//      +---------------------------------+----------------------------------+
//                                        | mem_addr, mem_we, mem_wr_data,
//                                        | mem_rd_data, mem_ready, mem_req
//                                        v
//      +--------------------------------------------------------------------+
//      |                      Main Memory (DRAM Model)                      |
//      |               256x32-bit backing store, 3-cycle delay              |
//      +--------------------------------------------------------------------+
// ============================================================

`timescale 1ns / 1ps

module memory_hierarchy_top (
    input  wire        clk,
    input  wire        rst,

    // --- Instruction Fetch Interface (CPU side) ---
    input  wire [7:0]  if_addr,       // Instruction fetch address from PC
    output wire [31:0] if_instr,      // Fetched instruction word
    output wire        if_stall,      // Pipeline stall on I-cache miss

    // --- Data Access Interface (CPU side) ---
    input  wire        d_we,          // Data write enable (1=Store, 0=Load)
    input  wire [7:0]  d_addr,        // Data memory address
    input  wire [31:0] d_wr_data,     // Store data to memory
    output wire [31:0] d_rd_data,     // Loaded data word from cache/memory
    output wire        d_stall,       // Pipeline stall on D-cache miss

    // --- Observability & Performance Monitoring Outputs ---
    output wire        icache_hit,    // I-Cache hit indicator strobe
    output wire        icache_miss,   // I-Cache miss indicator strobe
    output wire        dcache_hit,    // D-Cache hit indicator strobe
    output wire        dcache_miss    // D-Cache miss indicator strobe
);

    // ========================================================
    // Internal Interconnect Wires
    // ========================================================

    // ---- I-Cache <-> Cache Controller ----
    wire        icache_req;           // I-Cache requests main memory service
    wire [7:0]  icache_mem_addr;      // Memory fetch address for missed line
    wire [31:0] icache_mem_data;      // Instruction data returned from controller
    wire        icache_mem_ready;     // Valid strobe from controller to I-cache

    // ---- D-Cache <-> Cache Controller ----
    wire        dcache_req;           // D-Cache requests main memory service
    wire        dcache_mem_we;        // Write enable: 1=write-through, 0=read miss
    wire [7:0]  dcache_mem_addr;      // Memory address for missed or written word
    wire [31:0] dcache_mem_wr_data;   // Data payload for write-through store
    wire [31:0] dcache_mem_data;      // Read data returned from controller to D-cache
    wire        dcache_mem_ready;     // Ready / acknowledge strobe from controller

    // ---- Cache Controller <-> Main Memory ----
    wire [7:0]  mem_addr;             // Shared address bus to DRAM
    wire        mem_we;               // Shared write-enable strobe to DRAM
    wire [31:0] mem_wr_data;          // Shared write data payload to DRAM
    wire [31:0] mem_rd_data;          // Read data response returned by DRAM
    wire        mem_ready;            // DRAM operation completed ready strobe
    wire        mem_req;              // DRAM access request strobe
    wire        ctrl_busy;            // Controller active arbitration status

    // Drive memory request strobe whenever controller serves miss or write
    assign mem_req = mem_we | (icache_req | dcache_req);

    // ========================================================
    // Module Instantiations
    // ========================================================

    // --------------------------------------------------------
    // 1. L1 Instruction Cache (l1_icache)
    //    Direct-mapped instruction cache with hit/miss detection.
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // 2. L1 Data Cache (l1_dcache)
    //    Direct-mapped data cache supporting read and write-through.
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // 3. Cache Controller / Arbiter (cache_controller)
    //    Prioritizes D-cache over I-cache, arbitrating DRAM bus access.
    // --------------------------------------------------------
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
        .mem_req       (mem_req),
        .mem_rd_data   (mem_rd_data),
        .mem_ready     (mem_ready),
        .busy          (ctrl_busy)
    );

    // --------------------------------------------------------
    // 4. Main Memory DRAM Backing Store (main_memory)
    //    256x32 DRAM array with 3-cycle latency and handshake.
    // --------------------------------------------------------
    main_memory #(
        .DEPTH     (256),
        .DATA_WIDTH(32),
        .ADDR_WIDTH(8),
        .LATENCY   (3)
    ) mmem (
        .clk     (clk),
        .rst     (rst),
        .addr    (mem_addr),
        .we      (mem_we),
        .wr_data (mem_wr_data),
        .req     (mem_req),
        .rd_data (mem_rd_data),
        .ready   (mem_ready)
    );

endmodule
