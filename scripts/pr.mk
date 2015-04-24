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
PRECISION	= precision
PRECISIONFLAGS	= -shell -rtlplus

.PHONY: pr-help pr-ultraclean

ultraclean: pr-ultraclean

ifeq ($(call fullpath,.),$(rootdir))

pr-tests:
	@echo "Precision RTL synthesis regression test:"; \
	rm -f pr-tests.log; \
	for n in $(NOIGNOREMODULES); do \
		$(MAKE) -C $(srcrootdir)/$$n pr-tests | tee -a pr-tests.log; \
	done

pr-help:
	@cat $(scriptsdir)/pr-short.help

pr-ultraclean:

pr-logclean:
	@rm -rf pr-tests.log
	@for n in $(NOIGNOREMODULES); do \
		rm -rf $(srcrootdir)/$$n/pr-tests.log $(srcrootdir)/$$n/*.pr-tests.log
	done

else

pr-help:
	@cat $(scriptsdir)/pr-long.help

export

%.edf %.psyn:
	@PR_SYN_TOP=$(basename $@) $(PRECISION) $(PRECISIONFLAGS) -file $(scriptsdir)/pr.tcl

pr-tests:
	@echo "Precion RTL synthesis regression test:"; \
	rm -f *pr-tests.log; \
	for n in $(PR-SYN-TESTS); do \
		echo -n "  $$n: "; \
		log=$$n.pr-tests.log; \
		$(MAKE) $$n.psyn &> $$log; \
		if [ $$? -eq 0 ]; then \
			rm -f $$log; \
			echo "  $$n: OK" >> pr-tests.log; \
			echo "OK"; \
		else \
			echo "  $$n: *****KO*****" >> pr-tests.log; \
			echo "*****KO*****"; \
		fi; \
	done

pr-ultraclean:
	rm -rf *.pr-syn.* *.pr-syn *.edf

pr-logclean:
	rm -rf pr-tests.log *.pr-tests.log

endif
