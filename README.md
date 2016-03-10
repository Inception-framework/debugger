This repository and its sub-directories contain the VHDL source code, VHDL simulation environment, simulation and synthesis scripts of SAB4Z, a simple design example for the Xilinx Zynq core. It can be ported on any board based on Xilinx Zynq cores but has been specifically designed for the Zybo board by Digilent.

# Table of content
* [License](#license)
* [Content](#Content)
* [Description](#Description)
* [Install from the archive](#Archive)
* [Run SAB4Z on the Zybo](#Run)
    * [Read the STATUS register](#ReadStatus)
    * [Read and write the R register](#ReadWriteR)
    * [Read DDR locations](#ReadDDR)
    * [Press the push-button, select LED driver](#PushButton)
    * [Mount the SD card](#MountSDCard)
    * [Halt the system](#Halt)
* [Build the whole example from scratch](#Building)
    * [Downloads](#Downloads)
    * [Hardware synthesis](#Synthesis)
    * [Configure and build the Linux kernel](#Kernel)
    * [Configure and build U-Boot, the second stage boot loader](#Uboot)
    * [Configure and build a root file system](#RootFS)
    * [Generate and build the hardware dependant software](#SDK)
        * [Linux kernel device tree](#DTS)
        * [First Stage Boot Loader (FSBL)](#FSBL)
        * [Zynq boot image](#BootImg)
        * [Create U-Boot images of the Linux kernel and root file system](#Uimages)
        * [Prepare the micro SD card](#SDCard)
* [Going further](#Further)
    * [Create, compile and run a user software application](#UserApp)
        * [Transfer files from host PC to Zybo on SD card](#SDTransfer)
        * [Add custom files to the root file system](#Overlays)
        * [File transfer on the serial link](#RX)
    * [Access SAB4Z from a user software application](#SAB4ZSoft)
    * [Add a Linux driver for SAB4Z](#LinuxDriver)
    * [Boot Linux across SAB4Z](#BootInAAS)

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
    ├── C
    │   └── hello_world.c
    ├── COPYING
    ├── COPYING-FR
    ├── COPYRIGHT
    ├── hdl
    │   ├── axi_pkg.vhd
    │   ├── debouncer.vhd
    │   ├── sab4z.vhd
    │   └── utils.vhd
    ├── images
    │   ├── sab4z.fig
    │   ├── sab4z.png
    │   └── zybo.png
    ├── Makefile
    ├── README.md
    ├── scripts
    │   ├── boot.bif
    │   ├── dts.tcl
    │   ├── fsbl.tcl
    │   └── vvsyn.tcl
    └── sdcard.tgz

# <a name="Description"></a>Description

**SAB4Z** is a **S**imple **A**xi-to-axi **B**ridge **F**or **Z**ynq cores with two slave AXI ports (S0_AXI and S1_AXI), one master AXI port (M_AXI), two internal registers (STATUS and R), a 4-bits input (SW), a 4-bits output (LED) and a one bit command input (BTN). The following figure represents SAB4Z mapped in the Programmable Logic (PL) of the Zynq core of a Zybo board. SAB4Z is connected to the Processing System (PS) of the Zynq core through the 3 AXI ports. When the ARM processor of the PS reads or writes at addresses in the `[0..1G[` range (first giga byte) it accesses the DDR memory of the Zybo (512MB), directly through the DDR controller. When the addresses fall in the `[1G..2G[` or `[2G..3G[` ranges, it accesses SAB4Z, through its S0_AXI and S1_AXI ports, respectively. SAB4Z can also access the DDR in the `[0..1G[` range, through its M_AXI port. The four slide switches, LEDs and the rightmost push-button (BTN0) of the board are connected to the SW input, the LED output and the BTN input of SAB4Z, respectively.

![SAB4Z on a Zybo board](images/sab4z.png)

As shown on the figure, the accesses from the PS that fall in the `[2G..3G[` range (S1_AXI) are forwarded to M_AXI with an address shift from `[2G..3G[` to `[0..1G[`. The responses from M_AXI are forwarded back to S1_AXI. This path is thus a second way to access the DDR from the PS, through the PL. From the PS viewpoint each address in the `[0..1G[` range has an equivalent address in the `[2G..3G[` range. Note that the Zybo board has only 512 MB of DDR and accesses above the DDR limit fall back in the low half (aliasing). Each DDR location can thus be accessed with 4 different addresses in the `[0..512M[`, `[512M..1G[`, `[2G..2G+512M[` or `[2G+512M..3G[` ranges. Note that depending on the configuration, Zynq-based systems have a reserved low addresses range that cannot be accessed from the PL. In these systems this low range can be accessed in the `[0..1G[` range but not in the `[2G..3G[` range where errors are raised. Last but not least, randomly modifying the content of the memory using the `[2G..3G[` range can crash the running software stack or lead to unexpected behaviours if the modified region is currently in use.


The S0_AXI AXI slave port is used to access the internal registers. The mapping of the S0_AXI address space is the following:

| Address       | Mapped resource   | Description                                 | 
| ------------- | ----------------- | ------------------------------------------- | 
| `0x4000_0000` | STATUS (ro)       | 32 bits read-only status register           | 
| `0x4000_0004` | R      (rw)       | 32 bits general purpose read-write register | 
| `0x4000_0008` | Unmapped          |                                             | 
| ...           | Unmapped          |                                             | 
| `0x7fff_fffc` | Unmapped          |                                             | 

The organization of the STATUS register is the following:

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

The BTN input is filtered by a debouncer-resynchronizer. CNT is a 4-bits counter. It is initialized to zero after reset. Each time the BTN push-button is pressed, CNT is incremented (modulus 16). As long as the button is kept pressed, CNT is sent to LED. When it is released, the current value of CNT selects which 4-bits slice of which internal register is sent to LED: bits 4\*CNT+3..4\*CNT of STATUS register when 0<=CNT<=7, else bits 4\*(CNT-8)+3..4\*(CNT-8) of R register.

Accesses to the unmapped region of the S0_AXI `[0x4000_0008..2G[` address space raise DECERR AXI errors. Write accesses to the read-only STATUS register raise SLVERR AXI errors.

# <a name="Archive"></a>Install from the archive

Insert a micro SD card in your card reader and unpack the provided `sdcard.tgz` archive to it:

    cd sab4z
    tar -C <path-to-mounted-sd-card> sdcard.tgz
    sync

Unmount the micro SD card.

# <a name="Run"></a>Run SAB4Z on the Zybo

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
* Wait until Linux boots, log in as root and start interacting with SAB4Z with `devmem`, for instance.

`devmem` is a busybox utility that allows to access memory locations with their physical addresses. It is privileged but as we are root...

## <a name="ReadStatus"></a>Read the STATUS register

    # devmem 0x40000000 32
    0x00000004
    # devmem 0x40000000 32
    0x00000002
    # devmem 0x40000000 32
    0x00000008

As can be seen, the content of the STATUS register is all zeroes, except its 4 Least Significant Bits (LSBs), the life monitor, that spin with a period of about half a second and thus take different values depending on the exact time of reading. The CNT counter is zero, so the LEDs are driven by the life monitor. Change the configuration of the 4 slide switches, read again the STATUS register and check that the 4 Most Significant Bits (MSBs) reflect the chosen configuration:

    # devmem 0x40000000 32
    0x50000002

## <a name="ReadWriteR"></a>Read and write the R register

    # devmem 0x40000004 32
    0x00000000
    # devmem 0x40000004 32 0x12345678
    # devmem 0x40000004 32
    0x12345678

## <a name="ReadDDR"></a>Read DDR locations

    # devmem 0x01000000 32
    0x4D546529
    # devmem 0x81000000 32
    0x4D546529
    # devmem 0x40000000 32
    0x50001104

ARCNT and RCNT, the counters of address read and data read AXI transactions on AXI slave port S1_AXI, have been incremented because we performed a read access to the DDR at `0x8100_0000`. Let us write a DDR location, for instance `0x8200_0000`, but as we do not know whether the equivalent `0x0200_0000` is currently used by the running software stack, let us first read it and overwrite with the same value:

    # devmem 0x82000000 32
    0xEDFE0DD0
    # devmem 0x82000000 32 0xEDFE0DD0
    # devmem 0x40000000 32
    0x51112204

The read counters have been incremented once more because of the read access to `0x8200_0000`. The 3 write counters (AWCNT, WCNT and BCNT) have also been incremented by the write access to `0x8200_0000`.

## <a name="PushButton"></a>Press the push-button, select LED driver

If we press the push-button and do not release it yet, the LEDs display `0001`, the new value of the incremented CNT. If we release the button the LEDs still display `0001` because when CNT=1 their are driven by... CNT. Press and release the button once more and check that the LEDs display `0010`, the current value of ARCNT. Continue exploring the 16 possible values of CNT and check that the LEDs display what they should.

## <a name="MountSDCard"></a>Mount the SD card

By default the SD card is not mounted but it can be. This is a convenient way to import / export data or even custom applications to / from the host PC (of course, a network interface is even better). Simply add files to the SD card from the host PC and they will show up on the Zybo once the SD card is mounted. Conversely, if you store a file on the mounted SD card from the Zybo, properly unmount the card, remove it from its slot and mount it to your host PC, you will be able to transfer the file to the host PC.

    # mount /dev/mmcblk0p1 /mnt
    # ls /mnt
    boot.bin           devicetree.dtb     uImage             uramdisk.image.gz
    # umount /mnt

Do not forget to unmount the card properly before shutting down the Zybo. If you do not there is a risk that its content is damaged.

## <a name="Halt"></a>Halt the system

Always halt properly before switching the power off:

    # poweroff
    # Stopping network...Saving random seed... done.
    Stopping logging: OK
    umount: devtmpfs busy - remounted read-only
    umount: can't unmount /: Invalid argument
    The system is going down NOW!
    Sent SIGTERM to all processes
    Sent SIGKILL to all processes
    Requesting system poweroff
    reboot: System halted

# <a name="Building"></a>Build the whole example from scratch

To build the project you will need the Xilinx tools (Vivado and its companion SDK). In the following we assume that they are properly installed and in your PATH. You will also need to download several tools, configure and build them. Some steps can be run in parallel because they do not depend on the results of other steps. Let us first clone all components from their respective Git repositories.

## <a name="Downloads"></a>Downloads

    XLINUX=<some-path>/linux-xlnx
    XUBOOT=<some-path>/u-boot-xlnx
    XDTS=<some-path>/device-tree-xlnx
    git clone https://github.com/Xilinx/linux-xlnx.git $XLINUX
    git clone https://github.com/Xilinx/u-boot-xlnx.git $XUBOOT
    git clone http://github.com/Xilinx/device-tree-xlnx.git $XDTS
    SAB4Z=<some-path>
    git clone https://gitlab.eurecom.fr/renaud.pacalet/sab4z.git $SAB4Z
    BUILDROOT=<some-path>
    git clone http://git.buildroot.net/git/buildroot.git $BUILDROOT

## <a name="Synthesis"></a>Hardware synthesis

    cd $SAB4Z
    make vv-all

The generated bitstream is:

    $SAB4Z/build/vv/top.runs/impl_1/top_wrapper.bit

## <a name="Kernel"></a>Configure and build the Linux kernel

    export CROSS_COMPILE=arm-xilinx-linux-gnueabi- # (note the trailing '-')
    export PATH=$PATH:<path-to-xilinx-sdk>/gnu/arm/lin/bin
    ${CROSS_COMPILE}gcc --version

Note the toolchain version (result of the last command), we will need it later.

    cd $XLINUX
    make mrproper
    make O=build ARCH=arm xilinx_zynq_defconfig
    make -j8 O=build ARCH=arm zImage

Adapt the `make` -j option to your host system.

Note: if needed the configuration of the kernel can be tuned by running:

    make O=build ARCH=arm menuconfig

before building the kernel. The generated compressed Linux kernel image is:

    ZIMAGE=$XLINUX/build/arch/arm/boot/zImage

The Device Tree Compiler (dtc) is also generated and can be found in:

    $XLINUX/build/scripts/dtc

Add this directory to your PATH, we will need dtc later:

    export PATH=$PATH:$XLINUX/build/scripts/dtc

## <a name="Uboot"></a>Configure and build U-Boot, the second stage boot loader

The U-Boot build process uses dtc. Unless you have another dtc binary somewhere, wait until the Linux kernel is built before building U-Boot.

    cd $XUBOOT
    make mrproper
    make O=build zynq_zybo_defconfig
    make -j8 O=build

Adapt the `make` -j option to your host system.

Note: if needed the configuration of U-Boot can be tuned by running:

    make O=build menuconfig

before building U-Boot. The generated ELF of U-Boot is:

    UBOOT=$XUBOOT/build/u-boot

The mkimage U-Boot utility is also generated and can be found in:

    $XUBOOT/build/tools

Add this directory to your PATH, we will need mkimage later:

    export PATH=$PATH:$XUBOOT/build/tools

## <a name="RootFS"></a>Configure and build a root file system

Buildroot has no default configuration for the Zybo board but the ZedBoard configuration should work also for the Zybo:

    cd $BUILDROOT
    make O=build zedboard_defconfig
    make O=build menuconfig

In the buildroot configuration menus change the following options:

    Build options -> Location to save buildroot config -> ./build/buildroot.config
    Build options -> Enable compiler cache -> yes (faster build)
    Target packages -> BusyBox configuration file to use? -> ./build/busybox.config
    Toolchain -> Toolchain type -> External toolchain
    Toolchain -> Toolchain -> Custom toolchain
    Toolchain -> Toolchain path -> <path-to-xilinx-sdk/gnu/arm/lin
    Toolchain -> Toolchain prefix -> arm-xilinx-linux-gnueabi # (no trailing '-')
    Toolchain -> External toolchain gcc version -> <the-toolchain-version-you-noted>
    Toolchain -> External toolchain C library -> glibc/eglibc
    Toolchain -> Toolchain has RPC support? -> yes
    System configuration -> System hostname -> sab4z
    System configuration -> System banner -> Welcome to SAB4Z (c) Telecom ParisTech
    Kernel -> Linux Kernel -> no
    Bootloaders -> U-Boot -> no

If you intend to put the Zybo in a network with DHCP server and run a ssh server on the Zybo, also change the following options:

    System configuration -> Network interface to configure through DHCP -> eth0
    Target packages > Networking applications -> dropbear -> yes

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

The compressed archive of the root filesystem is:

    ROOTFS=$BUILDROOT/build/images/rootfs.cpio.gz

## <a name="SDK"></a>Generate and build the hardware dependant software

### <a name="DTS"></a>Linux kernel device tree

Generate the device tree sources:

    cd $SAB4Z
    make dts

The sources are at `build/dts`. If needed, edit them before compiling the device tree blob with dtc:

    dtc -I dts -O dtb -o build/devicetree.dtb build/dts/system.dts

The device tree blob is:

    build/devicetree.dtb

### <a name="FSBL"></a>First Stage Boot Loader (FSBL)

Generate the FSBL sources

    make fsbl

The sources are in `build/fsbl`. If needed, edit them before compiling the FSBL:

    make -C build/fsbl

The binary of the FSBL is:

    build/fsbl/executable.elf

### <a name="BootImg"></a>Zynq boot image

We are ready to generate the Zynq boot image. First copy the U-Boot ELF:

    cp $UBOOT build/u-boot.elf

and generate the image:

    bootgen -w -image scripts/boot.bif -o build/boot.bin

The boot image is:

    build/boot.bin

### <a name="Uimages"></a>Create U-Boot images of the Linux kernel and root file system

    mkimage -A arm -O linux -C none -T kernel -a 0x8000 -e 0x8000 -d $ZIMAGE build/uImage
    mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

### <a name="SDCard"></a>Prepare the micro SD card

Finally, copy the different components to the micro SD card:

    cd build
    cp boot.bin devicetree.dtb uImage uramdisk.image.gz <path-to-mounted-sd-card>
    sync

Unmount the micro SD card.

# <a name="Further"></a>Going further

## <a name="UserApp"></a>Create, compile and run a user software application

The `C` sub-directory contains a very simple example C code `hello_world.c` that prints a welcome message, waits 2 seconds, prints a good bye message and exits. Cross-compile it on your host PC:

    make CC=${CROSS_COMPILE}gcc -C C hello_world

The only thing to do next is transfer the `C/hello_world` binary on the Zybo and execute it. There are several ways to transfer a file from the host PC to the Zybo. The most convenient, of course, is a network interface and, for instance, `scp`. In case none is available, here are several other options:

### <a name="SDTransfer"></a>Transfer files from host PC to Zybo on SD card

Mount the SD card on your host PC, copy the `C/hello_world` executable on it, eject the SD card, plug it in the Zybo, power on and connect as root. Mount the SD card and run the application:

    # mount /dev/mmcblk0p1 /mnt
    # /mnt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

### <a name="Overlays"></a>Add custom files to the root file system

Another possibility is offered by the overlay feature of buildroot which allows to embed custom files in the generated root file system. To add the `hello_world` binary to the `/opt` directory of the root file system, first create a directory for our buildroot overlays and copy the file at destination:

    cd $BUILDROOT
    mkdir -p build/overlays/opt
    cp $SAB4Z/C/hello_world build/overlays/opt

Configure buildroot to add the overlays:

    make O=build menuconfig

In the configuration menu, change:

    System configuration -> Root filesystem overlay directories -> ./build/overlays

Quit with saving. Save the buildroot configuration and build the root file system:

    make O=build savedefconfig
    make O=build

Re-create the U-Boot image of the root file system:

    cd $SAB4Z
    mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

Mount the SD card on your host PC, copy the new root file system image on it eject the SD card, plug it in the Zybo, power on and connect as root. Run the application located in `/opt` without mounting the SD card:

    # /opt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

### <a name="RX"></a>File transfer on the serial link

The drawback of the two previous solutions is the SD card manipulations. There is a way to transfer files from the host PC to the Zybo using the serial interface. On the Zybo side we need the `rx` utility and on the host PC side we need the `sx` utility plus a serial console utility that supports file transfers with sx (like `picocom`, for instance). Let us first add rx to the busybox of our root file system (it is not enabled by default):

    cd $BUILDROOT
    make O=build busybox-menuconfig
   
In the busybox configuration menu, change:

    Miscellaneous Utilities -> rx -> yes

Quit with saving. Save the busybox configuration and build the root file system:

    make O=build busybox-update-config
    make O=build

Re-create the U-Boot image of the root file system:

    cd $SAB4Z
    mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

Mount the SD card on your host PC, copy the new root file system image on it eject the SD card, plug it in the Zybo, power on and connect as root. You can now transfer the application binary file (and any other file) from the host PC using picocom and rx. When launching picocom, pass the relevant options:

    picocom -b115200 -fn -pn -d8 -r -l --send-cmd "sx" --receive-cmd "rx" /dev/ttyUSB1
    # rx /tmp/hello_world
    C

On the Zybo the rx utility is now waiting for a file that it will store at `/tmp/hello_world`. Then, still in the picocom serial console, press `C-a C-s` (control-a control-s) and provide the name of the file to send:

    *** file: C/hello_world
    sx C/hello_world 
    Sending C/hello_world, 51 blocks: Give your local XMODEM receive command now.
    Bytes Sent:   6656   BPS:3443                            
    
    Transfer complete
    
    *** exit status: 0

After the transfer completes you can run the application located in `/tmp`. First change the file's mode to executable:

    # chmod +x /tmp/hello_world
    # /tmp/hello_world
    Hello SAB4Z
    Bye! SAB4Z

## <a name="SAB4ZSoft"></a>Access SAB4Z from a user software application

Accessing SAB4Z from a user software application running on top of the Linux operating system is not as simple as it seams: because of the virtual memory trying to access the SAB4Z registers using their physical addresses would fail. In order to do this we will use `/dev/mem`, a character device that is an image of the memory of the system. The character located at offset `x` from the beginning of `/dev/mem` is the byte stored at physical address `x`. Of course, accessing addresses that are not mapped in the system or writing at read-only addresses cause errors. As reading or writing at specific offset in a character device is not very convenient we will also use `mmap`, a Linux system call that can map a device to memory. To make it short, `/dev/mem` is an image of the physical memory space of the system and `mmap` allows us to map portions of this at a known virtual address. Reading and writing at the mapped virtual addresses becomes equivalent to reading and writing at the physical addresses.

All this, for obvious security reasons, is privileged, but as we are root...

The example C program in `C/sab4z.c` maps the STATUS and R registers of SAB4Z at a virtual address and the `[2G..2G+512M[` physical address range (that is, the DDR accessed across the PL) at another virtual address. It takes one string argument. It first prints a welcome message, then uses the mapping to print the content of STATUS and R registers. It then writes `0x12345678` in the R register and starts searching for the passed string argument in the `[2G..2G+512M[` range. If it finds it, it prints all charcaters in a `[-20..+20[` range around the found string, and stops the search. Then, it prints again STATUS and R, a good bye message and exits.

Compile:

    cd $SAB4Z
    make CC=${CROSS_COMPILE}gcc C/sab4z

Use one of the techniques presented above to transfer the binary to the Zybo and test it. In order to guarantee that a given string will indeed be stored somewhere in the DDR, you can, for instance, define an environment variable before launching the program. But this should not be necessary because the command you will type to launch the program will also probably be found in memory, as the example below demonstrates:

    picocom -b115200 -fn -pn -d8 -r -l --send-cmd "sx" --receive-cmd "rx" /dev/ttyUSB1
    # rx /tmp/sab4z 
    C
    *** file: sab4z
    sx sab4z 
    Sending sab4z, 69 blocks: Give your local XMODEM receive command now.
    Bytes Sent:   8960   BPS:1878                            
    
    Transfer complete
    
    *** exit status: 0
    # export FOO=barcuzqux
    # chmod +x /tmp/sab4z
    # /tmp/sab4z barcuz
    Hello SAB4Z
      0x40000000: 50004401 (STATUS)
      0x40000004: 12345678 (R)
      0x806d1f31: t|H.ov7l./tmp/sab4z.barcuz.USER=root.SHLVL=1.H
      0x40000000: 50002208 (STATUS)
      0x40000004: 12345678 (R)
    Bye! SAB4Z

## <a name="LinuxDriver"></a>Add a Linux driver for SAB4Z

TODO

## <a name="BootInAAS"></a>Boot Linux across SAB4Z

TODO

