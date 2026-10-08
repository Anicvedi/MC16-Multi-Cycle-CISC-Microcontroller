// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// 4-Digit Seven-Segment Display Multiplexer Driver for Basys 3
// Active-LOW segments seg[6:0] (a to g) and active-LOW anodes an[3:0]
// ==============================================================================

`timescale 1ns / 1ps

module seg7_driver (
    input  wire        clk,        // 100 MHz board clock
    input  wire        rst,
    input  wire [15:0] value,      // 16-bit value (4 hex digits)
    output reg  [3:0]  an,         // Anodes (active low)
    output reg  [6:0]  seg,        // Cathodes [g,f,e,d,c,b,a] (active low)
    output wire        dp          // Decimal point (active low)
);

    assign dp = 1'b1; // Turn off decimal point

    // Refresh rate divider (~1 kHz refresh rate, ~250 Hz per digit)
    reg [17:0] refresh_counter;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_counter <= 18'd0;
        end else begin
            refresh_counter <= refresh_counter + 18'd1;
        end
    end

    wire [1:0] digit_sel = refresh_counter[17:16];
    reg  [3:0] hex_digit;

    always @(*) begin
        case (digit_sel)
            2'b00: begin
                an = 4'b1110;       // Digit 0 (Rightmost)
                hex_digit = value[3:0];
            end
            2'b01: begin
                an = 4'b1101;       // Digit 1
                hex_digit = value[7:4];
            end
            2'b10: begin
                an = 4'b1011;       // Digit 2
                hex_digit = value[11:8];
            end
            2'b11: begin
                an = 4'b0111;       // Digit 3 (Leftmost)
                hex_digit = value[15:12];
            end
        endcase
    end

    // 7-segment hex decoder (g to a, active low)
    // Segments: seg[0]=a, seg[1]=b, seg[2]=c, seg[3]=d, seg[4]=e, seg[5]=f, seg[6]=g
    always @(*) begin
        case (hex_digit)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100011; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111;
        endcase
    end

endmodule
