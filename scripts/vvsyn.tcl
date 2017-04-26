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
create_project -part xc7z020clg484-1 -force sab4z sab4z
set sources { axi_pkg inception_pkg sab4z inception JTAG_Ctrl_Master debouncer fifo_ram }
foreach f $sources {
	add_files $rootdir/hdl/$f.vhd
}
import_files -force -norecurse
ipx::package_project -root_dir sab4z -vendor www.telecom-paristech.fr -library SAB4Z -force sab4z
close_project

############################
## Create top level design #
############################
set top top
create_project -part xc7z020clg484-1 -force $top .
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
set_property ip_repo_paths { ./sab4z } [current_fileset]
update_ip_catalog
create_bd_design "$top"
set sab4z [create_bd_cell -type ip -vlnv [get_ipdefs *www.telecom-paristech.fr:SAB4Z:sab4z:*] sab4z]
set ps7 [create_bd_cell -type ip -vlnv [get_ipdefs *xilinx.com:ip:processing_system7:*] ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $ps7
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] $ps7
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1}] $ps7
set_property -dict [list CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1}] $ps7

# Interconnections

# IRQ
create_bd_port -dir I irq_in
connect_bd_net [get_bd_pins /sab4z/irq_in] [get_bd_ports irq_in]
create_bd_port -dir O irq_ack
connect_bd_net [get_bd_pins /sab4z/irq_ack] [get_bd_ports irq_ack]

# JTAG ctlr master
create_bd_port -dir O TCK
connect_bd_net [get_bd_pins /sab4z/TCK] [get_bd_ports TCK]

create_bd_port -dir O TRST
connect_bd_net [get_bd_pins /sab4z/TRST] [get_bd_ports TRST]

create_bd_port -dir I TDO
connect_bd_net [get_bd_pins /sab4z/TDO] [get_bd_ports TDO]

create_bd_port -dir O TMS
connect_bd_net [get_bd_pins /sab4z/TMS] [get_bd_ports TMS]

create_bd_port -dir O TDI
connect_bd_net [get_bd_pins /sab4z/TDI] [get_bd_ports TDI]

# Slave FIFO
create_bd_port -dir O clk_out
connect_bd_net [get_bd_pins /sab4z/clk_out] [get_bd_ports clk_out]

create_bd_port -dir IO -from 31 -to 0 fdata
connect_bd_net [get_bd_pins /sab4z/fdata] [get_bd_ports fdata]

create_bd_port -dir O -from 1 -to 0 sladdr
connect_bd_net [get_bd_pins /sab4z/sladdr] [get_bd_ports sladdr]

create_bd_port -dir O sloe
connect_bd_net [get_bd_pins /sab4z/sloe] [get_bd_ports sloe]

create_bd_port -dir O slop
connect_bd_net [get_bd_pins /sab4z/slop] [get_bd_ports slop]

create_bd_port -dir I slwr_rdy
connect_bd_net [get_bd_pins /sab4z/slwr_rdy] [get_bd_ports slwr_rdy]

create_bd_port -dir I slwrirq_rdy
connect_bd_net [get_bd_pins /sab4z/slwrirq_rdy] [get_bd_ports slwrirq_rdy]

create_bd_port -dir I slrd_rdy
connect_bd_net [get_bd_pins /sab4z/slrd_rdy] [get_bd_ports slrd_rdy]

# Primary IOs
create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_pins /sab4z/led] [get_bd_ports led]
create_bd_port -dir O -from 3 -to 0 jtag_state_led
connect_bd_net [get_bd_pins /sab4z/jtag_state_led] [get_bd_ports jtag_state_led]
create_bd_port -dir I -from 3 -to 0 sw
connect_bd_net [get_bd_pins /sab4z/sw] [get_bd_ports sw]
create_bd_port -dir I btn1
connect_bd_net [get_bd_pins /sab4z/btn1] [get_bd_ports btn1]
create_bd_port -dir I btn2
connect_bd_net [get_bd_pins /sab4z/btn2] [get_bd_ports btn2]

# ps7 - sab4z
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins /sab4z/s0_axi]

