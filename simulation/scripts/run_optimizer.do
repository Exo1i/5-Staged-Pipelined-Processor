# ==============================================================================
# Processor Simulation Script - Corrected Resolution
# ==============================================================================

# 1. Environment Setup
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

if {![file exists memory_temp]} {
    mkdir memory_temp
}

# 2. Compilation (Order: Packages -> Commons -> Stages -> Top)

# --- Packages ---
vcom -2008 -work work ./src/common/control_signals_pkg.vhd
vcom -2008 -work work ./src/common/pipeline_data_pkg.vhd
vcom -2008 -work work ./src/common/pkg_opcodes.vhd
vcom -2008 -work work ./src/common/processor_interface_pkg.vhd

# --- Common & Memory ---
vcom -2008 -work work ./src/common/memory.vhd
vcom -2008 -work work ./src/common/simulation_memory.vhd

# --- Fetch Stage ---
vcom -2008 -work work ./src/fetch/pc.vhd
vcom -2008 -work work ./src/fetch/fetch_stage.vhd
vcom -2008 -work work ./src/fetch/if_id_register.vhd

# --- Decode Stage ---
vcom -2008 -work work ./src/decode/register_file.vhd
vcom -2008 -work work ./src/decode/decode_stage.vhd
vcom -2008 -work work ./src/control/opcode-decoder/opcode_decoder.vhd
vcom -2008 -work work ./src/decode/id_ex_register.vhd

# --- Execute Stage ---
vcom -2008 -work work ./src/execute/alu.vhd
vcom -2008 -work work ./src/execute/ccr.vhd
vcom -2008 -work work ./src/execute/execute_stage.vhd
vcom -2008 -work work ./src/execute/ex_mem_register.vhd

# --- Memory Stage ---
vcom -2008 -work work ./src/memory/stack_pointer.vhd
vcom -2008 -work work ./src/memory/memory_stage.vhd
vcom -2008 -work work ./src/memory/mem_wb_register.vhd

# --- Writeback Stage ---
vcom -2008 -work work ./src/writeback/writeback_stage.vhd

# --- Control Units ---
vcom -2008 -work work ./src/control/memory-hazard-unit/memory_hazard_unit.vhd
vcom -2008 -work work ./src/control/forwarding-unit/forwarding_unit.vhd
vcom -2008 -work work ./src/control/freeze-control/freeze_control.vhd
vcom -2008 -work work ./src/control/interrupt-unit/interrupt_unit.vhd
vcom -2008 -work work ./src/control/branch-control/branch-decision-unit/branch_decision_unit.vhd
vcom -2008 -work work ./src/control/branch-control/branch-predictor/branch_predictor.vhd

# --- Top Level ---
vcom -2008 -work work ./src/processor_top.vhd

# 3. Simulation Start (FIXED: Added -t 1ps to set resolution to picoseconds)
vsim -voptargs=+acc -t 1ps work.processor_top

# 4. Waveform Configuration
configure wave -signalnamewidth 1
configure wave -timelineunits ps

# ==============================================================================
# SIGNAL GROUPING AND COLORING
# Colors: White(Clk), Gold(Top), Cyan(Data), Yellow(Ctrl), Orange(Hazards), Green(Mem)
# ==============================================================================

# --- TOP LEVEL INTERFACE ---
add wave -noupdate -group "System Interface" -color white /processor_top/clk
add wave -noupdate -group "System Interface" -color white /processor_top/rst
add wave -noupdate -group "System Interface" -color cyan -radix hexadecimal /processor_top/in_port
add wave -noupdate -group "System Interface" -color cyan -radix hexadecimal /processor_top/out_port
add wave -noupdate -group "System Interface" -color yellow /processor_top/out_port_en
add wave -noupdate -group "System Interface" -color orange /processor_top/hardware_interrupt
add wave -noupdate -group "System Interface" -color orange /processor_top/pending_hw_interrupt
add wave -noupdate -group "System Interface" -color orange /processor_top/TakeHWInterrupt
add wave -noupdate -group "System Interface" -radix unsigned /processor_top/clk_count

# --- PC GROUP (inside Fetch) ---
add wave -noupdate -group "PC" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_reg
add wave -noupdate -group "PC" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_next
add wave -noupdate -group "PC" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_out
add wave -noupdate -group "PC" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_nxt
add wave -noupdate -group "PC" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_plus_one
add wave -noupdate -group "PC" -color yellow /processor_top/fetch_inst/pc_inst/reset_pending

