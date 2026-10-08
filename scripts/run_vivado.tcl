# ==============================================================================
# E3: 245 Processor System Design - IISc DESE
# Vivado Batch Script for Synthesis, Implementation, Timing Analysis & Bitstream
# Target: Digilent Basys 3 (XC7A35T-1CPG236C)
# Non-Project Flow (In-Memory Compilation)
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]
set report_dir "$root_dir/reports"
file mkdir $report_dir

# Create In-Memory Project targeting Artix-7 Basys 3
create_project -in_memory -part xc7a35tcpg236-1

# Add RTL source files
read_verilog [list \
    "$root_dir/rtl/defines.v" \
    "$root_dir/rtl/alu.v" \
    "$root_dir/rtl/reg_file.v" \
    "$root_dir/rtl/memory.v" \
    "$root_dir/rtl/datapath.v" \
    "$root_dir/rtl/controller.v" \
    "$root_dir/rtl/mc16_cpu.v" \
    "$root_dir/rtl/seg7_driver.v" \
    "$root_dir/rtl/basys3_top.v" \
]

set_property include_dirs [list "$root_dir/rtl"] [current_fileset]

# Add constraints
read_xdc "$root_dir/constrs/basys3.xdc"

# ------------------------------------------------------------------------------
# 1. Synthesis
# ------------------------------------------------------------------------------
puts "=== RUNNING SYNTHESIS ==="
synth_design -top basys3_top -part xc7a35tcpg236-1
report_utilization -file "$report_dir/post_synth_util.rpt"
report_timing_summary -file "$report_dir/post_synth_timing.rpt"

# ------------------------------------------------------------------------------
# 2. Optimization & Placement
# ------------------------------------------------------------------------------
puts "=== RUNNING OPT_DESIGN & PLACE_DESIGN ==="
opt_design
place_design
report_clock_utilization -file "$report_dir/clock_util.rpt"

# ------------------------------------------------------------------------------
# 3. Routing & Physical Optimization
# ------------------------------------------------------------------------------
puts "=== RUNNING ROUTE_DESIGN ==="
route_design
report_utilization -file "$report_dir/post_route_util.rpt"
report_utilization -hierarchical -file "$report_dir/post_route_util_hier.rpt"
report_timing_summary -max_paths 10 -report_unconstrained -file "$report_dir/post_route_timing.rpt"
report_drc -file "$report_dir/post_route_drc.rpt"
report_power -file "$report_dir/post_route_power.rpt"

# ------------------------------------------------------------------------------
# 4. Bitstream Generation
# ------------------------------------------------------------------------------
puts "=== GENERATING BITSTREAM ==="
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_bitstream -force "$report_dir/mc16_basys3.bit"

puts "=== BUILD COMPLETE! All reports generated in $report_dir ==="
exit
