// ============================================================
// Module: L1 Data Cache
// Project: Instruction and Data Memory Hierarchy
// Member: Member 2 — Kabir Sharma (@Kabir-glitch)
//
// Description: 8-line direct-mapped L1 Data Cache.
//   - Supports both CPU reads and writes
//   - Write-through policy: writes update cache AND main memory
//   - On read miss: stalls CPU, fetches from main memory
//   - 8-bit address: [7:5] tag | [4:2] index | [1:0] offset(unused)
// ============================================================

module l1_dcache (
    input  wire        clk,
    input  wire        rst,

    // CPU interface
    input  wire        cpu_we,         // 1=write, 0=read
    input  wire [7:0]  cpu_addr,       // Data address from CPU
    input  wire [31:0] cpu_wr_data,    // Data to write (on cpu_we)
    output reg  [31:0] cpu_rd_data,    // Data returned to CPU
    output reg         cpu_stall,      // Stall CPU on read miss

    // Memory interface
    input  wire [31:0] mem_data,       // Data returned by main memory
    input  wire        mem_ready,      // Memory read data is valid
    output reg  [7:0]  mem_addr,       // Address to main memory
    output reg         mem_we,         // Write enable to main memory
    output reg  [31:0] mem_wr_data,    // Data to write to main memory
    output reg         mem_req,        // Read request to main memory

    // Status
    output reg         hit,
    output reg         miss
);

    // Cache storage — 8 lines
    reg [31:0] cache_data  [0:7];
    reg [2:0]  cache_tag   [0:7];
    reg        cache_valid [0:7];

    // Address breakdown: [7:5] tag, [4:2] index, [1:0] byte offset
    wire [2:0] tag   = cpu_addr[7:5];
    wire [2:0] index = cpu_addr[4:2];

    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            cache_valid[i] = 1'b0;
            cache_tag[i]   = 3'b0;
            cache_data[i]  = 32'b0;
        end
    end

    // Sequential logic (to be implemented)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hit       <= 0;
            miss      <= 0;
            cpu_stall <= 0;
            mem_we    <= 0;
            mem_req   <= 0;
            for (i = 0; i < 8; i = i + 1)
                cache_valid[i] <= 1'b0;
        end else begin
            hit       <= 0;
            miss      <= 0;
            cpu_stall <= 0;
            mem_we    <= 0;
            mem_req   <= 0;

            // TODO: Read and write logic
        end
    end

endmodule
