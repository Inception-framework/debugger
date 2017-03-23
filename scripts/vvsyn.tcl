##
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
add_files $rootdir/hdl/axi_pkg.vhd $rootdir/hdl/debouncer.vhd $rootdir/hdl/sab4z.vhd
set sources { JTAG_Ctrl_Master fifo slaveFIFO2b_loopback slaveFIFO2b_streamIN slaveFIFO2b_ZLP slaveFIFO2b_fpga_top slaveFIFO2b_partial slaveFIFO2b_streamOUT axi_pkg debouncer inception sab4z }
foreach f $sources {
	add_files $rootdir/hdl/SlaveFIFO2b/$f.vhd
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
set_property ip_repo_paths { ./slaveFIFO2b_fpga_top ./sab4z } [current_fileset]
update_ip_catalog
create_bd_design "$top"

set slave_fifo [create_bd_cell -type ip -vlnv [get_ipdefs *www.telecom-paristech.fr:SAB4Z:slaveFIFO2b_fpga_top:*] slave_fifo]

set sab4z [create_bd_cell -type ip -vlnv [get_ipdefs *www.telecom-paristech.fr:SAB4Z:sab4z:*] sab4z]
set ps7 [create_bd_cell -type ip -vlnv [get_ipdefs *xilinx.com:ip:processing_system7:*] ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $ps7
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] $ps7
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1}] $ps7
set_property -dict [list CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1}] $ps7

# Interconnections
# Primary IOs
create_bd_port -dir O -from 3 -to 0 led
connect_bd_net [get_bd_pins /sab4z/led] [get_bd_ports led]
create_bd_port -dir I -from 3 -to 0 sw
connect_bd_net [get_bd_pins /sab4z/sw] [get_bd_ports sw]
create_bd_port -dir I btn1
connect_bd_net [get_bd_pins /sab4z/btn1] [get_bd_ports btn1]
create_bd_port -dir I btn2
connect_bd_net [get_bd_pins /sab4z/btn2] [get_bd_ports btn2]

connect_bd_net [get_bd_pins slave_fifo/aclk] [get_bd_pins ps7/FCLK_CLK0]

create_bd_port -dir IO -from 31 -to 0 fdata
connect_bd_net [get_bd_pins /slave_fifo/fdata] [get_bd_ports fdata]

create_bd_port -dir O -from 1 -to 0 faddr
connect_bd_net [get_bd_pins /slave_fifo/faddr] [get_bd_ports faddr]

create_bd_port -dir O clk_out
connect_bd_net [get_bd_pins /slave_fifo/clk_out] [get_bd_ports clk_out]
#connect_bd_net [get_bd_ports clk_out] [get_bd_pins ps7/FCLK_CLK0]

create_bd_port -dir O slcs
connect_bd_net [get_bd_pins /slave_fifo/slcs] [get_bd_ports slcs]

create_bd_port -dir O slrd
connect_bd_net [get_bd_pins /slave_fifo/slrd] [get_bd_ports slrd]

create_bd_port -dir O sloe
connect_bd_net [get_bd_pins /slave_fifo/sloe] [get_bd_ports sloe]

create_bd_port -dir O slwr
connect_bd_net [get_bd_pins /slave_fifo/slwr] [get_bd_ports slwr]

create_bd_port -dir O pktend
connect_bd_net [get_bd_pins /slave_fifo/pktend] [get_bd_ports pktend]

create_bd_port -dir I flaga
connect_bd_net [get_bd_pins /slave_fifo/flaga] [get_bd_ports flaga]

create_bd_port -dir I flagb
connect_bd_net [get_bd_pins /slave_fifo/flagb] [get_bd_ports flagb]

create_bd_port -dir I flagc
connect_bd_net [get_bd_pins /slave_fifo/flagc] [get_bd_ports flagc]

create_bd_port -dir I flagd
connect_bd_net [get_bd_pins /slave_fifo/flagd] [get_bd_ports flagd]

create_bd_port -dir I -from 2 -to 0 mode_p
connect_bd_net [get_bd_pins /slave_fifo/mode_p] [get_bd_ports mode_p]

# ps7 - sab4z
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins /sab4z/s0_axi]


connect_bd_net [get_bd_pins slave_fifo/aresetn] [get_bd_pins rst_ps7_100M/peripheral_aresetn]
#connect_bd_net [get_bd_pins slave_fifo/aresetn] [get_bd_pins ps7/FCLK_RESET0_N]

