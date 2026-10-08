# ==============================================================================
# Generate Post-Synthesis Timing Simulation on Desktop Project
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]
open_project "$root_dir/mc16_basys3/mc16_basys3.xpr"
set_property top basys3_top_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {40000ns} -objects [get_filesets sim_1]

puts "=== RUNNING POST-SYNTHESIS TIMING SIMULATION ON DESKTOP PROJECT ==="
launch_simulation -mode post-synthesis -type timing
run 40000ns
close_sim

close_project
puts "=== POST-SYNTHESIS TIMING SIMULATION SUCCESSFUL! ==="
exit
