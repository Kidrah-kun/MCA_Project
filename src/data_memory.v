// ============================================================
// Module: Data Memory (RAM)
// Project: Instruction and Data Memory Hierarchy
// Description: Byte-addressable read/write data memory.
//              256 locations of 32-bit width. Supports
//              synchronous write and asynchronous read.
// ============================================================

module data_memory (
    input  wire        clk,
    input  wire        we,       // Write enable
    input  wire [7:0]  addr,     // 8-bit address
    input  wire [31:0] wr_data,  // Data to write
    output wire [31:0] rd_data   // Data read out
);
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000000;

        // Pre-load some data values for simulation
        mem[0] = 32'h0000000A; // 10
        mem[1] = 32'h00000014; // 20
        mem[2] = 32'h0000001E; // 30
        mem[3] = 32'h00000028; // 40
    end

    // Synchronous write
    always @(posedge clk) begin
        if (we)
            mem[addr] <= wr_data;
    end

    // Asynchronous read
    assign rd_data = mem[addr];

endmodule

