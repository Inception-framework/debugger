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

# Options
if { [ info exists ::env(CHIPSCOPE) ] } {
	set chipscope 1
} else {
	set chipscope 0
}

create_project top . -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.0 [current_project]
set_property ip_repo_paths ./ip [current_fileset]
update_ip_catalog
create_bd_design "top"
create_bd_cell -type ip -vlnv www.telecom-paristech.fr:SecBus:${topentity}:1.0 ip_0
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50.000000} CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1}] [get_bd_cells processing_system7_0]

# Interconnections
# Primary IOs
create_bd_port -dir O -from 7 -to 0 gpo
connect_bd_net [get_bd_pins /ip_0/gpo] [get_bd_ports gpo]
create_bd_port -dir I -from 7 -to 0 gpi
connect_bd_net [get_bd_pins /ip_0/gpi] [get_bd_ports gpi]
# ps7 - ip
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins ip_0/s_axi]

# Addresses ranges
set_property offset 0x40000000 [get_bd_addr_segs processing_system7_0/Data/SEG_ip_0_reg0]
set_property range 4K [get_bd_addr_segs processing_system7_0/Data/SEG_ip_0_reg0]

# In-circuit debugging
if { $chipscope == 1 } {
	set_property HDL_ATTRIBUTE.MARK_DEBUG true [get_bd_intf_nets {axi_mem_intercon_S00_AXI }]
}

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

