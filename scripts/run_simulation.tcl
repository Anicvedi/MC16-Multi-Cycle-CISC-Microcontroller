# ==============================================================================
# E3: 245 Processor System Design - IISc DESE
# Vivado Batch Script for Behavioral Simulation
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]

# Set up project
create_project -force -part xc7a35tcpg236-1 mc16_sim "$root_dir/vivado_sim"

# Add HDL files
add_files [list \
    "$root_dir/rtl/defines.v" \
    "$root_dir/rtl/alu.v" \
    "$root_dir/rtl/reg_file.v" \
    "$root_dir/rtl/memory.v" \
    "$root_dir/rtl/datapath.v" \
    "$root_dir/rtl/controller.v" \
    "$root_dir/rtl/mc16_cpu.v" \
]

# Set include directories
set_property include_dirs [list "$root_dir/rtl"] [current_fileset]

# Add testbench
add_files -fileset sim_1 [list \
    "$root_dir/testbench/mc16_tb.v" \
]
set_property include_dirs [list "$root_dir/rtl"] [get_filesets sim_1]

# Set top
set_property top mc16_tb [get_filesets sim_1]

# Launch simulation
launch_simulation -mode behavioral

# Run
run 5000ns
close_sim
close_project
exit
