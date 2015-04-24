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

## This Makefile is to be included in ms.mk. It defines external libraries and
## how to import them in the project. To add definitions for new external
## libraries please look at the existing ones and add a dedicated section.

## Extern libraries from Xilinx
VLOGXILINXLIBS	= unisims_ver
VLOGXILINXTAGS	= $(patsubst %,$(buildrootdir)/externs/%.ext,$(VLOGXILINXLIBS))

$(VLOGXILINXTAGS): $(buildrootdir)/externs/exists

$(VLOGXILINXTAGS):
ifndef VLOGXILINXROOTDIR
	@echo '--------------------------------------------------------------------------------'; \
	 echo 'The VLOGXILINXROOTDIR environment variable is undefined. Skipping definitions of'; \
	 echo 'Xilinx Verilog libraries. If these libraries are needed, please define the'; \
	 echo 'VLOGXILINXROOTDIR environment variable and assign it the absolute path of the'; \
	 echo 'directory of the compiled XILINX Verilog libraries, e.g.:'; \
	 echo '  export VLOGXILINXROOTDIR=/<some-path>/xvloglibs'; \
	 echo '--------------------------------------------------------------------------------'
else
	@cd $(rootdir); \
	lib=$(patsubst %.ext,%,$(notdir $@)); \
	if [ ! -d $(VLOGXILINXROOTDIR)/$$lib ]; then \
	  echo '--------------------------------------------------------------------------------'; \
	  echo 'Library not found in the XILINX Verilog hierarchy:'; \
	  echo "  $$lib"; \
	  echo 'Skipping... If it is needed please build it first.'; \
	  echo '--------------------------------------------------------------------------------'; \
	else \
	  echo "$(VMAP) $$lib $(VLOGXILINXROOTDIR)/$$lib"; \
	  $(VMAP) $$lib $(VLOGXILINXROOTDIR)/$$lib; \
	fi; \
	touch $@
endif

VHDLXILINXLIBS	= unisims
VHDLXILINXTAGS	= $(patsubst %,$(buildrootdir)/externs/%.ext,$(VHDLXILINXLIBS))

$(VHDLXILINXTAGS): $(buildrootdir)/externs/exists

$(VHDLXILINXTAGS):
ifndef VHDLXILINXROOTDIR
	@echo '--------------------------------------------------------------------------------'; \
	 echo 'The VHDLXILINXROOTDIR environment variable is undefined. Skipping definitions of'; \
	 echo 'Xilinx VHDL libraries. If these libraries are needed, please define the'; \
	 echo 'VHDLXILINXROOTDIR environment variable and assign it the absolute path of the'; \
	 echo 'directory of the compiled XILINX VHDL libraries, e.g.:'; \
	 echo '  export VHDLXILINXROOTDIR=/<some-path>/xvhdllibs'; \
	 echo '--------------------------------------------------------------------------------'
else
	@cd $(rootdir); \
	lib=$(patsubst %.ext,%,$(notdir $@)); \
	if [ ! -d $(VHDLXILINXROOTDIR)/$$lib ]; then \
	  echo '--------------------------------------------------------------------------------'; \
	  echo 'Library not found in the XILINX Verilog hierarchy:'; \
	  echo "  $$lib"; \
	  echo 'Skipping... If it is needed please build it first.'; \
	  echo '--------------------------------------------------------------------------------'; \
	else \
	  echo "$(VMAP) $$lib $(VHDLXILINXROOTDIR)/$$lib"; \
	  $(VMAP) $$lib $(VHDLXILINXROOTDIR)/$$lib; \
	fi; \
	touch $@
endif

$(buildrootdir)/externs/exists: $(buildrootdir)/exists
	mkdir --parents $(buildrootdir)/externs
	touch $@
