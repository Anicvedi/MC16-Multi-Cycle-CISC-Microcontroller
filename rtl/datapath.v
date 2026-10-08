// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// 16-bit Datapath with Single Shared Central Data Bus Multiplexer
// ==============================================================================

`timescale 1ns / 1ps
`include "defines.v"

module datapath #(
    parameter MEM_INIT_FILE = "division_prog.mem"
)(
    input  wire        clk,
    input  wire        rst,

    // Bus & Register Controls from FSM Controller
    input  wire [2:0]  bus_sel,
    input  wire        temp_a_load,
    input  wire        temp_b_load,
    input  wire [3:0]  alu_op,
    input  wire        flags_we,
    input  wire        rf_we,
    input  wire        rf_raddr1_sel,  // 0: IR[4:2] (rs1), 1: IR[10:8] (rd)
    input  wire        mar_load,
    input  wire        mem_we,
    input  wire        mem_addr_sel,   // 0: PC, 1: MAR
    input  wire        pc_load,
    input  wire        pc_inc,
    input  wire        ipr_load,
    input  wire        ir_load,

    // Status / Decoding Outputs to Controller
    output wire [4:0]  opcode,
    output wire [2:0]  ir_rd,
    output wire [2:0]  ir_rs2,
    output wire [2:0]  ir_rs1,
    output reg         flag_c,
    output reg         flag_z,

    // Observability / Debug Outputs
    output wire [15:0] dbg_bus,
    output wire [5:0]  dbg_pc,
    output wire [15:0] dbg_ir,
    output wire [15:0] dbg_ipr,
    output wire [15:0] dbg_r0,
    output wire [15:0] dbg_r1,
    output wire [15:0] dbg_r2,
    output wire [15:0] dbg_r3,
    output wire [15:0] mem_dbg_quotient,
    output wire [15:0] mem_dbg_remainder
);

    // -------------------------------------------------------------------------
    // Internal Registers & Signals
    // -------------------------------------------------------------------------
    reg  [5:0]  pc;
    reg  [5:0]  mar;
    reg  [15:0] ipr;
    reg  [15:0] ir;
    reg  [15:0] temp_a;
    reg  [15:0] temp_b;

    wire [15:0] bus_data;
    wire [15:0] mem_dout;
    wire [15:0] rf_rdata1;
    wire [15:0] rf_rdata2;
    wire [15:0] alu_result;
    wire        alu_c_out;
    wire        alu_z_out;

    // -------------------------------------------------------------------------
    // Instruction Decoding
    // -------------------------------------------------------------------------
    assign opcode = ir[15:11];
    assign ir_rd  = ir[10:8];
    assign ir_rs2 = ir[7:5];
    assign ir_rs1 = ir[4:2];

    // -------------------------------------------------------------------------
    // Shared Central Data Bus Multiplexer
    // (Single shared bus for all data movement; multiplexer replaces tri-state)
    // -------------------------------------------------------------------------
    reg [15:0] bus_mux;
    always @(*) begin
        case (bus_sel)
            `BUS_MEM:     bus_mux = mem_dout;
            `BUS_REG1:    bus_mux = rf_rdata1;
            `BUS_REG2:    bus_mux = rf_rdata2;
            `BUS_ALU:     bus_mux = alu_result;
            `BUS_PC:      bus_mux = {10'b0, pc};
            `BUS_IR_ADDR: bus_mux = {11'b0, ir[4:0]};
            `BUS_IPR:     bus_mux = ipr;
            default:      bus_mux = 16'h0000;
        endcase
    end
    assign bus_data = bus_mux;

    // -------------------------------------------------------------------------
    // Program Counter (PC)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 6'd0;
        end else if (pc_load) begin
            pc <= bus_data[5:0];
        end else if (pc_inc) begin
            pc <= pc + 6'd1;
        end
    end

    // -------------------------------------------------------------------------
    // Memory Address Register (MAR)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mar <= 6'd0;
        end else if (mar_load) begin
            mar <= bus_data[5:0];
        end
    end

    // -------------------------------------------------------------------------
    // Instruction Prefetch Register (IPR) and Instruction Register (IR)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ipr <= 16'h0000;
            ir  <= 16'h0000;
        end else begin
            if (ir_load) begin
                ir <= ipr;
            end
            if (ipr_load) begin
                ipr <= mem_dout;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Temporary Registers (TEMP_A and TEMP_B)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            temp_a <= 16'h0000;
            temp_b <= 16'h0000;
        end else begin
            if (temp_a_load) temp_a <= bus_data;
            if (temp_b_load) temp_b <= bus_data;
        end
    end

    // -------------------------------------------------------------------------
    // Flags Register (Carry and Zero)
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            flag_c <= 1'b0;
            flag_z <= 1'b0;
        end else if (flags_we) begin
            flag_c <= alu_c_out;
            flag_z <= alu_z_out;
        end
    end

    // -------------------------------------------------------------------------
    // Sub-Module Instantiations
    // -------------------------------------------------------------------------

    wire [2:0] rf_raddr1_mux = (rf_raddr1_sel) ? ir_rd : ir_rs1;

    // 1. Register File
    reg_file u_reg_file (
        .clk    (clk),
        .rst    (rst),
        .we     (rf_we),
        .waddr  (ir_rd),
        .wdata  (bus_data),
        .raddr1 (rf_raddr1_mux),
        .rdata1 (rf_rdata1),
        .raddr2 (ir_rs2),
        .rdata2 (rf_rdata2)
    );

    // 2. ALU
    alu u_alu (
        .alu_op (alu_op),
        .a      (temp_a),
        .b      (temp_b),
        .c_in   (flag_c),
        .result (alu_result),
        .c_out  (alu_c_out),
        .z_out  (alu_z_out)
    );

    // 3. Instruction-cum-Data Memory (64x16 Distributed RAM)
    wire [5:0] effective_mem_addr = (mem_addr_sel == 1'b1) ? mar : pc;

    memory #(
        .MEM_INIT_FILE(MEM_INIT_FILE)
    ) u_memory (
        .clk  (clk),
        .we   (mem_we),
        .addr (effective_mem_addr),
        .din  (bus_data),
        .dout (mem_dout)
    );

    // Observability registers for quotient & remainder outputs
    reg [15:0] quotient_reg;
    reg [15:0] remainder_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            quotient_reg  <= 16'h0000;
            remainder_reg <= 16'h0000;
        end else if (mem_we && mem_addr_sel) begin
            if (mar == 6'd29) quotient_reg  <= bus_data;
            if (mar == 6'd30) remainder_reg <= bus_data;
        end
    end

    // -------------------------------------------------------------------------
    // Debug & Observability Assignments
    // -------------------------------------------------------------------------
    assign dbg_bus = bus_data;
    assign dbg_pc  = pc;
    assign dbg_ir  = ir;
    assign dbg_ipr = ipr;
    assign dbg_r0  = 16'h0000;
    assign dbg_r1  = 16'h0000;
    assign dbg_r2  = 16'h0000;
    assign dbg_r3  = 16'h0000;
    assign mem_dbg_quotient  = quotient_reg;
    assign mem_dbg_remainder = remainder_reg;

endmodule
