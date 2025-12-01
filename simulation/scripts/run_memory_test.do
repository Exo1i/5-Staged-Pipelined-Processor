# run_memory.do

vlib ./simulation/work
vmap work ./simulation/work

vcom -2008 ./rtl/common/memory.vhd
vcom -2008 ./rtl/common/simulation_memory.vhd
vcom -2008 ./testbench/common/tb_memory.vhd

vsim work.tb_memory -voptargs=+acc

view wave
add wave -position end sim:/tb_memory/*


run -all

log -r /*