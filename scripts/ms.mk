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

#####################################################
######## Don't change anything in this file #########
#####################################################

.NOTPARALLEL:

## Tool definitions
## The command that creates a VHDL library
VLIB	= vlib
## The command that maps a logical name on a VHDL library
VMAP	= vmap
## The comand that compiles a VHDL source file
VCOM	= vcom
## VHDL compiler options
VCOMFLAGS = -ignoredefaultbinding -nologo -quiet -2002
## The comand that compiles a Verilog source file
VLOG    = vlog
## Verilog compiler options
VLOGFLAGS = -nologo -quiet
## The command that launches the VHDL simulator on a snapshot
VSIM	= vsim
## Simulator options
VSIMFLAGS	= -voptargs="+acc"
## Configuration file for the tools
MSCONFIGFILENAME	= modelsim.ini
mainmsconfigfile	= $(rootdir)/$(MSCONFIGFILENAME)
## Name of dependency files
DEPFILENAME	= dependencies.txt

## Directory definitions
## Build root directory
BUILDROOTDIR	= build
buildrootdir	= $(rootdir)/$(BUILDROOTDIR)

.PHONY: ms-help ms-all ms-clean ms-ultraclean

clean: ms-clean
ultraclean: ms-ultraclean

include $(scriptsdir)/externs.mk

## Computed dependencies
DEPENDENCIES	= Makefile.ms.inc
dependencies	= $(scriptsdir)/$(DEPENDENCIES)
MAKEDEPENDS	= makedepends.sh
makedepends	= $(scriptsdir)/$(MAKEDEPENDS)

$(dependencies): $(wildcard $(srcrootdir)/*/$(DEPFILENAME)) $(wildcard $(srcrootdir)/*/*.vhd) $(makedepends)
	@$(makedepends) $(rootdir) > $@
	@echo "$(MAKEDEPENDS) $(ROOTDIR) > $(DEPENDENCIES)"

include $(dependencies)

ifeq ($(call fullpath,.),$(rootdir))

ms-help:
	@cat $(scriptsdir)/ms-short.help

ms-all: $(LIBS)

$(IGNORELIBS):
	@echo "$@: found an $(IGNOREFILENAME) file"

ms-tests:
	@echo "Modelsim compilation non-regression test:"; \
	rm -f ms-tests.log; \
	for n in $(NOIGNOREMODULES); do \
		$(MAKE) -C $(srcrootdir)/$$n ms-tests 2>&1 | tee -a ms-tests.log; \
	done

ms-sim-tests:
	@echo "Modelsim simulation non-regression test:"; \
	rm -f ms-sim-tests.log; \
	for n in $(NOIGNOREMODULES); do \
		$(MAKE) -C $(srcrootdir)/$$n ms-sim-tests 2>&1 | tee -a ms-sim-tests.log; \
	done

ms-clean:
	rm -rf transcript *.wlf

ms-ultraclean:
	rm -rf transcript *.wlf ms-tests.log ms-sim-tests.log
	rm -rf $(buildrootdir)
	rm -rf $(mainmsconfigfile)
#	rm -rf $(dependencies)

