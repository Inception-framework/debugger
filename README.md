# What?

USB3-to-JTag is a low latency USB3-based debugger.
It enables memory accesses for ARM processors using the Coresight design.
It has been tested on Cortex M3/M4 processors.

# How ?

## The fastest method - Flashing the SD Card with the released image

Due to GitHub limitation on file size, we splitted the SD card image into three pieces. 
Use the following commands to flash the FPGA SD card.

```bash
cat sdcard.bin.tgz.aa sdcard.bin.tgz.ab  sdcard.bin.tgz.ac >> sdcard.bin.tgz

tar zxvf sdcard.bin.tgz
```

Then, use dd to copy the image on your SD card. 
Replace of value with the correct path.
```bash
dd if=./sdcard.bin of=/dev/SDCARD bs=4M conv=fsync
```

Required jumper configuration on Zedboard
```
JMP11 OFF
JMP10 ON
JMP9  OFF
JMP8  OFF
```


## Other method - Building and Flashing the FPGA

Use the following command to synthesize the design.
This requires Vivado (2017.x/2018.x/2019.x).

```
mkdir build

vivado -mode tcl -source ./scripts/vvsyn.tcl -tclargs $(pwd) $(pwd)/build
```

Then, create top.sdk directory and export bitfile into it.
```
file mkdir /path/to/Inception-debugger/build/top.sdk
file copy -force /path/to/Inception-debugger/build/top.runs/impl_1/top_wrapper.sysdef /path/to/Inception-debugger/build/top.sdk/top_wrapper.hdf
```

Required jumper configuration on Zedboard
```
JMP11 OFF
JMP10 ON
JMP9  OFF
JMP8  OFF
```

```
launch_sdk -workspace /path/to/Inception-debugger/build/top.sdk -hwspec /path/to/Inception-debugger/build/top.sdk/top_wrapper.hdf
```

1. Create a new Application Project called ```app``` using the hello world template.

2. Set the xilffs option in the Board Support Package configurator.

3. Create a new Application Project called ```fsbl``` using the FSBL template.

4. Compile everythin using in Release mode.

5. Select the FSBL project and go to xilinx > Boot Image.
All fields should be filled otherwise you may have missed to select the fsbl project before starting the Boot Image configurator.

6. Add a data partition for app/Release/app.elf

7. Then, click on ```Create Image```

8. Finally, click on xilinx > Program Flash
Set the Image File: top.sdk/fsbl/bootimage/BOOT.bin
Set the FSBL File : top.sdk/fsbl/Release/fsbl.elf
Set ``Blank Check after erase``` and ```Verify after flash```.

9. When the flash process finishes, power-off the FPGA.

## Other method - Building and Flashing the SD card

To compile the design, we highly recommand you to use the dockerfile.
As Vivado is not present inside the container, you need to provide it using Docker volume.

```
sudo docker run -ti -v /path/to/Xilinx/:/media/vivado -t xilinx_zedboard /bin/bash
```

Once the docker started, run this command inside to build the design:
```
cd ~
bash ./build.sh
```

Then you need to copy the generated bit file on a SDCard and set Zedboard boot pins as follow:
```
JMP11 OFF
JMP10 ON
JMP9  On
JMP8  OFF
```

# Simulation

Simulation files are set for Modelsim only.

```
vlib work

vsim -do scripts/sim.do
```

# Acknowledgement

Synthesis scripts are from the project sab4z.
https://gitlab.telecom-paris.fr/renaud.pacalet/sab4z

The JTAG state machine is based on OpenJTAG
https://opencores.org/projects/openjtag-project