# --- FETCH STAGE ---
add wave -noupdate -group "Fetch Stage" -color cyan -radix hexadecimal -expand /processor_top/fetch_out
add wave -noupdate -group "Fetch Stage" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_reg
add wave -noupdate -group "Fetch Stage" -color violet -radix hexadecimal /processor_top/fetch_inst/pc_inst/pc_next
add wave -noupdate -group "Fetch Stage" -color yellow /processor_top/fetch_inst/stall
add wave -noupdate -group "Fetch Stage" -color yellow /processor_top/fetch_inst/BranchSelect

# --- IF/ID PIPELINE REG ---
add wave -noupdate -group "IF/ID Reg" -color gold -radix hexadecimal -expand /processor_top/ifid_out
add wave -noupdate -group "IF/ID Reg" -color yellow /processor_top/ifid_inst/enable
add wave -noupdate -group "IF/ID Reg" -color yellow /processor_top/ifid_inst/flush_instruction

# --- DECODE STAGE ---
add wave -noupdate -group "Decode Stage" -color cyan -radix hexadecimal -expand /processor_top/decode_out
add wave -noupdate -group "Decode Stage" -color yellow -expand /processor_top/decode_ctrl_out
add wave -noupdate -group "Decode Stage" -color yellow -expand /processor_top/decode_flags
add wave -noupdate -group "Decode Stage" -color cyan -radix hexadecimal /processor_top/decode_inst/reg_file_inst/registers
# --- OPCODE DECODER ---
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/opcode
add wave -noupdate -group "Opcode Decoder" -color yellow -expand /processor_top/opcode_decoder_inst/decode_ctrl
add wave -noupdate -group "Opcode Decoder" -color yellow -expand /processor_top/opcode_decoder_inst/execute_ctrl
add wave -noupdate -group "Opcode Decoder" -color yellow -expand /processor_top/opcode_decoder_inst/memory_ctrl
add wave -noupdate -group "Opcode Decoder" -color yellow -expand /processor_top/opcode_decoder_inst/writeback_ctrl
add wave -noupdate -group "Opcode Decoder" -color orange /processor_top/opcode_decoder_inst/override_operation
# All opcode_decoder inputs
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/override_type
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/isSwap_from_execute
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/take_interrupt
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/is_hardware_int_mem
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/requireImmediate
# All opcode_decoder outputs
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/is_jmp_out
add wave -noupdate -group "Opcode Decoder" -color yellow /processor_top/opcode_decoder_inst/is_jmp_conditional_out
# --- REGISTER FILE GROUP (inside Decode) ---
add wave -noupdate -group "Register File" -color cyan -radix hexadecimal /processor_top/decode_inst/reg_file_inst/registers
add wave -noupdate -group "Register File" -color yellow /processor_top/decode_inst/reg_file_inst/Ra
add wave -noupdate -group "Register File" -color yellow /processor_top/decode_inst/reg_file_inst/Rb
add wave -noupdate -group "Register File" -color yellow /processor_top/decode_inst/reg_file_inst/Rdst
add wave -noupdate -group "Register File" -color yellow /processor_top/decode_inst/reg_file_inst/WriteEnable
add wave -noupdate -group "Register File" -color cyan -radix hexadecimal /processor_top/decode_inst/reg_file_inst/ReadDataA
add wave -noupdate -group "Register File" -color cyan -radix hexadecimal /processor_top/decode_inst/reg_file_inst/ReadDataB
add wave -noupdate -group "Register File" -color cyan -radix hexadecimal /processor_top/decode_inst/reg_file_inst/WriteData

# --- DECODE CONTROLLER (OPCODE DECODER) ---
add wave -noupdate -group "Control Unit" -color yellow /processor_top/opcode_decoder_inst/opcode
add wave -noupdate -group "Control Unit" -color yellow -expand /processor_top/opcode_decoder_inst/decode_ctrl
add wave -noupdate -group "Control Unit" -color yellow -expand /processor_top/opcode_decoder_inst/execute_ctrl
add wave -noupdate -group "Control Unit" -color yellow -expand /processor_top/opcode_decoder_inst/memory_ctrl
add wave -noupdate -group "Control Unit" -color yellow -expand /processor_top/opcode_decoder_inst/writeback_ctrl
add wave -noupdate -group "Control Unit" -color orange /processor_top/opcode_decoder_inst/override_operation

