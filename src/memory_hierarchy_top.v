// ============================================================
// Module: Memory Hierarchy Top-Level Integration
// Project: Instruction and Data Memory Hierarchy
// Description: Connects all subsystems — instruction memory,
//              data memory, cache controller, and main memory
//              into a unified memory hierarchy. This top module
//              acts as the integration glue for simulation.
// ============================================================

module memory_hierarchy_top (
    input  wire        clk,
    input  wire        rst,

    // Instruction fetch interface
    input  wire [7:0]  if_addr,
    output wire [31:0] if_instr,

    // Data memory interface (CPU side)
    input  wire        d_we,
    input  wire [7:0]  d_addr,
    input  wire [31:0] d_wr_data,
    output wire [31:0] d_rd_data,

    // Status outputs
    output wire        cache_hit,
    output wire        cache_miss
);

    // ----- Internal Wires -----
    wire [31:0] mem_rd_data;
    wire        mem_we;
    wire [7:0]  mem_addr;
    wire [31:0] mem_wr_data;

    // ----- Instruction Memory -----
    instruction_memory imem (
        .clk   (clk),
        .addr  (if_addr),
        .instr (if_instr)
    );

    // ----- Cache Controller -----
    cache_controller cache (
        .clk         (clk),
        .rst         (rst),
        .cpu_we      (d_we),
        .cpu_addr    (d_addr),
        .cpu_wr_data (d_wr_data),
        .mem_rd_data (mem_rd_data),
        .cpu_rd_data (d_rd_data),
        .mem_we      (mem_we),
        .mem_addr    (mem_addr),
        .mem_wr_data (mem_wr_data),
        .cache_hit   (cache_hit),
        .cache_miss  (cache_miss)
    );

    // ----- Main Memory -----
    main_memory dmem (
        .clk     (clk),
        .we      (mem_we),
        .addr    (mem_addr),
        .wr_data (mem_wr_data),
        .rd_data (mem_rd_data)
    );

endmodule
