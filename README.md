This repository and its sub-directories contain the VHDL source code, VHDL simulation environment, simulation, synthesis scripts and companion example software for SAB4Z, a simple design example for the Xilinx Zynq core. It can be ported on any board based on Xilinx Zynq cores but has been specifically designed for the Zybo board by Digilent.

# Table of content
* [License](#license)
* [Content](#Content)
* [Description](#Description)
* [Install from the archive](#Archive)
* [Test SAB4Z on the Zybo](#Run)
* [Build everything from scratch](#Building)
    * [Downloads](#Downloads)
    * [Hardware synthesis](#Synthesis)
    * [Build a root file system](#RootFS)
    * [Build the Linux kernel](#Kernel)
    * [Build U-Boot](#Uboot)
    * [Build the hardware dependant software](#SDK)
* [Going further](#Further)
    * [Run a user application on the Zybo](#UserApp)
    * [Access SAB4Z from a user application on the Zybo](#SAB4ZSoft)
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
    ├── C                       Directory of C source files
    │   ├── hello_world.c       Simple example user application
    │   └── sab4z.c             User application that uses SAB4Z
    ├── COPYING                 License (English version)
    ├── COPYING-FR              Licence (version française)
    ├── COPYRIGHT               Copyright notice
    ├── hdl                     Directory of VHDL source files
    │   ├── axi_pkg.vhd         AXI definitions package
    │   ├── debouncer.vhd       Debouncer-resynchronizer
    │   └── sab4z.vhd           Top-level SAB4Z
    ├── images                  Directory of figures
    │   ├── sab4z.fig           Xfig figure of SAB4Z in Zybo
    │   ├── sab4z.png           PNG export of sab4z.fig
    │   └── zybo.png            PNG picture of Zybo
    ├── Makefile                Main makefile
    ├── README.md               This file
    └── scripts                 Directory of scripts
        ├── boot.bif            Zynq boot image description
        ├── dts.tcl             TCL script for device tree generation
        ├── fsbl.tcl            TCL script for FSBL generation
        ├── uEnv.txt            U-Boot environment variables definitions
        └── vvsyn.tcl           Vivado TCL synthesis script

# <a name="Description"></a>Description

**SAB4Z** is a **S**imple **A**xi-to-axi **B**ridge **F**or **Z**ynq cores with a lite AXI slave port (S0_AXI) an AXI slave port (S1_AXI), a master AXI port (M_AXI), two internal registers (STATUS and R), a 4-bits input (SW), a 4-bits output (LED) and a one-bit command input (BTN). The following figure represents SAB4Z mapped in the Programmable Logic (PL) of the Zynq core of a Zybo board. SAB4Z is connected to the Processing System (PS) of the Zynq core by the 3 AXI ports. When the ARM processor of the PS reads or writes at addresses in the `[0..1G[` range (first giga byte) it accesses the DDR memory of the Zybo (512MB), directly through the DDR controller. When the addresses fall in the `[1G..2G[` or `[2G..3G[` ranges, it accesses SAB4Z, through its S0_AXI and S1_AXI ports, respectively. SAB4Z can also access the DDR in the `[0..1G[` range, thanks to its M_AXI port. The four slide switches, LEDs and the rightmost push-button (BTN0) of the board are connected to the SW input, the LED output and the BTN input of SAB4Z, respectively.

![SAB4Z on a Zybo board](images/sab4z.png)

As shown on the figure, the accesses from the PS that fall in the `[2G..3G[` range (S1_AXI) are forwarded to M_AXI with an address down shift from `[2G..3G[` to `[0..1G[`. The responses from M_AXI are forwarded back to S1_AXI. This path is thus a second way to access the DDR from the PS, across the PL. From the PS viewpoint each address in the `[0..1G[` range has an equivalent address in the `[2G..3G[` range. The Zybo board has only 512 MB of DDR and accesses above the DDR limit fall back in the low half (aliasing). Each DDR location can thus be accessed with 4 different addresses in the `[0..512M[`, `[512M..1G[`, `[2G..2G+512M[` or `[2G+512M..3G[` ranges.

**Important**: depending on the configuration, Zynq-based systems have a reserved low addresses range that cannot be accessed from the PL. In these systems this low range can be accessed in the `[0..1G[` range but not in the `[2G..3G[` range where errors are raised. Last but not least, randomly modifying the content of the memory using the `[2G..3G[` range can crash the system or lead to unexpected behaviours if the modified region is currently in use by the currently running software stack.

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
| ...      |      3 | `15..12` | RCNT       | Counter of S1_AXI data-read transactions      |
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

In the following `Host>` is the host PC shell prompt and `Sab4z>` is the Zybo shell prompt. Code snippets without a prompt are commands outputs, excerpts of configuration files or configuration menus.

Download the archive, insert a MicroSD card in your card reader and unpack the archive to it:

    Host> cd /tmp
    Host> https://gitlab.eurecom.fr/renaud.pacalet/sab4z/uploads/98b4b8524e498a56868230778f79887f/sdcard.tgz
    Host> tar -C <path-to-mounted-sd-card> -xf sdcard.tgz
    Host> sync

Unmount and eject the MicroSD card.

# <a name="Run"></a>Test SAB4Z on the Zybo

* Plug the MicroSD card in the Zybo and connect the USB cable.
* Check the position of the jumper that selects the power source (USB or power adapter).
* Check the position of the jumper that selects the boot medium (MicroSD card).
* Power on.
* Launch a terminal emulator (picocom, minicom...) with the following configuration:
  * Baudrate 115200
  * No flow control
  * No paritys
  * 8 bits characters
  * No port reset
  * No port locking
  * Connected to the `/dev/ttyUSB1` device (if needed use dmesg to check the device name)
* Wait until Linux boots, log in as root (there is no password) and start interacting with SAB4Z. To access the SAB4Z memory spaces you can use devmem, a BusyBox utility that allows to access memory locations with their physical addresses. It is privileged but as we are root...


    Host> picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1
    ...
    Welcome to SAB4Z (c) Telecom ParisTech
    sab4z login: root
    Sab4z>

#### <a name="ReadStatus"></a>Read the STATUS register

    Sab4z> devmem 0x40000000 32
    0x00000004
    Sab4z> devmem 0x40000000 32
    0x00000002
    Sab4z> devmem 0x40000000 32
    0x00000008

As can be seen, the content of the STATUS register is all zeroes, except its 4 LSBs, the life monitor, that spin with a period of about half a second and thus take different values depending on the exact instant of reading. The CNT counter is zero, so the LEDs are driven by the life monitor. Change the configuration of the 4 slide switches, read again the STATUS register and check that the 4 MSBs reflect the chosen configuration:

    Sab4z> devmem 0x40000000 32
    0x50000002

#### <a name="ReadWriteR"></a>Read and write the R register

    Sab4z> devmem 0x40000004 32
    0x00000000
    Sab4z> devmem 0x40000004 32 0x12345678
    Sab4z> devmem 0x40000004 32
    0x12345678

#### <a name="ReadDDR"></a>Read DDR locations

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

#### <a name="PushButton"></a>Press the push-button, select LED driver

If we press the push-button and do not release it yet, the LEDs display `0001`, the new value of the incremented CNT. If we release the button the LEDs still display `0001` because when CNT=1 their are driven by... CNT. Press and release the button once more and check that the LEDs display `0010`, the current value of ARCNT. Continue exploring the 16 possible values of CNT and check that the LEDs display what they should.

#### <a name="MountSDCard"></a>Mount the MicroSD card

By default the MicroSD card is not mounted but it can be. This is a way to import / export data or even custom applications to / from the host PC (of course, a network interface is much better). Simply add files to the MicroSD card from the host PC and they will show up on the Zybo once the MicroSD card is mounted. Conversely, you can store a file on the mounted MicroSD card from the Zybo, properly unmount the card, remove it from its slot, mount it on your host PC and copy the file from the MicroSD card to the host PC.

    Sab4z> mount /dev/mmcblk0p1 /mnt
    Sab4z> ls /mnt
    boot.bin           devicetree.dtb     uImage             uramdisk.image.gz
    Sab4z> umount /mnt

Do not forget to unmount the card properly before shutting down the Zybo. If you do not there is a risk that its content is damaged.

#### <a name="Halt"></a>Halt the system

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

# <a name="Building"></a>Build everything from scratch

To build the project you will need the Xilinx tools (Vivado and its companion SDK). In the following we assume that they are properly installed and in your PATH. You will also need to download, configure and build several tools. Some steps can be run in parallel because they do not depend on the results of other steps.

**Important**: the Xilinx initialization script redefines the LD_LIBRARY_PATH environment variable to point to Xilinx shared libraries. A consequence is that many utilities on your host PC will crash with more or less accurate error messages. To avoid this, run the Xilinx tools in a separate, dedicated shell. In the following we will use the `Host-Xilinx>` shell prompt to distinguish this dedicated shell.

## <a name="Downloads"></a>Downloads

**Important**: after the build, the Linux repository occupies more than 2.5GB of disk space and the Buildroot repository more than 3GB. Carefully select where to install them... Clone all components from their respective Git repositories:

    Host> cd <some-path>
    Host> git clone https://gitlab.eurecom.fr/renaud.pacalet/sab4z.git
    Host> git clone https://github.com/Xilinx/linux-xlnx.git
    Host> git clone https://github.com/Xilinx/u-boot-xlnx.git
    Host> git clone http://github.com/Xilinx/device-tree-xlnx.git
    Host> git clone http://git.buildroot.net/git/buildroot.git
    Host> SAB4Z=<some-path>/sab4z
    Host> XLINUX=<some-path>/linux-xlnx
    Host> XUBOOT=<some-path>/u-boot-xlnx
    Host> XDTS=<some-path>/device-tree-xlnx
    Host> BUILDROOT=<some-path>/buildroot

## <a name="Synthesis"></a>Hardware synthesis

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> make vv-all

The generated bitstream is `SAB4Z/build/vv/top.runs/impl_1/top_wrapper.bit`.

## <a name="RootFS"></a>Build a root file system

We will use Buildroot to build a BusyBox-based tiny root file system. Buildroot has no default configuration for the Zybo board but the ZedBoard default configuration should work also for the Zybo. Let us first configure Buildroot to:

* use a compiler cache (faster build),
* enable the thread library debugging (needed to build the gdb server),
* build (for the host PC) the gdb cross debugger with TUI support,
* customize the host name and welcome banner,
* enable networking,
* embed some extra (overlays) files that we will provide later,
* skip Linux kernel build (we will use the Linux kernel from the Xilinx Git repository),
* embed a tiny gdb server,
* embed dropbear, a tiny ssh server,
* skip U-Boot build (we will the U-Boot from the Xilinx Git repository).

Run the Buildroot configuration:

    Host> cd $BUILDROOT
    Host> make O=build zedboard_defconfig
    Host> make O=build menuconfig

In the Buildroot configuration menus change the following options:

    Build options -> Enable compiler cache -> yes
    Toolchain -> Thread library debugging -> yes
    Toolchain -> Build cross gdb for the host -> yes
    Toolchain -> TUI support -> yes
    System configuration -> System hostname -> sab4z
    System configuration -> System banner -> Welcome to SAB4Z (c) Telecom ParisTech
    System configuration -> Network interface to configure through DHCP -> eth0
    System configuration -> Root filesystem overlay directories -> ./build/overlays
    Kernel -> Linux Kernel -> no
    Target packages -> Debugging, profiling and benchmark -> gdb -> yes
    Target packages -> Networking applications -> dropbear -> yes
    Bootloaders -> U-Boot -> no

Quit (save when asked). Let us now configure BusyBox to enable the rx utility that we will need later:

    Host> make O=build busybox-menuconfig

In the BusyBox configuration menus change the following option:

    Miscellaneous Utilities -> rx -> yes

Quit (save when asked), create the overlays directory, populate it and build the root file system:

    Host> mkdir -p build/overlays/etc/profile.d
    Host> echo "export PS1='Sab4z> '" > build/overlays/etc/profile.d/prompt.sh
    Host> make O=build

Note: the first build takes some time, especially because Buildroot must first build the toolchain for ARM targets, but most of the work will not have to be redone if we later change the configuration and re-build. Copy the generated root file system:

    Host> cp $BUILDROOT/build/images/rootfs.cpio.uboot $SAB4Z/build/uramdisk.image.gz

Buildroot also built applications for the host PC that we will need later:

* a complete toolchain (cross-compiler, debugger...) for the ARM processor of the Zybo,
* dtc, a device tree compiler,
* mkimage, a utility used to create images for U-Boot...

They are in `$BUILDROOT/build/host/usr/bin`. Add this directory to your PATH and define the CROSS_COMPILE environment variable (note the trailing `-`):

    Host> export PATH=$PATH:$BUILDROOT/build/host/usr/bin
    Host> export CROSS_COMPILE=arm-buildroot-linux-uclibcgnueabi-

## <a name="Kernel"></a>Build the Linux kernel

Do not start this part before the [toolchain](#RootFS) is built: it is needed. Note: select the value to pass to the make -j option depending on the characteristics of your host system. Note: if needed, you can adapt the configuration before building: run the commented command.

    Host> cd $XLINUX
    Host> make mrproper
    Host> make O=build ARCH=arm xilinx_zynq_defconfig
    Host> # make O=build ARCH=arm menuconfig
    Host> make -j8 O=build ARCH=arm LOADADDR=0x8000 uImage
    Host> cp $XLINUX/build/arch/arm/boot/uImage $SAB4Z/build

## <a name="Uboot"></a>Build U-Boot

Do not start this part before the [toolchain](#RootFS) is built: it is needed. Note: select the value to pass to the make -j option depending on the characteristics of your host system. Note: if needed, you can adapt the configuration before building: run the commented command.

    Host> cd $XUBOOT
    Host> make mrproper
    Host> make O=build zynq_zybo_defconfig
    Host> # make O=build menuconfig
    Host> make -j8 O=build
    Host> cp $XUBOOT/build/u-boot $SAB4Z/u-boot.elf

## <a name="SDK"></a>Build the hardware dependant software

Do not start this part before the [hardware synthesis finishes](#Synthesis) finishes and the [toolchain](#RootFS) is built: they are needed.

#### <a name="DTS"></a>Linux kernel device tree

Generate the device tree sources:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> make XDTS=<some-path>/device-tree-xlnx dts

The sources are in `build/dts`. If needed, edit them before compiling the device tree blob with dtc:

    Host> dtc -I dts -O dtb -o build/devicetree.dtb build/dts/system.dts

#### <a name="FSBL"></a>First Stage Boot Loader (FSBL)

Generate the FSBL sources

    Host-Xilinx> make fsbl

The sources are in `build/fsbl`. If needed, edit them before compiling the FSBL:

    Host-Xilinx> make -C build/fsbl

#### <a name="BootImg"></a>Zynq boot image

Generate the Zynq boot image:

    Host-Xilinx> bootgen -w -image scripts/boot.bif -o build/boot.bin

#### <a name="SDCard"></a>Prepare the MicroSD card

Finally, mount the MicroSD card on your host PC, and copy the different components to it:

    Host> cd build
    Host> cp boot.bin devicetree.dtb uImage uramdisk.image.gz <path-to-mounted-sd-card>
    Host> sync

# <a name="Further"></a>Going further

## <a name="UserApp"></a>Create, compile and run a user software application

Do not start this part before the [toolchain](#RootFS) is built: it is needed.

The `C` sub-directory contains a very simple example C code `hello_world.c` that prints a welcome message, waits 2 seconds, prints a good bye message and exits. Cross-compile it on your host PC:

    Host> cd $SAB4Z/C
    Host> make CC=${CROSS_COMPILE}gcc hello_world

The only thing to do next is transfer the `hello_world` binary on the Zybo and execute it. There are several ways to transfer a file from the host PC to the Zybo. The most convenient, of course, is a network interface but in case none is available, here are several other options:

#### <a name="SDTransfer"></a>Transfer files from host PC to Zybo on MicroSD card

Mount the MicroSD card on your host PC, copy the `hello_world` executable on it, unmount and eject the MicroSD card, plug it in the Zybo, power on and connect as root. Mount the MicroSD card and run the application:

    Sab4z> mount /dev/mmcblk0p1 /mnt
    Sab4z> /mnt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

#### <a name="Overlays"></a>Add custom files to the root file system

Another possibility is offered by the overlay feature of Buildroot which allows to embed custom files in the generated root file system. Add the `hello_world` binary to the `/opt` directory of the root file system and re-build the root file system:

    Host> cd $BUILDROOT
    Host> mkdir -p build/overlays/opt
    Host> cp $SAB4Z/C/hello_world build/overlays/opt
    Host> make O=build
    Host> cp $BUILDROOT/build/images/rootfs.cpio.uboot $SAB4Z/build/uramdisk.image.gz

Mount the MicroSD card on your host PC, copy the new root file system image on it, unmount and eject the MicroSD card, plug it in the Zybo, power on and connect as root. Run the application located in `/opt` without mounting the MicroSD card:

    Sab4z> /opt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

#### <a name="RX"></a>File transfer on the serial link

The drawback of the two previous solutions is the MicroSD card manipulations. There is a way to transfer files from the host PC to the Zybo using the serial interface. We will use the BusyBox rx utility on the Zybo side and the sx utility, plus a serial console utility that supports file transfers with sx (like picocom, for instance). Launch picocom, with the `--send-cmd "sx" --receive-cmd "rx"` options, launch `rx <destination-file>` on the Zybo, press `C-a C-s` (control-a control-s) to instruct picocom to send a file from the host PC to the Zybo and provide the name of the file to send:

    Host> cd $SAB4Z/C
    Host> picocom -b115200 -fn -pn -d8 -r -l --send-cmd "sx" --receive-cmd "rx" /dev/ttyUSB1
    Sab4z> rx /opt/hello_world
    C
    *** file: hello_world
    sx hello_world 
    Sending hello_world, 51 blocks: Give your local XMODEM receive command now.
    Bytes Sent:   6656   BPS:3443                            
    
    Transfer complete
    
    *** exit status: 0

After the transfer completes, change the file's mode to executable and run the application:

    Sab4z> chmod +x /opt/hello_world
    Sab4z> /opt/hello_world
    Hello SAB4Z
    Bye! SAB4Z

Note: this transfer method is not very reliable. Avoid using it on large files: the probability that a transfer fails increases with its length.

## <a name="SAB4ZSoft"></a>Access SAB4Z from a user software application

Accessing SAB4Z from a user software application running on top of the Linux operating system is not as simple as it seems: because of the virtual memory, trying to access the SAB4Z registers using their physical addresses would fail. In order to do this we will use `/dev/mem`, a character device that is an image of the memory of the system. The character located at offset x from the beginning of `/dev/mem` is the byte stored at physical address x. Of course, accessing offsets corresponding to addresses that are not mapped in the system or writing at offsets corresponding to read-only addresses cause errors. As reading or writing at specific offset in a character device is not very convenient, we will also use mmap, a Linux system call that can map a device to memory. To make it short, `/dev/mem` is an image of the physical memory space of the system and mmap allows us to map portions of this at a known virtual address. Reading and writing at the mapped virtual addresses becomes equivalent to reading and writing at the physical addresses.

All this, for obvious security reasons, is privileged, but as we are root...

The example C program in `C/sab4z.c` maps the STATUS and R registers of SAB4Z at a virtual address and the `[2G..2G+512M[` physical address range (that is, the DDR accessed across the PL) at another virtual address. It takes one string argument. It first prints a welcome message, then uses the mapping to print the content of STATUS and R registers. It then writes `0x12345678` in the R register and starts searching for the passed string argument in the `[2G..2G+512M[` range. If it finds it, it prints all characters in a `[-20..+20[` range around the found string, and stops the search. Then, it prints again STATUS and R, a good bye message and exits. Have a look at the source code and use it as a starting point for your own projects.

Compile:

    Host> cd $SAB4Z/C
    Host> make CC=${CROSS_COMPILE}gcc sab4z

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

#### <a name="BootInAASPrinciples"></a>Principles

Thanks to the AXI bridge that SAB4Z implements, the `[2G..3G[` address range is an alias of `[0..1G[`. It is thus possible to run software on the Zybo that use only the `[2G..3G[` range instead of `[0..1G[`. It is even possible to run the Linux kernel there. However we must carefully select the range of physical memory that we will instruct the kernel to use:

* The Zybo has only 512MB of DDR, so the most we can use is `[2G..2G+512M[`.
* As already mentioned, the low DDR addresses cannot be accessed from the PL. So, we cannot let Linux access the low addresses of `[2G..2G+512M[` because we could not forward the requests to the DDR.
* The Linux kernel insists that its physical memory is aligned on 128MB boundaries. So, to skip the low addresses of `[2G..2G+512M[` we must skip an entire 128MB chunk.

All in all, we can run the Linux kernel in the `[2G+128MB..2G+512M[` range (`[0x8800_0000..0xa000_0000[`), that is, only 384MB instead of 512MB. The other drawback is that the path to the DDR across the PL is much slower than the direct one: its bit-width is 32 bits instead of 64 and its clock frequency is that of the PL, 100MHz in our example design, instead of 650MHz. Of course, the overhead will impact only cache misses but there will be an overhead. So why doing this? Why using less memory than available and slowing down the memory accesses? There are several good reasons. One of them is that instead of just relaying the memory accesses, the SAB4Z could be modified to implement a kind of monitoring of these accesses. It already counts the AXI transactions but it could do something more sophisticated. It could even tamper with the memory accesses, for instance to emulate accidental memory faults or attacks against the system.

#### <a name="BootInAASDTS"></a>Modify the device tree

Anyway, to boot and run Linux in the `[0x8800_0000..0xa000_0000[` physical memory range we need to modify a few things. First, edit the device tree source (`$SAB4Z/build/dts/system.dts`) and replace the definition of the physical memory:

	memory {
		device_type = "memory";
		reg = <0x0 0x20000000>;
	};

by:

	memory {
		device_type = "memory";
		linux,usable-memory = <0x88000000 0x18000000>;
		//reg = <0x0 0x20000000>;
	};

Recompile the blob:

    Host> cd $SAB4Z
    Host> dtc -I dts -O dtb -o build/devicetree.dtb build/dts/system.dts

#### <a name="BootInAASKernel"></a>Change the load address in U-Boot image of Linux kernel

Next, recreate the U-Boot image of the Linux kernel with a different load address and entry point. This address is the one at which U-Boot loads the Linux kernel image (`uImage`) and at which it jumps afterwards:

    Host> cd $XLINUX
    Host> make -j8 O=build ARCH=arm LOADADDR=0x88008000 uImage
    Host> cp $XLINUX/build/arch/arm/boot/uImage $SAB4Z/build

#### <a name="BootInAASUboot"></a>Adapt the U-Boot environment variables

Last, we must instruct U-Boot to load the device tree blob, Linux kernel and root file system images at different addresses. And, very important, we must force it not to displace the device tree blob and the root file system image as it does by default. This can be done by changing the default values of several U-Boot environment variables, as specified in the provided file:

    Host> cat $SAB4Z/scripts/uEnv.txt
    devicetree_load_address=0x8a000000
    kernel_load_address=0x8a080000
    ramdisk_load_address=0x8c000000
    fdt_high=0xffffffff
    initrd_high=0xffffffff

If U-Boot finds a file named `uEnv.txt` on the MicroSD card, it uses its content to define its environment variables. Mount the MicroSD card on your host PC, copy the `uEnv.txt` file, the new device tree blob and the new U-Boot image of the Linux kernel on the MicroSD card:

    Host> cd $SAB4Z
    Host> cp scripts/uEnv.txt build/devicetree.dtb build/uImage <path-to-mounted-sd-card>

#### <a name="BootInAASBoot"></a>Boot and see

Unmount and eject the MicroSD card, plug it in the Zybo, power on. As you will probably notice U-Boot takes a bit longer to copy the binaries from the MicroSD card to the memory and to boot the kernel but the system, even if slightly slower, remains responsive and perfectly usable. You can check that the memory accesses are really routed across the PL by pressing the BTN push-button twice. This should drive the LEDs with the counter of AXI address read transactions and you should see the LEDs blinking while the CPU performs read-write accesses to the memory across SAB4Z. If the LEDs do not blink enough, interact with the system with the serial console, this should increase the number of memory accesses.

#### <a name="BootInAASExercise"></a>Exercise

There is a way to use more DDR than 384MB. This involves a hardware modification and a rework of the software changes. This is left as an exercise.

