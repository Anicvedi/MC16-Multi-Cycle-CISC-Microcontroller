# ==============================================================================
# E3: 245 Processor System Design - IISc DESE
# Interactive Vivado GUI Project Generator Script
# Creates a fresh 'mc16_basys3' project and leaves Vivado GUI open
# Target: Digilent Basys 3 FPGA (Artix-7 XC7A35T-1CPG236C)
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]
set proj_dir "$root_dir/mc16_basys3"

# 1. Create Vivado Project
create_project -force mc16_basys3 "$proj_dir" -part xc7a35tcpg236-1

# 2. Set Project Properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 3. Add RTL Sources and Memory Initialization Files
add_files -fileset sources_1 [list \
    "$root_dir/rtl/defines.v" \
    "$root_dir/rtl/alu.v" \
    "$root_dir/rtl/reg_file.v" \
    "$root_dir/rtl/memory.v" \
    "$root_dir/rtl/datapath.v" \
    "$root_dir/rtl/controller.v" \
    "$root_dir/rtl/mc16_cpu.v" \
    "$root_dir/rtl/seg7_driver.v" \
    "$root_dir/rtl/basys3_top.v" \
    "$root_dir/memory/division_prog.mem" \
    "$root_dir/memory/division_prog.coe" \
]

set_property include_dirs [list "$root_dir/rtl"] [current_fileset]
set_property top basys3_top [current_fileset]

# 4. Add Pin & Timing Constraints
add_files -fileset constrs_1 [list \
    "$root_dir/constrs/basys3.xdc" \
]

# 5. Add Simulation Testbenches
add_files -fileset sim_1 [list \
    "$root_dir/testbench/mc16_tb.v" \
    "$root_dir/testbench/basys3_top_tb.v" \
]
set_property include_dirs [list "$root_dir/rtl"] [get_filesets sim_1]
set_property top mc16_tb [get_filesets sim_1]

# 6. Set Bitstream Options
set_property -name {STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE} -value {true} -objects [get_runs impl_1]

# 7. Update Compile Order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "=========================================================================="
puts "  Vivado GUI Project 'mc16_basys3' created and configured successfully!"
puts "  Top Module (Synthesis/Implementation): basys3_top"
puts "  Top Module (Simulation): mc16_tb"
puts "=========================================================================="
