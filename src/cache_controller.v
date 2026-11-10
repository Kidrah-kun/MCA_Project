// ============================================================
// Module  : cache_controller
// Project : Instruction and Data Memory Hierarchy (MCA Project)
// Author  : Abhinav Chaudhary (Group Member 3)
// Role    : Cache Arbiter FSM — arbitrates L1 D-Cache and
//           L1 I-Cache miss requests to the shared main memory bus.
//           D-Cache is given priority over I-Cache.
//
// FSM Diagram:
//
//                    rst
//                     |
//                     v
//               +----------+
//        +----->|   IDLE   |<-----+
//        |      +----------+      |
//        |      /          \      |
//        | dcache_req    icache_req (no dcache_req)
//        |      |               |
//        |      v               v
//        |  +---------+    +---------+
//        |  | SERVE_D |    | SERVE_I |
//        |  +---------+    +---------+
//        |      |               |
//        +--mem_ready-------mem_ready--+
//
//   IDLE     : No pending cache miss. Watch for requests.
//   SERVE_D  : Forwarding D-cache miss to main memory (priority).
//   SERVE_I  : Forwarding I-cache miss to main memory.
//
// ============================================================

`timescale 1ns / 1ps

module cache_controller (
    input  wire        clk,
    input  wire        rst,

    // --- L1 I-Cache interface ---
    input  wire        icache_req,       // I-Cache miss request
    input  wire [7:0]  icache_addr,      // Miss address from I-Cache
    output reg  [31:0] icache_data,      // Data returned to I-Cache
    output reg         icache_ready,     // Data valid strobe to I-Cache

    // --- L1 D-Cache interface ---
    input  wire        dcache_req,       // D-Cache miss request
    input  wire        dcache_we,        // Write-enable (1=write, 0=read)
    input  wire [7:0]  dcache_addr,      // Miss address from D-Cache
    input  wire [31:0] dcache_wr_data,   // Write data from D-Cache
    output reg  [31:0] dcache_data,      // Data returned to D-Cache
    output reg         dcache_ready,     // Data valid / write-ack strobe

    // --- Main Memory interface ---
    output reg  [7:0]  mem_addr,         // Address driven to main memory
    output reg         mem_we,           // Write-enable to main memory
    output reg  [31:0] mem_wr_data,      // Write data to main memory
    input  wire [31:0] mem_rd_data,      // Read data from main memory
    input  wire        mem_ready         // Memory data-ready strobe
);

    // ----------------------------------------------------------
    // FSM state encoding
    // ----------------------------------------------------------
    localparam [1:0] IDLE    = 2'b00;   // Waiting for a cache miss
    localparam [1:0] SERVE_D = 2'b01;   // Serving D-cache miss (high priority)
    localparam [1:0] SERVE_I = 2'b10;   // Serving I-cache miss

    reg [1:0] state;

    // ----------------------------------------------------------
    // Sequential state register (always block — to be filled)
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        // TODO: implement state transitions
    end

endmodule
