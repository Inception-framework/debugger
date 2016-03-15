#
# Copyright (C) Telecom ParisTech
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

# Create new ILA core named $name, with clock $clock and connect it to all nets in list $nets. Add to ILA core as many debug ports as needed. ILA core properties have reasonable default values but can also be passed different values
proc add_ila_core { name clock nets { data_depth 1024 } { trigin_en false } { trigout_en false } { input_pipe_stages 1 } { en_strg_qual true } { adv_trigger true } { all_probe_same_mu true } { all_probe_same_mu_cnt 4 } } {
	puts "Instanciating ILA debug core"
	# Create ILA debug core
	set debug_core [ create_debug_core $name ila ]
	# Set ILA debug core properties
	set_property C_DATA_DEPTH $data_depth $debug_core
	set_property C_TRIGIN_EN $trigin_en $debug_core
	set_property C_TRIGOUT_EN $trigout_en $debug_core
	set_property C_INPUT_PIPE_STAGES $input_pipe_stages $debug_core
	set_property C_EN_STRG_QUAL $en_strg_qual $debug_core
	set_property C_ADV_TRIGGER $adv_trigger $debug_core
	set_property ALL_PROBE_SAME_MU $all_probe_same_mu $debug_core
	set_property ALL_PROBE_SAME_MU_CNT $all_probe_same_mu_cnt $debug_core
	# Connect clock $clock to ILA debug core. Create debug port if needed
	set clock_debug_port [ get_debug_ports $debug_core/clk ]
	if { [ llength $clock_debug_port ] == 0 } {
		set clock_debug_port [ create_debug_port $debug_core clk ]
	}
	connect_debug_port $clock_debug_port $clock
	# Number of nets to connect
	set num_nets [ llength $nets ]
	# Create missing debug ports if needed
	for { set num_debug_ports [ llength [ get_debug_ports $debug_core/probe* ] ] } { $num_debug_ports < $num_nets } { incr num_debug_ports 1 } {
		create_debug_port $debug_core probe
	}
	# List of debug ports
	set debug_ports [ get_debug_ports $debug_core/probe* ]
	# For each net to connect
	foreach net $nets {
		# Pick first debug port
		set debug_port [ lindex $debug_ports 0 ]
		# Search net in design
		set real_net [ get_nets -quiet ${net} ]
		# If net not found, search bus
		if { [ llength $real_net ] == 0 } {
			set real_net [ lsort -dictionary [ get_nets -quiet ${net}[*] ] ]
		}
		# Width of net or bus
		set net_width [ llength $real_net ]
		# If width not 0 (net or bus found)
		if { $net_width != 0 } {
			# Set width of debug port
			set_property port_width $net_width $debug_port
			puts "  Connecting $net ($net_width bits) to ILA debug core $debug_core, debug port $debug_port"
			# Connect net or bus
			connect_debug_port $debug_port $real_net
			# Remove debug port from list
			set debug_ports [ lreplace $debug_ports 0 0 ]
		} else {
			puts "  Warning: ${net} not found"
		}
	}
}

