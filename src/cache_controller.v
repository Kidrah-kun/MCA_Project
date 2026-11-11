// ============================================================
// Module: Cache Arbiter / Controller
// Project: Instruction and Data Memory Hierarchy
// Member: Member 3
//
// Description: Arbitrates between L1 I-Cache and D-Cache miss
//   requests to the shared main memory bus. D-Cache gets
//   priority over I-Cache. Issues read/write requests to main
//   memory and returns data to the requesting cache.
//
//   States:
//     IDLE      — no pending miss
//     SERVE_D   — serving D-cache miss (higher priority)
//     SERVE_I   — serving I-cache miss
//     WAIT_MEM  — waiting for main memory to respond
// ============================================================

module cache_controller (
    input  wire        clk,
    input  wire        rst,

    // From L1 I-Cache
    input  wire        icache_req,
    input  wire [7:0]  icache_addr,
    output reg  [31:0] icache_data,
    output reg         icache_ready,

    // From L1 D-Cache
    input  wire        dcache_req,
    input  wire        dcache_we,
    input  wire [7:0]  dcache_addr,
    input  wire [31:0] dcache_wr_data,
    output reg  [31:0] dcache_data,
    output reg         dcache_ready,

    // To Main Memory
    output reg  [7:0]  mem_addr,
    output reg         mem_we,
    output reg  [31:0] mem_wr_data,
    input  wire [31:0] mem_rd_data,
    input  wire        mem_ready
);

    // FSM states
    localparam IDLE     = 2'b00;
    localparam SERVE_D  = 2'b01;
    localparam SERVE_I  = 2'b10;
    localparam WAIT_MEM = 2'b11;

    reg [1:0] state, next_state;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else      state <= next_state;
    end

    // Next-state + output logic
    always @(*) begin
        // Defaults
        next_state    = state;
        icache_ready  = 0;
        dcache_ready  = 0;
        icache_data   = 32'b0;
        dcache_data   = 32'b0;
        mem_addr      = 8'b0;
        mem_we        = 0;
        mem_wr_data   = 32'b0;

        case (state)
            IDLE: begin
                if (dcache_req) begin
                    // D-Cache has priority
                    mem_addr    = dcache_addr;
                    mem_we      = dcache_we;
                    mem_wr_data = dcache_wr_data;
                    next_state  = dcache_we ? IDLE : SERVE_D;
                    if (dcache_we) dcache_ready = 1; // Writes complete in 1 cycle
                end else if (icache_req) begin
                    mem_addr   = icache_addr;
                    mem_we     = 0;
                    next_state = SERVE_I;
                end
            end

            SERVE_D: begin
                mem_addr = dcache_addr;
                if (mem_ready) begin
                    dcache_data  = mem_rd_data;
                    dcache_ready = 1;
                    next_state   = IDLE;
                end
            end

            SERVE_I: begin
                mem_addr = icache_addr;
                if (mem_ready) begin
                    icache_data  = mem_rd_data;
                    icache_ready = 1;
                    next_state   = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
