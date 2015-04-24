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
RC		= rc
RCFLAGS		= -E -6432 -quiet3264

.PHONY: rc-help rc-lib-help rc-ultraclean

ultraclean: rc-ultraclean

rc-lib-help:
	@cat $(scriptsdir)/rc-lib.help

ifeq ($(call fullpath,.),$(rootdir))

rc-tests:
	@echo "Cadence RC synthesis regression test:"; \
	rm -f rc-tests.log; \
	for n in $(NOIGNOREMODULES); do \
		$(MAKE) -C $(srcrootdir)/$$n rc-tests | tee -a rc-tests.log; \
	done

rc-help:
	@cat $(scriptsdir)/rc-short.help

rc-ultraclean:

rc-logclean:
	@rm -rf rc-tests.log
	@for n in $(NOIGNOREMODULES); do \
		rm -rf $(srcrootdir)/$$n/rc-tests.log $(srcrootdir)/$$n/*.rc-tests.log
	done

else

rc-help:
	@cat $(scriptsdir)/rc-long.help

%.rsyn:
	@RC_SYN_TOP=$(basename $@); \
	stamp=`date +'%s'`; \
	syndir="$$RC_SYN_TOP.rc-syn.$$stamp"; \
	mkdir $$syndir; \
	cd $$syndir; \
	s=`stty -g`; \
	RC_SYN_TOP=$$RC_SYN_TOP $(RC) $(RCFLAGS) -files $(scriptsdir)/rc.tcl; \
	stty $$s; \
	cd ..; \
	syndir_link="$$RC_SYN_TOP.rc-syn"; \
	rm -f $$syndir_link; \
	ln -s $$syndir $$syndir_link; \
	echo "--------------------------------------------------------------------------------"; \
	echo "Results stored in $$syndir"; \
	echo "--------------------------------------------------------------------------------"

rc-tests:
	@echo "Cadence RC synthesis regression test:"; \
	rm -f *rc-tests.log; \
	for n in $(RC-SYN-TESTS); do \
		echo -n "  $$n: "; \
		log=$$n.rc-tests.log; \
		$(MAKE) $$n.rsyn &> $$log; \
		if [ $$? -eq 0 ]; then \
			rm -f $$log; \
			echo "  $$n: OK" >> rc-tests.log; \
			echo "OK"; \
		else \
			echo "  $$n: *****KO*****" >> rc-tests.log; \
			echo "*****KO*****"; \
		fi; \
	done

rc-ultraclean:
	rm -rf *.rc-syn.* *.rc-syn rc.cmd.* rc.log.*

rc-logclean:
	rm -rf rc-tests.log *.rc-tests.log

endif
