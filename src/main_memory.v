// ============================================================
// Module: Main Memory Controller (main_memory)
// Project: Instruction and Data Memory Hierarchy (MCA Project)
// Author: Akshith Kumar (Group Member 4)
// Role: Main Memory Module
//
// Description: 256x32-bit main memory with a DRAM memory controller
//   simulating realistic 3-cycle access latency. Uses a request/ready
//   handshake interface. Queues requests, counts latency cycles,
//   maintains an access counter, and provides synthesis-guarded
//   simulation traces.
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

    // Latency controller registers
    reg [1:0]            delay_cnt;
    reg                  pending;
    reg [ADDR_WIDTH-1:0] pending_addr;
    reg                  pending_we;
    reg [DATA_WIDTH-1:0] pending_wr_data;

    // Performance access counter
    reg [31:0]           access_count;

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};

        // Pre-load test values
        mem[0] = 32'hDEADBEEF;
        mem[1] = 32'hCAFEBABE;
        mem[2] = 32'h12345678;
        mem[3] = 32'h0BADF00D;
        mem[4] = 32'hABCD1234;
        mem[5] = 32'h0000000A; // 10
        mem[6] = 32'h00000014; // 20
        mem[7] = 32'h0000001E; // 30

        access_count = 32'd0;
    end

    // Sequential 3-cycle DRAM latency controller
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready           <= 1'b0;
            pending         <= 1'b0;
            delay_cnt       <= 2'd0;
            rd_data         <= {DATA_WIDTH{1'b0}};
            pending_addr    <= {ADDR_WIDTH{1'b0}};
            pending_we      <= 1'b0;
            pending_wr_data <= {DATA_WIDTH{1'b0}};
            access_count    <= 32'd0;
        end else begin
            ready <= 1'b0; // Default: not ready

            // Latch new request via handshake
            if (req && !pending) begin
                pending         <= 1'b1;
                pending_addr    <= addr;
                pending_we      <= we;
                pending_wr_data <= wr_data;
                delay_cnt       <= 2'd0;
            end

            // Count down 3-cycle latency
            if (pending) begin
                if (delay_cnt == LATENCY - 1) begin
                    // Service request upon latency expiration
                    pending      <= 1'b0;
                    access_count <= access_count + 1;
                    if (pending_we) begin
                        mem[pending_addr] <= pending_wr_data;
                    end else begin
                        rd_data <= mem[pending_addr];
                        ready   <= 1'b1;
                    end
                end else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
        end
    end

    // synthesis translate_off
    always @(posedge clk) begin
        if (pending && (delay_cnt == LATENCY - 1)) begin
            if (pending_we)
                $display("[Main Mem] WRITE addr=0x%02X data=0x%08X (access #%0d)",
                         pending_addr, pending_wr_data, access_count + 1);
            else
                $display("[Main Mem] READ  addr=0x%02X data=0x%08X (access #%0d)",
                         pending_addr, mem[pending_addr], access_count + 1);
        end
    end
    // synthesis translate_on

endmodule
