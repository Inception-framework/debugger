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
set outputDir .
create_project $topentity . -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.0 [current_project]
set modules [ exec ls $srcrootdir ]
foreach m $modules {
	eval "set Paths_g(${m}_lib) $srcrootdir/$m"
}
getDependencies {} [ list $lib.$topentity ]
VHDLDependencies $lib.$topentity "vv"
for { set i 0 } { $i < [ array size DUSpecs_g ] } { incr i 1 } {
	set spec $DUSpecs_g($i)
	set d [ lindex $spec 0 ]
	set l [ lindex $spec 1 ]
	set p [ lindex $spec 2 ]
	add_files $p/$d
	set_property library $l [ get_files $p/$d ]
}
import_files -force -norecurse
set_property topentity $topentity [current_fileset]
launch_runs synth_1
wait_on_run synth_1
# open_run synth_1 -name netlist_1
# quit
