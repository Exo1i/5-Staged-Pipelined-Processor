# Compile Writeback Stage and dependencies

# Create work directory
vlib ./simulation/work
vmap work ./simulation/work

# Compile control signals package
vcom -2008 ./rtl/control/opcode-decoder/control_signals_pkg.vhd

# Compile writeback stage
vcom -2008 ./rtl/writeback/writeback_stage.vhd

# Compile writeback stage testbench
vcom -2008 ./testbench/writeback/tb_writeback_stage.vhd

# Run Writeback Stage testbench
vsim work.tb_writeback_stage -voptargs=+acc

view wave
add wave -position end sim:/tb_writeback_stage/*

run -all

log -r /*
