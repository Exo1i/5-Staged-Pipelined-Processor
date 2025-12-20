# Minimal integration: fetch + IF/ID + decode + opcode_decoder + ID/EX + execute + EX/MEM + memory_stage + MEM/WB + writeback

if {![file exists memory_temp]} {
    mkdir memory_temp
}

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

# MEM/WB + writeback
vcom -2008 ./src/memory/mem_wb_register.vhd
vcom -2008 ./src/writeback/writeback_stage.vhd

# Hazard unit
vcom -2008 ./src/control/memory-hazard-unit/memory_hazard_unit.vhd

# Forwarding unit
vcom -2008 ./src/control/forwarding-unit/forwarding_unit.vhd

# Freezing unit 
vcom -2008 ./src/control/freeze-control/freeze_control.vhd

# Interrupt unit
vcom -2008 ./src/control/interrupt-unit/interrupt_unit.vhd

# Branch decision unit
vcom -2008 ./src/control/branch-control/branch-decision-unit/branch_decision_unit.vhd

# Top
vcom -2008 ./src/processor_top.vhd

# Sim
vsim work.processor_top -voptargs=+acc -t 1ps

view wave
add wave -divider "Top"
add wave -radix binary sim:/processor_top/clk
add wave -radix binary sim:/processor_top/rst
add wave -radix hexadecimal sim:/processor_top/in_port
add wave -radix hexadecimal sim:/processor_top/out_port
add wave -radix binary sim:/processor_top/out_port_en

add wave -divider "Fetch"
add wave -radix hexadecimal sim:/processor_top/fetch_out.pc
add wave -radix hexadecimal sim:/processor_top/fetch_out.pushed_pc
add wave -radix hexadecimal sim:/processor_top/fetch_out.instruction

add wave -divider "IF/ID"
add wave -radix binary sim:/processor_top/ifid_out.take_interrupt
add wave -radix binary sim:/processor_top/ifid_out.override_operation
add wave -radix binary sim:/processor_top/ifid_out.override_op
add wave -radix hexadecimal sim:/processor_top/ifid_out.pc
add wave -radix hexadecimal sim:/processor_top/ifid_out.pushed_pc
add wave -radix hexadecimal sim:/processor_top/ifid_out.instruction

add wave -divider "Decode"
add wave -radix hexadecimal sim:/processor_top/decode_out.pc
add wave -radix hexadecimal sim:/processor_top/decode_out.pushed_pc
add wave -radix hexadecimal sim:/processor_top/decode_out.opcode
add wave -radix hexadecimal sim:/processor_top/decode_out.operand_a
add wave -radix hexadecimal sim:/processor_top/decode_out.operand_b
add wave -radix hexadecimal sim:/processor_top/decode_out.immediate
add wave -radix unsigned sim:/processor_top/decode_out.rsrc1
add wave -radix unsigned sim:/processor_top/decode_out.rsrc2
add wave -radix unsigned sim:/processor_top/decode_out.rd

add wave -divider "Register File"
add wave -radix unsigned sim:/processor_top/decode_inst/reg_file_inst/Ra
add wave -radix unsigned sim:/processor_top/decode_inst/reg_file_inst/Rb
add wave -radix hexadecimal sim:/processor_top/decode_inst/reg_file_inst/ReadDataA
add wave -radix hexadecimal sim:/processor_top/decode_inst/reg_file_inst/ReadDataB
add wave -radix unsigned sim:/processor_top/decode_inst/reg_file_inst/Rdst
add wave -radix hexadecimal sim:/processor_top/decode_inst/reg_file_inst/WriteData
add wave -radix binary sim:/processor_top/decode_inst/reg_file_inst/WriteEnable
add wave -radix hexadecimal sim:/processor_top/decode_inst/reg_file_inst/registers

