#
# Copyright (C) Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

#############
# Variables #
#############

# General purpose
DEBUG	?= 1
SHELL	:= /bin/bash

ifeq ($(DEBUG),0)
OUTPUT	:= &> /dev/null
else ifeq ($(DEBUG),1)
OUTPUT	:= > /dev/null
else
OUTPUT	:=
endif

BUILD		:= build
HDLDIR		:= hdl
HDLSRCS		:= $(wildcard $(HDLDIR)/*.vhd)
SCRIPTS		:= scripts

# Mentor Graphics Modelsim
MSBUILD		:= $(BUILD)/ms
MSRELPATH	:= ../..
MSLIB		:= vlib
MSMAP		:= vmap
MSCOM		:= vcom
MSCOMFLAGS	:= -ignoredefaultbinding -nologo -quiet -2008
MSLOG    	:= vlog
MSLOGFLAGS	:= -nologo -quiet
MSSIM		:= vsim
MSSIMFLAGS	:= -voptargs="+acc"
MSCONFIG	:= $(MSBUILD)/modelsim.ini
MSTAGS		:= $(patsubst $(HDLDIR)/%.vhd,$(MSBUILD)/%.tag,$(HDLSRCS))

# Xilinx Vivado
VIVADO		:= vivado
VIVADOFLAGS	:= -mode batch
VVBUILD		:= $(BUILD)/vv
VVRELPATH	:= ../..
VVIMPL		:= $(VVBUILD)/top.runs/impl_1
VVBIT		:= $(VVIMPL)/top_wrapper.bit
VVSCRIPT	:= $(SCRIPTS)/vvsyn.tcl

# Software Design Kits
XDTS			?= /opt/xlnx/device-tree-xlnx
HSI			:= hsi
DTSSCRIPT		:= $(SCRIPTS)/dts.tcl
DTSFLAGS		:= -mode batch -quiet -notrace -nojournal -nolog -tempDir /tmp
DTC			:= dtc
DTCFLAGS		:= -I dts -O dtb
SYSDEF			:= $(VVIMPL)/top_wrapper.sysdef
DTSBUILD		:= $(BUILD)/dts
DTSTOP			:= $(DTSBUILD)/system.dts
DTB			:= $(BUILD)/devicetree.dtb
FSBLSCRIPT		:= $(SCRIPTS)/fsbl.tcl
FSBLFLAGS		:= -mode batch -quiet -notrace -nojournal -nolog -tempDir /tmp
FSBLBUILD		:= $(BUILD)/fsbl
FSBLTOP			:= $(FSBLBUILD)/main.c
FSBLELF			:= $(FSBLBUILD)/executable.elf

# Messages
define HELP_message
make targets:
  make help       print this message (default goal)
  make ms-all     compile all VHDL source files with Modelsim ($(MSBUILD))
  make ms-clean   delete all files and directories automatically created by Modelsim
  make vv-all     synthesize design with Vivado ($(VVBUILD))
  make vv-clean   delete all files and directories automatically created by Vivado
  make dts        generate device tree sources ($(DTSBUILD))
  make dtb        compile device tree blob ($(DTB))
  make dt-clean   delete device tree sources and blob
  make fsbl       generate First Stage Boot Loader (FSBL) sources ($(FSBLBUILD))
  make fsblelf    compile First Stage Boot Loader (FSBL) ($(FSBLELF))
  make fs-clean   delete FSBL sources and ELF
  make clean      delete all automatically created files and directories

directories:
  hdl sources          ./$(HDLDIR)
  build                ./$(BUILD)
  Modelsim build       ./$(MSBUILD)
  Vivado build         ./$(VVBUILD)
  Device Tree Sources  ./$(DTSBUILD)
  FSBL sources         ./$(FSBLBUILD)

customizable make variables:
  DEBUG  debug level: 0=none, 1: some, 2: verbose ($(DEBUG))
  XDTS   clone of Xilinx device trees git repository ($(XDTS))
endef
export HELP_message

################
# Make targets #
################

# Help
help:
	@echo "$$HELP_message"

# Mentor Graphics Modelsim
ms-all: $(MSTAGS)

$(MSTAGS): $(MSBUILD)/%.tag: $(HDLDIR)/%.vhd
	@echo '[MSCOM] $<'; \
	cd $(MSBUILD); \
	$(MSCOM) $(MSCOMFLAGS) $(MSRELPATH)/$<; \
	touch $(notdir $@)

$(MSTAGS): $(MSCONFIG)

$(MSCONFIG):
	@echo '[MKDIR] $(MSBUILD)'; \
	mkdir -p $(MSBUILD); \
	cd $(MSBUILD); \
	$(MSLIB) .work $(OUTPUT); \
	$(MSMAP) work .work $(OUTPUT)

$(MSBUILD)/axi_register.tag: $(MSBUILD)/axi_pkg.tag $(MSBUILD)/debouncer.tag $(MSBUILD)/utils.tag

ms-clean:
	@echo '[RM] $(MSBUILD)'; \
	rm -rf $(MSBUILD)

# Xilinx Vivado
vv-all: $(VVBIT)

$(VVBIT): $(HDLSRCS) $(VVSCRIPT)
	@echo '[VIVADO] $(VVSCRIPT)'; \
	mkdir -p $(VVBUILD); \
	cd $(VVBUILD); \
	VVRELPATH=$(VVRELPATH) HDLDIR=$(HDLDIR) $(VIVADO) $(VIVADOFLAGS) -source $(VVRELPATH)/$(VVSCRIPT); \
	echo ''; \
	echo '[VIVADO] $(VVSCRIPT): done'; \
	echo '  bitstream in $(VVBIT)'; \
	echo '  resource utilization report in $(VVIMPL)/top_wrapper_utilization_placed.rpt'; \
	echo '  timing report in $(VVIMPL)/top_wrapper_timing_summary_routed.rpt'

$(VVIMPL)/$(SYSDEF): $(VVBIT)

vv-clean:
	@echo '[RM] $(VVBUILD)'; \
	rm -rf $(VVBUILD)

# Device tree
dts: $(DTSTOP)
dtb: $(DTB)

$(DTSTOP): $(SYSDEF) $(DTSSCRIPT)
	@if [ ! -d $(XDTS) ]; then \
		echo 'Xilinx device tree source directory $(XDTS) not found.'; \
		exit -1; \
	fi; \
	echo '[HSI] $< --> $(DTSBUILD)'; \
	$(HSI) $(DTSFLAGS) -source $(DTSSCRIPT) -tclargs $(SYSDEF) $(XDTS) $(DTSBUILD) $(OUTPUT)

$(DTB): $(DTSTOP)
	@echo '[DTC] $< --> $@'; \
	$(DTC) $(DTCFLAGS) -o $@ $(DTSTOP) $(OUTPUT)

dt-clean:
	@echo '[RM] $(DTSBUILD) $(DTB)'; \
	rm -rf $(DTSBUILD) $(DTB)

# First Stage Boot Loader (FSBL)
fsbl: $(FSBLTOP)
fsblelf: $(FSBLELF)

$(FSBLTOP): $(SYSDEF) $(FSBLSCRIPT)
	@echo '[HSI] $< --> $(FSBLBUILD)'; \
	$(HSI) $(FSBLFLAGS) -source $(FSBLSCRIPT) -tclargs $(SYSDEF) $(FSBLBUILD) $(OUTPUT)

$(FSBLELF): $(FSBLTOP)
	@echo '[MAKE] $(FSBLBUILD)'; \
	$(MAKE) -C $(FSBLBUILD)

fs-clean:
	@echo '[RM] $(FSBLBUILD) $(FSBLELF)'; \
	rm -rf $(FSBLBUILD) $(FSBLELF)

# Full clean
clean:
	@echo '[RM] $(BUILD)'; \
	rm -rf $(BUILD)