# In-circuit debugging
if { $chipscope == 1 } {
	create_debug_core u_ila_0 ila
	set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
	set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
	set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
	set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
	set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
	set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0 ]
	set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
	set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0 ]
	set_property port_width 1 [get_debug_ports u_ila_0/clk]
	connect_debug_port u_ila_0/clk [get_nets [list top_i/processing_system7_0_FCLK_CLK0 ]]
	set_property port_width 2 [get_debug_ports u_ila_0/probe0]
	connect_debug_port u_ila_0/probe0 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARBURST[0]} {top_i/axi_mem_intercon_M00_AXI_ARBURST[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 6 [get_debug_ports u_ila_0/probe1]
	connect_debug_port u_ila_0/probe1 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARID[0]} {top_i/axi_mem_intercon_M00_AXI_ARID[1]} {top_i/axi_mem_intercon_M00_AXI_ARID[2]} {top_i/axi_mem_intercon_M00_AXI_ARID[3]} {top_i/axi_mem_intercon_M00_AXI_ARID[4]} {top_i/axi_mem_intercon_M00_AXI_ARID[5]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 30 [get_debug_ports u_ila_0/probe2]
	connect_debug_port u_ila_0/probe2 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARADDR[0]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[1]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[2]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[3]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[4]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[5]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[6]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[7]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[8]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[9]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[10]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[11]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[12]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[13]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[14]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[15]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[16]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[17]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[18]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[19]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[20]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[21]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[22]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[23]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[24]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[25]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[26]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[27]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[28]} {top_i/axi_mem_intercon_M00_AXI_ARADDR[29]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe3]
	connect_debug_port u_ila_0/probe3 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARCACHE[0]} {top_i/axi_mem_intercon_M00_AXI_ARCACHE[1]} {top_i/axi_mem_intercon_M00_AXI_ARCACHE[2]} {top_i/axi_mem_intercon_M00_AXI_ARCACHE[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe4]
	connect_debug_port u_ila_0/probe4 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWLEN[0]} {top_i/axi_mem_intercon_M00_AXI_AWLEN[1]} {top_i/axi_mem_intercon_M00_AXI_AWLEN[2]} {top_i/axi_mem_intercon_M00_AXI_AWLEN[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 3 [get_debug_ports u_ila_0/probe5]
	connect_debug_port u_ila_0/probe5 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARPROT[0]} {top_i/axi_mem_intercon_M00_AXI_ARPROT[1]} {top_i/axi_mem_intercon_M00_AXI_ARPROT[2]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 6 [get_debug_ports u_ila_0/probe6]
	connect_debug_port u_ila_0/probe6 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_RID[0]} {top_i/axi_mem_intercon_M00_AXI_RID[1]} {top_i/axi_mem_intercon_M00_AXI_RID[2]} {top_i/axi_mem_intercon_M00_AXI_RID[3]} {top_i/axi_mem_intercon_M00_AXI_RID[4]} {top_i/axi_mem_intercon_M00_AXI_RID[5]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 3 [get_debug_ports u_ila_0/probe7]
	connect_debug_port u_ila_0/probe7 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWPROT[0]} {top_i/axi_mem_intercon_M00_AXI_AWPROT[1]} {top_i/axi_mem_intercon_M00_AXI_AWPROT[2]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 6 [get_debug_ports u_ila_0/probe8]
	connect_debug_port u_ila_0/probe8 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_BID[0]} {top_i/axi_mem_intercon_M00_AXI_BID[1]} {top_i/axi_mem_intercon_M00_AXI_BID[2]} {top_i/axi_mem_intercon_M00_AXI_BID[3]} {top_i/axi_mem_intercon_M00_AXI_BID[4]} {top_i/axi_mem_intercon_M00_AXI_BID[5]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 32 [get_debug_ports u_ila_0/probe9]
	connect_debug_port u_ila_0/probe9 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_WDATA[0]} {top_i/axi_mem_intercon_M00_AXI_WDATA[1]} {top_i/axi_mem_intercon_M00_AXI_WDATA[2]} {top_i/axi_mem_intercon_M00_AXI_WDATA[3]} {top_i/axi_mem_intercon_M00_AXI_WDATA[4]} {top_i/axi_mem_intercon_M00_AXI_WDATA[5]} {top_i/axi_mem_intercon_M00_AXI_WDATA[6]} {top_i/axi_mem_intercon_M00_AXI_WDATA[7]} {top_i/axi_mem_intercon_M00_AXI_WDATA[8]} {top_i/axi_mem_intercon_M00_AXI_WDATA[9]} {top_i/axi_mem_intercon_M00_AXI_WDATA[10]} {top_i/axi_mem_intercon_M00_AXI_WDATA[11]} {top_i/axi_mem_intercon_M00_AXI_WDATA[12]} {top_i/axi_mem_intercon_M00_AXI_WDATA[13]} {top_i/axi_mem_intercon_M00_AXI_WDATA[14]} {top_i/axi_mem_intercon_M00_AXI_WDATA[15]} {top_i/axi_mem_intercon_M00_AXI_WDATA[16]} {top_i/axi_mem_intercon_M00_AXI_WDATA[17]} {top_i/axi_mem_intercon_M00_AXI_WDATA[18]} {top_i/axi_mem_intercon_M00_AXI_WDATA[19]} {top_i/axi_mem_intercon_M00_AXI_WDATA[20]} {top_i/axi_mem_intercon_M00_AXI_WDATA[21]} {top_i/axi_mem_intercon_M00_AXI_WDATA[22]} {top_i/axi_mem_intercon_M00_AXI_WDATA[23]} {top_i/axi_mem_intercon_M00_AXI_WDATA[24]} {top_i/axi_mem_intercon_M00_AXI_WDATA[25]} {top_i/axi_mem_intercon_M00_AXI_WDATA[26]} {top_i/axi_mem_intercon_M00_AXI_WDATA[27]} {top_i/axi_mem_intercon_M00_AXI_WDATA[28]} {top_i/axi_mem_intercon_M00_AXI_WDATA[29]} {top_i/axi_mem_intercon_M00_AXI_WDATA[30]} {top_i/axi_mem_intercon_M00_AXI_WDATA[31]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe10]
	connect_debug_port u_ila_0/probe10 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWCACHE[0]} {top_i/axi_mem_intercon_M00_AXI_AWCACHE[1]} {top_i/axi_mem_intercon_M00_AXI_AWCACHE[2]} {top_i/axi_mem_intercon_M00_AXI_AWCACHE[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe11]
	connect_debug_port u_ila_0/probe11 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARLEN[0]} {top_i/axi_mem_intercon_M00_AXI_ARLEN[1]} {top_i/axi_mem_intercon_M00_AXI_ARLEN[2]} {top_i/axi_mem_intercon_M00_AXI_ARLEN[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 6 [get_debug_ports u_ila_0/probe12]
	connect_debug_port u_ila_0/probe12 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWID[0]} {top_i/axi_mem_intercon_M00_AXI_AWID[1]} {top_i/axi_mem_intercon_M00_AXI_AWID[2]} {top_i/axi_mem_intercon_M00_AXI_AWID[3]} {top_i/axi_mem_intercon_M00_AXI_AWID[4]} {top_i/axi_mem_intercon_M00_AXI_AWID[5]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe13]
	connect_debug_port u_ila_0/probe13 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWSIZE[0]} {top_i/axi_mem_intercon_M00_AXI_AWSIZE[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe14]
	connect_debug_port u_ila_0/probe14 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWLOCK[0]} {top_i/axi_mem_intercon_M00_AXI_AWLOCK[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe15]
	connect_debug_port u_ila_0/probe15 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_RRESP[0]} {top_i/axi_mem_intercon_M00_AXI_RRESP[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe16]
	connect_debug_port u_ila_0/probe16 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARLOCK[0]} {top_i/axi_mem_intercon_M00_AXI_ARLOCK[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe17]
	connect_debug_port u_ila_0/probe17 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWBURST[0]} {top_i/axi_mem_intercon_M00_AXI_AWBURST[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe18]
	connect_debug_port u_ila_0/probe18 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARSIZE[0]} {top_i/axi_mem_intercon_M00_AXI_ARSIZE[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe19]
	connect_debug_port u_ila_0/probe19 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_WSTRB[0]} {top_i/axi_mem_intercon_M00_AXI_WSTRB[1]} {top_i/axi_mem_intercon_M00_AXI_WSTRB[2]} {top_i/axi_mem_intercon_M00_AXI_WSTRB[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 6 [get_debug_ports u_ila_0/probe20]
	connect_debug_port u_ila_0/probe20 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_WID[0]} {top_i/axi_mem_intercon_M00_AXI_WID[1]} {top_i/axi_mem_intercon_M00_AXI_WID[2]} {top_i/axi_mem_intercon_M00_AXI_WID[3]} {top_i/axi_mem_intercon_M00_AXI_WID[4]} {top_i/axi_mem_intercon_M00_AXI_WID[5]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe21]
	connect_debug_port u_ila_0/probe21 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_ARQOS[0]} {top_i/axi_mem_intercon_M00_AXI_ARQOS[1]} {top_i/axi_mem_intercon_M00_AXI_ARQOS[2]} {top_i/axi_mem_intercon_M00_AXI_ARQOS[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 32 [get_debug_ports u_ila_0/probe22]
	connect_debug_port u_ila_0/probe22 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_RDATA[0]} {top_i/axi_mem_intercon_M00_AXI_RDATA[1]} {top_i/axi_mem_intercon_M00_AXI_RDATA[2]} {top_i/axi_mem_intercon_M00_AXI_RDATA[3]} {top_i/axi_mem_intercon_M00_AXI_RDATA[4]} {top_i/axi_mem_intercon_M00_AXI_RDATA[5]} {top_i/axi_mem_intercon_M00_AXI_RDATA[6]} {top_i/axi_mem_intercon_M00_AXI_RDATA[7]} {top_i/axi_mem_intercon_M00_AXI_RDATA[8]} {top_i/axi_mem_intercon_M00_AXI_RDATA[9]} {top_i/axi_mem_intercon_M00_AXI_RDATA[10]} {top_i/axi_mem_intercon_M00_AXI_RDATA[11]} {top_i/axi_mem_intercon_M00_AXI_RDATA[12]} {top_i/axi_mem_intercon_M00_AXI_RDATA[13]} {top_i/axi_mem_intercon_M00_AXI_RDATA[14]} {top_i/axi_mem_intercon_M00_AXI_RDATA[15]} {top_i/axi_mem_intercon_M00_AXI_RDATA[16]} {top_i/axi_mem_intercon_M00_AXI_RDATA[17]} {top_i/axi_mem_intercon_M00_AXI_RDATA[18]} {top_i/axi_mem_intercon_M00_AXI_RDATA[19]} {top_i/axi_mem_intercon_M00_AXI_RDATA[20]} {top_i/axi_mem_intercon_M00_AXI_RDATA[21]} {top_i/axi_mem_intercon_M00_AXI_RDATA[22]} {top_i/axi_mem_intercon_M00_AXI_RDATA[23]} {top_i/axi_mem_intercon_M00_AXI_RDATA[24]} {top_i/axi_mem_intercon_M00_AXI_RDATA[25]} {top_i/axi_mem_intercon_M00_AXI_RDATA[26]} {top_i/axi_mem_intercon_M00_AXI_RDATA[27]} {top_i/axi_mem_intercon_M00_AXI_RDATA[28]} {top_i/axi_mem_intercon_M00_AXI_RDATA[29]} {top_i/axi_mem_intercon_M00_AXI_RDATA[30]} {top_i/axi_mem_intercon_M00_AXI_RDATA[31]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 2 [get_debug_ports u_ila_0/probe23]
	connect_debug_port u_ila_0/probe23 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_BRESP[0]} {top_i/axi_mem_intercon_M00_AXI_BRESP[1]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 30 [get_debug_ports u_ila_0/probe24]
	connect_debug_port u_ila_0/probe24 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWADDR[0]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[1]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[2]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[3]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[4]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[5]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[6]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[7]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[8]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[9]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[10]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[11]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[12]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[13]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[14]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[15]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[16]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[17]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[18]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[19]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[20]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[21]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[22]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[23]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[24]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[25]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[26]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[27]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[28]} {top_i/axi_mem_intercon_M00_AXI_AWADDR[29]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 4 [get_debug_ports u_ila_0/probe25]
	connect_debug_port u_ila_0/probe25 [get_nets [list {top_i/axi_mem_intercon_M00_AXI_AWQOS[0]} {top_i/axi_mem_intercon_M00_AXI_AWQOS[1]} {top_i/axi_mem_intercon_M00_AXI_AWQOS[2]} {top_i/axi_mem_intercon_M00_AXI_AWQOS[3]} ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe26]
	connect_debug_port u_ila_0/probe26 [get_nets [list top_i/axi_mem_intercon_M00_AXI_ARREADY ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe27]
	connect_debug_port u_ila_0/probe27 [get_nets [list top_i/axi_mem_intercon_M00_AXI_ARVALID ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe28]
	connect_debug_port u_ila_0/probe28 [get_nets [list top_i/axi_mem_intercon_M00_AXI_AWREADY ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe29]
	connect_debug_port u_ila_0/probe29 [get_nets [list top_i/axi_mem_intercon_M00_AXI_AWVALID ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe30]
	connect_debug_port u_ila_0/probe30 [get_nets [list top_i/axi_mem_intercon_M00_AXI_BREADY ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe31]
	connect_debug_port u_ila_0/probe31 [get_nets [list top_i/axi_mem_intercon_M00_AXI_BVALID ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe32]
	connect_debug_port u_ila_0/probe32 [get_nets [list top_i/axi_mem_intercon_M00_AXI_RLAST ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe33]
	connect_debug_port u_ila_0/probe33 [get_nets [list top_i/axi_mem_intercon_M00_AXI_RREADY ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe34]
	connect_debug_port u_ila_0/probe34 [get_nets [list top_i/axi_mem_intercon_M00_AXI_RVALID ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe35]
	connect_debug_port u_ila_0/probe35 [get_nets [list top_i/axi_mem_intercon_M00_AXI_WLAST ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe36]
	connect_debug_port u_ila_0/probe36 [get_nets [list top_i/axi_mem_intercon_M00_AXI_WREADY ]]
	create_debug_port u_ila_0 probe
	set_property port_width 1 [get_debug_ports u_ila_0/probe37]
	connect_debug_port u_ila_0/probe37 [get_nets [list top_i/axi_mem_intercon_M00_AXI_WVALID ]]
}

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
