// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// 16-bit ALU with Carry and Zero Flags
// ==============================================================================

`timescale 1ns / 1ps
`include "defines.v"

module alu (
    input  wire [3:0]  alu_op,
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        c_in,       // Current carry flag for RRC
    output reg  [15:0] result,
    output reg         c_out,      // New carry / borrow
    output wire        z_out       // Zero flag
);

    always @(*) begin
        c_out = 1'b0;
        result = 16'h0000;
        case (alu_op)
            `ALU_ADD: begin
                {c_out, result} = a + b;
            end
            `ALU_SUB: begin
                // Subtraction: a - b
                // c_out is set to 1 if borrow needed (i.e. a < b)
                result = a - b;
                c_out  = (a < b) ? 1'b1 : 1'b0;
            end
            `ALU_INCR: begin
                {c_out, result} = a + 16'd1;
            end
            `ALU_DECR: begin
                result = a - 16'd1;
                c_out  = (a == 16'd0) ? 1'b1 : 1'b0;
            end
            `ALU_SHL: begin
                c_out  = a[15];
                result = {a[14:0], 1'b0};
            end
            `ALU_RRC: begin
                c_out  = a[0];
                result = {c_in, a[15:1]};
            end
            `ALU_AND: begin
                result = a & b;
                c_out  = 1'b0;
            end
            `ALU_OR: begin
                result = a | b;
                c_out  = 1'b0;
            end
            `ALU_PASSA: begin
                result = a;
                c_out  = c_in;
            end
            default: begin
                result = a;
                c_out  = 1'b0;
            end
        endcase
    end

    assign z_out = (result == 16'h0000);

endmodule
