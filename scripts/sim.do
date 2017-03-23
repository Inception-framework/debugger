vcom ../../hdl/fifo_ram.vhd
vcom ../../hdl/inception_pkg.vhd
vcom ../../hdl/JTAG_Ctrl_Master.vhd
vcom ../../hdl/inception.vhd
vcom ../../hdl/inception_tb.vhd

vsim -novopt work.inception_tb

do ../../scripts/wave.do

run 600000 ns
