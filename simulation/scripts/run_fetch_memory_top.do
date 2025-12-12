# Minimal integration: fetch + memory_stage + memory_hazard_unit + memory

# Create work directory
vlib ./simulation/work
vmap work ./simulation/work

# Packages / common
vcom -2008 ./src/common/control_signals_pkg.vhd
vcom -2008 ./src/common/pipeline_data_pkg.vhd
vcom -2008 ./src/common/pkg_opcodes.vhd

# Memory entity + simulation architecture
vcom -2008 ./src/common/memory.vhd
vcom -2008 ./src/common/simulation_memory.vhd

# Fetch stage dependencies
vcom -2008 ./src/fetch/pc.vhd
vcom -2008 ./src/fetch/fetch_stage.vhd

# Memory stage dependencies
vcom -2008 ./src/memory/stack_pointer.vhd
vcom -2008 ./src/memory/memory_stage.vhd

# Hazard unit
vcom -2008 ./src/control/memory-hazard-unit/memory_hazard_unit.vhd

# Top
vcom -2008 ./src/fetch_memory_top.vhd

# Sim
vsim work.fetch_memory_top -voptargs=+acc

view wave
add wave -divider "Top"
add wave -radix binary sim:/fetch_memory_top/clk
add wave -radix binary sim:/fetch_memory_top/rst

add wave -divider "Hazard"
add wave -radix binary sim:/fetch_memory_top/pass_pc

add wave -divider "Fetch"
add wave -radix hexadecimal sim:/fetch_memory_top/fetch_out.pc
add wave -radix hexadecimal sim:/fetch_memory_top/fetch_out.instruction

add wave -divider "Memory"
add wave -radix hexadecimal sim:/fetch_memory_top/mem_data

# Clock + reset
force -freeze sim:/fetch_memory_top/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/fetch_memory_top/rst 1 0, 0 {300 ps}

run 5000 ps
