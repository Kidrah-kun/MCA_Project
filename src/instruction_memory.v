// ============================================================
// Module: Instruction Memory (ROM)
// Project: Instruction and Data Memory Hierarchy
// Description: Word-addressable read-only instruction memory.
//              Stores 256 32-bit instructions. Outputs the
//              instruction at the given address on each clock.
// ============================================================

module instruction_memory (
    input  wire        clk,
    input  wire [7:0]  addr,     // 8-bit byte address (word-aligned)
    output reg  [31:0] instr     // 32-bit instruction output
);
    // 256 words of 32-bit instruction memory
    reg [31:0] mem [0:255];

    // Initialize with sample instructions (MIPS-like encoding)
    integer i;
    initial begin
        // Clear all memory
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000000; // NOP

        // Sample program: simple load/add/store sequence
        mem[0]  = 32'h8C010000; // lw  $1, 0($0)   — load word
        mem[1]  = 32'h8C020004; // lw  $2, 4($0)   — load word
        mem[2]  = 32'h00221820; // add $3, $1, $2  — add
        mem[3]  = 32'hAC030008; // sw  $3, 8($0)   — store word
        mem[4]  = 32'h1000FFFF; // beq (branch to self — halt)
    end

    // Synchronous read
    always @(posedge clk) begin
        instr <= mem[addr];
    end

endmodule

