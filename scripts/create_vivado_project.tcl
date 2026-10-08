# ==============================================================================
# E3: 245 Processor System Design - IISc DESE
# Vivado GUI Project Generator Script
# Creates 'mc16_basys3.xpr' for interactive use in Vivado GUI
# Target: Digilent Basys 3 FPGA (Artix-7 XC7A35T-1CPG236C)
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]
set proj_dir "$root_dir/mc16_basys3"

# Create standard Vivado GUI project
create_project -force mc16_basys3 "$proj_dir" -part xc7a35tcpg236-1

# Set target language to Verilog
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 1. Add RTL Design Sources
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

# Set include directory for rtl
set_property include_dirs [list "$root_dir/rtl"] [current_fileset]
set_property top basys3_top [current_fileset]

# 2. Add Constraints
add_files -fileset constrs_1 [list \
    "$root_dir/constrs/basys3.xdc" \
]

# 3. Add Simulation Testbench
add_files -fileset sim_1 [list \
    "$root_dir/testbench/mc16_tb.v" \
]
set_property include_dirs [list "$root_dir/rtl"] [get_filesets sim_1]
set_property top mc16_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 4. Set Bitstream Voltage Configuration Properties
set_property -name {STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE} -value {true} -objects [get_runs impl_1]

puts "=== PROJECT GENERATED SUCCESSFULLY AT: $proj_dir/mc16_basys3.xpr ==="

# 5. Launch Synthesis & Implementation within Project
puts "=== LAUNCHING SYNTHESIS (synth_1) ==="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

puts "=== LAUNCHING IMPLEMENTATION & BITSTREAM (impl_1) ==="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

puts "=== VIVADO PROJECT BUILD COMPLETE! ==="
puts "Project file: $proj_dir/mc16_basys3.xpr"
close_project
exit
