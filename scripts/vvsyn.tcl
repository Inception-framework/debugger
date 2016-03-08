#
# Copyright (C) Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

if { [ info exists ::env(VVRELPATH) ] && ( "x$::env(VVRELPATH)" != "x" ) } {
	set VVRELPATH $::env(VVRELPATH)
} else {
	error "VVRELPATH environment variable undefined"
}
if { [ info exists ::env(HDLDIR) ] && ( "x$::env(HDLDIR)" != "x" ) } {
	set HDLDIR $::env(HDLDIR)
} else {
	error "HDLDIR environment variable undefined"
}
set HDLRELPATH $VVRELPATH/$HDLDIR

########################################
# Create IP with all VHDL source files #
########################################
create_project ip . -part xc7z010clg400-1
add_files $HDLRELPATH/axi_pkg.vhd $HDLRELPATH/debouncer.vhd $HDLRELPATH/utils.vhd $HDLRELPATH/sab4z.vhd
import_files -force -norecurse
ipx::package_project -root_dir . -vendor www.telecom-paristech.fr -library SAB4Z
close_project

############################
## Create top level design #
############################
create_project top . -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
set_property ip_repo_paths . [current_fileset]
update_ip_catalog
create_bd_design "top"
set ar [create_bd_cell -type ip -vlnv www.telecom-paristech.fr:SAB4Z:sab4z:1.0 sab4z]
set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $ps7
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50.000000}] $ps7
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1}] $ps7
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP1 {1}] $ps7
set_property -dict [list CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1}] $ps7
set_property -dict [list CONFIG.PCW_M_AXI_GP1_ENABLE_STATIC_REMAP {1}] $ps7
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] $ps7
set_property -dict [list CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32}] $ps7

# Interconnections
# Primary IOs
create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_pins /sab4z/led] [get_bd_ports led]
create_bd_port -dir I -from 3 -to 0 sw
connect_bd_net [get_bd_pins /sab4z/sw] [get_bd_ports sw]
create_bd_port -dir I btn
connect_bd_net [get_bd_pins /sab4z/btn] [get_bd_ports btn]
# ps7 - ip
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins sab4z/s0_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins sab4z/s1_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/sab4z/m_axi" Clk "Auto" }  [get_bd_intf_pins ps7/S_AXI_HP0]

# Addresses ranges
set_property offset 0x40000000 [get_bd_addr_segs ps7/Data/SEG_sab4z_reg0]
set_property range 1G [get_bd_addr_segs ps7/Data/SEG_sab4z_reg0]
set_property offset 0x80000000 [get_bd_addr_segs ps7/Data/SEG_sab4z_reg01]
set_property range 1G [get_bd_addr_segs {ps7/Data/SEG_sab4z_reg01}]
set_property offset 0x00000000 [get_bd_addr_segs [list sab4z/m_axi/SEG_ps7_HP0_DDR_LOWOCM]]
set_property range 1G [get_bd_addr_segs [list sab4z/m_axi/SEG_ps7_HP0_DDR_LOWOCM]]

# Synthesis flow
validate_bd_design
generate_target all [get_files top.srcs/sources_1/bd/top/top.bd]
make_wrapper -files [get_files top.srcs/sources_1/bd/top/top.bd] -top
add_files -norecurse -force top.srcs/sources_1/bd/top/hdl/top_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
save_bd_design
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
launch_runs synth_1
wait_on_run synth_1
open_run synth_1 -name netlist_1

# IOs
array set ios {
	"sw[0]"		{ "G15" "LVCMOS33" }
	"sw[1]"		{ "P15" "LVCMOS33" }
	"sw[2]"		{ "W13" "LVCMOS33" }
	"sw[3]"		{ "T16" "LVCMOS33" }
	"led[0]"	{ "M14" "LVCMOS33" }
	"led[1]"	{ "M15" "LVCMOS33" }
	"led[2]"	{ "G14" "LVCMOS33" }
	"led[3]"	{ "D18" "LVCMOS33" }
	"btn"		{ "R18" "LVCMOS33" }
}
foreach io [ array names ios ] {
	set pin [ lindex $ios($io) 0 ]
	set std [ lindex $ios($io) 1 ]
	set_property package_pin $pin [get_ports $io]
	set_property iostandard $std [get_ports [list $io]]
}

# Timing constraints
set_false_path -from [get_clocks {clk_fpga_0}] -to [get_ports {led[*]}]
set_false_path -from [get_ports {btn sw[*]}] -to [get_clocks {clk_fpga_0}]

save_bd_design
save_constraints
reset_run impl_1
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
