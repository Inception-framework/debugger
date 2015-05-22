#
# Copyright (C) Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

set lib "[ file tail [ file dirname [ pwd  ] ] ]_lib"

#############
# Create IP #
#############

file mkdir ip
cd ip
create_project ip . -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.0 [current_project]
set modules [ exec ls $srcrootdir ]
foreach m $modules {
	eval "set Paths_g(${m}_lib) $srcrootdir/$m"
}
getDependencies {} [ list $lib.$topentity ]
VHDLDependencies $lib.$topentity
for { set i 0 } { $i < [ array size DUSpecs_g ] } { incr i 1 } {
	set spec $DUSpecs_g($i)
	set d [ lindex $spec 0 ]
	set l [ lindex $spec 1 ]
	set p [ lindex $spec 2 ]
	add_files $p/$d
	set_property library $l [ get_files $p/$d ]
}
import_files -force -norecurse
update_compile_order -fileset sources_1
ipx::package_project -root_dir ./ip.srcs/sources_1/imports
set_property vendor {www.telecom-paristech.fr} [ipx::current_core]
set_property library {SecBus} [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property ip_repo_paths ./ip.srcs/sources_1/imports [current_fileset]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core ./ip.srcs/sources_1/imports/www.telecom-paristech.fr_SecBus_ip_1.0.zip [ipx::current_core]
close_project
cd ..

##################
## Create design #
##################

create_project top . -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.0 [current_project]
set_property ip_repo_paths ./ip [current_fileset]
update_ip_catalog
create_bd_design "top"
set areg [create_bd_cell -type ip -vlnv www.telecom-paristech.fr:SecBus:${topentity}:1.0 areg]
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
create_bd_port -dir O -from 7 -to 0 gpo
connect_bd_net [get_bd_pins /areg/gpo] [get_bd_ports gpo]
create_bd_port -dir I -from 7 -to 0 gpi
connect_bd_net [get_bd_pins /areg/gpi] [get_bd_ports gpi]
# ps7 - ip
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins areg/s0_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins areg/s1_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/areg/m_axi" Clk "Auto" }  [get_bd_intf_pins ps7/S_AXI_HP0]

# Addresses ranges
set_property offset 0x40000000 [get_bd_addr_segs ps7/Data/SEG_areg_reg0]
set_property range 4K [get_bd_addr_segs ps7/Data/SEG_areg_reg0]
set_property offset 0x80000000 [get_bd_addr_segs ps7/Data/SEG_areg_reg01]
set_property range 512M [get_bd_addr_segs {ps7/Data/SEG_areg_reg01}]
set_property offset 0x00000000 [get_bd_addr_segs [list areg/m_axi/SEG_ps7_HP0_DDR_LOWOCM]]
set_property range 512M [get_bd_addr_segs [list areg/m_axi/SEG_ps7_HP0_DDR_LOWOCM]]

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
	"gpi[0]"	{ "F22" "LVCMOS33" }
	"gpi[1]"	{ "G22" "LVCMOS33" }
	"gpi[2]"	{ "H22" "LVCMOS33" }
	"gpi[3]"	{ "F21" "LVCMOS33" }
	"gpi[4]"	{ "H19" "LVCMOS33" }
	"gpi[5]"	{ "H18" "LVCMOS33" }
	"gpi[6]"	{ "H17" "LVCMOS33" }
	"gpi[7]"	{ "M15" "LVCMOS33" }
	"gpo[0]"	{ "T22" "LVCMOS33" }
	"gpo[1]"	{ "T21" "LVCMOS33" }
	"gpo[2]"	{ "U22" "LVCMOS33" }
	"gpo[3]"	{ "U21" "LVCMOS33" }
	"gpo[4]"	{ "V22" "LVCMOS33" }
	"gpo[5]"	{ "W22" "LVCMOS33" }
	"gpo[6]"	{ "U19" "LVCMOS33" }
	"gpo[7]"	{ "U14" "LVCMOS33" }
}
foreach io [ array names ios ] {
	set pin [ lindex $ios($io) 0 ]
	set std [ lindex $ios($io) 1 ]
	set_property package_pin $pin [get_ports $io]
	set_property iostandard $std [get_ports [list $io]]
}

# Timing constraints
set_false_path -from [get_clocks {clk_fpga_0}] -to [get_ports {gpo[*]}]
set_false_path -from [get_ports {gpi[*]}] -to [get_clocks {clk_fpga_0}]

save_bd_design
save_constraints
reset_run impl_1
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
