#
# Copyright (C) Telecom ParisTech
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

proc usage {} {
	puts "usage: vivado -mode batch -source <script> -tclargs <rootdir> <builddir> \[<ila>\]"
	puts "  <rootdir>:  absolute path of sab4z root directory"
	puts "  <builddir>: absolute path of build directory"
	puts "  <ila>:      embed Integrated Logic Analyzer (0 or 1, default 0)"
	exit -1
}

if { $argc == 3 } {
	set rootdir [lindex $argv 0]
	set builddir [lindex $argv 1]
	set ila [lindex $argv 2]
	if { $ila != 0 && $ila != 1 } {
		usage
	}
} else {
	usage
}

cd $builddir
source $rootdir/scripts/ila.tcl

###################
# Create SAB4Z IP #
###################
create_project -part xc7z010clg400-1 -force sab4z sab4z
add_files $rootdir/hdl/axi_pkg.vhd $rootdir/hdl/debouncer.vhd $rootdir/hdl/sab4z.vhd
import_files -force -norecurse
ipx::package_project -root_dir sab4z -vendor www.telecom-paristech.fr -library SAB4Z -force sab4z
close_project

############################
## Create top level design #
############################
set top top
create_project -part xc7z010clg400-1 -force $top .
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
set_property ip_repo_paths { ./sab4z } [current_fileset]
update_ip_catalog
create_bd_design "$top"
set sab4z [create_bd_cell -type ip -vlnv [get_ipdefs *www.telecom-paristech.fr:SAB4Z:sab4z:*] sab4z]
set ps7 [create_bd_cell -type ip -vlnv [get_ipdefs *xilinx.com:ip:processing_system7:*] ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $ps7
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] $ps7
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
# ps7 - sab4z
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins /sab4z/s0_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins /sab4z/s1_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/sab4z/m_axi" Clk "Auto" }  [get_bd_intf_pins /ps7/S_AXI_HP0]

# Addresses ranges
set_property offset 0x40000000 [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]
set_property range 1G [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]
set_property offset 0x80000000 [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP1]]
set_property range 1G [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP1]]
set_property offset 0x00000000 [get_bd_addr_segs -of_object [get_bd_intf_pins /sab4z/m_axi]]
set_property range 1G [get_bd_addr_segs -of_object [get_bd_intf_pins /sab4z/m_axi]]

# In-circuit debugging
if { $ila == 1 } {
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_intf_nets -of_objects [get_bd_intf_pins /sab4z/m_axi]]
}

# Synthesis flow
validate_bd_design
set files [get_files *$top.bd]
generate_target all $files
add_files -norecurse -force [make_wrapper -files $files -top]
save_bd_design
set run [get_runs synth*]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none $run
launch_runs $run
wait_on_run $run
open_run $run

# In-circuit debugging
if { $ila == 1 } {
	set topcell [get_cells $top*]
	set nets {}
	set suffixes {
		ARID ARADDR ARLEN ARSIZE ARBURST ARLOCK ARCACHE ARPROT ARQOS ARVALID
		RREADY
		AWID AWADDR AWLEN AWSIZE AWBURST AWLOCK AWCACHE AWPROT AWQOS AWVALID
		WID WDATA WSTRB WLAST WVALID
		BREADY
		ARREADY
		RID RDATA RRESP RLAST RVALID
		AWREADY
		WREADY
		BID BRESP BVALID
	}
	foreach suffix $suffixes {
		lappend nets $topcell/sab4z_m_axi_${suffix}
	}
	add_ila_core dc $topcell/ps7_FCLK_CLK0 $nets
}

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
set clock [get_clocks]
set_false_path -from $clock -to [get_ports {led[*]}]
set_false_path -from [get_ports {btn sw[*]}] -to $clock

# Implementation
save_constraints
set run [get_runs impl*]
reset_run $run
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true $run
launch_runs -to_step write_bitstream $run
wait_on_run $run

# Messages
set rundir ${builddir}/$top.runs/$run
puts ""
puts "\[VIVADO\]: done"
puts "  bitstream in $rundir/${top}_wrapper.bit"
puts "  resource utilization report in $rundir/${top}_wrapper_utilization_placed.rpt"
puts "  timing report in $rundir/${top}_wrapper_timing_summary_routed.rpt"
