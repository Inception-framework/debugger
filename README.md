This repository and its sub-directories contain the VHDL source code, VHDL simulation environment, simulation, synthesis scripts and companion example software for SAB4Z, a simple design example for the Xilinx Zynq core. It can be ported on any board based on Xilinx Zynq cores but has been specifically designed for the Zybo board by Digilent. All provided instructions are for a host computer running a GNU/Linux operating system and have been tested on a Debian 8 (jessie) distribution. Porting to other GNU/Linux distributions should be very easy. If you are working under Microsoft Windows or Apple Mac OS X, installing a virtualization framework and running a Debian OS in a virtual machine is probably the easiest path.

Please signal errors and send suggestions for improvements to renaud.pacalet@telecom-paristech.fr.

# Table of content
* [License](#License)
* [Content](#Content)
* [Description](#Description)
* [Install from the archive](#Archive)
* [Test SAB4Z on the Zybo](#Run)
* [Build everything from scratch](#Build)
    * [Downloads](#BuildDownloads)
    * [Hardware synthesis](#BuildSynthesis)
    * [Build a root file system](#BuildRootFs)
    * [Build the Linux kernel](#BuildKernel)
    * [Build U-Boot](#BuildUboot)
    * [Build the hardware dependant software](#BuildHwDepSw)
* [Going further](#Further)
    * [Set up a network interface on the Zybo](#FurtherNetwork)
    * [Create a local network between host and Zybo](#FurtherDnsmasq)
    * [Transfer files from host PC to Zybo without a network interface](#FurtherFileTransfer)
    * [Run a user application on the Zybo](#FurtherUserApp)
    * [Debug a user application with gdb](#FurtherUserAppDebug)
    * [Access SAB4Z from a user application on the Zybo](#FurtherSab4zApp)
    * [Run the complete software stack across SAB4Z](#FurtherRunAcrossSab4z)
    * [Debug hardware using ILA](#FurtherIla)
* [Common problems and solutions](#Problems)
* [Glossary](#Glossary)

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
    ├── archives                Archives
    │   └── sdcard.tgz          Archive to unpack on MicroSD card
    ├── C                       C source code
    │   ├── hello_world.c       Simple example user application
    │   └── sab4z.c             User application using SAB4Z
    ├── COPYING                 License (English version)
    ├── COPYING-FR              Licence (version française)
    ├── COPYRIGHT               Copyright notice
    ├── hdl                     VHDL source code
    │   ├── axi_pkg.vhd         Package of AXI definitions
    │   ├── debouncer.vhd       Debouncer-resynchronizer
    │   └── sab4z.vhd           Top-level SAB4Z
    ├── images                  Figures
    │   ├── sab4z.fig           SAB4Z in Zybo
    │   ├── sab4z.png           PNG export of sab4z.fig
    │   └── zybo.png            Zybo board
    ├── Makefile                Main makefile
    ├── README.md               This file
    └── scripts                 Scripts
        ├── boot.bif            Zynq Boot Image description File
        ├── dts.tcl             TCL script for device tree generation
        ├── fsbl.tcl            TCL script for FSBL generation
        ├── uEnv.txt            Definitions of U-Boot environment variables
        └── vvsyn.tcl           Vivado TCL synthesis script

# <a name="Description"></a>Description

**SAB4Z** is a **S**imple **A**xi-to-axi **B**ridge **F**or **Z**ynq cores with a lite [AXI](#GlossaryAxi) slave port (S0_AXI) an AXI slave port (S1_AXI), a master AXI port (M_AXI), two internal registers (STATUS and R), a 4-bits input (SW), a 4-bits output (LED) and a one-bit command input (BTN). Its VHDL synthesizable model is available in the `hdl` sub-directory. The following figure represents SAB4Z mapped in the Programmable Logic (PL) of the Zynq core of a Zybo board. SAB4Z is connected to the Processing System (PS) of the Zynq core by the 3 AXI ports. When the ARM processor of the PS reads or writes at addresses in the `[0..1G[` range (first giga byte) it accesses the DDR memory of the Zybo (512MB), directly through the DDR controller. When the addresses fall in the `[1G..2G[` or `[2G..3G[` ranges, it accesses SAB4Z, through its S0_AXI and S1_AXI ports, respectively. SAB4Z can also access the DDR in the `[0..1G[` range, thanks to its M_AXI port. The four slide switches, LEDs and the rightmost push-button (BTN0) of the board are connected to the SW input, the LED output and the BTN input of SAB4Z, respectively.

![SAB4Z on a Zybo board](images/sab4z.png)

As shown on the figure, the accesses from the PS that fall in the `[2G..3G[` range (S1_AXI) are forwarded to M_AXI with an address down-shift from `[2G..3G[` to `[0..1G[`. The responses from M_AXI are forwarded back to S1_AXI. This path is thus a second way to access the DDR from the PS, across the PL. From the PS viewpoint each address in the `[0..1G[` range has an equivalent address in the `[2G..3G[` range. The Zybo board has only 512 MB of DDR and accesses above the DDR limit fall back in the low half (aliasing). Each DDR location can thus be accessed with 4 different addresses in the `[0..512M[`, `[512M..1G[`, `[2G..2G+512M[` or `[2G+512M..3G[` ranges.

---

**Note**: depending on the configuration, Zynq-based systems have a reserved low addresses range that cannot be accessed from the PL. In our case this low range is the first 512kB. It can be accessed in the `[0..512k[` range but not in the `[2G..2G+512k[` range where errors are raised. Last but not least, randomly modifying the content of the memory using the `[2G..3G[` range can crash the system or lead to unexpected behaviours if the modified region is currently in use by the currently running software stack.

---

**Note**: the M_AXI port that SAB4Z uses to access the DDR is not cache-coherent and the `[2G..3G[` range is, by default, not cacheable. Reading or writing in the `[2G..3G[` range is thus not strictly equivalent to reading or writing in the `[0..1G[` range.

---

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

In the following example code blocks we will use different prompts for the different contexts:

* `Host>` is the shell prompt of the regular user (you) on the host PC.
* `Host-Xilinx>` is the prompt of the regular user (you) on the host PC, for the shell that has been configured to use Xilinx tools: the Xilinx initialization script redefines the LD_LIBRARY_PATH environment variable to point to Xilinx shared libraries. A consequence is that many utilities of your host PC cannot be used any more from this shell without crashing with more or less accurate error messages. To avoid this, run the Xilinx tools, and only them, in a separate, dedicated shell.
* `Host#` is the shell prompt of the root user on the host PC (some actions must be run as root on the host).
* `Zynq>` is the U-Boot prompt on the Zybo board (more on U-Boot later).
* `Sab4z>` is the shell prompt of the root user on the Zybo board (the only one we will use on the Zybo).

Download the archive, insert a MicroSD card in your card reader and unpack the archive to it:

    Host> cd /tmp
    Host> wget https://gitlab.eurecom.fr/renaud.pacalet/sab4z/raw/master/archives/sdcard.tgz
    Host> tar -C <path-to-mounted-sd-card> -xf sdcard.tgz
    Host> sync
    Host> umount <path-to-mounted-sd-card>

Eject the MicroSD card.

# <a name="Run"></a>Test SAB4Z on the Zybo

* Plug the MicroSD card in the Zybo and connect the USB cable.
* Check the position of the jumper that selects the power source (USB or power adapter).
* Check the position of the jumper that selects the boot medium (MicroSD card).
* Power on. A new [character device](#GlossaryFt2232hCharDev) should show up (`/dev/ttyUSB1` by default) on the host PC for the serial link whith the Zybo.
* Launch a [terminal emulator](#GlossaryTerminalEmulator) (picocom, minicom...) and attach it to the new character device, with a 115200 baudrate, no flow control, no parity, 8 bits characters, no port reset and no port locking: `picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1`.
* Wait until Linux boots, log in as root (there is no password) and start interacting with SAB4Z.

<!-- -->
    Host> picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1
    ...
    Welcome to SAB4Z (c) Telecom ParisTech
    sab4z login: root
    Sab4z>

**Common problem**: [FATAL: cannot open /dev/ttyUSB1: Permission denied](#ProblemsChaDevAccessRights)

#### <a name="RunReadStatus"></a>Read the STATUS register (address `0x4000_0000`)

To access the SAB4Z memory spaces you can use devmem, a [Busybox](https://www.busybox.net/) utility that allows to access memory locations with their physical addresses. It is privileged but as we are root... Let us first read the content of the 32-bits status register at address `0x4000_0000`:

    Sab4z> devmem 0x40000000 32
    0x00000004
    Sab4z> devmem 0x40000000 32
    0x00000002
    Sab4z> devmem 0x40000000 32
    0x00000008

As can be seen, the content of the STATUS register is all zeroes, except its 4 LSBs, the life monitor, that spin with a period of about half a second and thus take different values depending on the exact instant of reading. The CNT counter is zero, so the LEDs are driven by the life monitor. Change the configuration of the 4 slide switches, read again the STATUS register and check that the 4 MSBs reflect the chosen configuration:

    Sab4z> devmem 0x40000000 32
    0x50000002

#### <a name="RunReadWriteR"></a>Read and write the R register (address `0x4000_0004`)

    Sab4z> devmem 0x40000004 32
    0x00000000
    Sab4z> devmem 0x40000004 32 0x12345678
    Sab4z> devmem 0x40000004 32
    0x12345678

#### <a name="RunReadDDR"></a>Read DDR locations

    Sab4z> devmem 0x01000000 32
    0x4D546529
    Sab4z> devmem 0x81000000 32
    0x4D546529
    Sab4z> devmem 0x40000000 32
    0x50001104

As expected, the `0x0100_0000` and `0x8100_0000` addresses store the same value (but things could be different if `0x0100_0000` was cached in a write-back cache and was dirty...) ARCNT and RCNT, the counters of address read and data read AXI transactions on AXI slave port S1_AXI, have been incremented because we performed a read access to the DDR at `0x8100_0000`. Let us write a DDR location, for instance `0x8200_0000`, but as we do not know whether the equivalent `0x0200_0000` is currently used by the running software stack, let us first read it and overwrite with the same value:

    Sab4z> devmem 0x82000000 32
    0xEDFE0DD0
    Sab4z> devmem 0x82000000 32 0xEDFE0DD0
    Sab4z> devmem 0x40000000 32
    0x51112204

The read counters have again been incremented because of the read access at `0x8200_0000`. The 3 write counters (AWCNT, WCNT and BCNT) have also been incremented by the write access at `0x8200_0000`.

#### <a name="RunPushButton"></a>Press the push-button, select LED driver

If we press the push-button and do not release it yet, the LEDs display `0001`, the new value of the incremented CNT. If we release the button the LEDs still display `0001` because when CNT=1 their are driven by... CNT. Press and release the button once more and check that the LEDs display `0010`, the current value of ARCNT. Continue exploring the 16 possible values of CNT and check that the LEDs display what they should.

#### <a name="RunHalt"></a>Halt the system

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

# <a name="Build"></a>Build everything from scratch

The embedded system world sometimes looks overcomplicated to non-specialists. But most of this complexity comes from the large number of small things that make this world, not really from the complexity of these small things themselves. Understanding large portions of this exciting field is perfectly feasible, even without a strong background in computer sciences. And, of course, doing things alone is probably one of the best ways to understand them. In the following we will progressively build a complete computer system based on the Zybo board, with custom hardware extensions, and running a GNU/Linux operating system.

---

**Note**: You will need the Xilinx tools (Vivado and its companion SDK). In the following we assume that they are properly installed. You will also need to download, configure and build several free and open source software. Some steps can be run in parallel because they do not depend on the results of other steps. Some steps cannot be started before others finish and this will be signalled.

---

**Note**: the instructions bellow introduce new concepts one after the other, with the advantage that for any given goal the number of actions to perform is limited and each action is easier to understand. The drawback is that, each time we introduce a new concept, we will have to reconfigure, rebuild and reinstall one or several components. In certain circumstances (like, for instance, when reconfiguring the Buildroot tool chain) such a move will take several minutes or even worse. Just the once will not hurt, the impatient should thus read the complete document before she starts following the instructions.

---

**Note**: the Linux repository, the Buildroot repository and the directory in which we will build all components (`$SAB4Z/build`) occupy several GB of disk space each. Carefully select where to install them.

---

## <a name="BuildDownloads"></a>Downloads

Clone all components from their respective git repositories and define shell environment variables pointing to their local copies:

    Host> SAB4Z=<some-path>/sab4z
    Host> XLINUX=<some-path>/linux-xlnx
    Host> XUBOOT=<some-path>/u-boot-xlnx
    Host> XDTS=<some-path>/device-tree-xlnx
    Host> BUILDROOT=<some-path>/buildroot
    Host> git clone https://gitlab.eurecom.fr/renaud.pacalet/sab4z.git $SAB4Z
    Host> git clone https://github.com/Xilinx/linux-xlnx.git $XLINUX
    Host> git clone https://github.com/Xilinx/u-boot-xlnx.git $XUBOOT
    Host> git clone http://github.com/Xilinx/device-tree-xlnx.git $XDTS
    Host> git clone http://git.buildroot.net/git/buildroot.git $BUILDROOT

## <a name="BuildSynthesis"></a>Hardware synthesis

The hardware synthesis produces a bitstream file from the VHDL source code (in `$SAB4Z/hdl`). It is done by the Xilinx Vivado tools. SAB4Z comes with a Makefile and a synthesis script that automate the synthesis:

    Host-Xilinx> SAB4Z=<some-path>/sab4z
    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> make vv-all

The generated bitstream is `$SAB4Z/build/vv/top.runs/impl_1/top_wrapper.bit`. This binary file is used to configure the FPGA part of the Zynq core of the Zybo board such that it implements our VHDL design. A binary description of our hardware design is also available in `$SAB4Z/build/vv/top.runs/impl_1/top_wrapper.sysdef`. It is not human-readable but we will use it later to generate the [device tree](#GlossaryDeviceTree) sources and the [First Stage Boot Loader](#GlossaryFsbl) (FSBL) sources.

---

**Note**: we will also use the `$SAB4Z/build` directory to build and store all other components.

---

## <a name="BuildRootFs"></a>Build a root file system

Just like your host, our Zybo computer needs a root [file system](#GlossaryFileSystem) to run a decent operating system like GNU/Linux. We will use [Buildroot](https://buildroot.org/) to build and populated a Busybox-based, tiny, [initramfs](#GlossaryInitramfs) root file system. In other notes will will explore other types of root file systems (networked file systems, file systems on the MicroSD card...) but as initramfs is probably the simplest of all, let us start with this one.

Buildroot is a very nice and easy to use toolbox dedicated to the creation of root file systems for many different target embedded systems. It can also build Linux kernels and other useful software but we will use it only to generate our root file system. Buildroot has no default configuration for the Zybo board but the ZedBoard (another very common board based on Xilinx Zynq cores) default configuration works also for the Zybo. First create a default Buildroot configuration in `$SAB4Z/build/rootfs` for our board:

    Host> mkdir -p $SAB4Z/build/rootfs
    Host> touch $SAB4Z/build/rootfs/external.mk $SAB4Z/build/rootfs/Config.in
    Host> cd $BUILDROOT
    Host> make BR2_EXTERNAL=$SAB4Z/build/rootfs O=$SAB4Z/build/rootfs zynq_zed_defconfig

Then, customize the default configuration to:

* use a compiler cache (faster build),
* customize the host name and welcome banner,
* specify an overlay directory (a convenient way to customize the built root file system),
* skip Linux kernel build (we will use the Linux kernel from the Xilinx git repository),
* skip U-Boot build (we will the U-Boot from the Xilinx git repository).

<!-- -->
    Host> cd $SAB4Z/build/rootfs
    Host> make menuconfig

In the Buildroot configuration menus change the following options:

    Build options -> Enable compiler cache -> yes
    System configuration -> System hostname -> sab4z
    System configuration -> System banner -> Welcome to SAB4Z (c) Telecom ParisTech
    System configuration -> Root filesystem overlay directories -> $(BR2_EXTERNAL)/overlays
    Kernel -> Linux Kernel -> no
    Bootloaders -> U-Boot -> no

Quit (save when asked). The overlay directory that we specified will be incorporated in the root file system. It is anchored to the root directory of the root file system, that is, any file or directory located at the root of the overlay directory will be located at the root of the file system. Create the overlay directory, populate it with a simple shell script that changes the default shell prompt and build the root file system:

    Host> cd $SAB4Z/build/rootfs
    Host> mkdir -p overlays/etc/profile.d
    Host> echo "export PS1='Sab4z> '" > overlays/etc/profile.d/prompt.sh
    Host> make

---

**Note**: the first build takes some time, especially because Buildroot must first build the toolchain for ARM targets, but most of the work will not have to be redone if we later change the configuration and rebuild (unless we change the configuration of the Buildroot tool chain, in which case we will have to rebuild everything).

---

The generated root file system is available in different formats:

* `$SAB4Z/build/rootfs/images/rootfs.tar` is a tar archive that we can explore with the tar utility. This is left as an exercise for the reader.
* `$SAB4Z/build/rootfs/images/rootfs.cpio` is the same but in cpio format (another archive format).
* `$SAB4Z/build/rootfs/images/rootfs.cpio.gz` is the compressed version of `$SAB4Z/build/rootfs/images/rootfs.cpio`.
* Finally, `$SAB4Z/build/rootfs/images/rootfs.cpio.uboot` is the same as `$SAB4Z/build/rootfs/images/rootfs.cpio.gz` with a 64 bytes header added. As its name says, this last form is intended for use with the U-Boot boot loader and the added header is for U-Boot use. More on U-Boot later. This version is thus the root file system image that we will store on the MicroSD card and use on the Zybo, but is it not yet the final version. We still have a few things to add to the overlays.

The shell script that we added to the overlay (`$SAB4Z/build/rootfs/overlays/etc/profile.d/prompt.sh`) can be found at `/etc/profile.d/prompt.sh` in the generated root file system:

    Host> tar tf $SAB4Z/build/rootfs/images/rootfs.tar | grep prompt
    ./etc/profile.d/prompt.sh

Buildroot also built applications for the host PC that we will need later:

* a complete toolchain (cross-compiler, debugger...) for the ARM processor of the Zybo,
* dtc, a device tree compiler (more on this later),
* mkimage, a utility used to create images for U-Boot (and that the build system used to create `$SAB4Z/build/rootfs/images/rootfs.cpio.uboot`).

They are in `$SAB4Z/build/rootfs/host/usr/bin`. Add this directory to your PATH and define the CROSS_COMPILE environment variable (note the trailing hyphen):

    Host> export PATH=$PATH:$SAB4Z/build/rootfs/host/usr/bin
    Host> export CROSS_COMPILE=arm-buildroot-linux-uclibcgnueabi-

## <a name="BuildKernel"></a>Build the Linux kernel

---

**Note**: Do not start this part before the [toolchain](#GlossaryRootFs) is built: it is needed.

---

Run the [Linux kernel](#GlossaryLinuxKernel) configurator to create a default kernel configuration for our board in `$SAB4Z/build/kernel`:

    Host> cd $XLINUX
    Host> make O=$SAB4Z/build/kernel ARCH=arm xilinx_zynq_defconfig

Then, build the kernel:

    Host> cd $SAB4Z/build/kernel
    Host> make -j8 ARCH=arm

---

**Note**: select the value to pass to the make `-j` option depending on the characteristics of your host (number of physical / virtual cores).

---

**Note**: do not forget the `ARCH=arm` parameter: the Linux kernel can be build for many different types of processors and the processor embedded in the Zynq core of the Zybo is an ARM processor.

---

Just like Buildroot, the Linux kernel build system offers a way to tune the default configuration before building:

    Host> cd $SAB4Z/build/kernel
    Host> make ARCH=arm menuconfig
    Host> make -j8 ARCH=arm

As for the root file system, the kernel is available in different formats:

* `$SAB4Z/build/kernel/vmlinux` is an uncompressed executable in ELF format,
* `$SAB4Z/build/kernel/arch/arm/boot/zImage` is a compressed executable.

And just like for the root file system, none of these is the one we will use on the Zybo. In order to load the kernel in memory with U-Boot we must generate a kernel image in U-Boot format. This can be done using the Linux kernel build system. We just need to provide the load address and entry point that U-Boot will use when loading the kernel into memory and when jumping into the kernel:

    Host> cd $SAB4Z/build/kernel
    Host> make -j8 ARCH=arm LOADADDR=0x8000 uImage

The result is in `$SAB4Z/build/kernel/arch/arm/boot/uImage` and, as its size shows, it the same as `$SAB4Z/build/kernel/arch/arm/boot/zImage` with a 64 bytes U-Boot header added:


    Host> cd $SAB4Z/build/kernel
    Host> ls -l arch/arm/boot/zImage arch/arm/boot/uImage
    -rw-r--r-- 1 mary users 3750312 Apr 11 13:09 arch/arm/boot/uImage
    -rwxr-xr-x 1 mary users 3750248 Apr 11 12:08 arch/arm/boot/zImage

The 64 bytes header, among other parameters, contains the load address and entry point we specified (the two 32-bits words starting at address `0x20`, in little endian order):

    Host> od -N64 -tx4 arch/arm/boot/uImage
    0000000 56190527 ae382b10 e1850b57 68393900
    0000020 00800000 00800000 5845016d 00020205
    0000040 756e694c 2e342d78 2d302e34 696c6978
    0000060 332d786e 35353534 6137672d 66333030
    0000100

When loading the kernel, U-Boot will copy the archive somewhere in memory, parse the 64 bytes header, uncompress the kernel and install it starting at address `0x8000`, add some more information in the first 32 kB of memory and jump at the entry point, which is also `0x8000`. This kernel image is thus the one we will store on the MicroSD card and use on the Zybo.

The kernel embeds a collection of software device drivers that are responsible for the management of the various hardware devices (network interface, timer, interrupt controller...) Some are integrated into the kernel, some are delivered as _external modules_, a kind of device driver that is dynamically loaded in memory by the kernel when it is needed. These external modules must also be built and installed in our root file system where the kernel will find them, that is, in `/lib/modules`. The Buildroot overlays directory is the perfect way to embed the kernel modules in the root file system. Of course, we will have to rebuild the root file system but this should be very fast.

    Host> cd $SAB4Z/build/kernel
    Host> make -j8 ARCH=arm modules
    Host> make -j8 ARCH=arm modules_install INSTALL_MOD_PATH=$SAB4Z/build/rootfs/overlays
    Host> cd $SAB4Z/build/rootfs
    Host> make

The root file system `$SAB4Z/build/rootfs/images/rootfs.cpio.uboot` now contains the kernel modules and is complete:

    Host> cd $SAB4Z/build/rootfs
    Host> tar tf images/rootfs.tar ./lib/modules
    ./lib/modules/
    ./lib/modules/4.4.0-xilinx-34555-g7a003fc/
    ./lib/modules/4.4.0-xilinx-34555-g7a003fc/kernel/
    ...
    ./lib/modules/4.4.0-xilinx-34555-g7a003fc/modules.symbols.bin
    ./lib/modules/4.4.0-xilinx-34555-g7a003fc/modules.devname
    ./lib/modules/4.4.0-xilinx-34555-g7a003fc/modules.builtin

## <a name="BuildUboot"></a>Build U-Boot

---

**Note**: Do not start this part before the [toolchain](#BuildRootFs) is built: it is needed.

---

U-Boot is a boot loader that is very frequently used in embedded systems. It runs before the Linux kernel to:

* initialize the board,
* load the initramfs root file system image in RAM,
* load the device tree blob in RAM (more on this later),
* load the Linux kernel image in RAM,
* parse the header of the Linux kernel image,
* uncompress the Linux kernel and install it at the load address specified in the header,
* prepare some parameters for the kernel in CPU registers and in the first 32 kB of memory,
* jump into the kernel at the specified entry point.

Run the U-Boot configurator to create a default U-Boot configuration for our board in `$SAB4Z/build/uboot`:

    Host> cd $XUBOOT
    Host> make O=$SAB4Z/build/uboot zynq_zybo_defconfig

Then, build U-Boot:

    Host> cd $SAB4Z/build/uboot
    Host> make -j8

---

**Note**: select the value to pass to the make `-j` option depending on the characteristics of your host (number of physical / virtual cores).

---

Just like Buildroot and the Linux kernel, the U-Boot build system offers a way to tune the default configuration before building:

    Host> cd $SAB4Z/build/uboot
    Host> make menuconfig
    Host> make -j8

Again, the result of U-Boot build is available in different formats. The one we are interested in and that we will use on the Zybo is `$SAB4Z/build/uboot/u-boot`, the executable in ELF format. Later, we will glue it together with several other files to create a single _boot image_ file. As the Xilinx bootgen utility that we will use for that insists that its extension is `.elf`, rename it:

    Host> cp $SAB4Z/build/uboot/u-boot $SAB4Z/build/uboot/u-boot.elf

## <a name="BuildHwDepSw"></a>Build the hardware dependant software

Do not start this part before the [hardware synthesis finishes](#BuildSynthesis) finishes and the [toolchain](#BuildRootFs) is built: they are needed.

#### <a name="BuildHWDepSWDTS"></a>Linux kernel device tree

SAB4Z comes with a Makefile and a TCL script that automate the generation of device tree sources using the Xilinx hsi utility, the clone of the git repository of Xilinx device trees (`<some-path>/device-tree-xlnx`) and the description of our hardware design that was generated during the hardware synthesis (`$SAB4Z/build/vv/top.runs/impl_1/top_wrapper.sysdef`). Generate the default device tree sources for our hardware design for the Zybo:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> XDTS=<some-path>/device-tree-xlnx
    Host-Xilinx> make XDTS=$XDTS dts

The sources are in `$SAB4Z/build/dts`, the top level is `$SAB4Z/build/dts/system.dts`. Have a look at the sources. If needed, edit them before compiling the device tree blob with dtc:

    Host> cd $SAB4Z
    Host> dtc -I dts -O dtb -o build/devicetree.dtb build/dts/system.dts

#### <a name="BuildHWDepSWFSBL"></a>First Stage Boot Loader (FSBL)

Generate the FSBL sources

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> make fsbl

The sources are in `$SAB4Z/build/fsbl`. If needed, edit them before compiling the FSBL:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> make -C build/fsbl

#### <a name="BuildHWDepSWBootImg"></a>Zynq boot image

A Zynq boot image is a file that is read from the boot medium of the Zybo when the board is powered on. It contains the FSBL ELF, the bitstream and the U-Boot ELF. Generate the Zynq boot image with the Xilinx bootgen utility and the provided boot image description file:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> bootgen -w -image scripts/boot.bif -o build/boot.bin

#### <a name="BuildHWDepSWSDCard"></a>Prepare the MicroSD card

Finally, prepare a MicroSD card with a FAT32 first primary partition (8MB minimum), mount it on your host PC, and copy the different components to it:

    Host> cd $SAB4Z
    Host> cp build/boot.bin build/devicetree.dtb build/kernel/arch/arm/boot/uImage <path-to-mounted-sd-card>
    Host> cp build/rootfs/images/rootfs.cpio.uboot <path-to-mounted-sd-card>/uramdisk.image.gz
    Host> sync
    Host> umount <path-to-mounted-sd-card>

Eject the MicroSD card, plug it in the Zybo and power on.

# <a name="Further"></a>Going further

## <a name="FurtherNetwork"></a>Set up a network interface on the Zybo

The serial interface that we use to interact with the Zybo is limited both in terms of bandwidth and functionality. Transferring files between the host and the Zybo, for instance, even if [not impossible](#FurtherFileTransfer) through the serial interface is overcomplicated. This section will show you how to set up a much more powerful and convenient network interface between host and Zybo. In order to do this we will connect the board to a wired network using an Ethernet cable. Note that if you do not have a wired network or if, for security reasons, you cannot use your existing wired network, it is possible to [create a point-to-point Ethernet network between your host and the board](#FurtherDnsmasq).

From now on we consider that the host and the Zybo can be connected on the same wired network. We also consider that the host knows the Zybo under the sab4z hostname. The next step is to add dropbear, a tiny ssh server, to our root file system and enable the networking. This will allow us to connect to the Zybo from the host using a ssh client.

    Host> cd $SAB4Z/build/rootfs
    Host> make menuconfig

In the Buildroot configuration menus change the following options

    System configuration -> Network interface to configure through DHCP -> eth0
    Target packages -> Networking applications -> dropbear -> yes

By default, for security reasons, the board will reject ssh connections for user root. Let us copy our host ssh public key to the Zybo such that we can connect as root on the Zybo, from the host, without password. If you do not have a ssh key already, generate one first with ssh-keygen. Assuming our public key on the host is `~/.ssh/id_rsa.pub`, add it to the Buildroot overlays and rebuild the root file system:

    Host> cd $SAB4Z/build/rootfs
    Host> mkdir -p overlays/root/.ssh
    Host> cp ~/.ssh/id_rsa.pub overlays/root/.ssh/authorized_keys
    Host> make

Mount the MicroSD card on your host PC, copy the new root file system image on it, unmount and eject the MicroSD card, plug it in the Zybo, power on and try to connect from the host:

    Host> cd $SAB4Z/build/rootfs
    Host> cp images/rootfs.cpio.uboot <path-to-mounted-sd-card>/uramdisk.image.gz
    Host> sync
    Host> umount <path-to-mounted-sd-card>
    Host> ssh root@sab4z
    The authenticity of host 'sab4z (<no hostip for proxy command>)' can't be established.
    ECDSA key fingerprint is d3:c5:2e:05:5d:be:89:42:65:d5:62:45:39:18:41:24.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'sab4z' (ECDSA) to the list of known hosts.

A [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) host key has been automatically generated on the Zybo, sent back to the host for confirmation and, as we accepted it, has been added to the list of known hosts that we trust (compare the strings after the ecdsa-sha2-nistp521 token, on the Zybo board and on the host):

    Sab4z> ls /etc/dropbear
    dropbear_ecdsa_host_key
    Sab4z> dropbearkey -y -f /etc/dropbear/dropbear_ecdsa_host_key
    Public key portion is:
    ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAD8DHs2poUcaCO8H3pQAyFb5JzXe9CW7MZGXTp9C9toKBFcGS2447ROqxN9iLSASklpqF3deRNahRNOTOHMyEOgAgEsi209XSOX+aeNTvxldJG1YfWcVvzJHoaFpayDia69BskoQ+jbqccZhoFiAGejBGrjdhEBroWkCrlfjshJwltEnQ== root@sab4z
    Fingerprint: md5 9b:6a:22:01:87:1e:98:4a:03:43:10:25:9d:59:d9:04

<!-- -->

    Host> tail -1 ~/.ssh/known_hosts
    |1|hoC0OVXZJbRwQnCpSW7i2d6ZexE=|Guc9B8co0pmAWmxp3T7n2i5RPj4= ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAD8DHs2poUcaCO8H3pQAyFb5JzXe9CW7MZGXTp9C9toKBFcGS2447ROqxN9iLSASklpqF3deRNahRNOTOHMyEOgAgEsi209XSOX+aeNTvxldJG1YfWcVvzJHoaFpayDia69BskoQ+jbqccZhoFiAGejBGrjdhEBroWkCrlfjshJwltEnQ==

Unfortunately, our root file system is initramfs and thus non persistent accross reboot. Next time, a new ECDSA host key will be generated and it will be different, forcing us to delete the old one and add the new one to the `~/.ssh/known_hosts` file on the host. To avoid this, let us copy the generated ECDSA host key to the Buildroot overlays, such that the authentification of the Zybo becomes persistent accross reboot. The dropbear ssh server that runs on the Zybo, when discovering that an ECDSA host key is already present in `/etc/dropbear`, will reuse it instead of creating a new one. Let us use our new network interface to do this:

    Host> cd $SAB4Z/build/rootfs
    Host> mkdir -p overlays/etc/dropbear
    Host> scp root@sab4z:/etc/dropbear/dropbear_ecdsa_host_key overlays/etc/dropbear
    Host> make

We must now copy the new root file system image on the MicroSD card. But as we have a working network interface there is no need to eject-mount-copy-eject. Let us first mount the MicroSD card on the root file system of the running Zybo:

    Sab4z> mount /dev/mmcblk0p1 /mnt
    Sab4z> ls -al /mnt
    total 7142
    drwxr-xr-x    2 root     root           512 Jan  1 00:00 .
    drwxr-xr-x   17 root     root           400 Apr 14  2016 ..
    -rwxr-xr-x    1 root     root       2627944 Apr 14  2016 boot.bin
    -rwxr-xr-x    1 root     root          9113 Apr 14  2016 devicetree.dtb
    -rwxr-xr-x    1 root     root       3750456 Apr 14  2016 uImage
    -rwxr-xr-x    1 root     root        923881 Apr 14  2016 uramdisk.image.gz

Then, use the network link to transfer the new root file system image to the MicroSD card on the Zybo:

    Host> cd $SAB4Z
    Host> scp build/rootfs/images/rootfs.cpio.uboot root@sab4z:/mnt/uramdisk.image.gz

Finally, on the Zybo, unmount the MicroSD card and reboot:

    Sab4z> umount /mnt
    Sab4z> reboot

We should now be able to ssh or scp from host to Zybo without password, even after rebooting.

## <a name="FurtherDnsmasq"></a>Create a local network between host and Zybo

Under GNU/Linux, dnsmasq (http://www.thekelleys.org.uk/dnsmasq/doc.html) is a very convenient way to create a point-to-point Ethernet network between your host and the board. It even allows to share the wireless connection of a laptop with the board. To install dnsmasq on Debian:

    Host# apt-get install dnsmasq

To configure dnsmasq you will need the Ethernet MAC address of your board. Connect the Zybo to the host with the USB cable, power it up, launch your terminal emulator and hit a key to stop the U-Boot countdown.

    Host> picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1
    ...
    Hit any key to stop autoboot:  0
    Zynq> printenv ethaddr
    ethaddr=00:0a:35:00:01:81

---

**Note**: if you have not been fast enough to stop the U-Boot countdown, simply wait until the Linux kernel boots, log in as root and reboot.

---

Note the Ethernet MAC address (`00:0a:35:00:01:81` in our example). Create a dnsmasq configuration file for the Zybo (replace the Ethernet MAC address by the one you noted and the interface and IP address by whatever suits you best), add a new entry in `/etc/hosts` and force dnsmasq to reload its configuration:

    Host# cat <<! > /etc/dnsmasq.d/sab4z.conf
    interface=eth0
    dhcp-host=00:0A:35:00:01:81,sab4z,10.42.0.129,infinite
    !
    Host# echo "10.42.0.129    sab4z" >> /etc/hosts
    Host# /etc/init.d/dnsmasq reload

If needed, for instance to avoid conflicts, you can change the Ethernet MAC address of your Zybo from the U-Boot command line:

    Host> picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1
    ...
    Hit any key to stop autoboot:  0
    Zynq> printenv ethaddr
    ethaddr=00:0a:35:00:01:81
    Zynq> setenv ethaddr aa:bb:cc:dd:ee:ff
    Zynq> saveenv
    Saving Environment to SPI Flash...
    SF: Detected S25FL128S_64K with page size 256 Bytes, erase size 64 KiB, total 16 MiB
    Erasing SPI flash...Writing to SPI flash...done

The new Ethernet MAC address has been changed and stored in the on-board SPI Flash memory, from where it will be read again by U-Boot the next time we reboot the board.

## <a name="FurtherFileTransfer"></a>Transfer files from host PC to Zybo without a network interface

A network interface should always be preferred to transfer files from the host to the Zybo: it is fast, reliable and it avoids manipulating the delicate MicroSD card. Here are several alternate ways, in case you cannot set up a network interface between your host and the Zybo.

#### <a name="FurtherFileTransferSD"></a>Use the MicroSD card

By default the MicroSD card is not mounted on the root file system of the Zybo but it can be. This is a way to import / export data or even custom applications to / from the host PC (of course, a network interface is much better). Simply add files to the MicroSD card from the host PC and they will show up on the Zybo once the MicroSD card is mounted. Mount the MicroSD card on your host PC, copy the files to transfer on it, unmount and eject the MicroSD card:

    Host> cp foo <path-to-mounted-sd-card>
    Host> umount <path-to-mounted-sd-card>

Plug the MicroSD card in the Zybo, power on, connect as root and mount the MicroSD card:

    Sab4z> mount /dev/mmcblk0p1 /mnt
    Sab4z> ls -al /mnt
    total 7142
    drwxr-xr-x    2 root     root           512 Jan  1 00:00 .
    drwxr-xr-x   17 root     root           400 Apr 14  2016 ..
    -rwxr-xr-x    1 root     root       2627944 Apr 14  2016 boot.bin
    -rwxr-xr-x    1 root     root          9113 Apr 14  2016 devicetree.dtb
    -rwxr-xr-x    1 root     root          1295 Apr 14  2016 foo
    -rwxr-xr-x    1 root     root       3750456 Apr 14  2016 uImage
    -rwxr-xr-x    1 root     root        923881 Apr 14  2016 uramdisk.image.gz

Conversely, of course, you can store a file on the mounted MicroSD card from the Zybo, properly unmount the card, remove it from its slot, mount it on your host PC and copy the file from the MicroSD card to the host PC.

Do not forget to unmount the card properly before shutting down the Zybo. If you do not there is a risk that its content is damaged:

    Sab4z> umount /mnt
    Sab4z> poweroff

#### <a name="FurtherFileTransferOverlays"></a>Add custom files to the root file system

Another possibility is offered by the overlay feature of Buildroot which allows to embed custom files in the generated root file system. Add the files to transfer to the overlay and rebuild the root file system:

    Host> cd $SAB4Z/build/rootfs
    Host> mkdir -p overlays/tmp
    Host> cp foo overlays/tmp
    Host> make

Mount the MicroSD card on your host PC, copy the new root file system image on it:

    Host> cp $SAB4Z/build/rootfs/images/rootfs.cpio.uboot <path-to-mounted-sd-card>/uramdisk.image.gz

Unmount and eject the MicroSD card, plug it in the Zybo, power on and connect as root:

    Sab4z> ls /tmp
    foo

#### <a name="FurtherFileTransferRx"></a>File transfer on the serial link

The drawback of the two previous solutions is the MicroSD card manipulations. There is a way to transfer files from the host PC to the Zybo using the serial interface. On the Zybo side we will use the Busybox rx utility. As it is not enabled by default, we will first reconfigure and rebuild our root file system:

    Host> cd $SAB4Z/build/rootf
    Host> make busybox-menuconfig

In the Busybox configuration menus change the following option:

    Miscellaneous Utilities -> rx -> yes

Quit (save when asked), rebuild, mount the MicroSD card on the host, copy the new root file system image, unmount and eject the MicroSD card, plug it in the Zybo and power on:

    Host> cd $SAB4Z/build/rootf
    Host> make
    ...
    Host> cp $SAB4Z/build/rootfs/images/rootfs.cpio.uboot <path-to-mounted-sd-card>/uramdisk.image.gz
    Host> umount <path-to-mounted-sd-card>

On the host side we will use the sx utility. If it is not already, install it first - it is provided by the lrzsz Debian package. Launch picocom, with the `--send-cmd "sx" --receive-cmd "rx"` options, launch `rx <destination-file>` on the Zybo, press `C-a C-s` (control-a control-s) to instruct picocom to send a file from the host PC to the Zybo and provide the name of the file to send:

    Host> picocom -b115200 -fn -pn -d8 -r -l --send-cmd "sx" --receive-cmd "rx" /dev/ttyUSB1
    Sab4z> rx /tmp/foo
    C
    *** file: foo
    sx foo
    Sending foo, 51 blocks: Give your local XMODEM receive command now.
    Bytes Sent:   6656   BPS:3443                            
    
    Transfer complete
    
    *** exit status: 0
    Sab4z> ls /tmp
    foo

---

**Note**: this transfer method is not very reliable. Avoid using it on large files: the probability that a transfer fails increases with its length.

---

## <a name="FurtherUserApp"></a>Create, compile and run a user software application

Do not start this part before the [toolchain](#BuildRootFs) is built: it is needed.

The `C` sub-directory contains a very simple example C code `hello_world.c` that prints a welcome message, computes and prints the sum of the 100 first integers, waits 2 seconds, prints a good bye message and exits. Cross-compile it on your host PC:

    Host> cd $SAB4Z/C
    Host> ${CROSS_COMPILE}gcc -o hello_world hello_world.c

Transfer the `hello_world` binary on the Zybo (using the [network interface](#FurtherNetwork) or [another method](#FurtherFileTransfer) and execute it.

    Host> cd $SAB4Z/C
    Host> scp hello_world root@sab4z:
    Host> ssh root@sab4z
    Sab4z> ls
    hello_world
    Sab4z> ./hello_world 
    Hello SAB4Z
    sum_{i=0}^{i=100}{i}=5050
    Bye! SAB4Z

## <a name="FurtherUserAppDebug"></a>Debug a user application with gdb

In order to debug our simple user application while it is running on the target we will need a [network interface between the host PC and the Zybo](#FurtherNetwork). In the following we assume that the Zybo board is connected to the network and that its hostname is sab4z.

We will first rework once again our root file system to:

* enable the thread library debugging (needed to build the [gdb server](#GlossaryGdbServer)),
* build (for the Zybo board) a tiny gdb server,
* build (for the host PC) the gdb cross debugger with TUI and python support.

<!-- -->

    Host> cd $SAB4Z/build/rootfs
    Host> make menuconfig

In the Buildroot configuration menus change the following options

    Toolchain -> Thread library debugging -> yes
    Toolchain -> Build cross gdb for the host -> yes
    Toolchain -> TUI support -> yes
    Toolchain -> Python support -> yes
    Target packages -> Debugging, profiling and benchmark -> gdb -> yes

Rebuild the root file system, transfer its image to the MicroSD card mounted on the running Zybo and reboot the Zybo:

    Host> cd $SAB4Z/build/rootfs
    Host> make
    Host> scp images/rootfs.cpio.uboot root@sab4z:/mnt/uramdisk.image.gz

<!-- -->

    Sab4z> umount /mnt
    Sab4z> reboot

The Zybo now has everything that is needed to debug applications. Recompile the user application with debug information added, transfer the binary to the Zybo and launch gdbserver on the Zybo:

    Host> cd $SAB4Z/C
    Host> ${CROSS_COMPILE}gcc -g -o hello_world hello_world.c
    Host> scp hello_world root@sab4z:
    Host> ssh root@sab4z
    Sab4z> gdbserver :1234 hello_world

On the host PC, launch gdb, connect to the gdbserver that runs on the Zybo and start interacting (set breakpoints, examine variables...):

    Host> cd $SAB4Z/C
    Host> ${CROSS_COMPILE}gdb -x $SAB4Z/build/rootfs/staging/usr/share/buildroot/gdbinit hello_world
    GNU gdb (GDB) 7.9.1
    ...
    (gdb) target remote sab4z:1234
    ...
    (gdb) l 20
    15    
    16        printf("Hello SAB4Z\n");
    17        s = 0;
    18        for(i = 0; i <= 100; i++) {
    19          s += i;
    20        }
    21        printf("sum_{i=0}^{i=100}{i}=%d\n", s);
    22        sleep(2);
    23        printf("Bye! SAB4Z\n");
    24      }
    (gdb) b 21
    Breakpoint 1 at 0x1052c: file hello_world.c, line 21.
    (gdb) c
    Continuing.
    
    Breakpoint 1, main () at hello_world.c:21
    21	  printf("sum_{i=0}^{i=100}{i}=%d\n", s);
    (gdb) p s
    $1 = 5050
    (gdb) c
    Continuing.
    [Inferior 1 (process 734) exited with code 013]
    (gdb) q

---

**Note**: there are plenty of gdb front ends for those who do not like its command line interface. TUI is the gdb built-in, curses-based interface. Just type `C-x a` to enter TUI while gdb runs.

---

## <a name="FurtherSab4zApp"></a>Access SAB4Z from a user software application

Accessing SAB4Z from a user software application running on top of the Linux operating system is not as simple as it seems: because of the virtual memory, trying to access the SAB4Z registers using their physical addresses would fail. In order to do this we will use `/dev/mem`, a character device that is an image of the memory of the system:

    fd = open("/dev/mem", O_RDWR | O_SYNC); // Open dev-mem character device

The character located at offset x from the beginning of `/dev/mem` is the byte stored at physical address x. Of course, accessing offsets corresponding to addresses that are not mapped in the system or writing at offsets corresponding to read-only addresses cause errors. As reading or writing at specific offset in a character device is not very convenient, we will also use mmap, a Linux system call that can map a device to memory.

    unsigned long page_size = 8UL;
    off_t phys_addr = 0x40000000;
    void *virt_addr = mmap(0, page_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, phys_addr); // Map
    uint32_t *regs = (uint32_t *)(virt_addr);
    printf("STATUS = %08x\n", *regs);

To make it short, `/dev/mem` is an image of the physical memory space of the system and mmap allows us to map portions of this at a known virtual address. Reading and writing at the mapped virtual addresses becomes equivalent to reading and writing at the physical addresses.

All this, for obvious security reasons, is privileged, but as we are root...

The example C program in `C/sab4z.c` maps the STATUS and R registers of SAB4Z at a virtual address and the `[2G..2G+512M[` physical address range (that is, the DDR accessed across the PL) at another virtual address. It takes one string argument. It first prints a welcome message, then uses the mapping to print the content of STATUS and R registers. It then writes `0x12345678` in the R register and starts searching for the passed string argument in the `[2G+1M..2G+17M[` range. If it finds it, it prints all characters in a `[-20..+20[` range around the found string, and stops the search. Else, it prints a _String not found_ message. Then, it prints again STATUS and R, a good bye message and exits. Have a look at the source code and use it as a starting point for your own projects.

Cross-compile the example application and transfer the executable to the Zybo:

    Host> cd $SAB4Z/C
    Host> ${CROSS_COMPILE}gcc -o sab4z sab4z.c
    Host> scp sab4z root@sab4z:

Run the application on the Zybo:

    Host> ssh root@sab4z
    Sab4z> ./sab4z barcuz
    Hello SAB4Z
      0x40000000: f0000002 (STATUS)
      0x40000004: 00000000 (R)
      0x806f461c: ............./sab4z barcuz....................
      0x40000000: f000ff02 (STATUS)
      0x40000004: 12345678 (R)
    Bye! SAB4Z

## <a name="FurtherRunAcrossSab4z"></a>Run the complete software stack across SAB4Z

#### <a name="FurtherRunAcrossSab4zPrinciples"></a>Principles

Thanks to the AXI bridge that SAB4Z implements, the `[2G..3G[` address range is an alias of `[0..1G[`. It is thus possible to run software on the Zybo that use only the `[2G..3G[` range instead of `[0..1G[`. It is even possible to run the Linux kernel and all other software applications on top of it in the `[2G..3G[` range. However we must carefully select the range of physical memory that we will instruct the kernel to use:

* The Zybo has only 512MB of DDR, so the most we can use is `[2G..2G+512M[`.
* As already mentioned, the first 512kB of DDR cannot be accessed from the PL. So, we cannot let Linux access the low addresses of `[2G..2G+512M[` because we could not forward the requests to the DDR.
* The Linux kernel insists that its physical memory is aligned on 128MB boundaries. So, to skip the low addresses of `[2G..2G+512M[` we must skip an entire 128MB chunk.

All in all, we can run the software stack in the `[2G+128MB..2G+512M[` range (`[0x8800_0000..0xa000_0000[`), that is, only 384MB instead of 512MB. The other drawback is that the path to the DDR across the PL is much slower than the direct one: its bit-width is 32 bits instead of 64 and its clock frequency is that of the PL, 100MHz in our example design, instead of 650MHz. Of course, the overhead will impact only cache misses but there will be an overhead. So why doing this? Why using less memory than available and slowing down the memory accesses? There are several good reasons. One of them is that instead of just relaying the memory accesses, the SAB4Z could be modified to implement a kind of monitoring of these accesses. It already counts the AXI transactions but it could do something more sophisticated. It could even tamper with the memory accesses, for instance to emulate accidental memory faults or attacks against the system.

#### <a name="FurtherRunAcrossSab4zDT"></a>Modify the device tree

Anyway, to boot the Linux kernel and run the software stack in the `[0x8800_0000..0xa000_0000[` physical memory range we need to modify a few things. First, edit the device tree source (`$SAB4Z/build/dts/system.dts`) and replace the definition of the physical memory:

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

#### <a name="FurtherRunAcrossSab4zKernel"></a>Change the load address in U-Boot image of Linux kernel

Next, recreate the U-Boot image of the Linux kernel with a different load address and entry point. This address is the one at which U-Boot loads the Linux kernel image (`uImage`) and at which it jumps afterwards:

    Host> cd $XLINUX
    Host> make -j8 O=build ARCH=arm LOADADDR=0x88008000 uImage
    Host> cp $XLINUX/build/arch/arm/boot/uImage $SAB4Z/build

#### <a name="FurtherRunAcrossSab4zUboot"></a>Adapt the U-Boot environment variables

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

#### <a name="FurtherRunAcrossSab4zBoot"></a>Boot and see

Unmount and eject the MicroSD card, plug it in the Zybo, power on. As you will probably notice U-Boot takes a bit longer to copy the binaries from the MicroSD card to the memory and to boot the kernel but the system, even if slightly slower, remains responsive and perfectly usable. You can check that the memory accesses are really routed across the PL by pressing the BTN push-button twice. This should drive the LEDs with the counter of AXI address read transactions and you should see the LEDs blinking while the CPU performs read-write accesses to the memory across SAB4Z. If the LEDs do not blink enough, interact with the software stack with the serial console, this should increase the number of memory accesses.

#### <a name="FurtherRunAcrossSab4zExercise"></a>Exercise

There is a way to use more DDR than 384MB. This involves a hardware modification and a rework of the software changes. This is left as an exercise. Hint: SAB4Z transforms the addresses in S1_AXI requests before forwarding them to M_AXI: it subtracts `2G` (`0x8000_0000`) to bring them back in the `[0..1G[` DDR range. SAB4Z could implement a different address transform.

## <a name="FurtherIla"></a>Debug hardware using ILA

Xilinx tools offer several ways to debug the hardware mapped in the PL. One uses Integrated Logic Analyzers (ILAs), hardware blocks that the tools automatically add to the design and that monitor internal signals. The tools running on the host PC communicate with the ILAs in the PL. Triggers can be configured to start / stop the recording of the monitored signals and the recorded signals can be displayed as waveforms.

The provided synthesis script and Makefile have options to embed one ILA core to monitor all signals of the M_AXI interface of SAB4Z. The only thing to do is rerun the synthesis:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> make ILA=1 vv-clean vv-all

and regenerate the boot image:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> bootgen -w -image scripts/boot.bif -o build/boot.bin

Use one of the techniques presented above to transfer the new boot image to the MicroSD card on the Zybo and power on. Launch Vivado on the host PC:

    Host-Xilinx> cd $SAB4Z
    Host-Xilinx> vivado build/vv/top.xpr &

In the `Hardware Manager`, select `Open Target` and `Auto Connect`. The tool should now be connected to the ILA core in the PL of the Zynq of the Zybo. Select the signals to use for the trigger, for instance `top_i/sab4z_m_axi_ARVALID` and `top_i/sab4z_m_axi_ARREADY`. Configure the trigger such that it starts recording when both signals are asserted. Set the trigger position in window to 512 and run the trigger. If you are running the software stack across the PL (see section [Run the complete software stack across SAB4Z](#FurtherRunAcrossSab4z)), the trigger should be fired immediately (if it is not use the serial console to interact with the software stack and cause some read access to the DDR across the PL). If you are not running the software stack across the PL, use devmem to perform a read access to the DDR across the PL:

    Host> picocom -b115200 -fn -pn -d8 -r -l /dev/ttyUSB1
    Sab4z> devmem 0x90000000 32

Analyse the complete AXI transaction in the `Waveform` sub-window of Vivado.

---

**Note**: the trigger logic can be much more sophisticated than the suggested one. It can be based on state machines, for instance. See the Xilinx documentation for more information on this.

---

<!--
* embed a disk partitioning tool,
    Target packages -> Hardware handling -> gptfdisk -> yes
## <a name="LinuxDriver"></a>Add a Linux driver for SAB4Z

TODO

Build kernel module

    Host> cd $SAB4Z/C
    Host> make CROSS_COMPILE=${CROSS_COMPILE} ARCH=arm KDIR=$XLINUX/build

Debug kernel module

    Kernel Features -> Symmetric Multi-Processing -> No
    Kernel hacking -> Compile-time checks and compiler options -> Compile the kernel with debug info -> yes
    Kernel hacking -> Compile-time checks and compiler options -> Compile the kernel with debug info -> Generate dwarf4 debuginfo -> yes
    Kernel hacking -> Compile-time checks and compiler options -> Compile the kernel with debug info -> Provide GDB scripts for kernel debugging -> yes
    Kernel hacking -> KGDB: kernel debugger -> yes
    Kernel hacking -> KGDB: kernel debugger -> KGDB_KDB: include kdb frontend for kgdb -> yes

    Host> make -j8 O=build ARCH=arm LOADADDR=0x8000 uImage vmlinux

    Host-Xilinx> xmd
    XMD% connect arm hw

    Host> ${CROSS_COMPILE}gdb -x $BUILDROOT/build/staging/usr/share/buildroot/gdbinit -nw $XLINUX/build/vmlinux
    (gdb) target remote :1234
    (gdb) continue

    * [Add a Linux driver for SAB4Z](#LinuxDriver)

--->

# <a name="Problems"></a>Common problems

#### <a name="ProblemsCharDevAccessRights"></a>Character device access rights

If, when launching your terminal emulator, you get error messages like:

    FATAL: cannot open /dev/ttyUSB1: Permission denied

it is probably because the character device that was created when the FT2232H chip was discovered was created with limited access rights:

    Host> ls -l /dev/ttyUSB1
    crw-rw---- 1 root dialout 188, 1 Apr 11 14:53 /dev/ttyUSB1 

Of course, you could work as root but this is never a good solution. A better one is to add yourself to the group owning the serial device (if, as in our example, the group has read/write permissions):

    Host> sudo adduser mary dialout

Another option is to add a udev rule to create the character device with read/write permissions for all users when a FT2232H chip is discovered:

    Host# rule='SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"'
    Host# echo $rule > /etc/udev/rules.d/99-ft2232h.rules

# <a name="Glossary"></a>Glossary

#### <a name="GlossaryAxi"></a>AXI bus protocol

AXI (AMBA-4) is a bus protocol created by [ARM](http://www.arm.com/). It is an open standard frequently encountered in Systems-on-Chips (SoC). It is used to interconnect components and comes in different flavours (lite, regular, stream...), depending on the specific communication needs of the participants. The Xilinx Zynq cores use the AXI protocol to interconnect the Processing System (the ARM processor plus its peripherals) and the Programmable Logic (the FPGA part of the core). More information on the AXI bus protocol can be found on [ARM web site](http://www.arm.com/). More information the Zynq architecture can be found on [Xilinx web site](http://www.xilinx.com/).

#### <a name="GlossaryFt2232hCharDev"></a>Character device for the FT2232H FTDI chip

The micro-USB connector of the Zybo is connected to a [FT2232H](http://www.ftdichip.com/Products/ICs/FT2232H.htm) chip from [FTDI Chip](http://www.ftdichip.com/) situated on the back side of the board. This chip (among other things) converts the USB protocol to a [Universal Asynchronous Receiver/Transmitter](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver/transmitter) (UART) serial protocol. The UART side of the chip is connected to one of the UART ports of the Zynq core. The Linux kernel that runs on the Zynq is configured to use this UART port to send messages and to receive commands. When we connect the Zybo board to the host PC with the USB cable and power it up, a special file is automatically created on the host (e.g. `/dev/ttyUSB1`). This special file is called a _character device_. It is the visible part of the low-level software device driver that manages the communication between our host and the board through the USB cable and the FT2232H chip on the Zybo. The terminal emulator uses this character device to communicate with the board.

#### <a name="GlossaryDeviceTree"></a>Device tree

A device tree is a textual description of the hardware platform on which the Linux kernel runs. Before the concept of device trees have been introduced, running the same kernel on different platforms was difficult, even if the processor was the same. It was quite common to distribute different kernel binaries for very similar platforms because the set of devices was different or because some parameters, like the hardware address at which a device is found, were different. Thanks to device trees, the same kernel can discover the hardware architecture of the target and adapt itself during boot. To make a long story short, we generate a textual description of the Zybo - the device tree source - and transform it into an equivalent binary form - the device tree blob - with dtc - the device tree compiler - (dtc is one of the host utilities generated by Buildroot). We then add this device tree blob to the MicroSD card. U-Boot loads it from the MicroSD card, installs it somewhere in memory and passes its address to the Linux kernel. During the boot the Linux kernel parses this data structure and configures itself accordingly.

#### <a name="GlossaryFileSystem"></a>File system

A file system is a software layer that manages the data stored on a storage device like a Hard Disk Drive (HDD) or a flash card. It organizes the data in a hierarchy of directories and files. The term is also used to designate a hierarchy of directories that is managed by this software layer. The **root** file system, as its name says, is itself a file system and also the root of all other file systems, that are bound to (mounted on) sub-directories. The df command can show you all file systems of your host PC and their mount point:

    Host> df
    Filesystem                                        1K-blocks     Used Available Use% Mounted on
    /dev/dm-0                                         492126216 84731012 382373560  19% /
    udev                                                  10240        0     10240   0% /dev
    tmpfs                                               6587916    27648   6560268   1% /run
    tmpfs                                              16469780        8  16469772   1% /dev/shm
    tmpfs                                                  5120        4      5116   1% /run/lock
    ...

The file system mounted on `/` is the root file system:

    Host> cd /
    Host> ls -al
    total 120
    drwxr-xr-x  25 root    root     4096 Mar 17 17:31 .
    drwxr-xr-x  25 root    root     4096 Mar 17 17:31 ..
    drwxrwxr-x   2 root    root     4096 Apr  4 08:05 bin
    drwxr-xr-x   3 root    root     4096 Apr 11 15:48 boot
    drwxr-xr-x  20 root    root     3500 Apr 14 10:04 dev
    ...
    drwxrwxrwt  25 root    root    20480 Apr 14 10:42 tmp
    drwxr-xr-x  12 root    root     4096 Oct 23 11:53 usr
    drwxr-xr-x  12 root    root     4096 Oct 22 12:26 var

`/bin` and all its content are part of the root file system but `/dev` is the mount point of a different file system. In most cases it makes no difference whether a file is part of a file system or another: they all seem to be somewhere in the same unique hierarchy of directories that start at `/`.

#### <a name="GlossaryFsbl"></a>First Stage Boot Loader

When the Zynq core of the Zybo board is powered up, the ARM processor executes its first instructions from an on-chip ROM. This BootROM code performs several initializations, reads the configuration of the jumpers that select the boot medium (see the Zybo picture) and loads a boot image from the selected medium (the MicroSD card in our case). This boot image is a binary archive file that encapsulates up to 3 different binary files:

* A First Stage Boot Loader (FSBL) executable in ELF format.
* A bitstream to configure the PL (optional).
* A software application executable in ELF format.

The BootROM code loads the FSBL in the On-Chip RAM (OCR) of the Zynq core and jumps into the FSBL. So, technically speaking, the FSBL is not the **first** boot loader, as its name says, but the second. The real first boot loader is the BootROM code. Anyway, the FSBL, in turn, performs several initializations, extracts the bitstream from the boot image and uses it to configures the PL. Then, it loads the software application from the boot image, installs it in memory and jumps into it. In our case, this software application is U-Boot, that we use as a Second Stage Boot Loader (or shall we write **third**?) to load the Linux kernel, the device tree blob and the root file system before jumping into the kernel.

#### <a name="GlossaryGdbServer"></a>gdb server

A gdb server is a tiny application TBC
We could also have added the complete gdb to our root file system, instead of the tiny gdb server, and thus debugged our applications directly on the Zybo board. But the complete gdb is a rather large application and the size of our initramfs - memory limited - root file system would have been increased by a significant amount.

#### <a name="GlossaryInitramfs"></a>initramfs root file system

An initramfs root file system is loaded entirely in RAM at boot time, while the more classical root file system of your host probably resides on a Hard Disk Drive (HDD). With initramfs, a portion of the available memory is presented and used just like if it was mass storage. This portion is initialized at boot time from a binary file, the root file system image, stored on the boot medium (the MicroSD card in our case). The good point with initramfs is that it is ultra-fast because memory accesses are much faster than accesses to HDDs. The drawbacks are that it is not persistent across reboot (it is restored to its original state every time you boot) and that its size is limited by the available memory (512 MB on the Zybo - and even less because we need some working memory too - compared to the multi-GB capacity of the HDD of your host).

#### <a name="GlossaryLinuxKernel"></a>Linux kernel

The Linux kernel is a key component of our software stack, even if it is not sufficient and would not be very useful without our root file system and all the software applications in it. The kernel and its software device drivers are responsible for the management of our small Zybo computer. They control the sharing of all resources (memory, peripherals...) among the different software applications and serve as intermediates between the software and the hardware, hiding most of the low level details. They also offer the same (software) interface, independently of the underlying hardware: thanks to the kernel and its device drivers we will access the various features of our Zybo exactly as we would do on another type of computer. This is what is called _hardware abstraction_ in computer science.

#### <a name="GlossaryTerminalEmulator"></a>Terminal emulator

A terminal emulator (e.g. picocom) is a software application that runs on the host and behaves like the hardware terminals that were used in the old days to communicate with computers across a serial link. It is attached to a character device that works a bit like a file in which one can read and write characters. When we type characters on our keyboard, the terminal emulator writes them to the character device and the software device driver associated to the character device sends them to the board through the USB cable. Symmetrically, when the board sends characters through the USB cable, the terminal emulator reads them from the character device and prints them on our screen.

