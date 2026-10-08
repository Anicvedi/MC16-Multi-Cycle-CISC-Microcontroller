// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// 8 x 16-bit Register File (R0 - R7)
// Dual read ports (asynchronous) and single write port (synchronous)
// ==============================================================================

`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [2:0]  waddr,
    input  wire [15:0] wdata,
    input  wire [2:0]  raddr1,
    output wire [15:0] rdata1,
    input  wire [2:0]  raddr2,
    output wire [15:0] rdata2
);

    reg [15:0] regs [0:7];
    integer i;

    // Asynchronous read
    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

    // Synchronous write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 16'h0000;
            end
        end else if (we) begin
            regs[waddr] <= wdata;
        end
    end

endmodule
