// ============================================================
// Module: Main Memory (main_memory)
// Project: Instruction and Data Memory Hierarchy (MCA Project)
// Author: Akshith Kumar (Group Member 4)
// Role: Main Memory Module
//
// Description: Initial 256x32 DRAM model acting as backing store
//   for the memory hierarchy. Parameterized depth and latency,
//   with pre-loaded test memory map and simple synchronous
//   read/write access (zero-latency model before controller addition).
// ============================================================

`timescale 1ns / 1ps

module main_memory #(
    parameter DEPTH      = 256,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter LATENCY    = 3
)(
    input  wire                  clk,
    input  wire                  rst,

    // Requests from cache controller
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  we,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  req,

    // Response
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   ready
);

    // ============================================================
    // Pre-loaded Memory Map:
    // ------------------------------------------------------------
    // Address | Value      | Description
    // --------+------------+--------------------------------------
    // 0x00    | 0xDEADBEEF | Test Vector / Instruction 0
    // 0x01    | 0xCAFEBABE | Test Vector / Instruction 1
    // 0x02    | 0x12345678 | Test Vector / Instruction 2
    // 0x03    | 0x0BADF00D | Test Vector / Instruction 3
    // 0x04    | 0xABCD1234 | Test Vector / Instruction 4
    // 0x05    | 0x0000000A | Data: Constant 10
    // 0x06    | 0x00000014 | Data: Constant 20
    // 0x07    | 0x0000001E | Data: Constant 30
    // ============================================================

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};

        // Pre-load memory map values
        mem[0] = 32'hDEADBEEF;
        mem[1] = 32'hCAFEBABE;
        mem[2] = 32'h12345678;
        mem[3] = 32'h0BADF00D;
        mem[4] = 32'hABCD1234;
        mem[5] = 32'h0000000A; // 10
        mem[6] = 32'h00000014; // 20
        mem[7] = 32'h0000001E; // 30
    end

    // Simple zero-latency synchronous always block (no latency controller yet)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_data <= {DATA_WIDTH{1'b0}};
            ready   <= 1'b0;
        end else begin
            ready <= 1'b0;
            if (req) begin
                ready <= 1'b1;
                if (we) begin
                    mem[addr] <= wr_data;
                end else begin
                    rd_data   <= mem[addr];
                end
            end
        end
    end

endmodule
