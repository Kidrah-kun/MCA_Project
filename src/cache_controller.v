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
    input  wire        mem_ready,        // Memory data-ready strobe

    // --- Status / Performance monitoring ---
    output wire        busy              // HIGH whenever FSM is not in IDLE
);

    // ----------------------------------------------------------
    // FSM state encoding
    // ----------------------------------------------------------
    localparam [1:0] IDLE    = 2'b00;   // Waiting for a cache miss
    localparam [1:0] SERVE_D = 2'b01;   // Serving D-cache miss (high priority)
    localparam [1:0] SERVE_I = 2'b10;   // Serving I-cache miss

    reg [1:0] state, next_state;

    // ----------------------------------------------------------
    // busy output — asserted whenever the FSM is not idle
    // ----------------------------------------------------------
    assign busy = (state != IDLE);

    // ----------------------------------------------------------
    // Performance monitoring counters (synthesisable registers)
    // Reset on rst; wrap naturally on overflow.
    // ----------------------------------------------------------
    reg [31:0] dcache_req_count;   // Total D-cache miss requests served
    reg [31:0] icache_req_count;   // Total I-cache miss requests served

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dcache_req_count <= 32'd0;
            icache_req_count <= 32'd0;
        end else begin
            if (dcache_ready) dcache_req_count <= dcache_req_count + 1;
            if (icache_ready) icache_req_count <= icache_req_count + 1;
        end
    end

    // ----------------------------------------------------------
    // Sequential state register — with simulation debug traces
    // `ifndef SYNTHESIS ensures $display is stripped by synthesisers.
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
`ifndef SYNTHESIS
            $display("[%0t] cache_controller: RESET -> IDLE", $time);
`endif
        end else begin
            if (next_state != state) begin
`ifndef SYNTHESIS
                $display("[%0t] cache_controller: state %0b -> %0b (dcache_req=%b icache_req=%b mem_ready=%b)",
                         $time, state, next_state,
                         dcache_req, icache_req, mem_ready);
`endif
            end
            state <= next_state;
        end
    end

    // ----------------------------------------------------------
    // Combinational: next-state logic + output logic
    // D-Cache has PRIORITY over I-Cache in IDLE arbitration.
    // ----------------------------------------------------------
    always @(*) begin
        // Safe defaults — prevents latches
        next_state   = state;
        icache_ready = 1'b0;
        dcache_ready = 1'b0;
        icache_data  = 32'b0;
        dcache_data  = 32'b0;
        mem_addr     = 8'b0;
        mem_we       = 1'b0;
        mem_wr_data  = 32'b0;

        case (state)

            // --------------------------------------------------
            // IDLE: Arbitrate between pending miss requests.
            //       D-Cache always wins if both request together.
            // --------------------------------------------------
            IDLE: begin
                if (dcache_req) begin
                    // --- D-Cache has priority ---
                    mem_addr    = dcache_addr;
                    mem_we      = dcache_we;
                    mem_wr_data = dcache_wr_data;
                    if (dcache_we) begin
                        // Write completes in 1 cycle — stay IDLE
                        dcache_ready = 1'b1;
                        next_state   = IDLE;
                    end else begin
                        // Read miss — go wait for memory
                        next_state   = SERVE_D;
                    end
                end else if (icache_req) begin
                    // --- I-Cache (lower priority, only when D quiet) ---
                    mem_addr   = icache_addr;
                    mem_we     = 1'b0;
                    next_state = SERVE_I;
                end
                // else: nothing pending — stay IDLE
            end

            // --------------------------------------------------
            // SERVE_D: Wait for main memory to supply D-cache data.
            // --------------------------------------------------
            SERVE_D: begin
                mem_addr = dcache_addr;
                mem_we   = 1'b0;
                if (mem_ready) begin
                    dcache_data  = mem_rd_data;
                    dcache_ready = 1'b1;
                    next_state   = IDLE;
                end
            end

            // --------------------------------------------------
            // SERVE_I: Wait for main memory to supply I-cache data.
            // --------------------------------------------------
            SERVE_I: begin
                mem_addr = icache_addr;
                mem_we   = 1'b0;
                if (mem_ready) begin
                    icache_data  = mem_rd_data;
                    icache_ready = 1'b1;
                    next_state   = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
