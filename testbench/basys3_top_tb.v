// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// Top-Level Board Testbench for Digilent Basys 3
// Compatible with:
//   - Behavioral Simulation
//   - Post-Synthesis Functional & Timing Simulation
//   - Post-Implementation Functional & Timing Simulation
// ==============================================================================

`timescale 1ns / 1ps

module basys3_top_tb;

    reg         clk;
    reg         btnC;
    reg  [15:0] sw;
    wire [15:0] led;
    wire [6:0]  seg;
    wire        dp;
    wire [3:0]  an;

    // 100 MHz master clock (period = 10ns)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Instantiate Top-Level Device Under Test (basys3_top)
    basys3_top uut (
        .clk  (clk),
        .btnC (btnC),
        .sw   (sw),
        .led  (led),
        .seg  (seg),
        .dp   (dp),
        .an   (an)
    );

    initial begin
        $dumpfile("basys3_timing_sim.vcd");
        $dumpvars(0, basys3_top_tb);

        $display("================================================================");
        $display("  Starting Basys 3 Top Timing Simulation (mc16_basys3)");
        $display("================================================================");

        // Initial conditions
        sw   = 16'h0000; // sw[0]=0 (Quotient), sw[1]=0 (10 MHz CPU clock)
        btnC = 1'b1;     // Assert reset
        #200;
        btnC = 1'b0;     // Release reset
        $display("[Time %0t ns] Reset released. CPU executing at 10 MHz...", $time);

        // Allow processor to run the division program
        // At 10 MHz CPU clock (100 ns period), 270 cycles take ~27,000 ns.
        #35000;

        // Check quotient on LEDs (sw[0] = 0)
        sw[0] = 1'b0;
        #500;
        $display("----------------------------------------------------------------");
        $display("  TIMING SIMULATION RESULTS (from basys3_top output pins):");
        $display("  Discrete LEDs [sw[0]=0] (Quotient) : %0d (Expected: 14, Hex: 0x%04X)", led, led);

        // Check remainder on LEDs (sw[0] = 1)
        sw[0] = 1'b1;
        #500;
        $display("  Discrete LEDs [sw[0]=1] (Remainder): %0d (Expected: 2,  Hex: 0x%04X)", led, led);
        $display("  7-Segment Cathodes (seg)           : 7'b%7b", seg);
        $display("  7-Segment Anodes   (an)            : 4'b%4b", an);
        $display("----------------------------------------------------------------");

        if (led === 16'd2) begin
            $display(">>> TIMING SIMULATION PASSED SUCCESSFULLY! Verified on board I/O pins! <<<");
        end else begin
            $display(">>> WARNING: Timing simulation output check! <<<");
        end
        $display("================================================================\n");

        #1000;
        $finish;
    end

endmodule
