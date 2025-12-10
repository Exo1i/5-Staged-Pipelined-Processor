# Compile Forwarding Unit and dependencies

# Create work directory
vlib ./simulation/work
vmap work ./simulation/work

# Compile forwarding unit
vcom -2008 ./src/control/forwarding-unit/forwarding_unit.vhd

# Compile forwarding unit testbench
vcom -2008 ./src/control/testbench/tb_forwarding_unit.vhd

# Run Forwarding Unit testbench
vsim work.tb_forwarding_unit -voptargs=+acc

view wave
add wave -position end sim:/tb_forwarding_unit/*

run -all

log -r /*
