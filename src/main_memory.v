// ============================================================
// Module: Main Memory (main_memory)
// Project: Instruction and Data Memory Hierarchy (MCA Project)
// Author: Akshith Kumar (Group Member 4)
// Role: Main Memory Module
//
// Description: Main memory DRAM model with request latching.
//   Captures incoming memory requests using internal state registers
//   to decouple request initiation from service execution.
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
    input  wire                  req,       // Pulse high for 1 cycle to start request

    // Response
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   ready     // Pulses high when read data is valid
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

    // Request latching registers
    reg                  pending;
    reg [ADDR_WIDTH-1:0] pending_addr;
    reg                  pending_we;
    reg [DATA_WIDTH-1:0] pending_wr_data;

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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready           <= 1'b0;
            pending         <= 1'b0;
            rd_data         <= {DATA_WIDTH{1'b0}};
            pending_addr    <= {ADDR_WIDTH{1'b0}};
            pending_we      <= 1'b0;
            pending_wr_data <= {DATA_WIDTH{1'b0}};
        end else begin
            ready <= 1'b0;

            // Latch incoming memory request
            if (req && !pending) begin
                pending         <= 1'b1;
                pending_addr    <= addr;
                pending_we      <= we;
                pending_wr_data <= wr_data;
            end

            // Process latched request
            if (pending) begin
                pending <= 1'b0;
                if (pending_we) begin
                    mem[pending_addr] <= pending_wr_data;
                end else begin
                    rd_data <= mem[pending_addr];
                    ready   <= 1'b1;
                end
            end
        end
    end

endmodule
