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

## Tool definitions
VIVADO		= vivado
VIVADOFLAGS	?= -mode batch

.PHONY: vv-help vv-ultraclean

ultraclean: vv-ultraclean

ifeq ($(call fullpath,.),$(rootdir))

vv-tests:
	@echo "Xilinx Vivado synthesis regression test:"; \
	rm -f vv-tests.log; \
	for n in $(NOIGNOREMODULES); do \
		$(MAKE) -C $(srcrootdir)/$$n vv-tests | tee -a vv-tests.log; \
	done

vv-help:
	@cat $(scriptsdir)/vv-short.help

vv-ultraclean:

vv-logclean:
	@rm -rf vv-tests.log
	@for n in $(NOIGNOREMODULES); do \
		rm -rf $(srcrootdir)/$$n/vv-tests.log $(srcrootdir)/$$n/*.vv-tests.log
	done

else

vv-help:
	@cat $(scriptsdir)/vv-long.help

%.vsyn:
	@VV_SYN_TOP=$(basename $@); \
	stamp=`date +'%s'`; \
	syndir="$$VV_SYN_TOP.vv-syn.$$stamp"; \
	mkdir $$syndir; \
	cd $$syndir; \
	VV_SYN_TOP=$$VV_SYN_TOP $(VIVADO) $(VIVADOFLAGS) -source $(scriptsdir)/vv.tcl; \
	cd ..; \
	syndir_link="$$VV_SYN_TOP.vv-syn"; \
	rm -f $$syndir_link; \
	ln -s $$syndir $$syndir_link; \
	echo "--------------------------------------------------------------------------------"; \
	echo "Results stored in $$syndir"; \
	echo "--------------------------------------------------------------------------------"

vv-tests:
	@echo "Xilinx Vivado synthesis regression test:"; \
	rm -f *vv-tests.log; \
	for n in $(VV-SYN-TESTS); do \
		echo -n "  $$n: "; \
		log=$$n.vv-tests.log; \
		$(MAKE) $$n.vsyn &> $$log; \
		if [ $$? -eq 0 ]; then \
			rm -f $$log; \
			echo "  $$n: OK" >> vv-tests.log; \
			echo "OK"; \
		else \
			echo "  $$n: *****KO*****" >> vv-tests.log; \
			echo "*****KO*****"; \
		fi; \
	done

vv-ultraclean:
	rm -rf *.vv-syn *.vv-syn.* vivado_*.backup.jou vivado.jou vivado.log vivado_*.backup.log

vv-logclean:
	rm -rf vv-tests.log *.vv-tests.log

endif
