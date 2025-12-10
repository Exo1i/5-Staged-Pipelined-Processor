# run_memory.do

vlib ./simulation/work
vmap work ./simulation/work

vcom -2008 ./rtl/control/opcode-decoder/control_signals_pkg.vhd
vcom -2008 ./rtl/memory/stack_pointer.vhd
vcom -2008 ./rtl/memory/memory_stage.vhd
vcom -2008 ./testbench/memory/tb_memory_stage.vhd

vsim work.tb_memory_stage -voptargs=+acc

view wave
add wave -position end sim:/tb_memory_stage/*


run -all

log -r /*