This repository and its sub-directories contain the VHDL source code, VHDL simulation environment, simulation and synthesis scripts of a simple design example for the Xilinx Zynq core. It can be ported on any board based on Xilinx Zynq cores but has been specifically designed for the Zybo board by Digilent.

# Table of content
1. [License](#license)
1. [Content](#Content)
1. [Description](#Description)
1. [Building](#Building)
1. [Running](#Running)
1. [Examples](#Building)

# <a name="License"></a>License

Copyright Telecom ParisTech  
Copyright Renaud Pacalet (renaud.pacalet@telecom-paristech.fr)

Licensed uder the CeCILL license, Version 2.1 of
2013-06-21 (the "License"). You should have
received a copy of the License. Else, you may
obtain a copy of the License at:

http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt

# <a name="Content"></a>Content

```
.
|-- C/
|   |-- hello_world.c
|-- COPYING
|-- COPYING-FR
|-- COPYRIGHT
|-- HEADER.#
|-- HEADER.--
|-- Makefile			
|-- README.md
|-- hdl/
|   |-- axi_pkg.vhd
|   |-- axi_register.vhd
|   |-- debouncer.vhd
|   |-- utils.vhd
+-- scripts/
    |-- boot.bif
    |-- dts.tcl
    |-- fsbl.tcl
    |-- vvsyn.tcl
```

# <a name="Description"></a>Description

This design is a simple AXI-AXI bridge with two slave AXI ports, one master AXI port, several internal registers, a 4-bits input connected to the 4 slide-switches, a 4-bits output connected to the 4 LEDs and a one bit command input connected to the leftmost push-button (BTN0):

```
                                                         +---+
                                                         |DDR|
                                                         +---+
                                                           ^
                                                           |
---------+     +-------------------+     +-----------------|---
   PS    |     |  SIMPLE REGISTER  |     |   PS            v
         |     |                   |     |             +------+
M_AXI_GP1|<--->|S1_AXI<----->M_AXI |<--->|S_AXI_HP0<-->| DDR  |
         |     |                   |     |             | Ctrl |
M_AXI_GP0|<--->|S0_AXI<-->REGs     |     |             +------+
---------+     |                   |     +---------------------
               |                   |
     BTN0 ---->|BTN                |
               |                   |
 Switches ---->|SW              LED|----> LEDs
               +-------------------+
```

The S1_AXI AXI slave port is forwarded to the M_AXI AXI master port. It is used to access the DDR controller from the Processing System (PS) through the FPGA fabric. The S0_AXI AXI slave port is used to access the internal registers. The mapping of the S0_AXI address space is the following:

| Address      | Mapped resource   | Description                                 | 
| ------------ | ----------------- | ------------------------------------------- | 
| `0x40000000` | STATUS (ro)       | 32 bits read-only status register           | 
| `0x40000004` | R      (rw)       | 32 bits general purpose read-write register | 
| `0x40000008` | Unmapped          |                                             | 
| ...          | Unmapped          |                                             | 
| `0x7ffffffc` | Unmapped          |                                             | 

The organization of the status register is the following:

| Bits     | Role                                                |
|----------|-----------------------------------------------------|
|  `3...0` | LIFE, rotating bit (life monitor)                   |
|  `7...4` | CNT, counter of BTN events                          |
| `11...8` | ARCNT, counter of S1_AXI address-read transactions  |
| `15..12` | RCNT, counter of S1_AXI date-read transactions      |
| `19..16` | AWCNT, counter of S1_AXI address-write transactions |
| `23..20` | WCNT, counter of S1_AXI data-write transactions     |
| `27..24` | BCNT, counter of S1_AXI write-response transactions |
| `31..28` | SW, current value                                   |

The BTN input is filtered by a debouncer-resynchronizer. The counter of BTN events is initialized to zero after reset. Each time the BTN push-button is pressed, the counter is incremented modulus 16 and its value is sent to LED until the button is released. When the button is released the current value CNT of the counter selects which 4-bits slice of which internal register is sent to LED: bits 4*CNT+3..4*CNT of STATUS register when 0<=CNT<=7, else bits 4*(CNT-8)+3..4*(CNT-8) of R register.

Thanks to the S1_AXI to M_AXI bridge the complete 1GB address space `[0x00000000..0x40000000[` is also mapped to `[0x80000000..0xc0000000[`. Note that the Zybo board has only 512 MB of DDR and accesses above the DDR limit either fall back in the low half (aliasing) or raise errors. Accesses in the unmapped region of the S0_AXI `[0x40000008..0x80000000[` address space will raise DECERR AXI errors. Write accesses to the read-only status register will raise SLVERR AXI errors.

Moreover, depending on the configuration, Zynq-based systems have a reserved low addresses range that cannot be accessed from the AXI_HP ports. In these systems this low range can be accessed in the `[0x00000000..0x40000000[` range but not in the `[0x80000000..0xc0000000[` range.

# <a name="Building"></a>Building the whole example from scratch

Fetch sources (if not already done, else simply git pull to get the latest versions)
```
export DISTRIB=<some-path>
export SIMPLEREGISTER4ZYNQ=$DISTRIB/simpleregister4zynq
export UBOOT=$DISTRIB/u-boot-xlnx
export KERNEL=$DISTRIB/linux-xlnx
export DEVICETREEXLNX=$DISTRIB/device-tree-xlnx
git clone --recursive git@gitlab.eurecom.fr:renaud.pacalet/simpleregister4zynq.git $SIMPLEREGISTER4ZYNQ
git clone http://github.com/Xilinx/u-boot-xlnx.git $UBOOT
git clone http://github.com/Xilinx/linux-xlnx.git $KERNEL
git clone http://github.com/Xilinx/device-tree-xlnx.git $DEVICETREEXLNX
cd $DISTRIB
wget http://www.wiki.xilinx.com/file/view/arm_ramdisk.image.gz

##########
# U-Boot #
##########
cd $UBOOT
git pull
export CROSS_COMPILE=arm-xilinx-linux-gnueabi-
make distclean
rm -rf build
make O=build zynq_zed_config all
export PATH=$PATH:$UBOOT/build/tools

##########
# rootfs #
##########
# Note: to modify the root file system before building the image:
# cd $DISTRIB
# gunzip ramdisk.image.gz
# chmod u+rwx ramdisk.image
# mkdir tmp_mnt/
# sudo mount -o loop ramdisk.image tmp_mnt/
## Modify tmp_mnt/
# sudo umount tmp_mnt/
# gzip ramdisk.image
mkimage -A arm -T ramdisk -C gzip -d arm_ramdisk.image.gz uramdisk.image.gz

################
# Linux kernel #
################
cd $KERNEL
git pull
export CROSS_COMPILE=arm-xilinx-linux-gnueabi-
make distclean
make ARCH=arm xilinx_zynq_defconfig
make ARCH=arm menuconfig
make ARCH=arm UIMAGE_LOADADDR=0x8000 uImage
export PATH=$KERNEL/scripts/dtc:$PATH

############################################
# Hardware and hardware dependant software #
############################################
export DESIGN=$SIMPLEREGISTER4ZYNQ/hdl/axi_register
cd $DESIGN
cp $UBOOT/build/u-boot u-boot.elf
make syn
make fsbl dtb bin
mkdir sdcard
cp axi_register_wrapper.vv-syn/top.sdk/dts/system.dtb sdcard
cp $KERNEL/arch/arm/boot/uImage sdcard
cp $DISTRIB/uramdisk.image.gz sdcard
cp boot.bin sdcard
```

# <a name="Running"></a>Using the simple register on the ZedBoard

* Copy the provided files on a SD card:
```
cp boot.bin system.dtb uImage uramdisk.image.gz /media/SDCARD
sync
```
* To avoid strange bugs, please cross-check the result of the copy:
  * compute the md5sum of the provided files,
  * copy the files on the SD card
  * sync and un-mount the SD card
  * mount the SD card again
  * compute the md5sum of the SD card files and compare with the originals
* Configure the ZedBoard jumpers to boot from SD card (set MIO4 and MIO5, unset MIO2, MIO3 and MIO6), insert the SD card, plug the power and console USB cable and power on.
* Launch a terminal emulator like minicom (minicom -D /dev/ttyACM0) and stop U-Boot by hitting the keyboard.
* Set the following U-Boot environment variables:
```
     setenv bootcmd 'run $modeboot'
     setenv modeboot 'sdboot'
     setenv sdboot 'fatload mmc 0 0x3000000 uImage && fatload mmc 0 0x2000000 uramdisk.image.gz && fatload mmc 0 0x2a00000 system.dtb && bootm 0x3000000 0x2000000 0x2a00000'
```
   and save them on the QSPI flash:
```
     saveenv
```
   so that U-Boot remembers them for the next time.
* Continue the boot sequence (boot), wait until Linux boots and start interacting with the register (with devmem, for instance).

# <a name="Example"></a>Example experiments

```
# First test the design in the PL by setting the switches to any configuration
# other than 0x00 (e.g. 0x02) and looking at the LEDs: if the LEDs illuminate in
# the 0x55 configuration things are probably OK, else the PL does not work as
# expected.

# Reading the current status of the 8 switches:
zynq> devmem 0x40000000 32
0x00000002

# Illuminating the 8 LEDs (first set the switches to 0x00):
zynq> devmem 0x40000004 32 0xFF

# Reading in the external memory through the FPGA fabric:
zynq> devmem 0x90000000 32

# Power off
zynq> poweroff
The system is going down NOW!
Sent SIGTERM to all processes
Sent SIGKILL to all processes
Requesting system poweroff
reboot: System halted
```
