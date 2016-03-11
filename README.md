This repository and its sub-directories contain the VHDL source code, VHDL simulation environment, simulation, synthesis scripts and companion example software for SAB4Z, a simple design example for the Xilinx Zynq core. It can be ported on any board based on Xilinx Zynq cores but has been specifically designed for the Zybo board by Digilent.

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
    * [Mount the MicroSD card](#MountSDCard)
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
        * [Prepare the MicroSD card](#SDCard)
* [Going further](#Further)
    * [Create, compile and run a user software application](#UserApp)
        * [Transfer files from host PC to Zybo on MicroSD card](#SDTransfer)
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
    │   ├── hello_world.c
    │   └── sab4z.c
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

**SAB4Z** is a **S**imple **A**xi-to-axi **B**ridge **F**or **Z**ynq cores with a lite AXI slave port (S0_AXI) an AXI slave port (S1_AXI), a master AXI port (M_AXI), two internal registers (STATUS and R), a 4-bits input (SW), a 4-bits output (LED) and a one-bit command input (BTN). The following figure represents SAB4Z mapped in the Programmable Logic (PL) of the Zynq core of a Zybo board. SAB4Z is connected to the Processing System (PS) of the Zynq core by the 3 AXI ports. When the ARM processor of the PS reads or writes at addresses in the `[0..1G[` range (first giga byte) it accesses the DDR memory of the Zybo (512MB), directly through the DDR controller. When the addresses fall in the `[1G..2G[` or `[2G..3G[` ranges, it accesses SAB4Z, through its S0_AXI and S1_AXI ports, respectively. SAB4Z can also access the DDR in the `[0..1G[` range, thanks to its M_AXI port. The four slide switches, LEDs and the rightmost push-button (BTN0) of the board are connected to the SW input, the LED output and the BTN input of SAB4Z, respectively.

![SAB4Z on a Zybo board](images/sab4z.png)

As shown on the figure, the accesses from the PS that fall in the `[2G..3G[` range (S1_AXI) are forwarded to M_AXI with an address down shift from `[2G..3G[` to `[0..1G[`. The responses from M_AXI are forwarded back to S1_AXI. This path is thus a second way to access the DDR from the PS, across the PL. From the PS viewpoint each address in the `[0..1G[` range has an equivalent address in the `[2G..3G[` range. The Zybo board has only 512 MB of DDR and accesses above the DDR limit fall back in the low half (aliasing). Each DDR location can thus be accessed with 4 different addresses in the `[0..512M[`, `[512M..1G[`, `[2G..2G+512M[` or `[2G+512M..3G[` ranges.

Important: depending on the configuration, Zynq-based systems have a reserved low addresses range that cannot be accessed from the PL. In these systems this low range can be accessed in the `[0..1G[` range but not in the `[2G..3G[` range where errors are raised. Last but not least, randomly modifying the content of the memory using the `[2G..3G[` range can crash the system or lead to unexpected behaviours if the modified region is currently in use by the currently running software stack.

The AXI slave port S0_AXI is used to access the internal registers. The mapping of the S0_AXI address space is the following:

| Address       | Mapping     | Description                                 | 
| :------------ | :---------- | :------------------------------------------ | 
| `0x4000_0000` | STATUS (ro) | 32 bits read-only status register           | 
| `0x4000_0004` | R      (rw) | 32 bits general purpose read-write register | 
| `0x4000_0008` | Unmapped    |                                             | 
| ...           | ...         |                                             | 
| `0x7fff_fffc` | Unmapped    |                                             | 

The two registers are subdivided in 16 four-bits nibbles, indexed from 0, for the four Least Significant Bits (LSBs) of STATUS, to 15, for the four Most Significant Bits (MSBs) of R. The organization of the registers is the following:

| Register | Nibble | Bits     | Field name | Role                                          |
| :------- | -----: | -------: | :--------- | :-------------------------------------------- |
| STATUS   |      0 |  `3...0` | LIFE       | Rotating bit (life monitor)                   |
| ...      |      1 |  `7...4` | CNT        | Counter of BTN events                         |
| ...      |      2 | `11...8` | ARCNT      | Counter of S1_AXI address-read transactions   |
| ...      |      3 | `15..12` | RCNT       | Counter of S1_AXI date-read transactions      |
| ...      |      4 | `19..16` | AWCNT      | Counter of S1_AXI address-write transactions  |
| ...      |      5 | `23..20` | WCNT       | Counter of S1_AXI data-write transactions     |
| ...      |      6 | `27..24` | BCNT       | Counter of S1_AXI write-response transactions |
| STATUS   |      7 | `31..28` | SW         | Current configuration of slide-switches       |
| R        |      8 |   `3..0` | R0         | General purpose                               |
| ...      |    ... | ...      | ...        | ...                                           |
| R        |     15 | `31..28` | R7         | General purpose                               |

CNT is a 4-bits counter. It is initialized to zero after reset. Each time the BTN push-button is pressed, CNT is incremented (modulus 16). The LEDs are driven by CNT when BTN is pressed (a way to check the value of the counter) and by nibble number CNT when the button is not pressed. The BTN input is filtered by a debouncer-resynchronizer before being used to increment CNT.

Accesses to the unmapped region of the S0_AXI `[1G+8..2G[` address space raise DECERR AXI errors. Write accesses to the read-only STATUS register raise SLVERR AXI errors.

# <a name="Archive"></a>Install from the archive

In the following `Host>` is the host PC shell prompt, `Sab4z>` is the Zybo shell prompt and `Zybo>` is the U-Boot prompt. Code snipsets without a prompt are commands outputs, excerpts of configuration files or configuration menus.

Insert a MicroSD card in your card reader and unpack the provided `sdcard.tgz` archive to it:

    Host> cd sab4z
    Host> tar -C <path-to-mounted-sd-card> sdcard.tgz
    Host> sync

Unmount the MicroSD card.

# <a name="Run"></a>Run SAB4Z on the Zybo

* Plug the MicroSD card in the Zybo and connect the USB cable.
* Check the position of the jumper that selects the power source (USB or power adapter).
* Check the position of the jumper that selects the boot medium (MicroSD card).
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
* Wait until Linux boots, log in as root (there is no password) and start interacting with SAB4Z with `devmem`, for instance.

`devmem` is a busybox utility that allows to access memory locations with their physical addresses. It is privileged but as we are root...

## <a name="ReadStatus"></a>Read the STATUS register

    Sab4z> devmem 0x40000000 32
    0x00000004
    Sab4z> devmem 0x40000000 32
    0x00000002
    Sab4z> devmem 0x40000000 32
    0x00000008

As can be seen, the content of the STATUS register is all zeroes, except its 4 LSBs, the life monitor, that spin with a period of about half a second and thus take different values depending on the exact instant of reading. The CNT counter is zero, so the LEDs are driven by the life monitor. Change the configuration of the 4 slide switches, read again the STATUS register and check that the 4 MSBs reflect the chosen configuration:

    Sab4z> devmem 0x40000000 32
    0x50000002

## <a name="ReadWriteR"></a>Read and write the R register

    Sab4z> devmem 0x40000004 32
    0x00000000
    Sab4z> devmem 0x40000004 32 0x12345678
    Sab4z> devmem 0x40000004 32
    0x12345678

## <a name="ReadDDR"></a>Read DDR locations

    Sab4z> devmem 0x01000000 32
    0x4D546529
    Sab4z> devmem 0x81000000 32
    0x4D546529
    Sab4z> devmem 0x40000000 32
    0x50001104

As expected, the `0x0100_0000` and `0x8100_0000` addresses store the same value. ARCNT and RCNT, the counters of address read and data read AXI transactions on AXI slave port S1_AXI, have been incremented because we performed a read access to the DDR at `0x8100_0000`. Let us write a DDR location, for instance `0x8200_0000`, but as we do not know whether the equivalent `0x0200_0000` is currently used by the running software stack, let us first read it and overwrite with the same value:

    Sab4z> devmem 0x82000000 32
    0xEDFE0DD0
    Sab4z> devmem 0x82000000 32 0xEDFE0DD0
    Sab4z> devmem 0x40000000 32
    0x51112204

The read counters have again been incremented because of the read access at `0x8200_0000`. The 3 write counters (AWCNT, WCNT and BCNT) have also been incremented by the write access at `0x8200_0000`.

## <a name="PushButton"></a>Press the push-button, select LED driver

If we press the push-button and do not release it yet, the LEDs display `0001`, the new value of the incremented CNT. If we release the button the LEDs still display `0001` because when CNT=1 their are driven by... CNT. Press and release the button once more and check that the LEDs display `0010`, the current value of ARCNT. Continue exploring the 16 possible values of CNT and check that the LEDs display what they should.

## <a name="MountSDCard"></a>Mount the MicroSD card

By default the MicroSD card is not mounted but it can be. This is a convenient way to import / export data or even custom applications to / from the host PC (of course, a network interface is even better). Simply add files to the MicroSD card from the host PC and they will show up on the Zybo once the MicroSD card is mounted. Conversely, if you store a file on the mounted MicroSD card from the Zybo, properly unmount the card, remove it from its slot and mount it to your host PC, you will be able to transfer the file to the host PC.

    Sab4z> mount /dev/mmcblk0p1 /mnt
    Sab4z> ls /mnt
    boot.bin           devicetree.dtb     uImage             uramdisk.image.gz
    Sab4z> umount /mnt

Do not forget to unmount the card properly before shutting down the Zybo. If you do not there is a risk that its content is damaged.

## <a name="Halt"></a>Halt the system

Always halt properly before switching the power off:

    Sab4z> poweroff
    Sab4z> Stopping network...Saving random seed... done.
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

    Host> XLINUX=<some-path>/linux-xlnx
    Host> XUBOOT=<some-path>/u-boot-xlnx
    Host> XDTS=<some-path>/device-tree-xlnx
    Host> git clone https://github.com/Xilinx/linux-xlnx.git $XLINUX
    Host> git clone https://github.com/Xilinx/u-boot-xlnx.git $XUBOOT
    Host> git clone http://github.com/Xilinx/device-tree-xlnx.git $XDTS
    Host> SAB4Z=<some-path>
    Host> git clone https://gitlab.eurecom.fr/renaud.pacalet/sab4z.git $SAB4Z
    Host> BUILDROOT=<some-path>
    Host> git clone http://git.buildroot.net/git/buildroot.git $BUILDROOT

## <a name="Synthesis"></a>Hardware synthesis

    Host> cd $SAB4Z
    Host> make vv-all

The generated bitstream is `SAB4Z/build/vv/top.runs/impl_1/top_wrapper.bit`.

## <a name="Kernel"></a>Configure and build the Linux kernel

    Host> export CROSS_COMPILE=arm-xilinx-linux-gnueabi- # (note the trailing '-')
    Host> export PATH=$PATH:<path-to-xilinx-sdk>/gnu/arm/lin/bin
    Host> ${CROSS_COMPILE}gcc --version

Note the toolchain version (result of the last command), we will need it later.

    Host> cd $XLINUX
    Host> make mrproper
    Host> make O=build ARCH=arm xilinx_zynq_defconfig
    Host> make -j8 O=build ARCH=arm zImage

Adapt the `make` -j option to your host system.

Note: if needed the configuration of the kernel can be tuned by running:

    Host> make O=build ARCH=arm menuconfig

before building the kernel. The generated compressed Linux kernel image is:

    Host> ZIMAGE=$XLINUX/build/arch/arm/boot/zImage

The Device Tree Compiler (dtc) is also generated in `XLINUX/build/scripts/dtc`. Add this directory to your PATH, we will need dtc later:

    Host> export PATH=$PATH:$XLINUX/build/scripts/dtc

## <a name="Uboot"></a>Configure and build U-Boot, the second stage boot loader

The U-Boot build process uses dtc. Unless you have another dtc binary somewhere, wait until the Linux kernel is built before building U-Boot.

    Host> cd $XUBOOT
    Host> make mrproper
    Host> make O=build zynq_zybo_defconfig
    Host> make -j8 O=build

Adapt the `make` -j option to your host system.

Note: if needed the configuration of U-Boot can be tuned by running:

    Host> make O=build menuconfig

before building U-Boot. The generated ELF of U-Boot is:

    Host> UBOOT=$XUBOOT/build/u-boot

The mkimage U-Boot utility is also generated in `$XUBOOT/build/tools`. Add this directory to your PATH, we will need mkimage later:

    Host> export PATH=$PATH:$XUBOOT/build/tools

## <a name="RootFS"></a>Configure and build a root file system

Buildroot has no default configuration for the Zybo board but the ZedBoard configuration should work also for the Zybo:

    Host> cd $BUILDROOT
    Host> make O=build zedboard_defconfig
    Host> make O=build menuconfig

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

    Host> make O=build savedefconfig
    Host> make O=build

If you get an error:

    Incorrect selection of kernel headers: expected x.x.x, got y.y.y

note the `y.y.y` and run again the buildroot configuration:

    Host> make O=build menuconfig

change:

    Toolchain -> External toolchain kernel headers series -> the-kernel-headers-version-you-noted

quit with saving, save again the configuration and build:

    Host> make O=build savedefconfig
    Host> make O=build

The compressed archive of the root filesystem is:

    Host> ROOTFS=$BUILDROOT/build/images/rootfs.cpio.gz

## <a name="SDK"></a>Generate and build the hardware dependant software

### <a name="DTS"></a>Linux kernel device tree

Generate the device tree sources:

    Host> cd $SAB4Z
    Host> make dts

The sources are at `build/dts`. If needed, edit them before compiling the device tree blob with dtc:

    Host> dtc -I dts -O dtb -o build/devicetree.dtb build/dts/system.dts

The device tree blob is `build/devicetree.dtb`.

### <a name="FSBL"></a>First Stage Boot Loader (FSBL)

Generate the FSBL sources

    Host> make fsbl

The sources are in `build/fsbl`. If needed, edit them before compiling the FSBL:

    Host> make -C build/fsbl

The binary of the FSBL is `build/fsbl/executable.elf`.

### <a name="BootImg"></a>Zynq boot image

We are ready to generate the Zynq boot image. First copy the U-Boot ELF:

    Host> cp $UBOOT build/u-boot.elf

and generate the image:

    Host> bootgen -w -image scripts/boot.bif -o build/boot.bin

The boot image is `build/boot.bin`.

### <a name="Uimages"></a>Create U-Boot images of the Linux kernel and root file system

    Host> mkimage -A arm -O linux -C none -T kernel -a 0x8000 -e 0x8000 -d $ZIMAGE build/uImage
    Host> mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

### <a name="SDCard"></a>Prepare the MicroSD card

Finally, copy the different components to the MicroSD card:

    Host> cd build
    Host> cp boot.bin devicetree.dtb uImage uramdisk.image.gz <path-to-mounted-sd-card>
    Host> sync

Unmount the MicroSD card.

# <a name="Further"></a>Going further

## <a name="UserApp"></a>Create, compile and run a user software application

The `C` sub-directory contains a very simple example C code `hello_world.c` that prints a welcome message, waits 2 seconds, prints a good bye message and exits. Cross-compile it on your host PC:

    Host> make CC=${CROSS_COMPILE}gcc -C C hello_world

The only thing to do next is transfer the `C/hello_world` binary on the Zybo and execute it. There are several ways to transfer a file from the host PC to the Zybo. The most convenient, of course, is a network interface and, for instance, `scp`. In case none is available, here are several other options:

### <a name="SDTransfer"></a>Transfer files from host PC to Zybo on MicroSD card

Mount the MicroSD card on your host PC, copy the `C/hello_world` executable on it, eject the MicroSD card, plug it in the Zybo, power on and connect as root. Mount the MicroSD card and run the application:

    Sab4z> mount /dev/mmcblk0p1 /mnt
    Sab4z> /mnt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

### <a name="Overlays"></a>Add custom files to the root file system

Another possibility is offered by the overlay feature of buildroot which allows to embed custom files in the generated root file system. To add the `hello_world` binary to the `/opt` directory of the root file system, first create a directory for our buildroot overlays and copy the file at destination:

    Host> cd $BUILDROOT
    Host> mkdir -p build/overlays/opt
    Host> cp $SAB4Z/C/hello_world build/overlays/opt

Configure buildroot to add the overlays:

    Host> make O=build menuconfig

In the configuration menu, change:

    System configuration -> Root filesystem overlay directories -> ./build/overlays

Quit with saving. Save the buildroot configuration and build the root file system:

    Host> make O=build savedefconfig
    Host> make O=build

Re-create the U-Boot image of the root file system:

    Host> cd $SAB4Z
    Host> mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

Mount the MicroSD card on your host PC, copy the new root file system image on it eject the MicroSD card, plug it in the Zybo, power on and connect as root. Run the application located in `/opt` without mounting the MicroSD card:

    Sab4z> /opt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

### <a name="RX"></a>File transfer on the serial link

The drawback of the two previous solutions is the MicroSD card manipulations. There is a way to transfer files from the host PC to the Zybo using the serial interface. On the Zybo side we need the `rx` utility and on the host PC side we need the `sx` utility plus a serial console utility that supports file transfers with sx (like `picocom`, for instance). Let us first add rx to the busybox of our root file system (it is not enabled by default):

    Host> cd $BUILDROOT
    Host> make O=build busybox-menuconfig
   
In the busybox configuration menu, change:

    Miscellaneous Utilities -> rx -> yes

Quit with saving. Save the busybox configuration and build the root file system:

    Host> make O=build busybox-update-config
    Host> make O=build

Re-create the U-Boot image of the root file system:

    Host> cd $SAB4Z
    Host> mkimage -A arm -T ramdisk -C gzip -d $ROOTFS build/uramdisk.image.gz

Mount the MicroSD card on your host PC, copy the new root file system image on it eject the MicroSD card, plug it in the Zybo, power on and connect as root. You can now transfer the application binary file (and any other file) from the host PC using picocom and rx. Launch picocom, with the `--send-cmd "sx" --receive-cmd "rx"` options, in the Zybo shell run `rx <destination-file>`, press `C-a C-s` (control-a control-s) to instruct picocom that a file must be sent from the host PC to the Zybo and provide the name of the file to send:

    Host> picocom -b115200 -fn -pn -d8 -r -l --send-cmd "sx" --receive-cmd "rx" /dev/ttyUSB1
    Sab4z> rx /tmp/hello_world
    C
    *** file: C/hello_world
    sx C/hello_world 
    Sending C/hello_world, 51 blocks: Give your local XMODEM receive command now.
    Bytes Sent:   6656   BPS:3443                            
    
    Transfer complete
    
    *** exit status: 0

After the transfer completes you can run the application located in `/tmp`. First change the file's mode to executable:

    Sab4z> chmod +x /tmp/hello_world
    Sab4z> /tmp/hello_world
    Hello SAB4Z
    Bye! SAB4Z

## <a name="SAB4ZSoft"></a>Access SAB4Z from a user software application

Accessing SAB4Z from a user software application running on top of the Linux operating system is not as simple as it seems: because of the virtual memory trying to access the SAB4Z registers using their physical addresses would fail. In order to do this we will use `/dev/mem`, a character device that is an image of the memory of the system. The character located at offset `x` from the beginning of `/dev/mem` is the byte stored at physical address `x`. Of course, accessing addresses that are not mapped in the system or writing at read-only addresses cause errors. As reading or writing at specific offset in a character device is not very convenient we will also use `mmap`, a Linux system call that can map a device to memory. To make it short, `/dev/mem` is an image of the physical memory space of the system and `mmap` allows us to map portions of this at a known virtual address. Reading and writing at the mapped virtual addresses becomes equivalent to reading and writing at the physical addresses.

All this, for obvious security reasons, is privileged, but as we are root...

The example C program in `C/sab4z.c` maps the STATUS and R registers of SAB4Z at a virtual address and the `[2G..2G+512M[` physical address range (that is, the DDR accessed across the PL) at another virtual address. It takes one string argument. It first prints a welcome message, then uses the mapping to print the content of STATUS and R registers. It then writes `0x12345678` in the R register and starts searching for the passed string argument in the `[2G..2G+512M[` range. If it finds it, it prints all charcaters in a `[-20..+20[` range around the found string, and stops the search. Then, it prints again STATUS and R, a good bye message and exits. Have a look at the source code and use it as a starting point for your own projects.

Compile:

    Host> cd $SAB4Z
    Host> make CC=${CROSS_COMPILE}gcc C/sab4z

Use one of the techniques presented above to transfer the binary to the Zybo and test it. In order to guarantee that a given string will indeed be stored somewhere in the DDR, you can, for instance, define an environment variable before launching the program. But this should not be necessary because the command you will type to launch the program will also probably be found in memory, as the example below demonstrates:

    Host> picocom -b115200 -fn -pn -d8 -r -l --send-cmd "sx" --receive-cmd "rx" /dev/ttyUSB1
    Sab4z> rx /tmp/sab4z 
    C
    *** file: sab4z
    sx sab4z 
    Sending sab4z, 69 blocks: Give your local XMODEM receive command now.
    Bytes Sent:   8960   BPS:1878                            
    
    Transfer complete
    
    *** exit status: 0
    Sab4z> export FOO=barcuzqux
    Sab4z> chmod +x /tmp/sab4z
    Sab4z> /tmp/sab4z barcuz
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

As, thanks to the AXI bridge that SAB4Z implements, the `[2G..3G[` address range is an alias of `[0..1G[`. It is thus possible to run software on the Zybo that use only the `[2G..3G[` range instead of `[0..1G[`. It is even possible for the Linux kernel. However we need to carefuly select the range of physical memory that we will instruct the kernel to use:

* The Zybo has only 512MB of DDR, so the most we can use is `[2G..2G+512M[`.
* As already mentionned the low DDR addresses cannot be accessed from the PL. So, we cannot let Linux access the low addresses of `[2G..2G+512M[` because we could not forward the requests to the DDR.
* The Linux kernel insists to have its physical memory aligned on 128MB boundaries. To skip the low addresses of `[2G..2G+512M[` we must skip an entire 128MB chunk.

All in all, we can run the Linux kernel in the `[2G+128MB..2G+512M[` range (`[0x8800_0000..0xa000_0000[`), that is only 384MB instead of 512MB. The other drawback is that the path to the DDR across the PL is much slower than the direct one: its bit-width is 32 bits instead of 64 and its clock frequency is that of the PL, that is 100MHz in our example instead of 650MHz. Of course, the overhead will impact only cache misses but there will be an overhead. So why doing this? Why using less memory than available and slowing down the memory accesses? There are several good reasons. One of them is that instead of just relaying the memory accesses, the SAB4Z could be modified to implement a kind of monitoring of these accesses. It already counts the AXI transactions but it could do something more sophisticated. It could even tamper with the memory accesses, for instance to emulate attacks against the system or accidental memory faults.

Anyway, to boot and run Linux in the `[0x8800_0000..0xa000_0000[` physical memory range we need to modify a few things. First, edit the device tree source (`build/dts/system.dts`) and replace the definition of the physical memory:

	memory {
		device_type = "memory";
		reg = <0x0 0x20000000>;
	};

by:

	memory {
		device_type = "memory";
		linux,usable-memory = <0x88000000 0x18000000>;
	};

Recompile the blob:

    Host> cd $SAB4Z
    Host> dtc -I dts -O dtb -o build/devicetree.dtb build/dts/system.dts

Next, recreate the U-Boot image of the Linux kernel with a different load address and entry point:

    Host> cd $SAB4Z
    Host> mkimage -A arm -O linux -C none -T kernel -a 0x88008000 -e 0x88008000 -d $ZIMAGE build/uImage

Last, we must instruct U-Boot to load the device tree blob, Linux kernel and root file system images at different addresses. And, very important, we must force it not to displace the device tree blob and the root file system image as it does by default. Copy the new device tree blob and U-Boot image of the Linux kernel on the MicroSD card:

    Host> cd $SAB4Z
    Host> cp build/devicetree.dtb build/uImage <path-to-mounted-sd-card>

Eject the MicroSD card, plug it in the Zybo, power on and stop the U-Boot count down by pressing a key. Modify the following U-Boot environment variables:

    Zybo> setenv devicetree_load_address 0x8a000000
    Zybo> setenv kernel_load_address 0x8a080000
    Zybo> setenv ramdisk_load_address 0x8c000000
    Zybo> setenv fdt_high 0xffffffff
    Zybo> setenv initrd_high 0xffffffff

If you want these changes to be stored in the on-board flash such that U-Boot reuses them the next time:

    Zybo> saveenv

It is time to boot:

    Zybo> boot

As you will probably notice it takes a bit longer to copy the binaries from the MicroSD card to the memory and to boot the kernel but the system, even if slightly slower, remains responsive and perfectly usable. You can check that the memory accesses are really routed across the PL by pressing the BTN push-button twice. This should drive the LEDs with the counter of AXI address read transactions and you should see the LEDs blinking while the CPU performs read-write accesses to the memory across SAB4Z. If the LEDs do not blink enough, interact with the system with the serial console, this should increase the number of memory accesses.
