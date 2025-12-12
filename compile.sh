#!/bin/bash
set -e

echo "Cleaning work library..."
rm -f work-obj08.cf

echo "Analyzing packages..."
ghdl -a --std=08 --work=work ./src/common/*.vhd

echo "Analyzing Fetch stage..."
ghdl -a --std=08 --work=work ./src/fetch/pc.vhd
ghdl -a --std=08 --work=work ./src/fetch/fetch_stage.vhd

echo "Analyzing Decode stage..."
ghdl -a --std=08 --work=work ./src/decode/register_file.vhd
ghdl -a --std=08 --work=work ./src/decode/decode_stage.vhd

echo "Analyzing Execute stage..."
ghdl -a --std=08 --work=work ./src/execute/alu.vhd
ghdl -a --std=08 --work=work ./src/execute/ccr.vhd
ghdl -a --std=08 --work=work ./src/execute/execute_stage.vhd

echo "Analyzing Memory stage..."
ghdl -a --std=08 --work=work ./src/memory/stack_pointer.vhd
ghdl -a --std=08 --work=work ./src/memory/memory_stage.vhd

echo "Analyzing Writeback stage..."
ghdl -a --std=08 --work=work ./src/writeback/writeback_stage.vhd

echo "Analyzing control units..."
ghdl -a --std=08 --work=work ./src/control/opcode-decoder/opcode_decoder.vhd
ghdl -a --std=08 --work=work ./src/control/branch-control/branch-decision-unit/branch_decision_unit.vhd
ghdl -a --std=08 --work=work ./src/control/branch-control/branch-predictor/branch_predictor.vhd
ghdl -a --std=08 --work=work ./src/control/forwarding-unit/forwarding_unit.vhd
ghdl -a --std=08 --work=work ./src/control/freeze-control/freeze_control.vhd
ghdl -a --std=08 --work=work ./src/control/interrupt-unit/interrupt_unit.vhd
ghdl -a --std=08 --work=work ./src/control/memory-hazard-unit/memory_hazard_unit.vhd

echo "Analyzing pipeline registers..."
ghdl -a --std=08 --work=work ./src/fetch/if_id_register.vhd
ghdl -a --std=08 --work=work ./src/decode/id_ex_register.vhd
ghdl -a --std=08 --work=work ./src/execute/ex_mem_register.vhd
ghdl -a --std=08 --work=work ./src/memory/mem_wb_register.vhd

echo "Analyzing Top level..."
ghdl -a --std=08 --work=work ./src/processor_top.vhd

echo "Elaborating processor_top..."
ghdl -e --std=08 --work=work processor_top

echo "✓ Compilation successful!"
