// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// 64 x 16-bit Instruction-cum-Data Memory (Distributed RAM)
// Asynchronous Read, Synchronous Write
// Initialized with Unsigned Division Program & Data
// ==============================================================================

`timescale 1ns / 1ps

module memory #(
    parameter MEM_INIT_FILE = "division_prog.mem"
)(
    input  wire        clk,
    input  wire        we,
    input  wire [5:0]  addr,
    input  wire [15:0] din,
    output wire [15:0] dout
);

    (* ram_style = "distributed" *) reg [15:0] ram [0:63];
    integer i;

    // Asynchronous read
    assign dout = ram[addr];

    // Synchronous write
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
    end

    // Memory Initialization:
    // Both synthesized bitstream and simulation will have the exact binary image
    initial begin
        // Clear all 64 memory words to 0
        for (i = 0; i < 64; i = i + 1) begin
            ram[i] = 16'h0000;
        end

        // Instructions (assembled from memory/division_prog.asm)
        ram[0]  = 16'h481A; // [00] LOAD R0, [26]   ; R0 = Dividend (100)
        ram[1]  = 16'h491B; // [01] LOAD R1, [27]   ; R1 = Divisor (7)
        ram[2]  = 16'h4A1C; // [02] LOAD R2, [28]   ; R2 = Quotient (0)
        ram[3]  = 16'h1320; // [03] SUB  R3, R0, R1 ; R3 = R0 - R1, updates Carry
        ram[4]  = 16'h7008; // [04] JC   8          ; Jump to address 8 (DIV_DONE) if R0 < R1
        ram[5]  = 16'h1020; // [05] SUB  R0, R0, R1 ; R0 = R0 - R1
        ram[6]  = 16'h1A00; // [06] INCR R2         ; Quotient++
        ram[7]  = 16'h5803; // [07] JMP  3          ; Repeat loop
        ram[8]  = 16'h505D; // [08] STORE [29], R2  ; Store Quotient at [29]
        ram[9]  = 16'h501E; // [09] STORE [30], R0  ; Store Remainder at [30]
        ram[10] = 16'h580A; // [10] JMP  10         ; HALT: Infinite self-jump

        // Data section
        ram[26] = 16'd100;  // [26] Dividend  = 100 (0x0064)
        ram[27] = 16'd7;    // [27] Divisor   = 7   (0x0007)
        ram[28] = 16'd0;    // [28] Constant  = 0   (0x0000)
        ram[29] = 16'd0;    // [29] Quotient  = placeholder (expected 14)
        ram[30] = 16'd0;    // [30] Remainder = placeholder (expected 2)

        // Attempt file read if file exists in runtime directory
        $readmemh(MEM_INIT_FILE, ram);
    end

endmodule
