# 5-Staged Pipelined Processor - Architecture Documentation

This document provides comprehensive documentation for all components in the `src/` directory.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Fetch Stage](#fetch-stage)
3. [Decode Stage](#decode-stage)
4. [Execute Stage](#execute-stage)
5. [Memory Stage](#memory-stage)
6. [Writeback Stage](#writeback-stage)
7. [Control Unit](#control-unit)
8. [Common Packages](#common-packages)
9. [Assembler](#assembler)

---

## System Overview

### Top-Level Files

#### `processor_top.vhd`

The main processor entity that instantiates and connects all pipeline stages.

**Ports:**
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | in | 1 | System clock |
| `reset` | in | 1 | Active-high reset |
| `interrupt` | in | 1 | Hardware interrupt request |
| `in_port` | in | 32 | Input port data |
| `out_port` | out | 32 | Output port data |

#### `system_top.vhd`

System-level wrapper that includes memory and I/O connections.

---

## Fetch Stage

**Location:** `src/fetch/`

### Components

#### `pc.vhd` - Program Counter

Manages the instruction address with support for:

- Sequential increment (`PC + 1`)
- Branch target address loading
- Reset vector handling
- Interrupt vector loading

**Key Signals:**

- `pc_enable`: Enables PC update
- `pc_source`: Selects next PC value (increment, branch, interrupt)
- `current_pc`: Current program counter value

#### `fetch_stage.vhd` - Fetch Stage Controller

Coordinates instruction fetching from memory.

**Functionality:**

1. Outputs current PC to memory
2. Receives instruction from memory
3. Passes instruction to IF/ID register
4. Handles stalls and flushes

#### `if_id_register.vhd` - IF/ID Pipeline Register

Stores fetched instruction between Fetch and Decode stages.

**Stored Values:**

- Current PC
- Fetched instruction (32-bit)
- Valid bit for pipeline control

---

## Decode Stage

**Location:** `src/decode/`

### Components

#### `decode_stage.vhd` - Decode Stage Controller

Main decode logic that:

1. Extracts opcode and register addresses
2. Reads operands from register file
3. Generates control signals
4. Handles immediate value sign extension

**Key Operations:**

```
Instruction[31:27] → Opcode
Instruction[26:24] → Rdst/R1
Instruction[23:21] → Rsrc1/R2
Instruction[20:18] → Rsrc2/R3
```

#### `register_file.vhd` - Register File

8 general-purpose 32-bit registers (R0-R7).

**Features:**

- 2 read ports (combinational)
- 1 write port (synchronous)
- R0 is NOT hardwired to zero

**Ports:**
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `read_addr1` | in | 3 | First read address |
| `read_addr2` | in | 3 | Second read address |
| `write_addr` | in | 3 | Write address |
| `write_data` | in | 32 | Data to write |
| `write_enable` | in | 1 | Write enable |
| `read_data1` | out | 32 | First read data |
| `read_data2` | out | 32 | Second read data |

#### `id_ex_register.vhd` - ID/EX Pipeline Register

Stores decoded instruction data for Execute stage.

**Stored Values:**

- Control signals
- Operand values
- Destination register address
- Immediate value
- PC for branch calculation

---

## Execute Stage

**Location:** `src/execute/`

### Components

#### `execute_stage.vhd` - Execute Stage Controller

Coordinates ALU operations and branch resolution.

**Features:**

- Forwarding mux integration
- Branch condition evaluation
- ALU operation selection

#### `alu.vhd` - Arithmetic Logic Unit

Performs all arithmetic and logic operations.

**ALU Operations:**
| ALU Op | Operation | Description |
|--------|-----------|-------------|
| 000 | ADD | A + B |
| 001 | SUB | A - B |
| 010 | AND | A AND B |
| 011 | NOT | NOT A |
| 100 | INC | A + 1 |
| 101 | PASS_A | Pass A through |
| 110 | PASS_B | Pass B through |
| 111 | SETC | Set carry flag |

#### `ccr.vhd` - Condition Code Register

Maintains processor status flags.

**Flags:**
| Flag | Bit | Description |
|------|-----|-------------|
| Zero (Z) | 0 | Set when result is zero |
| Negative (N) | 1 | Set when result is negative |
| Carry (C) | 2 | Set on carry/borrow |

#### `ex_mem_register.vhd` - EX/MEM Pipeline Register

Stores execution results for Memory stage.

---

## Memory Stage

**Location:** `src/memory/`

### Components

#### `memory_stage.vhd` - Memory Stage Controller

Handles data memory and stack operations.

**Operations:**

- Load (LDD): Read from memory
- Store (STD): Write to memory
- Push: Decrement SP, write to stack
- Pop: Read from stack, increment SP

#### `stack_pointer.vhd` - Stack Pointer

Hardware-managed stack pointer.

**Features:**

- Initial value: `0x3FFFF` (top of memory)
- Auto-decrement on PUSH/CALL/INT
- Auto-increment on POP/RET/RTI

#### `mem_wb_register.vhd` - MEM/WB Pipeline Register

Stores memory results for Writeback stage.

---

## Writeback Stage

**Location:** `src/writeback/`

### Components

#### `writeback_stage.vhd` - Writeback Stage Controller

Selects and writes result back to register file.

**Write Source Selection:**
| Source | Description |
|--------|-------------|
| ALU Result | From execute stage |
| Memory Data | From load operation |
| PC | For CALL instruction |

---

## Control Unit

**Location:** `src/control/`

The control unit is divided into specialized sub-units:

### Opcode Decoder (`opcode-decoder/`)

Decodes instruction opcode to generate control signals.

**Generated Signals:**

- `alu_op`: ALU operation select
- `mem_read`, `mem_write`: Memory access
- `reg_write`: Register file write enable
- `branch_type`: Branch condition type
- `stack_op`: Stack operation type

### Forwarding Unit (`forwarding-unit/`)

Implements data forwarding to resolve RAW hazards.

**Forwarding Paths:**

```
EX/MEM → Execute (1-cycle forward)
MEM/WB → Execute (2-cycle forward)
```

**Forwarding Select:**
| Value | Source |
|-------|--------|
| 00 | No forwarding (register file) |
| 01 | Forward from EX/MEM |
| 10 | Forward from MEM/WB |

### Memory Hazard Unit (`memory-hazard-unit/`)

Detects load-use hazards requiring pipeline stalls.

**Stall Condition:**

```
IF (ID/EX.MemRead = '1') AND
   ((ID/EX.Rdst = IF/ID.Rsrc1) OR (ID/EX.Rdst = IF/ID.Rsrc2))
THEN stall pipeline
```

### Branch Control (`branch-control/`)

Manages branch prediction and resolution.

**Features:**

- 2-bit saturating counter predictor
- Branch target buffer
- Misprediction recovery

**Predictor States:**

```
00: Strongly Not Taken → predict not taken
01: Weakly Not Taken   → predict not taken
10: Weakly Taken       → predict taken
11: Strongly Taken     → predict taken
```

### Freeze Control (`freeze-control/`)

Manages pipeline stalls and flushes.

**Freeze Sources:**

- Load-use hazard
- Branch misprediction
- Interrupt handling

### Interrupt Unit (`interrupt-unit/`)

Handles hardware and software interrupts.

**Interrupt Sequence:**

1. Save PC and flags to stack
2. Disable interrupts
3. Load interrupt vector
4. Execute ISR
5. RTI restores state

---

## Common Packages

**Location:** `src/common/`

### `pkg_opcodes.vhd`

Defines all instruction opcodes and ALU operations.

**Opcode Definitions:**
| Opcode | Binary | Instruction |
|--------|--------|-------------|
| 00000 | 0x00 | NOP |
| 00001 | 0x01 | HLT |
| 00010 | 0x02 | SETC |
| 00011 | 0x03 | NOT |
| 00100 | 0x04 | INC |
| 00101 | 0x05 | OUT |
| 00110 | 0x06 | IN |
| 00111 | 0x07 | MOV |
| 01000 | 0x08 | SWAP |
| 01001 | 0x09 | ADD |
| 01010 | 0x0A | SUB |
| 01011 | 0x0B | AND |
| 01100 | 0x0C | IADD |
| 01101 | 0x0D | PUSH |
| 01110 | 0x0E | POP |
| 01111 | 0x0F | LDM |
| 10000 | 0x10 | LDD |
| 10001 | 0x11 | STD |
| 10010 | 0x12 | JZ |
| 10011 | 0x13 | JN |
| 10100 | 0x14 | JC |
| 10101 | 0x15 | JMP |
| 10110 | 0x16 | CALL |
| 10111 | 0x17 | RET |
| 11000 | 0x18 | INT |
| 11001 | 0x19 | RTI |

### `control_signals_pkg.vhd`

Defines control signal types and bundles.

### `pipeline_data_pkg.vhd`

Defines pipeline register data types.

### `processor_interface_pkg.vhd`

Defines processor I/O interface types.

### Memory Modules

- `simulation_memory.vhd`: Memory for simulation (loadable)
- `synthesis_memory.vhd`: Memory for synthesis
- `memory.vhd`: Memory wrapper

---

## Assembler

**Location:** `src/assembler/`

A two-pass Python assembler for generating machine code.

### Files

- `assembler.py`: Main assembler implementation
- `isa_constants.py`: ISA definitions

### Usage

```bash
python3 assembler.py <input.asm> -o <output.mem> [-v] [--hex]
```

### Instruction Formats

**1-Word Instructions:**

```
| OPCODE(5) | Rdst(3) | Rsrc1(3) | Rsrc2(3) | Reserved(18) |
```

**2-Word Instructions:**

```
Word 1: | OPCODE(5) | Rdst(3) | Rsrc1(3) | Reserved(21) |
Word 2: | Immediate/Offset (32 bits)                    |
```

### Directives

- `.ORG address`: Set location counter
- Labels: `LABEL_NAME:` (case insensitive)

### Number Formats

- Decimal: `42`
- Hexadecimal: `0x2A` or `2Ah`
- Binary: `0b101010` or `101010b`

---

## Signal Naming Conventions

| Prefix/Suffix | Meaning                  |
| ------------- | ------------------------ |
| `_i`          | Input signal             |
| `_o`          | Output signal            |
| `_n`          | Active-low signal        |
| `_reg`        | Registered signal        |
| `if_id_`      | IF/ID pipeline register  |
| `id_ex_`      | ID/EX pipeline register  |
| `ex_mem_`     | EX/MEM pipeline register |
| `mem_wb_`     | MEM/WB pipeline register |

---

## Testing

Test programs are located in `tests/` directory:

| Test                      | Description                |
| ------------------------- | -------------------------- |
| `test1_basic.asm`         | Basic arithmetic and logic |
| `test2_loops.asm`         | Loop constructs            |
| `test3_complex_jumps.asm` | Branch testing             |
| `test4_stack.asm`         | PUSH/POP operations        |
| `test5_memory.asm`        | LDD/STD operations         |
| `test6_interrupts.asm`    | INT/RTI handling           |
| `test7_all.asm`           | Combined test              |
| `test8_complex.asm`       | Complex program            |

### Running Tests

```bash
# Assemble test
python3 ./src/assembler/assembler.py ./tests/test1_basic.asm -o ./memory_data.mem -v --hex

# Run simulation
vsim -do ./simulation/scripts/run_optimizer.do
```
