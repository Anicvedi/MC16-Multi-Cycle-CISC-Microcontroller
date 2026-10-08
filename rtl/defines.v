// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// Multi-Cycle MC16 Processor: Global Definitions & Opcodes
// ==============================================================================

`ifndef DEFINES_V
`define DEFINES_V

// Instruction Opcodes (5 bits: IR[15:11])
`define OP_NOP      5'b00000
`define OP_ADD      5'b00001
`define OP_SUB      5'b00010
`define OP_INCR     5'b00011
`define OP_DECR     5'b00100
`define OP_SHL      5'b00101
`define OP_RRC      5'b00110
`define OP_AND      5'b00111
`define OP_OR       5'b01000
`define OP_LOAD     5'b01001
`define OP_STORE    5'b01010
`define OP_JMP      5'b01011
`define OP_JZ       5'b01100
`define OP_JNZ      5'b01101
`define OP_JC       5'b01110
`define OP_JNC      5'b01111

// Single Shared Data Bus Multiplexer Selection Codes (bus_sel)
`define BUS_NONE    3'd0
`define BUS_MEM     3'd1   // Memory Data Output
`define BUS_REG1    3'd2   // Register File Port 1 Data
`define BUS_REG2    3'd3   // Register File Port 2 Data
`define BUS_ALU     3'd4   // ALU Result
`define BUS_PC      3'd5   // Program Counter
`define BUS_IR_ADDR 3'd6   // IR address/immediate extended (IR[4:0])
`define BUS_IPR     3'd7   // Instruction Prefetch Register

// ALU Operations
`define ALU_ADD     4'd0
`define ALU_SUB     4'd1
`define ALU_INCR    4'd2
`define ALU_DECR    4'd3
`define ALU_SHL     4'd4
`define ALU_RRC     4'd5
`define ALU_AND     4'd6
`define ALU_OR      4'd7
`define ALU_PASSA   4'd8

`endif
