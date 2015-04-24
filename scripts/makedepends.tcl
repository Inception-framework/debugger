#!/usr/bin/tclsh

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

# This TCL source file defines a set of procedures to manage the dependencies between VHDL source files for logic synthesis.

# All string comparisons are case insensitive unless otherwise specified. Uppercase procedure parameters are passed by name. Lowercase parameters are passed by
# value. Lowercase variable names with a leading uppercase letter are arrays. Global variable names end with _g. Violated 'MUST' specifications raise errors.

# Debug flag
# 0: no debug
# 1: instead of eveluating them, print commands
# 2: same as 1 plus print procedure calls
set degug_g 0

# Name of dependencies files
set dependenciesfilename_g "dependencies.txt"

# If du is normalized, LIB.NAME<-du and true is returned. Else, LIB.NAME<-"".du and false is returned.
proc du2libname {du LIB NAME} {
	global degug_g

	if { $degug_g > 1 } {
		puts "du2libname $du $LIB $NAME"
	}

	upvar $LIB lib
	upvar $NAME name
	set lib ""
	set name $du
	return [ regexp {(.*)\.(.*)} $du dummy lib name ]
}

# Adds normalized design unit names as keys of the global array Nosyn_g of non-synthesizable design units. $l is the default library name to be used for
# normalization of non normalized design unit names. $deps is a list of design units (normalized or not). If normalized, their containing library MUST be $l.
# Each design unit name in $deps is normalized and added as a key to the array Nosyn_g. This command is called when parsing library-specific dependencies files
# and a '.NOSYN' target is encountered.
proc nosyn {l deps} {
	global Nosyn_g
	global degug_g

	if { $degug_g > 1 } {
		puts "nosyn $l \{$deps\}"
	}

	foreach d $deps {
		if ![ du2libname $d lib name ] {
			set d $l.$d
		} elseif [ string compare $l $lib ] {
			error "nosyn $l \{$deps\}: library names mismatch ($l, $lib)"
		}
		set Nosyn_g($d) 1
	}
}

# Adds a list of normalized design unit names to the dependencies of a design unit. $l is the default library name to be used for normalization of non
# normalized design unit names. $d is the top design unit and $deps is a list of design units $d depends on. If $d is normalized, its containing library MUST be
# $l. d and deps are first normalized. Then, for each design unit name in $deps, if it is not already in the $Dependencies_g($d) list, it is appended to
# Dependencies_g($d). The global array Libtodo_g is also updated by inserting as a new key each encountered library name that is not already a key of the global
# array Libdone_g. This command is called when parsing library-specific dependencies files and a regular (not .NOSYN) target is encountered. It can be used to
# recursively walk through the whole project and build the dependencies global array.
proc dep {l d deps} {
	global Dependencies_g
	global Libdone_g
	global Libtodo_g
	global degug_g

	if { $degug_g > 1 } {
		puts "dep $l $d \{$deps\}"
	}

	# If $d is .NOSYN...
	if ![ string compare $d ".NOSYN" ] {
		nosyn $l $deps
		return
	}
	# If $d normalized...
	if [ du2libname $d lib name ] {
		# ...but containing library is not $l...
		if [ string compare $l $lib ] {
			error "dep $l $d \{$deps\}: library names mismatch ($l, $lib)"
		}
	} else {
		set d $l.$d
	}
	# If there is yet no dependencies for $d...
	if ![ info exists Dependencies_g($d) ] {
		set Dependencies_g($d) {}
	}
	foreach x $deps {
		set x [ string trim $x ]
		# If $x normalized...
		if [ du2libname $x lib n ] {
			# ...containing library is EXTERN...
			if ![ string compare "EXTERN" $lib ] {
				continue
			}
			# ...has a different containing library than $l and this library has not yet been processed...
			if { [ string compare $l $lib ] && ![ info exists Libdone_g($lib) ] } {
				# Mark library as to be done
				set Libtodo_g($lib) 1
			}
		} else {
			set x $l.$x
		}
		# If $x is not already in $d's dependencies...
		if { [ lsearch -exact Dependencies_g($d) $x ] < 0 } {
			# Add $x to $d's dependency list
			lappend Dependencies_g($d) $x
		}
	}
}