# --- ID/EX PIPELINE REG ---
add wave -noupdate -group "ID/EX Reg" -color gold -radix hexadecimal -expand /processor_top/idex_data_out
add wave -noupdate -group "ID/EX Reg" -color yellow -expand /processor_top/idex_ctrl_out
add wave -noupdate -group "ID/EX Reg" -color orange /processor_top/idex_inst/flush

# --- FORWARDING UNIT GROUP ---
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/MemRegWrite
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/MemRdst
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/MemIsSwap
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/WBRegWrite
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/WBRdst
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ExRsrc1
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ExRsrc2
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ExOutBSelect
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ExIsImm
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ForwardA
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ForwardB
add wave -noupdate -group "Forwarding Unit" -color orange /processor_top/forwarding_unit_inst/ForwardSecondary

# --- EXECUTE STAGE ---
add wave -noupdate -group "Execute Stage" -color cyan -radix hexadecimal -expand /processor_top/execute_out
add wave -noupdate -group "Execute Stage" -color cyan -radix hexadecimal /processor_top/execute_inst/ALU_UNIT/Result
add wave -noupdate -group "Execute Stage" -color cyan -radix binary /processor_top/execute_inst/CCR_UNIT/CCR_Out
add wave -noupdate -group "Execute Stage" -color yellow /processor_top/execute_inst/ALU_UNIT/Zero
add wave -noupdate -group "Execute Stage" -color yellow /processor_top/execute_inst/ALU_UNIT/Negative
add wave -noupdate -group "Execute Stage" -color yellow /processor_top/execute_inst/ALU_UNIT/Carry
add wave -noupdate -group "Execute Stage" -color orange /processor_top/forwarding
# --- ALU GROUP (inside Execute) ---
add wave -noupdate -group "ALU" -color cyan -radix hexadecimal /processor_top/execute_inst/ALU_UNIT/OperandA
add wave -noupdate -group "ALU" -color cyan -radix hexadecimal /processor_top/execute_inst/ALU_UNIT/OperandB
add wave -noupdate -group "ALU" -color yellow /processor_top/execute_inst/ALU_UNIT/ALU_Op
add wave -noupdate -group "ALU" -color cyan -radix hexadecimal /processor_top/execute_inst/ALU_UNIT/Result
add wave -noupdate -group "ALU" -color yellow /processor_top/execute_inst/ALU_UNIT/Zero
add wave -noupdate -group "ALU" -color yellow /processor_top/execute_inst/ALU_UNIT/Negative
add wave -noupdate -group "ALU" -color yellow /processor_top/execute_inst/ALU_UNIT/Carry
add wave -noupdate -group "ALU" -color yellow /processor_top/execute_inst/ALU_UNIT/Carry_In
# --- CCR GROUP (inside Execute) ---
add wave -noupdate -group "CCR" -color cyan -radix binary /processor_top/execute_inst/CCR_UNIT/CCR_Out
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/ALU_Zero
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/ALU_Negative
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/ALU_Carry
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/CCRWrEn
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/SetCarry
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/MemToCCR
add wave -noupdate -group "CCR" -color yellow /processor_top/execute_inst/CCR_UNIT/StackFlags

# --- EX/MEM PIPELINE REG ---
add wave -noupdate -group "EX/MEM Reg" -color gold -radix hexadecimal -expand /processor_top/exmem_data_out
add wave -noupdate -group "EX/MEM Reg" -color yellow -expand /processor_top/exmem_ctrl_out

# --- MEMORY STAGE ---
add wave -noupdate -group "Memory Stage" -color green -radix hexadecimal /processor_top/mem_stage_addr
add wave -noupdate -group "Memory Stage" -color green -radix hexadecimal /processor_top/mem_stage_wdata
add wave -noupdate -group "Memory Stage" -color green -radix hexadecimal /processor_top/mem_data
add wave -noupdate -group "Memory Stage" -color yellow /processor_top/mem_stage_read_req
add wave -noupdate -group "Memory Stage" -color yellow /processor_top/mem_stage_write_req
add wave -noupdate -group "Memory Stage" -color violet -radix hexadecimal /processor_top/memory_stage_inst/sp_unit/Data

