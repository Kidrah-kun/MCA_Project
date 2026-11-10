// ============================================================
// Module: Main Memory
// Project: Instruction and Data Memory Hierarchy
// Description: 256 x 32-bit main memory acting as the backing
//              store for the cache. Supports synchronous write
//              and asynchronous read. Simulates DRAM-like
//              behavior in the memory hierarchy.
// ============================================================

module main_memory (
    input  wire        clk,
    input  wire        we,        // Write enable (from cache controller)
    input  wire [7:0]  addr,      // Address
    input  wire [31:0] wr_data,   // Write data
    output wire [31:0] rd_data    // Read data
);
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000000;

        // Pre-load test data
        mem[0]  = 32'hDEADBEEF;
        mem[1]  = 32'hCAFEBABE;
        mem[2]  = 32'h12345678;
        mem[3]  = 32'h0BADF00D;
        mem[4]  = 32'hABCD1234;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (we)
            mem[addr] <= wr_data;
    end

    // Asynchronous read
    assign rd_data = mem[addr];

endmodule
