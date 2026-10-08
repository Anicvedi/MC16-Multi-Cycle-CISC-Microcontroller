// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// Testbench for 16-bit Multi-Cycle MC16 Processor
// Verifies Unsigned Division of two 16-bit numbers
// ==============================================================================

`timescale 1ns / 1ps

module mc16_tb;

    reg clk;
    reg rst;

    wire [4:0]  state;
    wire [5:0]  pc;
    wire [15:0] ir;
    wire [15:0] ipr;
    wire [15:0] bus_data;
    wire [15:0] r0;
    wire [15:0] r1;
    wire [15:0] r2;
    wire [15:0] r3;
    wire        flag_c;
    wire        flag_z;
    wire [15:0] quotient;
    wire [15:0] remainder;

    // Clock generation (100 MHz, period = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate CPU core
    mc16_cpu #(
        .MEM_INIT_FILE("memory/division_prog.mem")
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .state     (state),
        .pc        (pc),
        .ir        (ir),
        .ipr       (ipr),
        .bus_data  (bus_data),
        .r0        (r0),
        .r1        (r1),
        .r2        (r2),
        .r3        (r3),
        .flag_c    (flag_c),
        .flag_z    (flag_z),
        .quotient  (quotient),
        .remainder (remainder)
    );

    integer cycle_count;
    integer max_cycles = 1000;

    initial begin
        $dumpfile("mc16_tb.vcd");
        $dumpvars(0, mc16_tb);

        $display("================================================================");
        $display("  Starting Multi-Cycle MC16 Processor Simulation");
        $display("  Test Program: 16-bit Unsigned Division (100 / 7)");
        $display("================================================================");

        rst = 1'b1;
        cycle_count = 0;
        #25;
        rst = 1'b0;
        $display("[Time %0t ns] Reset deasserted. CPU executing...", $time);

        // Run until completion or timeout
        while (cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            // Monitor state transitions
            if (state == 5'd2) begin // S_DECODE
                $display("[Cycle %4d] PC=%02d | IR=0x%04X | R0(Dividend)=%0d | R1(Divisor)=%0d | R2(Quotient)=%0d | C=%b Z=%b",
                         cycle_count, pc, ir, r0, r1, r2, flag_c, flag_z);
            end

            // Check if reached HALT instruction (jump to same address 10)
            if (ir == 16'h580A && state == 5'd14) begin
                $display("\n[Time %0t ns] Program reached HALT self-loop!", $time);
                #50; // Allow final state settling
                
                $display("----------------------------------------------------------------");
                $display("  SIMULATION VERIFICATION RESULTS:");
                $display("  Dividend : %0d (Expected: 100)", dut.u_datapath.u_memory.ram[26]);
                $display("  Divisor  : %0d (Expected: 7)",   dut.u_datapath.u_memory.ram[27]);
                $display("  Quotient : %0d (Expected: 14, Hex: 0x%04X)", quotient, quotient);
                $display("  Remainder: %0d (Expected: 2,  Hex: 0x%04X)", remainder, remainder);
                $display("----------------------------------------------------------------");

                if (quotient === 16'd14 && remainder === 16'd2) begin
                    $display(">>> TEST PASSED SUCCESSFULLY! Division result is verified! <<<");
                end else begin
                    $display(">>> TEST FAILED! Mismatch in quotient or remainder! <<<");
                end
                $display("================================================================\n");
                $finish;
            end
        end

        $display("ERROR: Simulation timed out after %0d cycles!", max_cycles);
        $finish;
    end

endmodule
