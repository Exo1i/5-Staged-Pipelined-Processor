# Contributing Guide

This document explains the expected workflow, coding conventions, and the project directory structure to help maintain consistency across the repository.

---

## 1. Project Structure

Below is the high-level directory layout used in this project. Each folder has a clear purpose and should be followed when adding new modules or files.

```
processor_project/
├── README.md
├── docs/
│   ├── architecture_spec.pdf
│   ├── opcode_table.md
│   ├── control_signals.xlsx
│   ├── interface_spec.md
│
├── rtl/
│   ├── common/
│   ├── fetch/
│   ├── decode/
│   ├── control/
│   ├── execute/
│   ├── memory/
│   ├── writeback/
│   ├── io/
│   └── processor_top.vhd
│
├── testbench/
│   ├── tb_processor_top.vhd
│   ├── tb_alu.vhd
│   ├── tb_register_file.vhd
│   ├── tb_control_decoder.vhd
│   ├── tb_forwarding_unit.vhd
│   ├── tb_memory.vhd
│   ├── tb_interrupt_unit.vhd
│   └── utilities/
│       ├── clock_generator.vhd
│       └── memory_loader.vhd
│
├── simulation/
│   ├── modelsim.ini
│   ├── wave_configs/
│   ├── scripts/
│   └── work/
│
├── assembler/
│   ├── assembler.py
│   ├── opcodes.json
│   ├── instruction_parser.py
│   ├── encoder.py
│   └── examples/
│
├── tests/
│   ├── assembly/
│   ├── machine_code/
│   └── expected_outputs/
│
├── verification/
│   ├── cocotb/
│   └── coverage/
│
├── tools/
├── synthesis/
└── reports/
```

### Directory Purpose Summary

* **docs/** – Specifications, and design documentation.
* **rtl/** – All VHDL source files organized per pipeline stage.
* **testbench/** – Unit tests and full processor testbenches.
* **simulation/** – ModelSim configuration, waveform files, and scripts.
* **assembler/** – Python assembler and tools for generating machine code.
* **tests/** – Assembly programs, generated machine code, and expected results.
* **verification/** – Cocotb-based verification and coverage results.
* **tools/** – Utility scripts for analysis and debugging.
* **synthesis/** – FPGA synthesis constraints and reports.
* **reports/** – PDF reports and project documentation.

---

## 2. Naming Conventions

### **VHDL Files**

* Modules: `module_name.vhd`
* Registers: `stage_register.vhd`
* Packages: `types.vhd`, `constants.vhd`
* Top-level stage wrappers end with `_stage.vhd`

### **Python Files (Assembler)**

* Use lowercase with underscores.
* Keep functionality modular.

### **Tests**

* Assembly tests: `test_<feature>.asm`
* Expected output: `test_<feature>_expected.txt`

---

## 3. Contribution Workflow

### **1. Create a feature branch**

```
git checkout -b feature/<name>
```

### **2. Follow directory structure & conventions**

Place new files in the correct folder.

### **3. Run existing tests**

Use ModelSim scripts:

```
do simulation/scripts/run_unit_tests.do
do simulation/scripts/run_integration.do
```

### **4. Submit a pull request**

Include:

* Purpose of change
* Affected modules
* Test results
* Waveform screenshots (if relevant)

---

## 4. Coding Standards

### **VHDL Style Rules**

* Use `std_logic` / `std_logic_vector` consistently.
* Use descriptive signal names.
* Avoid combinational loops.
* Pipeline stages must follow the architecture spec.

### **Python Style Rules (Assembler)**

* Follow PEP 8.
* Keep functions pure when possible.
* Add unit tests for new instructions.