# Addresses ranges
set_property offset 0x40000000 [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]
set_property range 1G [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]

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
	"sw[0]"         { "F22"  "LVCMOS25" }
	"sw[1]"         { "G22"  "LVCMOS25" }
	"sw[2]"         { "H22"  "LVCMOS25" }
	"sw[3]"         { "F21"  "LVCMOS25" }
	"led[0]"        { "T22"  "LVCMOS33" }
	"led[1]"        { "T21"  "LVCMOS33" }
	"led[2]"        { "U22"  "LVCMOS33" }
	"led[3]"        { "U21"  "LVCMOS33" }
	"jtag_state_led[3]"   { "U14"  "LVCMOS33" }
	"jtag_state_led[2]"   { "U19"  "LVCMOS33" }
	"jtag_state_led[1]"   { "W22"  "LVCMOS33" }
	"jtag_state_led[0]"   { "V22"  "LVCMOS33" }
	"btn1"           { "T18"  "LVCMOS25" }
	"btn2"           { "R16"  "LVCMOS25" }
        "clk_out"       { "M19"  "LVCMOS25" }
        "sloe"          { "G21"  "LVCMOS25" }
        "slop"          { "G20"  "LVCMOS25" }
        "slwr_rdy"      { "F19"  "LVCMOS25" }
        "slwrirq_rdy"   { "K21"  "LVCMOS25" }
        "slrd_rdy"      { "C22"  "LVCMOS25" }
        "sladdr[0]"     { "B21"  "LVCMOS25" }
        "sladdr[1]"     { "B22"  "LVCMOS25" }
        "fdata[0]"      { "L18"  "LVCMOS25" }
        "fdata[1]"      { "P17"  "LVCMOS25" }
        "fdata[2]"      { "P18"  "LVCMOS25" }
        "fdata[3]"      { "M21"  "LVCMOS25" }
        "fdata[4]"      { "M22"  "LVCMOS25" }
        "fdata[5]"      { "T16"  "LVCMOS25" }
        "fdata[6]"      { "T17"  "LVCMOS25" }
        "fdata[7]"      { "N17"  "LVCMOS25" }
        "fdata[8]"      { "N18"  "LVCMOS25" }
        "fdata[9]"      { "J16"  "LVCMOS25" }
        "fdata[10]"     { "J17"  "LVCMOS25" }
        "fdata[11]"     { "G15"  "LVCMOS25" }
        "fdata[12]"     { "G16"  "LVCMOS25" }
        "fdata[13]"     { "E19"  "LVCMOS25" }
        "fdata[14]"     { "E20"  "LVCMOS25" }
        "fdata[15]"     { "A18"  "LVCMOS25" }
        "fdata[16]"     { "A19"  "LVCMOS25" }
        "fdata[17]"     { "A16"  "LVCMOS25" }
        "fdata[18]"     { "A17"  "LVCMOS25" }
        "fdata[19]"     { "C15"  "LVCMOS25" }
        "fdata[20]"     { "B15"  "LVCMOS25" }
        "fdata[21]"     { "A21"  "LVCMOS25" }
        "fdata[22]"     { "A22"  "LVCMOS25" }
        "fdata[23]"     { "D18"  "LVCMOS25" }
        "fdata[24]"     { "C19"  "LVCMOS25" }
        "fdata[25]"     { "N22"  "LVCMOS25" }
        "fdata[26]"     { "P22"  "LVCMOS25" }
        "fdata[27]"     { "J21"  "LVCMOS25" }
        "fdata[28]"     { "J22"  "LVCMOS25" }
        "fdata[29]"     { "P20"  "LVCMOS25" }
        "fdata[30]"     { "P21"  "LVCMOS25" }
        "fdata[31]"     { "J20"  "LVCMOS25" }
        "TDI"           { "Y11"  "LVCMOS25" }
        "TRST"          { "AA8"  "LVCMOS25" }
        "TMS"           { "AA11"  "LVCMOS25" }
        "TCK"           { "Y10"  "LVCMOS25" }
        "TDO"           { "AA9"  "LVCMOS25" }
        "irq_in"        { "AB9"  "LVCMOS25" }
        "irq_ack"       { "AB10"  "LVCMOS25" }
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
set_false_path -from $clock -to [get_ports {jtag_state_led[*]}]
set_false_path -from [get_ports {btn1 btn2 irq_in sw[*]}] -to $clock

create_generated_clock -source [get_pins -hierarchical sab4z/aclk] -master_clock [get_clocks] -add -name clk_out [get_ports clk_out] -edges {2 3 4}

set clock [get_clocks clk_fpga_0]
set_input_delay -clock $clock 2 [get_ports TDO]
set_output_delay -clock $clock 1 [get_ports TCK]
set_output_delay -clock $clock 1 [get_ports TRST]
set_output_delay -clock $clock 1 [get_ports TMS]
set_output_delay -clock $clock 1 [get_ports TDI]
set_output_delay -clock $clock 1 [get_ports irq_ack]
set_input_delay -clock $clock 1 [get_ports fdata]
set_input_delay -clock $clock 1 [get_ports slwr_rdy]
set_input_delay -clock $clock 1 [get_ports slwrirq_rdy]
set_input_delay -clock $clock 1 [get_ports slrd_rdy]

#set clock [get_clocks clk_out]
set_output_delay -clock $clock 1 [get_ports fdata]
set_output_delay -clock $clock 1 [get_ports slop]
set_output_delay -clock $clock 1 [get_ports sloe]
set_output_delay -clock $clock 1 [get_ports sladdr]


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

