// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// Top-Level FPGA Module for Digilent Basys 3 Board
// Target Device: Xilinx Artix-7 XC7A35T-1CPG236C
// ==============================================================================

`timescale 1ns / 1ps

module basys3_top #(
    parameter MEM_INIT_FILE = "division_prog.mem"
)(
    input  wire        clk,        // 100 MHz master clock (pin W5)
    input  wire        btnC,       // Center push button for Reset (pin U18)
    input  wire [15:0] sw,         // Slide switches
    output wire [15:0] led,        // 16 Discrete LEDs
    output wire [6:0]  seg,        // 7-segment cathodes (active low)
    output wire        dp,         // 7-segment decimal point
    output wire [3:0]  an          // 7-segment anodes (active low)
);

    // Synchronize and debounce reset button
    reg [2:0] rst_sync;
    always @(posedge clk) begin
        rst_sync <= {rst_sync[1:0], btnC};
    end
    wire rst = rst_sync[2];

    // Clock divider for CPU execution
    // sw[1] = 0 -> Run at 10 MHz (divide by 10)
    // sw[1] = 1 -> Run at ~1 kHz for visual observation
    reg [16:0] clk_div_counter;
    reg        cpu_clk;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_counter <= 17'd0;
            cpu_clk         <= 1'b0;
        end else begin
            if (sw[1] == 1'b1) begin
                // ~1 kHz clock (divide 100 MHz by 100,000 -> toggle at 50,000)
                if (clk_div_counter >= 17'd50000) begin
                    clk_div_counter <= 17'd0;
                    cpu_clk         <= ~cpu_clk;
                end else begin
                    clk_div_counter <= clk_div_counter + 17'd1;
                end
            end else begin
                // 10 MHz clock (divide 100 MHz by 10 -> toggle at 5)
                if (clk_div_counter >= 17'd4) begin
                    clk_div_counter <= 17'd0;
                    cpu_clk         <= ~cpu_clk;
                end else begin
                    clk_div_counter <= clk_div_counter + 17'd1;
                end
            end
        end
    end

    // CPU Signals
    wire [4:0]  cpu_state;
    wire [5:0]  cpu_pc;
    wire [15:0] cpu_ir;
    wire [15:0] cpu_ipr;
    wire [15:0] cpu_bus;
    wire [15:0] cpu_r0;
    wire [15:0] cpu_r1;
    wire [15:0] cpu_r2;
    wire [15:0] cpu_r3;
    wire        flag_c;
    wire        flag_z;
    wire [15:0] quotient;
    wire [15:0] remainder;

    // Instantiate MC16 CPU
    mc16_cpu #(
        .MEM_INIT_FILE(MEM_INIT_FILE)
    ) u_mc16_cpu (
        .clk       (cpu_clk),
        .rst       (rst),
        .state     (cpu_state),
        .pc        (cpu_pc),
        .ir        (cpu_ir),
        .ipr       (cpu_ipr),
        .bus_data  (cpu_bus),
        .r0        (cpu_r0),
        .r1        (cpu_r1),
        .r2        (cpu_r2),
        .r3        (cpu_r3),
        .flag_c    (flag_c),
        .flag_z    (flag_z),
        .quotient  (quotient),
        .remainder (remainder)
    );

    // Display selection:
    // sw[0] == 0 -> Display Quotient
    // sw[0] == 1 -> Display Remainder
    wire [15:0] display_val = (sw[0] == 1'b1) ? remainder : quotient;

    // Discrete LEDs:
    // led[15:0] shows selected 16-bit result value
    assign led = display_val;

    // 7-Segment Display:
    // Shows selected 16-bit result as 4 hexadecimal digits
    seg7_driver u_seg7 (
        .clk   (clk),         // Runs at 100 MHz for flicker-free multiplexing
        .rst   (rst),
        .value (display_val),
        .an    (an),
        .seg   (seg),
        .dp    (dp)
    );

endmodule
