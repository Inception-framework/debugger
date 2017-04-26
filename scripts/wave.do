onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {fpga clk}
add wave -noupdate /inception_tb/aclk
add wave -noupdate /inception_tb/aresetn
add wave -noupdate -divider {fpga debug io}
add wave -noupdate /inception_tb/sw
add wave -noupdate /inception_tb/led
add wave -noupdate /inception_tb/jtag_state_led
add wave -noupdate /inception_tb/r
add wave -noupdate /inception_tb/status
add wave -noupdate -divider {jtag interface}
add wave -noupdate /inception_tb/TDO
add wave -noupdate /inception_tb/TCK
add wave -noupdate /inception_tb/TMS
add wave -noupdate /inception_tb/TDI
add wave -noupdate /inception_tb/TRST
add wave -noupdate -divider {fx3 interface}
add wave -noupdate /inception_tb/clk_out
add wave -noupdate /inception_tb/fdata
add wave -noupdate /inception_tb/sloe
add wave -noupdate /inception_tb/sladdr
add wave -noupdate -divider {command fifo}
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/aclk
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/aresetn
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/empty
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/full
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/put
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/get
add wave -noupdate -childformat {{/inception_tb/dut/cmd_fifo_inst/state.wr_ptr -radix unsigned} {/inception_tb/dut/cmd_fifo_inst/state.rd_ptr -radix unsigned} {/inception_tb/dut/cmd_fifo_inst/state.cnt -radix unsigned}} -expand -subitemconfig {/inception_tb/dut/cmd_fifo_inst/state.wr_ptr {-height 17 -radix unsigned} /inception_tb/dut/cmd_fifo_inst/state.rd_ptr {-height 17 -radix unsigned} /inception_tb/dut/cmd_fifo_inst/state.cnt {-height 17 -radix unsigned}} /inception_tb/dut/cmd_fifo_inst/state
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/din
add wave -noupdate /inception_tb/dut/cmd_fifo_inst/dout
add wave -noupdate -divider {data fifo}
add wave -noupdate /inception_tb/dut/data_fifo_inst/aclk
add wave -noupdate /inception_tb/dut/data_fifo_inst/aresetn
add wave -noupdate /inception_tb/dut/data_fifo_inst/empty
add wave -noupdate /inception_tb/dut/data_fifo_inst/full
add wave -noupdate /inception_tb/dut/data_fifo_inst/put
add wave -noupdate /inception_tb/dut/data_fifo_inst/get
add wave -noupdate -childformat {{/inception_tb/dut/data_fifo_inst/state.wr_ptr -radix unsigned} {/inception_tb/dut/data_fifo_inst/state.rd_ptr -radix unsigned} {/inception_tb/dut/data_fifo_inst/state.cnt -radix unsigned}} -expand -subitemconfig {/inception_tb/dut/data_fifo_inst/state.wr_ptr {-height 17 -radix unsigned} /inception_tb/dut/data_fifo_inst/state.rd_ptr {-height 17 -radix unsigned} /inception_tb/dut/data_fifo_inst/state.cnt {-height 17 -radix unsigned}} /inception_tb/dut/data_fifo_inst/state
add wave -noupdate /inception_tb/dut/data_fifo_inst/din
add wave -noupdate /inception_tb/dut/data_fifo_inst/dout
add wave -noupdate -divider {irq fifo}
add wave -noupdate /inception_tb/dut/irq_fifo_inst/aclk
add wave -noupdate /inception_tb/dut/irq_fifo_inst/aresetn
add wave -noupdate /inception_tb/dut/irq_fifo_inst/empty
add wave -noupdate /inception_tb/dut/irq_fifo_inst/full
add wave -noupdate /inception_tb/dut/irq_fifo_inst/put
add wave -noupdate /inception_tb/dut/irq_fifo_inst/get
add wave -noupdate /inception_tb/dut/irq_fifo_inst/din
add wave -noupdate /inception_tb/dut/irq_fifo_inst/dout
add wave -noupdate /inception_tb/dut/irq_fifo_inst/state
add wave -noupdate -divider {jtag converter}
add wave -noupdate /inception_tb/dut/jtag_bit_count
add wave -noupdate /inception_tb/dut/jtag_shift_strobe
add wave -noupdate /inception_tb/dut/jtag_busy
add wave -noupdate /inception_tb/dut/jtag_state_start
add wave -noupdate /inception_tb/dut/jtag_state_end
add wave -noupdate /inception_tb/dut/jtag_state_current
add wave -noupdate /inception_tb/dut/jtag_di
add wave -noupdate /inception_tb/dut/jtag_do
add wave -noupdate -childformat {{/inception_tb/dut/jtag_state.step -radix unsigned} {/inception_tb/dut/jtag_state.size -radix unsigned} {/inception_tb/dut/jtag_state.number -radix unsigned}} -expand -subitemconfig {/inception_tb/dut/jtag_state.step {-height 17 -radix unsigned -radixshowbase 0} /inception_tb/dut/jtag_state.size {-height 17 -radix unsigned -radixshowbase 0} /inception_tb/dut/jtag_state.number {-height 17 -radix unsigned -radixshowbase 0}} /inception_tb/dut/jtag_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 303
configure wave -valuecolwidth 202
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1199500 ns} {1200027 ns}
