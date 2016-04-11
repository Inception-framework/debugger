CROSS_COMPILE	?= arm-buildroot-linux-gnueabi-
PRGS		:= sab4z hello_world
OBJS		:= $(patsubst %,%.o,$(PRGS))

define HELP_message
make help: this message
make foo: compile foo.c
make ARCH=arm KDIR=<path-to-linux-build> hello_world_module: build hello world module
endef
export HELP_message

help:
	@echo "$$HELP_message"

ifneq ($(KERNELRELEASE),)
# kbuild part of makefile
obj-m  := hello_world_module.o

else
# normal makefile
KDIR ?= /lib/modules/`uname -r`/build

default:
	$(MAKE) -C $(KDIR) M=$$PWD

all: $(PRGS)

$(PRGS): %: %.c
	$(CROSS_COMPILE)gcc -g -o $@ $<

clean:
	rm -f $(OBJS) $(PRGS)

endif

