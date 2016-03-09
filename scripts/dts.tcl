#
# Copyright (C) Telecom ParisTech
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

if { $argc != 3 } {
	puts "usage: hsi -mode batch -quiet -notrace -source dts.tcl -tclargs <hardware-description-file> <path-to-device-tree-xlnx> <local-device-tree-directory>"
} else {
	set hdf [lindex $argv 0]
	set xdts [lindex $argv 1]
	set ldts [lindex $argv 2]
	open_hw_design $hdf
	set_repo_path $xdts
	create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
	generate_target -dir $ldts
}