# --- STACK POINTER ---
add wave -noupdate -group "Stack Pointer" -color violet -radix hexadecimal /processor_top/memory_stage_inst/sp_unit/Data
add wave -noupdate -group "Stack Pointer" -color violet -radix unsigned /processor_top/memory_stage_inst/sp_unit/sp
add wave -noupdate -group "Stack Pointer" -color violet -radix unsigned /processor_top/memory_stage_inst/sp_unit/incremented_sp
add wave -noupdate -group "Stack Pointer" -color violet -radix unsigned /processor_top/memory_stage_inst/sp_unit/sp_out
add wave -noupdate -group "Stack Pointer" -color yellow /processor_top/memory_stage_inst/sp_unit/Increment
add wave -noupdate -group "Stack Pointer" -color yellow /processor_top/memory_stage_inst/sp_unit/Decrement
add wave -noupdate -group "Stack Pointer" -color yellow /processor_top/memory_stage_inst/sp_unit/enb
add wave -noupdate -group "Stack Pointer" -color white /processor_top/memory_stage_inst/sp_unit/clk
add wave -noupdate -group "Stack Pointer" -color white /processor_top/memory_stage_inst/sp_unit/rst

# --- MEM/WB PIPELINE REG ---
add wave -noupdate -group "MEM/WB Reg" -color gold -radix hexadecimal -expand /processor_top/memwb_data
add wave -noupdate -group "MEM/WB Reg" -color yellow -expand /processor_top/memwb_ctrl

# --- WRITEBACK STAGE ---
add wave -noupdate -group "Writeback Stage" -color cyan -radix hexadecimal -expand /processor_top/wb_out

# --- HAZARD & FREEZE CONTROL ---
add wave -noupdate -group "Freeze/Stall" -color orange /processor_top/pc_freeze
add wave -noupdate -group "Freeze/Stall" -color orange /processor_top/ifde_write_enable
add wave -noupdate -group "Freeze/Stall" -color orange /processor_top/insert_nop_ifde
add wave -noupdate -group "Freeze/Stall" -color orange /processor_top/insert_nop_deex
add wave -noupdate -group "Freeze/Stall" -color orange /processor_top/int_stall
add wave -noupdate -group "Freeze/Stall" -color orange /processor_top/freeze_control_inst/is_hlt

# --- BRANCHING & INTERRUPTS ---
add wave -noupdate -group "Branch/Intr Unit" -color orange /processor_top/branch_select
add wave -noupdate -group "Branch/Intr Unit" -color orange /processor_top/branch_target_select
add wave -noupdate -group "Branch/Intr Unit" -color cyan -radix hexadecimal -expand /processor_top/branch_targets
add wave -noupdate -group "Branch/Intr Unit" -color orange /processor_top/actual_taken
add wave -noupdate -group "Branch/Intr Unit" -color orange /processor_top/int_take_interrupt
add wave -noupdate -group "Branch/Intr Unit" -color orange /processor_top/int_override_type

# --- INTERRUPT UNIT GROUP ---
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsInterrupt_DE
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsRet_DE
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsReti_DE
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsInterrupt_EX
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsReti_EX
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsRet_EX
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsInterrupt_MEM
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsRet_MEM
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsReti_MEM
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsHardwareInt_MEM
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/HardwareInterrupt
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/freeze_fetch
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/memory_hazard
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/PassPC_NotPCPlus1
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/TakeInterrupt
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/IsHardwareIntMEM_Out
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/OverrideOperation
add wave -noupdate -group "Interrupt Unit" -color orange /processor_top/interrupt_unit_inst/OverrideType

# ==============================================================================
# SIMULATION STIMULUS
# ==============================================================================

# 1. Reset
force -freeze sim:/processor_top/clk 1 0, 0 {50 ps} -r 100 ps
force -freeze sim:/processor_top/rst 1 0, 0 {300 ps}

# 2. Initial State
force -freeze sim:/processor_top/in_port 16#00000000 0
force -freeze sim:/processor_top/hardware_interrupt 0 0

# Run past reset
run 500 ps

# 3. Test Cases
# Hardware Interrupt at 2400ps
force -freeze sim:/processor_top/hardware_interrupt 1 2360ps, 0 2540ps

# Input Port changes
force -freeze sim:/processor_top/in_port 16#0000ABCD 2000ps
force -freeze sim:/processor_top/in_port 16#FFFFFFFF 3000ps

# Run simulation
run 10000 ps

# Zoom to full view
wave zoom full