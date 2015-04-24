#
# Copyright (C) Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

open_hw_design axi_register_wrapper.vv-syn/top.sdk/top_wrapper.hdf
if { [ info exists ::env(DEVICETREEXLNX) ] && ( "x$::env(DEVICETREEXLNX)" != "x" ) } {
	set_repo_path $::env(DEVICETREEXLNX)
	create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
	generate_target -dir axi_register_wrapper.vv-syn/top.sdk/dts
} else {
	puts ""
	puts "**************************************************************"
	puts "DEVICETREEXLNX environment variable undefined. Plese define it"
	puts "and let it point to the device-tree-xlnx git repository. If"
	puts "needed first clone the git repository from:"
	puts "  http://github.com/Xilinx/device-tree-xlnx.git"
	puts "**************************************************************"
	puts ""
}
