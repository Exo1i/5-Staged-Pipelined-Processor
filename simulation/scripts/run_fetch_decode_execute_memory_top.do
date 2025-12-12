# Minimal integration: fetch + IF/ID + decode + opcode_decoder + ID/EX + execute + EX/MEM + memory_stage + hazard arb

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

# EX/MEM
vcom -2008 ./src/execute/ex_mem_register.vhd

# Memory stage deps
vcom -2008 ./src/memory/stack_pointer.vhd
vcom -2008 ./src/memory/memory_stage.vhd

# Hazard unit
vcom -2008 ./src/control/memory-hazard-unit/memory_hazard_unit.vhd

# Top
vcom -2008 ./src/fetch_decode_execute_memory_top.vhd

# Sim
vsim work.fetch_decode_execute_memory_top -voptargs=+acc

view wave
add wave -divider "Top"
add wave -radix binary sim:/fetch_decode_execute_memory_top/clk
add wave -radix binary sim:/fetch_decode_execute_memory_top/rst
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/in_port

add wave -divider "Fetch"
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/fetch_out.pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/fetch_out.pushed_pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/fetch_out.instruction

add wave -divider "IF/ID"
add wave -radix binary sim:/fetch_decode_execute_memory_top/ifid_out.take_interrupt
add wave -radix binary sim:/fetch_decode_execute_memory_top/ifid_out.override_operation
add wave -radix binary sim:/fetch_decode_execute_memory_top/ifid_out.override_op
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/ifid_out.pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/ifid_out.pushed_pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/ifid_out.instruction

add wave -divider "Decode"
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/decode_out.pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/decode_out.pushed_pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/decode_out.opcode
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/decode_out.operand_a
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/decode_out.operand_b
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/decode_out.immediate
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/decode_out.rsrc1
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/decode_out.rsrc2
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/decode_out.rd

add wave -divider "Decode Ctrl"
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.OutBSelect
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsInterrupt
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsHardwareInterrupt
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsCall
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsReturn
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsReti
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsJMP
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsJMPConditional
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.decode_ctrl.IsSwap
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.execute_ctrl.CCR_WriteEnable
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.execute_ctrl.PassCCR
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.execute_ctrl.PassImm
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.execute_ctrl.ALU_Operation
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.execute_ctrl.ConditionalType
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.SP_Enable
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.SP_Function
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.SPtoMem
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.PassInterrupt
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.MemRead
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.MemWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.FlagFromMem
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.memory_ctrl.IsSwap
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.writeback_ctrl.MemToALU
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/decode_ctrl_out.writeback_ctrl.OutPortWriteEn

add wave -divider "ID/EX"
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/idex_data_out.pc
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/idex_data_out.operand_a
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/idex_data_out.operand_b
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/idex_data_out.immediate
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/idex_data_out.rsrc1
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/idex_data_out.rsrc2
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/idex_data_out.rd
add wave -radix binary sim:/fetch_decode_execute_memory_top/idex_ctrl_out.execute_ctrl.ALU_Operation
add wave -radix binary sim:/fetch_decode_execute_memory_top/idex_ctrl_out.memory_ctrl.MemRead
add wave -radix binary sim:/fetch_decode_execute_memory_top/idex_ctrl_out.memory_ctrl.MemWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/idex_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/idex_ctrl_out.writeback_ctrl.MemToALU

add wave -divider "Execute"
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/execute_out.primary_data
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/execute_out.secondary_data
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/execute_out.rdst
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_out.ccr_flags

add wave -divider "Execute Ctrl"
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_ctrl_out.wb_regwrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_ctrl_out.wb_memtoreg
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_ctrl_out.m_memread
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_ctrl_out.m_memwrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_ctrl_out.m_sptomem
add wave -radix binary sim:/fetch_decode_execute_memory_top/execute_ctrl_out.m_passinterrupt
add wave -divider "EX/MEM"
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/exmem_data_out.primary_data
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/exmem_data_out.secondary_data
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/exmem_data_out.rdst1
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.writeback_ctrl.MemToALU
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.MemRead
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.MemWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.SP_Enable
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.SP_Function
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.SPtoMem
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.PassInterrupt
add wave -radix binary sim:/fetch_decode_execute_memory_top/exmem_ctrl_out.memory_ctrl.FlagFromMem

add wave -divider "Memory Stage"
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_stage_read_req
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_stage_write_req
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_stage_addr
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_stage_wdata
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_wb_data_out.memory_data
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_wb_data_out.alu_data
add wave -radix unsigned sim:/fetch_decode_execute_memory_top/mem_wb_data_out.rdst
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_wb_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_wb_ctrl_out.writeback_ctrl.MemToALU
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_wb_ctrl_out.writeback_ctrl.OutPortWriteEn

add wave -divider "Arb / Memory"
add wave -radix binary sim:/fetch_decode_execute_memory_top/pass_pc
add wave -radix binary sim:/fetch_decode_execute_memory_top/front_enable
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_addr_mux
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_wdata_mux
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_read_mux
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_write_mux
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_read_out
add wave -radix binary sim:/fetch_decode_execute_memory_top/mem_write_out

add wave -divider "Memory Data"
add wave -radix hexadecimal sim:/fetch_decode_execute_memory_top/mem_data

# Clock + reset
force -freeze sim:/fetch_decode_execute_memory_top/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/fetch_decode_execute_memory_top/rst 1 0, 0 {300 ps}
force -freeze sim:/fetch_decode_execute_memory_top/in_port 16#00000000 0

run 20000 ps
