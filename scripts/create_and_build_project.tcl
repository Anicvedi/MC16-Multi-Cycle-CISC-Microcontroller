# ==============================================================================
# E3: 245 Processor System Design - IISc DESE
# Fast & Clean Vivado Project Generator & Builder
# Runs in C:/temp to bypass OneDrive sync locks, then exports to workspace
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set src_root [file normalize [file dirname $script_dir]]
set build_dir "C:/temp/mc16_build"
set final_dir "$src_root/mc16_basys3"

file mkdir "C:/temp"
file delete -force "$build_dir"

# 1. Create Vivado Project
create_project -force mc16_basys3 "$build_dir" -part xc7a35tcpg236-1

set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 2. Add RTL Sources
add_files -fileset sources_1 [list \
    "$src_root/rtl/defines.v" \
    "$src_root/rtl/alu.v" \
    "$src_root/rtl/reg_file.v" \
    "$src_root/rtl/memory.v" \
    "$src_root/rtl/datapath.v" \
    "$src_root/rtl/controller.v" \
    "$src_root/rtl/mc16_cpu.v" \
    "$src_root/rtl/seg7_driver.v" \
    "$src_root/rtl/basys3_top.v" \
    "$src_root/memory/division_prog.mem" \
    "$src_root/memory/division_prog.coe" \
]

set_property include_dirs [list "$src_root/rtl"] [current_fileset]
set_property top basys3_top [current_fileset]

# 3. Add Constraints
add_files -fileset constrs_1 [list \
    "$src_root/constrs/basys3.xdc" \
]

# 4. Add Simulation Testbench
add_files -fileset sim_1 [list \
    "$src_root/testbench/mc16_tb.v" \
]
set_property include_dirs [list "$src_root/rtl"] [get_filesets sim_1]
set_property top mc16_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 5. Set Voltage configuration
set_property -name {STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE} -value {true} -objects [get_runs impl_1]

puts "=== STARTING PROJECT SYNTHESIS (synth_1) ==="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: synth_1 failed!"
    exit 1
}
puts "=== SYNTHESIS COMPLETE (100%) ==="

puts "=== STARTING PROJECT IMPLEMENTATION & BITSTREAM (impl_1) ==="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: impl_1 failed!"
    exit 1
}
puts "=== IMPLEMENTATION & BITSTREAM COMPLETE (100%) ==="

# 6. Run simulation in project to verify
puts "=== RUNNING SIMULATION IN PROJECT (sim_1) ==="
launch_simulation -simset sim_1 -mode behavioral
run 3000ns
close_sim

close_project
puts "=== PROJECT SUCCESSFULLY BUILT IN $build_dir ==="
exit
