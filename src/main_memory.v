// ============================================================
// Module: Main Memory Controller
// Project: Instruction and Data Memory Hierarchy
// Member: Member 4
//
// Description: 256×32-bit main memory with a simple memory
//   controller that simulates realistic DRAM access latency
//   (3-cycle delay). Uses a request/ready handshake interface.
//   The controller queues one request at a time and asserts
//   mem_ready after the latency expires.
// ============================================================

module main_memory (
    input  wire        clk,
    input  wire        rst,

    // Requests from cache controller
    input  wire [7:0]  addr,
    input  wire        we,
    input  wire [31:0] wr_data,
    input  wire        req,       // Pulse high for 1 cycle to start request

    // Response
    output reg  [31:0] rd_data,
    output reg         ready     // Pulses high when read data is valid
);

    // Memory array
    reg [31:0] mem [0:255];

    // Latency counter (simulates DRAM delay)
    localparam LATENCY = 3;
    reg [1:0] delay_cnt;
    reg       pending;
    reg [7:0] pending_addr;
    reg       pending_we;
    reg [31:0] pending_wr_data;

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000000;

        // Pre-load test values
        mem[0]  = 32'hDEADBEEF;
        mem[1]  = 32'hCAFEBABE;
        mem[2]  = 32'h12345678;
        mem[3]  = 32'h0BADF00D;
        mem[4]  = 32'hABCD1234;
        mem[5]  = 32'h0000000A; // 10
        mem[6]  = 32'h00000014; // 20
        mem[7]  = 32'h0000001E; // 30
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready     <= 0;
            pending   <= 0;
            delay_cnt <= 0;
            rd_data   <= 0;
        end else begin
            ready <= 0; // Default: not ready

            // Latch new request
            if (req && !pending) begin
                pending          <= 1;
                pending_addr     <= addr;
                pending_we       <= we;
                pending_wr_data  <= wr_data;
                delay_cnt        <= 0;
            end

            // Count down latency
            if (pending) begin
                if (delay_cnt == LATENCY - 1) begin
                    // Service the request
                    pending <= 0;
                    if (pending_we) begin
                        mem[pending_addr] <= pending_wr_data;
                    end else begin
                        rd_data <= mem[pending_addr];
                        ready   <= 1;
                    end
                end else begin
                    delay_cnt <= delay_cnt + 1;
                end
            end
        end
    end

endmodule
