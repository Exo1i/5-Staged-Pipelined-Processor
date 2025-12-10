# ModelSim/QuestaSim Wave Configuration for Execute Stage
# File: simulation/wave_configs/wave_execute.do

onerror {resume}
quietly WaveActivateNextPane {} 0

# Add clock and reset
add wave -noupdate -divider {Clock and Reset}
add wave -noupdate -format Logic /tb_execute_stage/clk
add wave -noupdate -format Logic /tb_execute_stage/reset

# Add register file signals
add wave -noupdate -divider {Register File}
add wave -noupdate -format Literal -radix binary /tb_execute_stage/UUT/Ra_Addr
add wave -noupdate -format Literal -radix binary /tb_execute_stage/UUT/Rb_Addr
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/UUT/rf_readA
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/UUT/rf_readB
add wave -noupdate -format Literal -radix binary /tb_execute_stage/WB_Rdst
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/WB_WriteData
add wave -noupdate -format Logic /tb_execute_stage/WB_RegWrite

# Add forwarding signals
add wave -noupdate -divider {Forwarding Control}
add wave -noupdate -format Literal -radix binary /tb_execute_stage/ForwardA
add wave -noupdate -format Literal -radix binary /tb_execute_stage/ForwardB
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/Forwarded_MEM
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/Forwarded_WB

# Add operand multiplexer outputs
add wave -noupdate -divider {ALU Operands}
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/UUT/operandA
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/UUT/operandB
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/Immediate
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/SP

# Add control signals
add wave -noupdate -divider {Control Signals}
add wave -noupdate -format Literal -radix binary /tb_execute_stage/ALU_Op
add wave -noupdate -format Logic /tb_execute_stage/spToALU
add wave -noupdate -format Logic /tb_execute_stage/ImmToALU
add wave -noupdate -format Logic /tb_execute_stage/CCRWrEn
add wave -noupdate -format Logic /tb_execute_stage/PassCCR

# Add ALU outputs
add wave -noupdate -divider {ALU Results}
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/ALU_Result
add wave -noupdate -format Logic /tb_execute_stage/UUT/alu_zero
add wave -noupdate -format Logic /tb_execute_stage/UUT/alu_neg
add wave -noupdate -format Logic /tb_execute_stage/UUT/alu_carry

# Add CCR
add wave -noupdate -divider {Condition Code Register}
add wave -noupdate -format Literal -radix binary /tb_execute_stage/CCR_Out
add wave -noupdate -format Logic /tb_execute_stage/CCR_Out(2)
add wave -noupdate -format Logic /tb_execute_stage/CCR_Out(1)
add wave -noupdate -format Logic /tb_execute_stage/CCR_Out(0)
add wave -noupdate -format Literal -radix binary /tb_execute_stage/StackFlags

# Add output to next stage
add wave -noupdate -divider {Outputs to MEM Stage}
add wave -noupdate -format Literal -radix hexadecimal /tb_execute_stage/RegB_Out

# Configure wave window
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ns} {1000 ns}