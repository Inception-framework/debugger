ifneq ($(KERNELRELEASE),)
# kbuild part of makefile
obj-m  := hello_world_module.o

else
# normal makefile
KDIR ?= /lib/modules/`uname -r`/build

default:
	$(MAKE) -C $(KDIR) M=$$PWD
endif

CFLAGS	:= -g -c
CC	:= $(CROSS_COMPILE)gcc
PRGS	:= sab4z hello_world
OBJS	:= $(patsubst %,%.o,$(PRGS))

$(OBJS): %.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

$(PRGS): %: %.o
	$(CC) -o $@ $<

clean:
	rm -f $(OBJS) $(PRGS)
