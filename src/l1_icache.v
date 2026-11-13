// ============================================================
// Module: L1 Instruction Cache
// Project: Instruction and Data Memory Hierarchy
// Member: Member 1 — Kidrah-kun
//
// Description: 8-line direct-mapped L1 Instruction Cache.
//   - Read-only (instructions never written by CPU)
//   - On hit: returns cached instruction in 1 cycle
//   - On miss: signals cache controller to fetch from memory
//   - 8-bit address: [7:5] tag | [4:2] index | [1:0] offset(unused)
// ============================================================

module l1_icache #(
    parameter CACHE_LINES = 8,   // Number of cache lines (must be power of 2)
    parameter ADDR_WIDTH  = 8,   // CPU address width in bits
    parameter DATA_WIDTH  = 32   // Data word width in bits
) (
    input  wire        clk,
    input  wire        rst,

    // CPU interface
    input  wire [7:0]  cpu_addr,       // Instruction address from CPU
    output reg  [31:0] cpu_instr,      // Instruction returned to CPU
    output reg         cpu_stall,      // Stall CPU on miss

    // Memory interface (on miss)
    input  wire [31:0] mem_data,       // Data returned by main memory
    input  wire        mem_ready,      // Memory data is valid
    output reg  [7:0]  mem_addr,       // Address sent to main memory
    output reg         mem_req,        // Request to main memory

    // Status
    output reg         hit,
    output reg         miss
);

    // Cache storage — 8 lines
    reg [31:0] cache_data  [0:7];
    reg [2:0]  cache_tag   [0:7];
    reg        cache_valid [0:7];

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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hit       <= 0; miss    <= 0;
            cpu_stall <= 0; mem_req <= 0;
            for (i = 0; i < 8; i = i + 1)
                cache_valid[i] <= 1'b0;
        end else begin
            hit <= 0; miss <= 0; mem_req <= 0; cpu_stall <= 0;

            if (cache_valid[index] && cache_tag[index] == tag) begin
                // HIT
                hit        <= 1;
                cpu_instr  <= cache_data[index];
            end else begin
                // MISS — request from main memory
                miss      <= 1;
                cpu_stall <= 1;
                mem_req   <= 1;
                mem_addr  <= cpu_addr;

                if (mem_ready) begin
                    cache_data[index]  <= mem_data;
                    cache_tag[index]   <= tag;
                    cache_valid[index] <= 1'b1;
                    cpu_instr          <= mem_data;
                    cpu_stall          <= 0;
                end
            end
        end
    end


    // ---- Performance Counters (simulation only) ----
    reg [15:0] hit_count;
    reg [15:0] miss_count;

    initial begin
        hit_count  = 0;
        miss_count = 0;
    end

    // synthesis translate_off
    always @(posedge clk) begin
        if (hit)  hit_count  <= hit_count  + 1;
        if (miss) miss_count <= miss_count + 1;
    end

    always @(posedge clk) begin
        if (hit)  $display("[I-Cache] HIT  addr=0x%02X instr=0x%08X", cpu_addr, cpu_instr);
        if (miss) $display("[I-Cache] MISS addr=0x%02X — fetching from memory", cpu_addr);
    end
    // synthesis translate_on

endmodule
