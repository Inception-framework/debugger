#
# Copyright (C) Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

##############################################################
######## Do not change this part, HWPrj relies on it #########
##############################################################

## Root directory of the project.
ROOTDIR	= ../..

include $(ROOTDIR)/Makefile

##############################################################
################# End of part HWPrj relies on ################
##############################################################

TOP		= axi_register_wrapper
BIT		= $(TOP).vv-syn/top.runs/impl_1/top_wrapper.bit
SDK		= $(TOP).vv-syn/top.sdk
FSBL		= $(SDK)/fsbl/executable.elf
DTS		= $(SDK)/dts/system.dts
DTB		= $(patsubst %.dts,%.dtb,$(DTS))
UBOOTELF	?= u-boot.elf
BIF		= boot.bif
BIN		= boot.bin

syn: $(BIT)
bit: $(BIT)
fsbl: $(FSBL)
dts: $(DTS)
dtb: $(DTB)
bin: $(BIN)

$(BIT):
	$(MAKE) $(TOP).vsyn

$(DTB): $(DTS)
	dtc -I dts -O dtb -o $@ $<

$(DTS): $(SDK)/top_wrapper.hdf
	hsi -mode batch -quiet -notrace -source dts.hsi.tcl

$(FSBL): $(SDK)/top_wrapper.hdf
	hsi -mode batch -source fsbl.hsi.tcl

$(BIN): $(BIF) $(FSBL) $(BIT) $(UBOOTELF)
	bootgen -w -image $< -o $@

$(SDK)/top_wrapper.hdf: $(TOP).vv-syn/top.runs/impl_1/top_wrapper.sysdef
	mkdir -p $(SDK)
	cp $< $@
