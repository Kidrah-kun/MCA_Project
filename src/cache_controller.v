// ============================================================
// Module: Cache Controller (Direct-Mapped, Write-Through)
// Project: Instruction and Data Memory Hierarchy
// Description: Implements a direct-mapped cache with 16 lines,
//              each holding a 32-bit data word. On a miss, data
//              is fetched from main memory. Write-through policy
//              ensures main memory is always updated on writes.
//
//  Address breakdown (8-bit):
//    [7:4] — Tag      (4 bits)
//    [3:0] — Index    (4 bits → 16 cache lines)
// ============================================================

module cache_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        cpu_we,       // CPU write enable
    input  wire [7:0]  cpu_addr,     // CPU address
    input  wire [31:0] cpu_wr_data,  // CPU write data
    input  wire [31:0] mem_rd_data,  // Data returned from main memory

    output reg  [31:0] cpu_rd_data,  // Data returned to CPU
    output reg         mem_we,       // Write enable to main memory
    output reg  [7:0]  mem_addr,     // Address sent to main memory
    output reg  [31:0] mem_wr_data,  // Data sent to main memory
    output reg         cache_hit,    // Hit indicator (for monitoring)
    output reg         cache_miss    // Miss indicator (for monitoring)
);

    // Cache storage
    reg [31:0] cache_data  [0:15];  // Data store
    reg [3:0]  cache_tag   [0:15];  // Tag store
    reg        cache_valid [0:15];  // Valid bits

    wire [3:0] tag   = cpu_addr[7:4];
    wire [3:0] index = cpu_addr[3:0];

    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            cache_valid[i] = 1'b0;
            cache_tag[i]   = 4'b0;
            cache_data[i]  = 32'b0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cache_hit  <= 0;
            cache_miss <= 0;
            mem_we     <= 0;
            for (i = 0; i < 16; i = i + 1)
                cache_valid[i] <= 1'b0;
        end else begin
            mem_we     <= 0;
            cache_hit  <= 0;
            cache_miss <= 0;

            // --- READ ---
            if (!cpu_we) begin
                if (cache_valid[index] && (cache_tag[index] == tag)) begin
                    // HIT
                    cache_hit    <= 1;
                    cpu_rd_data  <= cache_data[index];
                end else begin
                    // MISS — fetch from main memory
                    cache_miss          <= 1;
                    mem_addr            <= cpu_addr;
                    cpu_rd_data         <= mem_rd_data;
                    cache_data[index]   <= mem_rd_data;
                    cache_tag[index]    <= tag;
                    cache_valid[index]  <= 1'b1;
                end
            end

            // --- WRITE (Write-Through) ---
            if (cpu_we) begin
                // Update cache
                cache_data[index]  <= cpu_wr_data;
                cache_tag[index]   <= tag;
                cache_valid[index] <= 1'b1;
                // Always write through to main memory
                mem_we      <= 1;
                mem_addr    <= cpu_addr;
                mem_wr_data <= cpu_wr_data;
            end
        end
    end

endmodule