ms-logclean:
	@rm -rf ms-tests.log ms-sim-tests.log
	@for n in $(NOIGNOREMODULES); do \
		rm -rf $(srcrootdir)/$$n/ms-tests.log $(srcrootdir)/$$n/*.ms-tests.log $(srcrootdir)/$$n/ms-sim-tests.log $(srcrootdir)/$$n/*.ms-sim-tests.log; \
	done

else

ms-help:
	@cat $(scriptsdir)/ms-long.help

MODULE		= $(notdir $(shell pwd))
builddir	= $(buildrootdir)/$(MODULE)_lib
srcdir		= $(srcrootdir)/$(MODULE)

ms-all: $(MODULE)_lib

# Simulation
%.sim: VSIMFLAGS += -c
%.sim %.simi: VSIMFLAGS += -t ps
%.sim %.simi: $(builddir)/%.tag
	@f=$(patsubst $(builddir)/%.tag,%,$<); \
	if [ -f $@.tcl ]; then \
	  extraflags="-do $@.tcl"; \
	fi; \
	echo "$(VSIM) $(VSIMFLAGS) $$extraflags $$f"; \
	$(VSIM) $(VSIMFLAGS) $$extraflags $$f; \


%.ms-tests:
	@n=$(patsubst %.ms-tests,%,$@); \
	echo "Modelsim compilation regression test for $$n:"; \
	rm -f $$n.ms-tests.log; \
	echo -n "  $$n: "; \
	log=$$n.ms-tests.log; \
	$(MAKE) --no-print-directory -C ../.. ms-ultraclean &> /dev/null; \
	$(MAKE) ms-ultraclean &> /dev/null; \
	$(MAKE) $$n &> $$log; \
	if [ $$? -eq 0 ]; then \
		rm -f $$log; \
		echo "  $$n: OK" >> ms-tests.log; \
		echo "OK"; \
	else \
		echo "  $$n: *****KO*****" >> ms-tests.log; \
		echo "*****KO*****"; \
	fi

ms-tests:
	@echo "Modelsim compilation non-regression test:"; \
	rm -f *ms-tests.log; \
	for n in $(patsubst %.vhd,%,$(wildcard *.vhd)); do \
		echo -n "  $$n: "; \
		log=$$n.ms-tests.log; \
		$(MAKE) --no-print-directory -C ../.. ms-ultraclean &> /dev/null; \
		$(MAKE) ms-ultraclean &> /dev/null; \
		$(MAKE) $$n &> $$log; \
		if [ $$? -eq 0 ]; then \
			rm -f $$log; \
			echo "  $$n: OK" >> ms-tests.log; \
			echo "OK"; \
		else \
			echo "  $$n: *****KO*****" >> ms-tests.log; \
			echo "*****KO*****"; \
		fi; \
	done

ms-sim-tests:
	@echo "Modelsim simulation non-regression test:"; \
	rm -f *ms-sim-tests.log; \
	for n in $(MS-SIM-TESTS); do \
		echo -n "  $$n: "; \
		log=$$n.ms-sim-tests.log; \
		$(MAKE) --no-print-directory -C ../.. ms-ultraclean &> /dev/null; \
		$(MAKE) ms-ultraclean &> /dev/null; \
		$(MAKE) $$n.sim &> $$log; \
		s1=$$?; \
		grep --ignore-case --quiet 'Regression test passed' $$log; \
		s2=$$?; \
		if [ $$s1 -eq 0 -a $$s2 -eq 0 ]; then \
			rm -f $$log; \
			echo "  $$n: OK" >> ms-sim-tests.log; \
			echo "OK"; \
		else \
			echo "  $$n: *****KO*****" >> ms-sim-tests.log; \
			echo "*****KO*****"; \
		fi; \
	done

ms-clean:
	rm -rf transcript *.wlf

ms-ultraclean:
	rm -rf transcript *.wlf
	rm -rf $(builddir)
	rm -f $(MSCONFIGFILENAME)

ms-logclean:
	rm -rf ms-tests.log *.ms-tests.log ms-sim-tests.log *.ms-sim-tests.log

$(basename $(wildcard *.vhd)) : % : $(builddir)/%.tag

$(basename $(wildcard *.v)) : % : $(builddir)/%.tag

endif

%.tag:
	@f=$(basename $(notdir $@)); \
	m=$(notdir $(patsubst %_lib/,%,$(dir $@))); \
	if [ -f $(srcrootdir)/$${m}/$${f}.vhd ]; then \
		echo "$(VCOM) $(VCOMFLAGS) -work $${m}_lib $${f}.vhd"; \
		$(VCOM) $(VCOMFLAGS) -work $${m}_lib $(srcrootdir)/$${m}/$${f}.vhd && \
		touch $(buildrootdir)/$${m}_lib/$${f}.tag; \
	else \
		echo "$(VLOG) $(VLOGFLAGS) -work $${m}_lib $${f}.v"; \
		$(VLOG) $(VLOGFLAGS) -work $${m}_lib $(srcrootdir)/$${m}/$${f}.v && \
		touch $(buildrootdir)/$${m}_lib/$${f}.tag; \
	fi;

$(buildrootdir)/exists:
	mkdir --parents $(buildrootdir)
	touch $@

$(buildrootdir)/%_lib/exists: $(buildrootdir)/exists
	@cd $(rootdir); \
	m=$(patsubst $(buildrootdir)/%_lib/exists,%,$@); \
	builddir=$(buildrootdir)/$${m}_lib; \
	libdir=$$builddir/lib; \
	libname=$${m}_lib; \
	mkdir --parents $$builddir; \
	echo "$(VLIB) $$libdir"; \
	$(VLIB) $$libdir; \
	echo "$(VMAP) $$libname $$libdir"; \
	$(VMAP) $$libname $$libdir; \
	srcdir=$(srcrootdir)/$${m}; \
	cd $$srcdir; \
	echo "[Library]" > $(MSCONFIGFILENAME); \
	echo "others = ../../$(MSCONFIGFILENAME)" >> $(MSCONFIGFILENAME); \
	echo "work = $$libdir" >> $(MSCONFIGFILENAME); \
	touch $@
