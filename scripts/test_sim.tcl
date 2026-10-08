set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]
set proj_file "$root_dir/mc16_basys3/mc16_basys3.xpr"

open_project $proj_file
set_property top mc16_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "=== LAUNCHING BEHAVIORAL SIMULATION (mc16_tb) ==="
launch_simulation -mode behavioral
run 3000ns
close_sim

close_project
puts "=== SIMULATION COMPLETED SUCCESSFULLY ==="
exit 0
