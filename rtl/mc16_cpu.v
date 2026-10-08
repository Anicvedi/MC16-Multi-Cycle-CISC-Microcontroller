// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// 16-bit Multi-Cycle MC16 CPU Top Core
// Combines Multi-Cycle Controller and Single-Bus Datapath
// ==============================================================================

`timescale 1ns / 1ps

module mc16_cpu #(
    parameter MEM_INIT_FILE = "division_prog.mem"
)(
    input  wire        clk,
    input  wire        rst,

    // Status / Observability outputs
    output wire [4:0]  state,
    output wire [5:0]  pc,
    output wire [15:0] ir,
    output wire [15:0] ipr,
    output wire [15:0] bus_data,
    output wire [15:0] r0,
    output wire [15:0] r1,
    output wire [15:0] r2,
    output wire [15:0] r3,
    output wire        flag_c,
    output wire        flag_z,
    output wire [15:0] quotient,
    output wire [15:0] remainder
);

    // Control wires between Controller and Datapath
    wire [2:0]  bus_sel;
    wire        temp_a_load;
    wire        temp_b_load;
    wire [3:0]  alu_op;
    wire        flags_we;
    wire        rf_we;
    wire        rf_raddr1_sel;
    wire        mar_load;
    wire        mem_we;
    wire        mem_addr_sel;
    wire        pc_load;
    wire        pc_inc;
    wire        ipr_load;
    wire        ir_load;

    // Status wires from Datapath to Controller
    wire [4:0]  opcode;
    wire [2:0]  ir_rd;
    wire [2:0]  ir_rs2;
    wire [2:0]  ir_rs1;

    // Instantiate Controller FSM
    controller u_controller (
        .clk           (clk),
        .rst           (rst),
        .opcode        (opcode),
        .flag_c        (flag_c),
        .flag_z        (flag_z),
        .bus_sel       (bus_sel),
        .temp_a_load   (temp_a_load),
        .temp_b_load   (temp_b_load),
        .alu_op        (alu_op),
        .flags_we      (flags_we),
        .rf_we         (rf_we),
        .rf_raddr1_sel (rf_raddr1_sel),
        .mar_load      (mar_load),
        .mem_we        (mem_we),
        .mem_addr_sel  (mem_addr_sel),
        .pc_load       (pc_load),
        .pc_inc        (pc_inc),
        .ipr_load      (ipr_load),
        .ir_load       (ir_load),
        .current_state (state)
    );

    // Instantiate Datapath
    datapath #(
        .MEM_INIT_FILE (MEM_INIT_FILE)
    ) u_datapath (
        .clk               (clk),
        .rst               (rst),
        .bus_sel           (bus_sel),
        .temp_a_load       (temp_a_load),
        .temp_b_load       (temp_b_load),
        .alu_op            (alu_op),
        .flags_we          (flags_we),
        .rf_we             (rf_we),
        .rf_raddr1_sel     (rf_raddr1_sel),
        .mar_load          (mar_load),
        .mem_we            (mem_we),
        .mem_addr_sel      (mem_addr_sel),
        .pc_load           (pc_load),
        .pc_inc            (pc_inc),
        .ipr_load          (ipr_load),
        .ir_load           (ir_load),
        .opcode            (opcode),
        .ir_rd             (ir_rd),
        .ir_rs2            (ir_rs2),
        .ir_rs1            (ir_rs1),
        .flag_c            (flag_c),
        .flag_z            (flag_z),
        .dbg_bus           (bus_data),
        .dbg_pc            (pc),
        .dbg_ir            (ir),
        .dbg_ipr           (ipr),
        .dbg_r0            (r0),
        .dbg_r1            (r1),
        .dbg_r2            (r2),
        .dbg_r3            (r3),
        .mem_dbg_quotient  (quotient),
        .mem_dbg_remainder (remainder)
    );

endmodule
