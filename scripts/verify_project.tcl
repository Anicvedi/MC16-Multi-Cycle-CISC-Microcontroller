set script_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file dirname $script_dir]]
set proj_file "$root_dir/mc16_basys3/mc16_basys3.xpr"

puts "Opening project $proj_file..."
open_project $proj_file
puts "Project opened successfully!"
puts "Sources in sources_1:"
foreach f [get_files -of_objects [get_filesets sources_1]] {
    puts "  [get_property NAME $f]"
}
puts "Top module sources_1: [get_property top [current_fileset]]"
puts "Top module sim_1: [get_property top [get_filesets sim_1]]"
close_project
puts "Verification completed successfully!"
exit 0