add wave -divider "Decode Ctrl"
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.OutBSelect
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsInterrupt
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsHardwareInterrupt
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsCall
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsReturn
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsReti
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsJMP
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsJMPConditional
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.IsSwap
add wave -radix binary sim:/processor_top/decode_ctrl_out.decode_ctrl.RequireImmediate
add wave -radix binary sim:/processor_top/decode_ctrl_out.execute_ctrl.CCR_WriteEnable
add wave -radix binary sim:/processor_top/decode_ctrl_out.execute_ctrl.PassCCR
add wave -radix binary sim:/processor_top/decode_ctrl_out.execute_ctrl.PassImm
add wave -radix binary sim:/processor_top/decode_ctrl_out.execute_ctrl.ALU_Operation
add wave -radix binary sim:/processor_top/decode_ctrl_out.execute_ctrl.ConditionalType
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.SP_Enable
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.SP_Function
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.SPtoMem
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.PassInterrupt
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.MemRead
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.MemWrite
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.MemToCCR
add wave -radix binary sim:/processor_top/decode_ctrl_out.memory_ctrl.IsSwap
add wave -radix binary sim:/processor_top/decode_ctrl_out.writeback_ctrl.PassMem
add wave -radix binary sim:/processor_top/decode_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/processor_top/decode_ctrl_out.writeback_ctrl.OutPortWriteEn

add wave -divider "ID/EX"
add wave -radix hexadecimal sim:/processor_top/idex_data_out.pc
add wave -radix hexadecimal sim:/processor_top/idex_data_out.operand_a
add wave -radix hexadecimal sim:/processor_top/idex_data_out.operand_b
add wave -radix unsigned sim:/processor_top/idex_data_out.rsrc1
add wave -radix unsigned sim:/processor_top/idex_data_out.rsrc2
add wave -radix unsigned sim:/processor_top/idex_data_out.rd
add wave -radix binary sim:/processor_top/idex_ctrl_out.execute_ctrl.ALU_Operation
add wave -radix binary sim:/processor_top/idex_ctrl_out.memory_ctrl.MemRead
add wave -radix binary sim:/processor_top/idex_ctrl_out.memory_ctrl.MemWrite
add wave -radix binary sim:/processor_top/idex_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/processor_top/idex_ctrl_out.writeback_ctrl.PassMem

add wave -divider "Execute"
add wave -radix hexadecimal sim:/processor_top/execute_out.primary_data
add wave -radix hexadecimal sim:/processor_top/execute_out.secondary_data
add wave -radix hexadecimal  sim:/processor_top/execute_inst/immediate
add wave -radix unsigned sim:/processor_top/execute_out.rdst
add wave -radix binary sim:/processor_top/execute_out.ccr_flags
add wave -radix binary  sim:/processor_top/execute_inst/In_A
add wave -radix binary  sim:/processor_top/execute_inst/In_B
add wave -radix binary  sim:/processor_top/execute_inst/forwarded_B
add wave -radix binary  sim:/processor_top/execute_inst/forwarding

add wave -divider "ALU Internal state"
add wave -radix hexadecimal sim:/processor_top/execute_inst/ALU_UNIT/OperandA
add wave -radix hexadecimal sim:/processor_top/execute_inst/ALU_UNIT/OperandB
add wave -radix binary sim:/processor_top/execute_inst/ALU_UNIT/ALU_Op
add wave -radix hexadecimal sim:/processor_top/execute_inst/ALU_UNIT/Result
add wave -radix binary sim:/processor_top/execute_inst/ALU_UNIT/Zero
add wave -radix binary sim:/processor_top/execute_inst/ALU_UNIT/Negative
add wave -radix binary sim:/processor_top/execute_inst/ALU_UNIT/Carry

add wave -divider "CCR Internal"
add wave -radix binary sim:/processor_top/execute_inst/CCR_UNIT/CCRWrEn
add wave -radix binary sim:/processor_top/execute_inst/CCR_UNIT/MemToCCR
add wave -radix binary sim:/processor_top/execute_inst/CCR_UNIT/StackFlags
add wave -radix binary sim:/processor_top/execute_inst/CCR_UNIT/CCR_Out

