#
# Copyright (C) Telecom ParisTech
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

if { $argc != 2 } {
	puts "usage: hsi -mode batch -quiet -notrace -source fsbl.tcl -tclargs <hardware-description-file> <fsbl-build-directory>"
} else {
	set hdf [lindex $argv 0]
	set dir [lindex $argv 1]
	set design [ open_hw_design ${hdf} ]
	generate_app -hw $design -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -sw fsbl -dir ${dir}
}
