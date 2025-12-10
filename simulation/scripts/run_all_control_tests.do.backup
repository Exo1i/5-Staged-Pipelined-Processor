if {[file exists work]} {
    vdel -all
}
vlib work


echo ">>> Compiling Package Files..."
vcom -2008 -work work ../../rtl/control/opcode-decoder/pkg_opcodes.vhd
vcom -2008 -work work ../../rtl/control/opcode-decoder/control_signals_pkg.vhd

vcom -2008 -work work ../../rtl/control/opcode-decoder/opcode_decoder.vhd
vcom -2008 -work work ../../rtl/control/opcode-decoder/testbench_decoder.vhd

vsim -c work.testbench_decoder -do "run -all; quit -sim"

vcom -2008 -work work ../../rtl/control/memory-hazard-unit/memory_hazard_unit.vhd
vcom -2008 -work work ../../rtl/control/memory-hazard-unit/tb_memory_hazard_unit.vhd

vsim -c work.tb_memory_hazard_unit -do "run -all; quit -sim"

vcom -2008 -work work ../../rtl/control/freeze-control/freeze_control.vhd
vcom -2008 -work work ../../rtl/control/freeze-control/tb_freeze_control.vhd

vsim -c work.tb_freeze_control -do "run -all; quit -sim"

vcom -2008 -work work ../../rtl/control/interrupt-unit/interrupt_unit.vhd
vcom -2008 -work work ../../rtl/control/interrupt-unit/tb_interrupt_unit.vhd

vsim -c work.tb_interrupt_unit -do "run -all; quit -sim"

vcom -2008 -work work ../../rtl/control/branch-control/branch-predictor/branch_predictor.vhd
vcom -2008 -work work ../../rtl/control/branch-control/branch-predictor/tb_branch_predictor.vhd

vsim -c work.tb_branch_predictor -do "run -all; quit -sim"


vcom -2008 -work work ../../rtl/control/branch-control/branch-decision-unit/branch_decision_unit.vhd
vcom -2008 -work work ../../rtl/control/branch-control/branch-decision-unit/tb_branch_decision_unit.vhd

vsim -c work.tb_branch_decision_unit -do "run -all; quit -sim"

# Compile all sub-modules
vcom -2008 -work work ../../rtl/control/opcode-decoder/opcode_decoder.vhd
vcom -2008 -work work ../../rtl/control/memory-hazard-unit/memory_hazard_unit.vhd
vcom -2008 -work work ../../rtl/control/interrupt-unit/interrupt_unit.vhd
vcom -2008 -work work ../../rtl/control/freeze-control/freeze_control.vhd
vcom -2008 -work work ../../rtl/control/branch-control/branch-predictor/branch_predictor.vhd
vcom -2008 -work work ../../rtl/control/branch-control/branch-decision-unit/branch_decision_unit.vhd

# Compile top-level control unit
vcom -2008 -work work ../../rtl/control/control_unit.vhd

# Compile and run testbench
vcom -2008 -work work ../../testbench/tb_control_unit.vhd
vsim -c work.tb_control_unit -do "run -all; quit -sim"


quit -sim
