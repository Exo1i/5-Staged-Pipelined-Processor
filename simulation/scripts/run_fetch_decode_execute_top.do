# Minimal integration: fetch + IF/ID + decode + opcode_decoder + ID/EX + execute

vlib ./simulation/work
vmap work ./simulation/work

# Packages
vcom -2008 ./src/common/control_signals_pkg.vhd
vcom -2008 ./src/common/pipeline_data_pkg.vhd
vcom -2008 ./src/common/pkg_opcodes.vhd

# Memory (entity + simulation architecture)
vcom -2008 ./src/common/memory.vhd
vcom -2008 ./src/common/simulation_memory.vhd

# Fetch stage
vcom -2008 ./src/fetch/pc.vhd
vcom -2008 ./src/fetch/fetch_stage.vhd

# IF/ID
vcom -2008 ./src/fetch/if_id_register.vhd

# Decode stage deps
vcom -2008 ./src/decode/register_file.vhd
vcom -2008 ./src/decode/decode_stage.vhd

# Opcode decoder
vcom -2008 ./src/control/opcode-decoder/opcode_decoder.vhd

# ID/EX
vcom -2008 ./src/decode/id_ex_register.vhd

# Execute stage deps
vcom -2008 ./src/execute/alu.vhd
vcom -2008 ./src/execute/ccr.vhd
vcom -2008 ./src/execute/execute_stage.vhd

# Top
vcom -2008 ./src/fetch_decode_execute_top.vhd

# Sim
vsim work.fetch_decode_execute_top -voptargs=+acc

view wave
add wave -divider "Top"
add wave -radix binary sim:/fetch_decode_execute_top/clk
add wave -radix binary sim:/fetch_decode_execute_top/rst
add wave -radix hexadecimal sim:/fetch_decode_execute_top/in_port

add wave -divider "Fetch"
add wave -radix hexadecimal sim:/fetch_decode_execute_top/fetch_out.pc
add wave -radix hexadecimal sim:/fetch_decode_execute_top/fetch_out.instruction

add wave -divider "Decode"
add wave -radix hexadecimal sim:/fetch_decode_execute_top/decode_out.opcode
add wave -radix hexadecimal sim:/fetch_decode_execute_top/decode_out.operand_a
add wave -radix hexadecimal sim:/fetch_decode_execute_top/decode_out.operand_b
add wave -radix hexadecimal sim:/fetch_decode_execute_top/decode_out.immediate
add wave -radix unsigned sim:/fetch_decode_execute_top/decode_out.rd

add wave -divider "ID/EX"
add wave -radix hexadecimal sim:/fetch_decode_execute_top/idex_data_out.operand_a
add wave -radix hexadecimal sim:/fetch_decode_execute_top/idex_data_out.operand_b
add wave -radix hexadecimal sim:/fetch_decode_execute_top/idex_data_out.immediate
add wave -radix unsigned sim:/fetch_decode_execute_top/idex_data_out.rd

add wave -divider "Execute"
add wave -radix hexadecimal sim:/fetch_decode_execute_top/execute_out.primary_data
add wave -radix hexadecimal sim:/fetch_decode_execute_top/execute_out.secondary_data
add wave -radix unsigned sim:/fetch_decode_execute_top/execute_out.rdst
add wave -radix binary sim:/fetch_decode_execute_top/execute_out.ccr_flags

# Clock + reset
force -freeze sim:/fetch_decode_execute_top/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/fetch_decode_execute_top/rst 1 0, 0 {300 ps}
force -freeze sim:/fetch_decode_execute_top/in_port 16#00000000 0

run 5000 ps
