This repository and its sub-directories contain the VHDL source code, VHDL simulation environment, simulation and synthesis scripts of a simple design example for the Xilinx Zynq core. It can be ported on any board based on Xilinx Zynq cores but has been specifically designed for the Zybo board by Digilent.

# Table of content
1. [License](#license)
1. [Content](#Content)
1. [Description](#Description)
1. [Installing from the archive](#Archive)
1. [Running](#Running)
1. [Building from scratch](#Building)
1. [Going further](#Further)

# <a name="License"></a>License

Copyright Telecom ParisTech  
Copyright Renaud Pacalet (renaud.pacalet@telecom-paristech.fr)

Licensed uder the CeCILL license, Version 2.1 of
2013-06-21 (the "License"). You should have
received a copy of the License. Else, you may
obtain a copy of the License at:

http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt

# <a name="Content"></a>Content

    .
    |-- C/
    |   |-- hello_world.c
    |-- COPYING
    |-- COPYING-FR
    |-- COPYRIGHT
    |-- Makefile			
    |-- README.md
    |-- hdl/
    |   |-- axi_pkg.vhd
    |   |-- sab4z.vhd
    |   |-- debouncer.vhd
    |   |-- utils.vhd
    +-- scripts/
    |   |-- boot.bif
    |   |-- dts.tcl
    |   |-- fsbl.tcl
    |   |-- vvsyn.tcl
    +-- sdcard.tgz

# <a name="Description"></a>Description

This design is a simple AXI-to-AXI bridge for Zynq cores (`sab4z`) with two slave AXI ports, one master AXI port, two internal registers, a 4-bits input connected to the 4 slide-switches, a 4-bits output connected to the 4 LEDs and a one bit command input connected to the rightmost push-button (BTN0):

                                                             +---+
                                                             |DDR|
                                                             +---+
                                                               ^
                                                               |
    ---------+     +-------------------+     +-----------------|---
       PS    |     |       SAB4Z       |     |   PS            v
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

The requests from the S1_AXI AXI slave port are forwarded to the M_AXI AXI master port and the responses from the M_AXI AXI master port are forwarded to the S1_AXI AXI slave port. S1_AXI is used to access the DDR controller from the Processing System (PS) through the FPGA fabric. The S0_AXI AXI slave port is used to access the internal registers. The mapping of the S0_AXI address space is the following:

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

The BTN input is filtered by a debouncer-resynchronizer. The counter of BTN events CNT is initialized to zero after reset. Each time the BTN push-button is pressed, CNT is incremented (modulus 16) and its value is sent to LED until the button is released. When the button is released the current value of CNT selects which 4-bits slice of which internal register is sent to LED: bits 4*CNT+3..4*CNT of STATUS register when 0<=CNT<=7, else bits 4*(CNT-8)+3..4*(CNT-8) of R register. Accesses to the unmapped region of the S0_AXI `[0x40000008..0x80000000[` address space will raise DECERR AXI errors. Write accesses to the read-only status register will raise SLVERR AXI errors.

Thanks to the S1_AXI to M_AXI bridge the complete 1GB address space `[0x00000000..0x40000000[` is also mapped to `[0x80000000..0xc0000000[`. Note that the Zybo board has only 512 MB of DDR and accesses above the DDR limit either fall back in the low half (aliasing) or raise errors. Moreover, depending on the configuration, Zynq-based systems have a reserved low addresses range that cannot be accessed from the PL. In these systems this low range can be accessed in the `[0x00000000..0x40000000[` range but not in the `[0x80000000..0xc0000000[` range where errors are raised. Last but not least, randomly modifying the content of the memory using the `[0x80000000..0xc0000000[` range can crash the running software stack or lead to unexpected behaviours if the modified region is currently in use.

# <a name="Archive"></a>Installing from the archive

Insert a micro SD card in your card reader and unpack the provided `sdcard.tgz` archive to it:

    cd sab4z
    tar -C <path-to-mounted-sd-card> sdcard.tgz
    sync

Unmount the micro SD card.

# <a name="Running"></a>Using SAB4Z on the Zybo

* Plug the micro SD card in the Zybo and connect the USB cable.
* Check the position of the jumper that selects the power source (USB or power adapter).
* Check the position of the jumper that selects the boot medium (SD card).
* Power on.
* Launch a terminal emulator (minicom, picocom...) with the following configuration:
  * Baudrate 115200
  * No flow control
  * No paritys
  * 8 bits characters
  * No port reset
  * No port locking
  * Connected to the `/dev/ttyUSB1` device (if needed use `dmesg` to check the device name)
  * e.g. `picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1`
* Wait until Linux boots, log in as root and start interacting with SAB4Z (with `devmem`, for instance).

# <a name="Building"></a>Building the whole example from scratch

To build the project you will need the Xilinx tools (Vivado and its companion SDK). In the following we assume that they are properly installed and in your PATH. You will also need to download several tools, configure and build them. Some steps can be run in parallel because they do not depend on the results of other steps. Let us first clone all components from their respective Git repositories.

## Downloads

    export XLINUX=<some-path>/linux-xlnx
    export XUBOOT=<some-path>/u-boot-xlnx
    export XDTS=<some-path>/device-tree-xlnx
    git clone https://github.com/Xilinx/linux-xlnx.git $XLINUX
    git clone https://github.com/Xilinx/u-boot-xlnx.git $XUBOOT
    git clone http://github.com/Xilinx/device-tree-xlnx.git $XDTS
    export SR4Z=<some-path>
    git clone https://gitlab.eurecom.fr/renaud.pacalet/sab4z.git $SR4Z
    export BUILDROOT=<some-path>
    git clone http://git.buildroot.net/git/buildroot.git $BUILDROOT

## Hardware synthesis

    cd $SR4Z
    make vv-all

The bitstream `top_wrapper.bit` is at:

    $SR4Z/build/vv/top.runs/impl_1

## Configure and build the Linux kernel

    export CROSS_COMPILE=arm-xilinx-linux-gnueabi- # (note the trailing '-')
    export PATH=$PATH:<path-to-xilinx-sdk>/gnu/arm/lin/bin
    ${CROSS_COMPILE}gcc --version

Note the toolchain version (result of the last command), we will need it later.

    cd $XLINUX
    make mrproper
    make O=build ARCH=arm xilinx_zynq_defconfig
    make -j8 O=build ARCH=arm zImage

Adapt the `make` -j option to your host system. The generated compressed Linux kernel image is at:

    $XLINUX/build/arch/arm/boot/zImage

Note: if needed the configuration of the kernel can be tuned by running:

    make O=build ARCH=arm menuconfig

before building the kernel.

## Configure and build U-Boot, the second stage boot loader

To build U-Boot we need the Device Tree Compiler (dtc), which is built at the same time as the Linux kernel and can be found at:

    $XLINUX/build/scripts/dtc/dtc

Unless you have another dtc binary somewhere, wait until the Linux kernel is built before building U-Boot.

    export PATH=$PATH:$XLINUX/build/scripts/dtc
    cd $XUBOOT
    make mrproper
    make O=build zynq_zybo_defconfig
    make -j8 O=build

Adapt the `make` -j option to your host system. The generated ELF of U-Boot is at:

    $XUBOOT/build/u-boot

Note: if needed the configuration of U-Boot can be tuned by running:

    make O=build menuconfig

before building U-Boot.

## Configure and build a root file system

There is no buildroot configuration file for the Zybo board but the ZedBoard configuration should work also for the Zybo:

cd $BUILDROOT
make O=build zedboard_defconfig
make O=build menuconfig

In the buildroot configuration menus change the following options:

    Build options -> Location to save buildroot config -> ./build/buildroot.config
    Build options -> Enable compiler cache -> yes (faster build)
    Toolchain -> Toolchain type -> External toolchain
    Toolchain -> Toolchain -> Custom toolchain
    Toolchain -> Toolchain path -> <path-to-xilinx-sdk/gnu/arm/lin
    Toolchain -> Toolchain prefix -> arm-xilinx-linux-gnueabi # (no trailing '-')
    Toolchain -> External toolchain gcc version -> <the-toolchain-version-you-noted>
    Toolchain -> External toolchain C library -> glibc/eglibc
    Toolchain -> Toolchain has RPC support? -> yes
    System configuration -> System hostname -> sr4z
    System configuration -> System banner -> Welcome to SR4Z (c) Telecom ParisTech
    Kernel -> Linux Kernel -> no
    Bootloaders -> U-Boot -> no

Quit with saving. Save the buildroot configuration and build the root file system:

    make O=build savedefconfig
    make O=build

If you get an error:

    Incorrect selection of kernel headers: expected x.x.x, got y.y.y

note the `y.y.y` and run again the buildroot configuration:

    make O=build menuconfig

change:

    Toolchain -> External toolchain kernel headers series -> the-kernel-headers-version-you-noted

quit with saving, save again the configuration and build:

    make O=build savedefconfig
    make O=build

The compressed archive of the root filesystem is at:

    $BUILDROOT/build/images/rootfs.cpio.gz

## Generate and build the hardware dependant software

### Linux kernel device tree

Generate the device tree sources:

    cd $SR4Z
    make dts

The sources are at `build/dts`. If needed, edit them before compiling the device tree blob:

    make dtb

The device tree blob is at:

    build/devicetree.dtb

### First Stage Boot Loader (FSBL)

Generate the FSBL sources

    make fsbl

The sources are at `build/fsbl`. If needed, edit them before compiling the FSBL:

    make fsblelf

The binary of the FSBL is at:

    build/fsbl/executable.elf

### Zyqnq boot image

We are ready to generate the Zynq boot image. First copy the U-Boot ELF:

    cp $XUBOOT/build/u-boot build/u-boot.elf

and generate the image:

    bootgen -w -image scripts/boot.bif -o build/boot.bin

The boot image is at:

    build/boot.bin

### U-Boot formatted images of Linux kernel and root file system

Add the U-Boot tools directory to your PATH and format the compressed Linux kernel image and the root file system for U-Boot:

    export PATH=$PATH:$XUBOOT/build/tools
    ZIMAGE=$XLINUX/build/arch/arm/boot/zImage
    ROOTFS=$BUILDROOT/build/images/rootfs.cpio.gz
    mkimage -A arm -O linux -C none -T kernel -a 0x8000 -e 0x8000 -d $ZIMAGE build/uImage
    mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

### Preparing the micro SD card

Finally, copy the different components to the micro SD card:

    cd build
    cp boot.bin devicetree.dtb uImage uramdisk.image.gz <path-to-mounted-sd-card>
    sync

Unmount the micro SD card.

# <a name="Further"></a>Going further

## Creating, compiling and running a software application

TODO

## Accessing SAB4Z from a software application

TODO

## Adding a Linux driver for SAB4Z

TODO

## Booting Linux across SAB4Z

TODO