# Parse a dependencies file in Makefile format. $l is the default library name to be used for normalization of non normalized design unit names. $f is the path
# to the dependencies file. l shall be set to the library name corresponding to the source directory in which the $f dependencies file is stored. For each
# dependency encountered during the parsing, dep is called.
proc parseDependenciesFile {l f} {
	global degug_g

	if { $degug_g > 1 } {
		puts "parseDependenciesFile $l $f"
	}

	if ![ file exists $f ] {
		error "parseDependenciesFile $l $f: could not open $f."
	}

	set fd [ open $f r ]
	set state "init"
	set n 0
#	puts "parseDependenciesFile $l $f"
	while { [ gets $fd line ] >= 0 } {
		incr n
		# Delete comments
		regsub {([^#]*)#.*} $line {\1} line
		# Delete leading and trailing spaces
		regsub {^[ \t]*} $line {} line
		regsub {[ \t]*$} $line {} line
		# Skip empty lines
		if { [ string length $line ] == 0 } {
			continue
		}
		# If start of a dependency definition
		if { $state == "init" && [ regexp {(.*):(.*)} $line dummy d deps ] } {
			if [ regsub {(.*)(\\$)} $deps {\1} deps ] {
				set state "cont"
			}
		} elseif { $state == "cont" } {
			if ![ regsub {(.*)(\\$)} $line {\1} line ] {
				set state "init"
			}
			set deps [ concat $deps $line ]
		} else {
			error "$f:$n syntax error"
		}
		if { $state == "init" } {
			set d [ string trim $d ]
			dep $l $d $deps
		}
	}
	if { $state != "init" } {
		error "$f:$n: unexpected end of file"
	}
	close $fd
}

# Collates all dependencies from a list of libraries ($libs) and a list of normalized design units ($dus). Recursively searches the source directories for
# dependencies files and parses them, until no new library is discovered. This procedure is the topmost one for dependencies building: it initializes the
# Nosyn_g and Dependencies_g global variables. It depends on the Paths_g global variable which MUST be initialized prior calling getDependencies. The keys of
# Paths_g are library names and the values are absolute paths to the source directories of the libraries:
#   set Paths_g(fep_lib) /home/johndoe/src/fep
# Example of use to build all dependencies for libraries foo_lib and bar_lib and for the myLib.myDu design unit:
#   set Paths_g(foo_lib) /home/johndoe/src/foo
#   set Paths_g(bar_lib) /home/johndoe/src/bar
#   set Paths_g(myLib_lib) /home/johndoe/src/myLib
#   ...
#   getDependencies { foo_lib bar_lib } { myLib.myDu }
# Example of use to build all dependencies for the myLib.myDu design unit:
#   set Paths_g(myLib_lib) /home/johndoe/src/myLib
#   ...
#   getDependencies {} { myLib.myDu }
proc getDependencies { { libs {} } { dus {} } } {
	global Paths_g
	global Libdone_g
	global Libtodo_g
	global dependenciesfilename_g
	global degug_g

	if { $degug_g > 1 } {
		puts "getDependencies \{$libs\} \{$dus\}"
	}

	foreach l $libs {
		if ![ info exists Libdone_g($l) ] {
			# If source directory of library $l is not defined...
			if ![ info exists Paths_g($l) ] {
				error "getDependencies \{$libs\} \{$dus\}: source directory of library $l is undefined"
			}
			set path $Paths_g($l)
			set Libdone_g($l) 1
			# If there is a $dependenciesfilename_g file in $l's source directory...
			if [ file exists $path/$dependenciesfilename_g ] {
				parseDependenciesFile $l $path/$dependenciesfilename_g
			}
		}
	}
	foreach d $dus {
		if ![ du2libname $d l n ] {
			error "getDependencies \{$libs\} \{$dus\}: $d should be normalized"
		}
		if ![ info exists Libdone_g($l) ] {
			# If source directory of library $l is not defined...
			if ![ info exists Paths_g($l) ] {
				error "getDependencies \{$libs\} \{$dus\}: source directory of library $l is undefined"
			}
			set path $Paths_g($l)
			set Libdone_g($l) 1
			# If there is a $dependenciesfilename_g file in $l's source directory...
			if [ file exists $path/$dependenciesfilename_g ] {
				parseDependenciesFile $l $path/$dependenciesfilename_g
			}
		}
	}
	while { [ array size Libtodo_g ] > 0 } {
		foreach l [ array names Libtodo_g ] {
			if [ info exists Libdone_g($l) ] {
				unset Libtodo_g($l)
			}
		}
		if [ array size Libtodo_g ] {
			getDependencies [ array names Libtodo_g ]
		}
	}
}

# Removes normalized design unit $du from all dependencies. Deletes empty dependencies. Deletes $du's dependency definition if any.
proc prune {du} {
	global Dependencies_g
	global degug_g

	if { $degug_g > 1 } {
		puts "prune $du"
	}

	if ![ du2libname $du l n ] {
		error "prune $du: $du should be normalized"
	}
	foreach d [ array names Dependencies_g ] {
		while { [ set idx [ lsearch -exact $Dependencies_g($d) $du ] ] >= 0 } {
			# Delete $du from $d's dependencies
			set Dependencies_g($d) [ lreplace $Dependencies_g($d) $idx $idx ]
		}
		# If $d's dependency list empty...
		if { [ llength $Dependencies_g($d) ] == 0 } {
			# Delete $d's dependency list
			unset Dependencies_g($d)
		}
	}
	# If $du has a dependency list...
	if [ info exists Dependencies_g($du) ] {
		# Delete $du's dependency list
		unset Dependencies_g($du)
	}
}

# Loads all dependencies of design unit $du in a monotonic order: each unit depending on another is guaranteed to be loaded after its dependency. $du MUST be
# normalized. Dependencies are loaded by evaluating a string built with the $frm formatting string which can refer to 3 different fields:
#
# - design unit's name
# - design unit's library
# - path to directory containing design unit's source file
#
# loadVHDLSources builds, consumes and destroys the Dependencies_g global variable. It also uses the Paths_g global variable that must be initialized with the
# paths of the source directories of all libraries $du depends on, either directly or indirectly. Example of use to load all dependencies of design unit
# fep_lib.fep with Mentor Graphics' Precision RTL (note that the monotonic order is not relevant for Precision RTL as it is capable of reordering):
#
#   set Paths_g(global_lib) /home/johndoe/src/global
#   set Paths_g(random_lib) /home/johndoe/src/random
#   ...
#   set Paths_g(fep_lib) /home/johndoe/src/fep
#   loadVHDLSources fep_lib.fep 'add_input_file -work %2$s %3$s/%1$s.vhd'
#
# This should evaluate the following commands:
#
#   add_input_file -work global_lib /home/johndoe/src/global/numeric_std.vhd
#   add_input_file -work global_lib /home/johndoe/src/global/global.vhd
#   ...
#   add_input_file -work fep_lib /home/johndoe/src/fep/rams.vhd
#   add_input_file -work fep_lib /home/johndoe/src/fep/fep.vhd
#
# Note: the format string for Cadence RC would be 'read_hdl -vhdl -top fep -library %2$s %3$s/%1$s.vhd' and the monotonic order would be important because
# Cadence RC does not reorder. With the same definitions as for Precision RTL and:
#
#   loadVHDLSources fep_lib.fep 'add_input_file -work %2$s %3$s/%1$s.vhd'
#
# the result should be:
#
#   read_hdl -vhdl -top fep -library global_lib /home/johndoe/src/global/numeric_std.vhd
#   read_hdl -vhdl -top fep -library global_lib /home/johndoe/src/global/global.vhd
#   ...
#   read_hdl -vhdl -top fep -library fep_lib /home/johndoe/src/fep/rams.vhd
#   read_hdl -vhdl -top fep -library fep_lib /home/johndoe/src/fep/fep.vhd

proc loadVHDLSources {du frm} {
	global Dependencies_g
	global Paths_g
	global Nosyn_g
	global degug_g

	if { $degug_g > 1 } {
		puts "loadVHDLSources $du $frm"
	}

	if ![ du2libname $du l n ] {
		error "loadVHDLSources $du $frm: $du should be normalized"
	}
	if { ![ info exists Nosyn_g($du) ] } {
		if [ info exists Dependencies_g($du) ] {
			while { [ info exists Dependencies_g($du) ] && [ llength $Dependencies_g($du) ] != 0 } {
				loadVHDLSources [ lindex $Dependencies_g($du) 0 ] $frm
			}
		}
		if ![ info exists Paths_g($l) ] {
			error "loadVHDLSources $du $frm: source directory of library $l is undefined"
		}
		set n [ format "%s.vhd" $n ]
		set cmd [ format "$frm" $n $l $Paths_g($l) ]
		puts $cmd
		if !$degug_g {
			eval $cmd
		}
	}
	prune $du
}

# Builds the DUSpecs_g ordered array, indexed from 0 to length-1, of design units specifications. The order is "dependencies before dependent": if design unit X
# depends on design unit Y, X is guaranteed to have a larger index than Y in the returned array. Design unit specifications are {F, L, P} lists where:
# - F is the source file's name
# - L is the name of the library in which F must be analyzed
# - P is the path of the directory where the F source file can be found
proc VHDLDependencies {du} {
	global DUSpecs_g

	if [ array exists DUSpecs_g ] {
		unset DUSpecs_g
	}
	VHDLDependencies_recurse $du
}

proc VHDLDependencies_recurse {du} {
	global DUSpecs_g
	global Dependencies_g
	global Paths_g
	global Nosyn_g
	global degug_g

	if { $degug_g > 1 } {
		puts "VHDLDependencies_recurse $du"
	}

	if ![ du2libname $du l n ] {
		error "VHDLDependencies_recurse $du: $du should be normalized"
	}
	if { ![ info exists Nosyn_g($du) ] } {
		if [ info exists Dependencies_g($du) ] {
			while { [ info exists Dependencies_g($du) ] && [ llength $Dependencies_g($du) ] != 0 } {
				VHDLDependencies_recurse [ lindex $Dependencies_g($du) 0 ]
			}
		}
		if ![ info exists Paths_g($l) ] {
			error "VHDLDependencies_recurse $du: source directory of library $l is undefined"
		}
		set n [ format "%s.vhd" $n ]
		set spec [ list $n $l $Paths_g($l) ]
		puts $spec
		if { ![ array exists DUSpecs_g ] } {
			set DUSpecs_g(0) $spec;
		} else {
			set x [ array size DUSpecs_g ]
			set DUSpecs_g($x) $spec;
		}
	}
	prune $du
}