add wave -divider "Forwarding Unit"
add wave -radix binary sim:/processor_top/forwarding.forward_a
add wave -radix binary sim:/processor_top/forwarding.forward_b
add wave -radix binary sim:/processor_top/forwarding.forward_secondary
add wave -radix binary sim:/processor_top/forwarding_unit_inst/MemRegWrite
add wave -radix unsigned sim:/processor_top/forwarding_unit_inst/MemRdst
add wave -radix binary sim:/processor_top/forwarding_unit_inst/MemIsSwap
add wave -radix binary sim:/processor_top/forwarding_unit_inst/WBRegWrite
add wave -radix unsigned sim:/processor_top/forwarding_unit_inst/WBRdst
add wave -radix unsigned sim:/processor_top/forwarding_unit_inst/ExRsrc1
add wave -radix unsigned sim:/processor_top/forwarding_unit_inst/ExRsrc2
add wave -radix binary sim:/processor_top/forwarding_unit_inst/ExOutBSelect
add wave -radix binary sim:/processor_top/forwarding_unit_inst/ExIsImm
add wave -radix binary sim:/processor_top/forwarding_unit_inst/ForwardA
add wave -radix binary sim:/processor_top/forwarding_unit_inst/ForwardB
add wave -radix binary sim:/processor_top/forwarding_unit_inst/ForwardSecondary

add wave -divider "Execute Ctrl"
add wave -radix binary sim:/processor_top/execute_inst/idex_ctrl_in.execute_ctrl
add wave -radix binary sim:/processor_top/execute_ctrl_out.wb_regwrite
add wave -radix binary sim:/processor_top/execute_ctrl_out.wb_memtoreg
add wave -radix binary sim:/processor_top/execute_ctrl_out.m_memread
add wave -radix binary sim:/processor_top/execute_ctrl_out.m_memwrite
add wave -radix binary sim:/processor_top/execute_ctrl_out.m_sptomem
add wave -radix binary sim:/processor_top/execute_ctrl_out.m_passinterrupt

add wave -divider "EX/MEM"
add wave -radix hexadecimal sim:/processor_top/exmem_data_out.primary_data
add wave -radix hexadecimal sim:/processor_top/exmem_data_out.secondary_data
add wave -radix unsigned sim:/processor_top/exmem_data_out.rdst1
add wave -radix binary sim:/processor_top/exmem_ctrl_out.writeback_ctrl.RegWrite
add wave -radix binary sim:/processor_top/exmem_ctrl_out.writeback_ctrl.PassMem
add wave -radix binary sim:/processor_top/exmem_ctrl_out.writeback_ctrl.OutPortWriteEn
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.MemRead
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.MemWrite
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.SP_Enable
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.SP_Function
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.SPtoMem
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.PassInterrupt
add wave -radix binary sim:/processor_top/exmem_ctrl_out.memory_ctrl.MemToCCR

add wave -divider "Memory Stage"
add wave -radix binary sim:/processor_top/mem_stage_read_req
add wave -radix binary sim:/processor_top/mem_stage_write_req
add wave -radix hexadecimal sim:/processor_top/mem_stage_addr
add wave -radix hexadecimal sim:/processor_top/mem_stage_wdata
add wave -radix hexadecimal sim:/processor_top/mem_wb_data_comb.memory_data
add wave -radix hexadecimal sim:/processor_top/mem_wb_data_comb.alu_data
add wave -radix unsigned sim:/processor_top/mem_wb_data_comb.rdst
add wave -radix binary sim:/processor_top/mem_wb_ctrl_comb.writeback_ctrl.RegWrite
add wave -radix binary sim:/processor_top/mem_wb_ctrl_comb.writeback_ctrl.PassMem
add wave -radix binary sim:/processor_top/mem_wb_ctrl_comb.writeback_ctrl.OutPortWriteEn

add wave -divider "Stack Pointer"
add wave -radix hexadecimal sim:/processor_top/memory_stage_inst/sp_unit/Data
add wave -radix binary sim:/processor_top/memory_stage_inst/sp_unit/enb
add wave -radix binary sim:/processor_top/memory_stage_inst/sp_unit/Increment
add wave -radix binary sim:/processor_top/memory_stage_inst/sp_unit/Decrement

add wave -divider "WB"
add wave -radix binary sim:/processor_top/wb_out.reg_we
add wave -radix unsigned sim:/processor_top/wb_out.rdst
add wave -radix hexadecimal sim:/processor_top/wb_out.data

