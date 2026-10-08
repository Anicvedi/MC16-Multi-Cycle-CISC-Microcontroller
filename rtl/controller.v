// ==============================================================================
// E3: 245 Processor System Design - IISc DESE
// Multi-Cycle Controller FSM (Level 0, Level 1, Level 2)
// ==============================================================================

`timescale 1ns / 1ps
`include "defines.v"

module controller (
    input  wire        clk,
    input  wire        rst,

    // Status inputs from Datapath
    input  wire [4:0]  opcode,
    input  wire        flag_c,
    input  wire        flag_z,

    // Control outputs to Datapath
    output reg  [2:0]  bus_sel,
    output reg         temp_a_load,
    output reg         temp_b_load,
    output reg  [3:0]  alu_op,
    output reg         flags_we,
    output reg         rf_we,
    output reg         rf_raddr1_sel,  // 0: rs1, 1: rd
    output reg         mar_load,
    output reg         mem_we,
    output reg         mem_addr_sel,   // 0: PC, 1: MAR
    output reg         pc_load,
    output reg         pc_inc,
    output reg         ipr_load,
    output reg         ir_load,

    // Debug / State output
    output reg  [4:0]  current_state
);

    // State definitions
    localparam S_BOOT_0           = 5'd0;
    localparam S_BOOT_1           = 5'd1;
    localparam S_DECODE           = 5'd2;
    localparam S_ALU_1            = 5'd3;
    localparam S_ALU_2            = 5'd4;
    localparam S_ALU_3            = 5'd5;
    localparam S_UNARY_1          = 5'd6;
    localparam S_UNARY_2          = 5'd7;
    localparam S_LOAD_1           = 5'd8;
    localparam S_LOAD_2           = 5'd9;
    localparam S_LOAD_PREFETCH    = 5'd10;
    localparam S_STORE_1          = 5'd11;
    localparam S_STORE_2          = 5'd12;
    localparam S_STORE_PREFETCH   = 5'd13;
    localparam S_BRANCH           = 5'd14;
    localparam S_BRANCH_RELOAD_0  = 5'd15;
    localparam S_BRANCH_RELOAD_1  = 5'd16;

    reg [4:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_BOOT_0;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        current_state = state;
    end

    // Branch condition evaluation
    reg branch_condition_met;
    always @(*) begin
        case (opcode)
            `OP_JMP: branch_condition_met = 1'b1;
            `OP_JZ:  branch_condition_met = flag_z;
            `OP_JNZ: branch_condition_met = ~flag_z;
            `OP_JC:  branch_condition_met = flag_c;
            `OP_JNC: branch_condition_met = ~flag_c;
            default: branch_condition_met = 1'b0;
        endcase
    end

    // Next-state logic & Output Control Logic
    always @(*) begin
        // Defaults
        next_state    = state;
        bus_sel       = `BUS_NONE;
        temp_a_load   = 1'b0;
        temp_b_load   = 1'b0;
        alu_op        = `ALU_PASSA;
        flags_we      = 1'b0;
        rf_we         = 1'b0;
        rf_raddr1_sel = 1'b0;
        mar_load      = 1'b0;
        mem_we        = 1'b0;
        mem_addr_sel  = 1'b0;  // Default: PC
        pc_load       = 1'b0;
        pc_inc        = 1'b0;
        ipr_load      = 1'b0;
        ir_load       = 1'b0;

        case (state)
            // -----------------------------------------------------------------
            // Boot / Pipeline Startup
            // -----------------------------------------------------------------
            S_BOOT_0: begin
                // PC = 0. Fetch MEM[0] into IPR. Increment PC to 1.
                mem_addr_sel = 1'b0; // PC
                ipr_load     = 1'b1;
                pc_inc       = 1'b1;
                next_state   = S_BOOT_1;
            end

            S_BOOT_1: begin
                // IR gets MEM[0] from IPR. Fetch MEM[1] into IPR. Increment PC to 2.
                ir_load      = 1'b1;
                mem_addr_sel = 1'b0; // PC
                ipr_load     = 1'b1;
                pc_inc       = 1'b1;
                next_state   = S_DECODE;
            end

            // -----------------------------------------------------------------
            // Instruction Decode (Level 1)
            // -----------------------------------------------------------------
            S_DECODE: begin
                case (opcode)
                    `OP_ADD, `OP_SUB, `OP_AND, `OP_OR: begin
                        next_state = S_ALU_1;
                    end
                    `OP_INCR, `OP_DECR, `OP_SHL, `OP_RRC: begin
                        next_state = S_UNARY_1;
                    end
                    `OP_LOAD: begin
                        next_state = S_LOAD_1;
                    end
                    `OP_STORE: begin
                        next_state = S_STORE_1;
                    end
                    `OP_JMP, `OP_JZ, `OP_JNZ, `OP_JC, `OP_JNC: begin
                        next_state = S_BRANCH;
                    end
                    `OP_NOP: begin
                        // Advance to next instruction
                        ir_load    = 1'b1;
                        ipr_load   = 1'b1;
                        pc_inc     = 1'b1;
                        next_state = S_DECODE;
                    end
                    default: begin
                        // Unknown / NOP
                        ir_load    = 1'b1;
                        ipr_load   = 1'b1;
                        pc_inc     = 1'b1;
                        next_state = S_DECODE;
                    end
                endcase
            end

            // -----------------------------------------------------------------
            // Arithmetic-Logic Instructions (3-operand: rd <= rs1 op rs2)
            // -----------------------------------------------------------------
            S_ALU_1: begin
                // Transfer rs1 from RegFile onto bus into TEMP_A
                rf_raddr1_sel = 1'b0;      // rs1
                bus_sel       = `BUS_REG1;
                temp_a_load   = 1'b1;
                next_state    = S_ALU_2;
            end

            S_ALU_2: begin
                // Transfer rs2 from RegFile onto bus into TEMP_B
                bus_sel     = `BUS_REG2;
                temp_b_load = 1'b1;
                next_state  = S_ALU_3;
            end

            S_ALU_3: begin
                // Execute ALU operation, drive bus with result, write to RegFile[rd]
                case (opcode)
                    `OP_ADD: alu_op = `ALU_ADD;
                    `OP_SUB: alu_op = `ALU_SUB;
                    `OP_AND: alu_op = `ALU_AND;
                    `OP_OR:  alu_op = `ALU_OR;
                    default: alu_op = `ALU_ADD;
                endcase
                bus_sel  = `BUS_ALU;
                rf_we    = 1'b1;
                flags_we = 1'b1;

                // Concurrent Prefetch: Advance to next instruction
                ir_load    = 1'b1;
                ipr_load   = 1'b1;
                pc_inc     = 1'b1;
                next_state = S_DECODE;
            end

            // -----------------------------------------------------------------
            // Unary ALU Instructions (INCR, DECR, SHL, RRC)
            // -----------------------------------------------------------------
            S_UNARY_1: begin
                // Transfer rd from RegFile into TEMP_A
                rf_raddr1_sel = 1'b1;      // rd
                bus_sel       = `BUS_REG1;
                temp_a_load   = 1'b1;
                next_state    = S_UNARY_2;
            end

            S_UNARY_2: begin
                case (opcode)
                    `OP_INCR: alu_op = `ALU_INCR;
                    `OP_DECR: alu_op = `ALU_DECR;
                    `OP_SHL:  alu_op = `ALU_SHL;
                    `OP_RRC:  alu_op = `ALU_RRC;
                    default:  alu_op = `ALU_INCR;
                endcase
                bus_sel  = `BUS_ALU;
                rf_we    = 1'b1;
                flags_we = 1'b1;

                // Concurrent Prefetch: Advance to next instruction
                ir_load    = 1'b1;
                ipr_load   = 1'b1;
                pc_inc     = 1'b1;
                next_state = S_DECODE;
            end

            // -----------------------------------------------------------------
            // LOAD rd, [Addr]
            // -----------------------------------------------------------------
            S_LOAD_1: begin
                // Drive bus with IR address and latch into MAR
                bus_sel    = `BUS_IR_ADDR;
                mar_load   = 1'b1;
                next_state = S_LOAD_2;
            end

            S_LOAD_2: begin
                // Read memory at MAR onto bus and write to RegFile[rd]
                mem_addr_sel = 1'b1;      // MAR
                bus_sel      = `BUS_MEM;
                rf_we        = 1'b1;
                next_state   = S_LOAD_PREFETCH;
            end

            S_LOAD_PREFETCH: begin
                // Restore PC as memory address, advance IR from IPR, prefetch next
                mem_addr_sel = 1'b0;      // PC
                ir_load      = 1'b1;
                ipr_load     = 1'b1;
                pc_inc       = 1'b1;
                next_state   = S_DECODE;
            end

            // -----------------------------------------------------------------
            // STORE [Addr], rs2
            // -----------------------------------------------------------------
            S_STORE_1: begin
                // Drive bus with IR address and latch into MAR
                bus_sel    = `BUS_IR_ADDR;
                mar_load   = 1'b1;
                next_state = S_STORE_2;
            end

            S_STORE_2: begin
                // Drive bus with RegFile[rs2] and write to memory at MAR
                mem_addr_sel = 1'b1;      // MAR
                bus_sel      = `BUS_REG2;
                mem_we       = 1'b1;
                next_state   = S_STORE_PREFETCH;
            end

            S_STORE_PREFETCH: begin
                // Restore PC as memory address, advance IR from IPR, prefetch next
                mem_addr_sel = 1'b0;      // PC
                ir_load      = 1'b1;
                ipr_load     = 1'b1;
                pc_inc       = 1'b1;
                next_state   = S_DECODE;
            end

            // -----------------------------------------------------------------
            // Branch / Jump Instructions
            // -----------------------------------------------------------------
            S_BRANCH: begin
                if (branch_condition_met) begin
                    // Branch Taken: load target address into PC
                    bus_sel    = `BUS_IR_ADDR;
                    pc_load    = 1'b1;
                    next_state = S_BRANCH_RELOAD_0;
                end else begin
                    // Branch Not Taken: advance to next instruction normally
                    ir_load    = 1'b1;
                    ipr_load   = 1'b1;
                    pc_inc     = 1'b1;
                    next_state = S_DECODE;
                end
            end

            S_BRANCH_RELOAD_0: begin
                // Memory is now addressed by new PC (target). Fetch target into IPR.
                mem_addr_sel = 1'b0; // PC
                ipr_load     = 1'b1;
                pc_inc       = 1'b1;
                next_state   = S_BRANCH_RELOAD_1;
            end

            S_BRANCH_RELOAD_1: begin
                // IR takes target instruction from IPR. Fetch target+1 into IPR.
                ir_load      = 1'b1;
                mem_addr_sel = 1'b0; // PC
                ipr_load     = 1'b1;
                pc_inc       = 1'b1;
                next_state   = S_DECODE;
            end

            default: begin
                next_state = S_BOOT_0;
            end
        endcase
    end

endmodule
