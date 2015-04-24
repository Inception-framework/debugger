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

# Vivado synthesis script. Please make vv-help for more information about the synthesis process.

# First set 'rootdir' to the absolute path of the root directory of the project
if { [ info exists ::env(rootdir) ] && ( "x$::env(rootdir)" != "x" ) } {
	set rootdir [ file normalize $::env(rootdir) ]
} elseif { [ info exists ::env(ROOTDIR) ] && ( "x$::env(ROOTDIR)" != "x" ) } {
	set rootdir [ file normalize $::env(ROOTDIR) ]
} else {
	error "rootdir environment variable undefined"
}

# Toplevel source file:
if { [ info exists ::env(VV_SYN_TOP) ] && ( "x$::env(VV_SYN_TOP)" != "x" ) } {
	set topfile [ file rootname [ file tail $::env(VV_SYN_TOP) ] ]
} else {
	error "VV_SYN_TOP environment variable undefined"
}

# Toplevel entity name
if { [ info exists ::env(VV_SYN_TOPENTITY) ] && ( "x$::env(VV_SYN_TOPENTITY)" != "x" ) } {
	set topentity $::env(VV_SYN_TOPENTITY)
} else {
	set topentity $topfile
}

set scriptsdir $rootdir/scripts
set srcrootdir $rootdir/src
source $scriptsdir/makedepends.tcl

# If synthesis script exists, source it
if [ file exists "../$topfile.vsyn.tcl" ] {
	source "../$topfile.vsyn.tcl"
} elseif [ file exists "$scriptsdir/vv-default.tcl" ] {
	source "$scriptsdir/vv-default.tcl"
}

# quit
