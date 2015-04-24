#
# SimpleRegister4Zynq - This file is part of SimpleRegister4Zynq
# Copyright (C) 2015 - Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

# Precision RTL synthesis script. Please make pr-help for more information about the synthesis process.

# First set 'rootdir' to the absolute path of the root directory of the project
if { [ info exists ::env(rootdir) ] && ( "x$::env(rootdir)" != "x" ) } {
	set rootdir [ file normalize $::env(rootdir) ]
} elseif { [ info exists ::env(ROOTDIR) ] && ( "x$::env(ROOTDIR)" != "x" ) } {
	set rootdir [ file normalize $::env(ROOTDIR) ]
} else {
	error "rootdir environment variable undefined"
}

# Source myself to get rid of annoying echo of TCL commands
if ![ info exists already_sourced ] {
	set already_sourced 1
	source $rootdir/scripts/pr.tcl
}

# Toplevel source file:
if { [ info exists ::env(PR_SYN_TOP) ] && ( "x$::env(PR_SYN_TOP)" != "x" ) } {
	set topfile [ file rootname [ file tail $::env(PR_SYN_TOP) ] ]
} else {
	error "PR_SYN_TOP environment variable undefined"
}

# Toplevel entity name
if { [ info exists ::env(PR_SYN_TOPENTITY) ] && ( "x$::env(PR_SYN_TOPENTITY)" != "x" ) } {
	set topentity $::env(PR_SYN_TOPENTITY)
} else {
	set topentity $topfile
}

# If synthesis script exists, source it
if [ file exists "$topfile.psyn.tcl" ] {
	source "$topfile.psyn.tcl"
}

# Parameters that influence the synthesis flow and their default values
array set synthesis_options {
      addio				true
      auto_resource_allocation_ram	true
      bottom_up_flow			false
      compile_for_timing		true
      dsp_across_hier			true
      edif				true
      family				Zynq
      generics				{}
      hdl				vhdl_2002
      ignore_ram_rw_collision		true
      input_delay			2500
      manufacturer			Xilinx
      max_fanout			16
      max_fanout_strategy		AUTO
      output_delay			2500
      part				7Z020CLG484
      period				5000
      resource_sharing			false
      speed				1
}

# Compute synthesis options with the TCL variable > environment variable > default priority.
foreach o [ array names synthesis_options ] {
	set oo pr_syn_$o
	set OO [ string toupper $oo ]
	if [ info exists $oo ] {
		eval "set synthesis_options($o) [ set $oo ]"
	} elseif [ info exists ::env($OO) ] {
		eval "set synthesis_options($o) $::env($OO)"
	}
}

# Set 'lib' to the VHDL library associated to the current source directory
set lib "[ file tail [ pwd ] ]_lib"

# Create the directory in which to store synthesis results: $topfile.pr-syn.T where T is time in seconds since epoch
set syndir "$topfile.pr-syn.[ clock seconds ]"
file mkdir $syndir

set scriptsdir $rootdir/scripts
set srcrootdir $rootdir/src
source $scriptsdir/makedepends.tcl

# After completion all the synthesis results will be stored in the current directory. Note: the script takes care of creating a new directory for each synthesis
# run. Do not modify unless you want to launch the synthesis manually.
set_results_dir $syndir

# Preprocessing before HDL read
if { [ info procs preLoad ] eq "preLoad" } {
	preLoad
}

# Read HDL files
set modules [ exec ls $srcrootdir ]
foreach m $modules {
	eval "set Paths_g(${m}_lib) $srcrootdir/$m"
}
set frm "add_input_file -work %2\$s -format vhdl %3\$s/%1\$s"
getDependencies {} [ list $lib.$topfile ]
loadVHDLSources $lib.$topfile "$frm"

# Apply synthesis options
setup_design -addio=$synthesis_options(addio)
setup_design -auto_resource_allocation_ram=$synthesis_options(auto_resource_allocation_ram)
setup_design -bottom_up_flow=$synthesis_options(bottom_up_flow)
setup_design -compile_for_timing=$synthesis_options(compile_for_timing)
setup_design -design=$topentity
setup_design -dsp_across_hier=$synthesis_options(dsp_across_hier)
setup_design -edif=$synthesis_options(edif)
setup_design -manufacturer=$synthesis_options(manufacturer) -family=$synthesis_options(family) -part=$synthesis_options(part) -speed=$synthesis_options(speed)
if { [ llength $synthesis_options(generics) ] != 0 } {
	setup_design -overrides $synthesis_options(generics)
}
setup_design -frequency=[ expr 1000000 / $synthesis_options(period) ]
setup_design -hdl=$synthesis_options(hdl)
setup_design -ignore_ram_rw_collision=$synthesis_options(ignore_ram_rw_collision)
setup_design -input_delay=[ expr $synthesis_options(input_delay) / 1000 ]
setup_design -max_fanout=$synthesis_options(max_fanout)
setup_design -max_fanout_strategy=$synthesis_options(max_fanout_strategy)
setup_design -output_delay=[ expr $synthesis_options(output_delay) / 1000 ]
setup_design -resource_sharing=$synthesis_options(resource_sharing)

# Postprocessing after HDL read
if { [ info procs postLoad ] eq "postLoad" } {
	postLoad
}

# Reports
puts "--------------------------------------------------------------------------------"
puts "Input files:"
puts "--------------------------------------------------------------------------------"
report_input_file_list
puts "--------------------------------------------------------------------------------"
puts "Output files:"
puts "--------------------------------------------------------------------------------"
report_output_file_list
puts "--------------------------------------------------------------------------------"

# Compile
compile

# Reports
puts "--------------------------------------------------------------------------------"
puts "Constraints:"
puts "--------------------------------------------------------------------------------"
report_constraints
puts "--------------------------------------------------------------------------------"

# Postprocessing after compile
if { [ info procs postCompile ] eq "postCompile" } {
	postCompile
}

synthesize

# Postprocessing after synthesis
if { [ info procs postSynthesis ] eq "postSynthesis" } {
	postSynthesis
}

report_area
report_timing

close_results_dir

puts "--------------------------------------------------------------------------------"
puts "Results stored in $syndir"
puts "--------------------------------------------------------------------------------"

# Create the $topfile.pr-syn symlink (first deleted if it exists).
set syndir_link "$topfile.pr-syn"
file delete -force $syndir_link
file link -symbolic $syndir_link $syndir

quit