# Addresses rangesf
set_property offset 0x40000000 [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]
set_property range 1G [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]

# In-circuit debugging
if { $ila == 1 } {
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports clk_out]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports fdata]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports faddr]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports flaga]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports flagb]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports flagc]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports flagd]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports slcs]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports slrd]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports sloe]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports slwr]
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_ports pktend]
}


# Synthesis flow
validate_bd_design
set files [get_files *$top.bd]
generate_target all $files
add_files -norecurse -force [make_wrapper -files $files -top]
save_bd_design
set run [get_runs synth*]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY full $run
launch_runs $run
wait_on_run $run
open_run $run

# In-circuit debugging
if { $ila == 1 } {
	set topcell [get_cells $top*]
	set nets {}
	set suffixes {
		clk_out fdata faddr flaga flagb flagc flagd slcs slrd sloe slwr pktend
	}
	foreach suffix $suffixes {
		lappend nets $topcell/slave_fifo/${suffix}
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
	"btn1"           { "T18"  "LVCMOS25" }
	"btn2"           { "TR16"  "LVCMOS25" }
        "clk_out"       { "M19"  "LVCMOS25" }
        "sloe"          { "G21"  "LVCMOS25" }
        "slcs"          { "K21"  "LVCMOS25" }
        "slwr"          { "G20"  "LVCMOS25" }
        "slrd"          { "G19"  "LVCMOS25" }
        "pktend"        { "C17"  "LVCMOS25" }
        "faddr[1]"      { "B22"  "LVCMOS25" }
        "faddr[0]"      { "B21"  "LVCMOS25" }
        "flaga"         { "F19"  "LVCMOS25" }
        "flagb"         { "D22"  "LVCMOS25" }
        "flagc"         { "C22"  "LVCMOS25" }
        "flagd"         { "C18"  "LVCMOS25" }
        "mode_p[2]"     { "M15"  "LVCMOS25" }
        "mode_p[1]"     { "H17"  "LVCMOS25" }
        "mode_p[0]"     { "H18"  "LVCMOS25" }
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
	}

foreach io [ array names ios ] {
	set pin [ lindex $ios($io) 0 ]
	set std [ lindex $ios($io) 1 ]
	set_property package_pin $pin [get_ports $io]
	set_property iostandard $std [get_ports [list $io]]
}

#set_property iostandard LVCMOS25 [get_ports [get_iobanks 34]]
# Location constraints
#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*data_out_d.*]
#phys_opt_design -force_replication_on_nets [get_cells -hierarchical -regexp .*slave_fifo.*slwr_n_d.*]
#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*slwr_n_d.*]
#set_property IOB TRUE [all_inputs]
#set_property IOB TRUE [all_outputs]

#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*fdata_d.*]
#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*flaga_d.*]
#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*flagb_d.*]
#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*flagc_d.*]
#set_property IOB TRUE [get_cells -hierarchical -regexp .*slave_fifo.*flagd_d.*]

# Timing constraints
set clock [get_clocks]
set_false_path -from $clock -to [get_ports {led[*]}]
set_false_path -from [get_ports {btn1 btn2 sw[*]}] -to $clock

create_generated_clock -source [get_pins -hierarchical slave_fifo/aclk] -master_clock [get_clocks] -add -name clk_out [get_ports clk_out] -edges {2 3 4}

set clock [get_clocks clk_out]

# add timing constraints for fifo
set_false_path -from [get_ports {mode_p sw[*]}] -to $clock
set_output_delay -clock $clock 1 [get_ports slcs]
set_output_delay -clock $clock 1 [get_ports fdata]
set_output_delay -clock $clock 1 [get_ports faddr]
set_output_delay -clock $clock 1 [get_ports slrd]
set_output_delay -clock $clock 1 [get_ports slwr]
set_output_delay -clock $clock 1 [get_ports sloe]
set_output_delay -clock $clock 1 [get_ports pktend]
set_input_delay -clock $clock 7.5 [get_ports fdata]
#set_input_delay -clock $clock 7.5 [get_ports mode_p]
set_input_delay -clock $clock 7.5 [get_ports flaga]
set_input_delay -clock $clock 7.5 [get_ports flagb]
set_input_delay -clock $clock 7.5 [get_ports flagc]
set_input_delay -clock $clock 7.5 [get_ports flagd]


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
