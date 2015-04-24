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

# Cadence RC synthesis script. Please make rc-help for more information about the synthesis process.

# PATCH  TPT/PARIS
set_attribute lib_search_path "/comelec/stkits/cmos065_536/CORE65LPHVT_5.1/libs"

# First set 'rootdir' to the absolute path of the root directory of the project
if { [ info exists ::env(rootdir) ] && ( "x$::env(rootdir)" != "x" ) } {
	set rootdir [ file normalize $::env(rootdir) ]
} elseif { [ info exists ::env(ROOTDIR) ] && ( "x$::env(ROOTDIR)" != "x" ) } {
	set rootdir [ file normalize $::env(ROOTDIR) ]
} else {
	error "rootdir environment variable undefined"
}

# Toplevel source file:
if { [ info exists ::env(RC_SYN_TOP) ] && ( "x$::env(RC_SYN_TOP)" != "x" ) } {
	set topfile [ file rootname [ file tail $::env(RC_SYN_TOP) ] ]
} else {
	error "RC_SYN_TOP environment variable undefined"
}

# Toplevel entity name
if { [ info exists ::env(RC_SYN_TOPENTITY) ] && ( "x$::env(RC_SYN_TOPENTITY)" != "x" ) } {
	set topentity $::env(RC_SYN_TOPENTITY)
} else {
	set topentity $topfile
}

# If synthesis script exists, source it
if [ file exists "../$topfile.rsyn.tcl" ] {
	source "../$topfile.rsyn.tcl"
}

# Parameters that influence the synthesis flow and their default values
array set synthesis_options {
	period				1000
	input_delay			0
	output_delay			0
	hdl_parameter_naming_style	""
	driving_cell			*_AND2X4
	driving_pin			Z
	operating_conditions		_nominal_
	wireload_mode			top
	library		                CORE65LPHVT_nom_1.20V_25C.lib
	generics			{}
}

# Compute synthesis options with the TCL variable > environment variable > default priority.
foreach o [ array names synthesis_options ] {
	set oo rc_syn_$o
	set OO [ string toupper $oo ]
	if [ info exists $oo ] {
		eval "set synthesis_options($o) [ set $oo ]"
	} elseif [ info exists ::env($OO) ] {
		eval "set synthesis_options($o) $::env($OO)"
	}
}

# Set 'lib' to the VHDL library associated to the current source directory
set lib "[ file tail [ file dirname [ lpwd ] ] ]_lib"

set scriptsdir $rootdir/scripts
set srcrootdir $rootdir/src

source $scriptsdir/makedepends.tcl

# Target library
set_attribute library $synthesis_options(library)

# Prevent renaming of design names
set_attribute hdl_parameter_naming_style ""

# Preprocessing before HDL read
if { [ info procs preLoad ] eq "preLoad" } {
	preLoad
}

# Read HDL files
set modules [ exec ls $srcrootdir ]
foreach m $modules {
	eval "set Paths_g(${m}_lib) $srcrootdir/$m"
}
set frm "read_hdl -vhdl -library %2\$s %3\$s/%1\$s"
getDependencies {} [ list $lib.$topfile ]
#loadVHDLSources $lib.$topfile "$frm" "rc"
loadVHDLSources $lib.$topfile "$frm" 

# Postprocessing after HDL read
if { [ info procs postLoad ] eq "postLoad" } {
	postLoad
}

# Elaborate
if { [ llength $synthesis_options(generics) ] != 0 } {
	elaborate -parameters $synthesis_options(generics) $topentity
} else {
	elaborate $topentity
}

# Set design constraints
set_attribute external_driver [ find [ find / -libcell $synthesis_options(driving_cell) ] -libpin $synthesis_options(driving_pin) ] [ find / -port ports_in/* ]

# Set timing constraints
set clock_port_names [ clock_ports ]
if { [ string length "$clock_port_names" ] == 0 } {
	set clk1 [ define_clock -name virtual_clock -period $synthesis_options(period) -design $topentity ]
} else {
	set clock_port_tail_names {}
	foreach c $clock_port_names {
		set c [ file tail $c ]
		set_attribute external_driver "" [ find / -port $c ]
		lappend clock_port_tail_names $c
	}
	set clk1 [ define_clock -name virtual_clock -period $synthesis_options(period) -design $topentity $clock_port_tail_names ]
}
external_delay -clock $clk1 -input $synthesis_options(input_delay) -name in_con [ find / -port ports_in/* ]
external_delay -clock $clk1 -output $synthesis_options(output_delay) -name out_con [ find / -port ports_out/* ]

# Set operating conditions
set_attribute operating_conditions $synthesis_options(operating_conditions)

# Set wireload mode
set_attribute wireload_mode $synthesis_options(wireload_mode)

# Preprocessing before synthesis
if { [ info procs preSynthesis ] eq "preSynthesis" } {
	preSynthesis
}

# Synthesize
synthesize -to_mapped

# Postprocessing after synthesis
if { [ info procs postSynthesis ] eq "postSynthesis" } {
	postSynthesis
}

# Retiming
# retime -clock $clk1 -effort high -min_delay $topentity

# Reports
puts "--------------------------------------------------------------------------------"
puts "AREA REPORT"
report gates $topentity
puts "--------------------------------------------------------------------------------"
report gates $topentity > $topfile.area
puts "--------------------------------------------------------------------------------"
puts "TIMING REPORT"
report timing
puts "--------------------------------------------------------------------------------"
report timing > $topfile.timing

# Write output files
write_hdl $topentity > $topfile.v
write_script $topentity > $topfile.g

# Quit
quit