add wave -divider "MEM/WB"
add wave -radix hexadecimal sim:/processor_top/memwb_data.memory_data
add wave -radix hexadecimal sim:/processor_top/memwb_data.alu_data
add wave -radix unsigned sim:/processor_top/memwb_data.rdst
add wave -radix binary sim:/processor_top/memwb_ctrl.writeback_ctrl.RegWrite
add wave -radix binary sim:/processor_top/memwb_ctrl.writeback_ctrl.PassMem
add wave -radix binary sim:/processor_top/memwb_ctrl.writeback_ctrl.OutPortWriteEn

add wave -divider "Arb / Memory"
add wave -radix binary sim:/processor_top/pass_pc
add wave -radix binary sim:/processor_top/front_enable
add wave -radix hexadecimal sim:/processor_top/mem_addr_mux
add wave -radix hexadecimal sim:/processor_top/mem_wdata_mux
add wave -radix binary sim:/processor_top/mem_read_mux
add wave -radix binary sim:/processor_top/mem_write_mux
add wave -radix binary sim:/processor_top/mem_read_out
add wave -radix binary sim:/processor_top/mem_write_out
add wave -radix hexadecimal sim:/processor_top/mem_data

add wave -divider "Freeze Control"
add wave -radix binary sim:/processor_top/pc_freeze
add wave -radix binary sim:/processor_top/ifde_write_enable
add wave -radix binary sim:/processor_top/insert_nop_ifde
add wave -radix binary sim:/processor_top/insert_nop_deex
add wave -radix binary sim:/processor_top/freeze_control_inst/is_swap
add wave -radix binary sim:/processor_top/freeze_control_inst/requireImmediate
add wave -radix binary sim:/processor_top/freeze_control_inst/stall_condition

add wave -divider "Interrupt Unit"
add wave -radix binary sim:/processor_top/hardware_interrupt
add wave -radix binary sim:/processor_top/int_stall
add wave -radix binary sim:/processor_top/int_pass_pc_not_plus1
add wave -radix binary sim:/processor_top/int_take_interrupt
add wave -radix binary sim:/processor_top/int_is_hardware_int_mem
add wave -radix binary sim:/processor_top/int_override_operation
add wave -radix binary sim:/processor_top/int_override_type

add wave -divider "Interrupt Unit Internal"
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsInterrupt_DE
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsCall_DE
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsReturn_DE
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsReti_DE
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsInterrupt_EX
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsReti_EX
add wave -radix binary sim:/processor_top/interrupt_unit_inst/IsHardwareInt_MEM
add wave -divider "Branch Decision Unit"
add wave -radix binary sim:/processor_top/branch_select
add wave -radix binary sim:/processor_top/branch_target_select
add wave -radix binary sim:/processor_top/flush_if
add wave -radix binary sim:/processor_top/flush_de
add wave -radix binary sim:/processor_top/stall_branch
add wave -radix binary sim:/processor_top/actual_taken
add wave -radix binary sim:/processor_top/idex_ctrl_out.decode_ctrl.IsJMP
add wave -radix binary sim:/processor_top/idex_ctrl_out.decode_ctrl.IsJMPConditional
add wave -radix binary sim:/processor_top/idex_ctrl_out.execute_ctrl.ConditionalType
add wave -radix binary sim:/processor_top/execute_out.ccr_flags

add wave -divider "Branch Targets"
add wave -radix hexadecimal sim:/processor_top/branch_targets.target_decode
add wave -radix hexadecimal sim:/processor_top/branch_targets.target_execute
add wave -radix hexadecimal sim:/processor_top/branch_targets.target_memory

# Clock + reset
force -freeze sim:/processor_top/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/processor_top/rst 1 0, 0 {300 ps}
force -freeze sim:/processor_top/in_port 16#00000000 0
force -freeze sim:/processor_top/in_port 16#12345678 0
force -freeze sim:/processor_top/hardware_interrupt 0 0

run 30000 ps

# Example: Test in_port input changes during simulation
force -freeze sim:/processor_top/in_port 16#00000000 0
force -freeze sim:/processor_top/in_port 16#0000ABCD 2000ps
force -freeze sim:/processor_top/in_port 16#FFFFFFFF 3000ps
force -freeze sim:/processor_top/in_port 16#00000000 4000ps

run 10000 ps
