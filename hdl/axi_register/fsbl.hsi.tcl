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
generate_app -hw top_imp -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir axi_register_wrapper.vv-syn/top.sdk/fsbl
