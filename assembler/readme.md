# Assembler Documentation

## Overview

A two-pass assembler for a 5-stage pipelined RISC processor with Von Neumann architecture. This tool targets a **32-bit Word Addressable Memory** system. It converts assembly language programs into machine code files suitable for hardware simulation (e.g., ModelSim).

## Files

- **`assembler.py`** - Main assembler implementation
- **`isa_constants.py`** - ISA definitions, opcodes, and constants
- **`example.asm`** - Comprehensive example assembly program

## Features

### Core Features
- **32-bit Word Addressable**: Generates 32-bit hex codes where each address holds one word.
- Two-pass assembly (symbol resolution).
- Label support for branches and jumps.
- Multiple number formats (hex, binary, decimal).
- `.ORG` directive for setting address origin.
- Three output formats (hex, binary, mem).
- Verbose debugging mode.

### Instruction Encoding
- **Fixed 32-bit Word Width**.
- **Variable Instruction Length**:
    - **1 Word**: Register-only or No-operand instructions.
    - **2 Words**: Instructions with Immediates or Offsets.
- **5-bit opcodes** (Bits 31:27).
- **3-bit register fields** (R0-R7).
- **Sign-Extended Immediates**: 16-bit immediates are sign-extended to 32 bits and stored in the **second memory word**.

## Installation

No external dependencies required - uses only Python standard library.

```bash
# Ensure you have Python 3.6+
python --version

# Make executable (optional)
chmod +x assembler.py
```

## Usage

### Basic Usage

```bash
# Assemble a program
python assembler.py program.asm

# Specify output file
python assembler.py program.asm -o output.mem

# Use verbose mode
python assembler.py program.asm -v

# Generate hex format
python assembler.py program.asm -o output.hex -f hex
```

### Command Line Options

```
positional arguments:
  input_file            Input assembly file (.asm)

optional arguments:
  -h, --help            Show help message
  -o OUTPUT             Output file (default: output.mem)
  -f {hex,bin,mem}      Output format (default: mem)
  -v, --verbose         Enable verbose output
  --start-address ADDR  Starting memory address (default: 0)
```

### Output Formats

**MEM Format** (default - for simulation, 32-bit hex values):
```
00000000
3C000000
0000000A
```

**HEX Format** (Address : Value):
```
0000: 00000000
0001: 3C000000
0002: 0000000A
```

**BIN Format** (32-bit binary):
```
00000000000000000000000000000000: 00000000000000000000000000000000
00000000000000000000000000000001: 00111100000000000000000000000000
```

## Assembly Language Syntax

### Comments

```asm
; This is a comment
NOP         ; Inline comment
```

### Labels

```asm
START:      ; Label at current address
    LDM R1, 10
LOOP:       ; Another label
    JMP LOOP
```

### Directives

#### `.ORG` - Set Origin Address

Sets the location counter to a specific **word address**. 

```asm
.ORG 0x0000
    JMP MAIN        ; Reset vector (Takes 2 words: Addr 0 and 1)

.ORG 0x0100         ; Move to Word Address 0x100
MAIN:
    LDM R0, 0       ; Main program starts here
```

### Number Formats

```asm
LDM R1, 10      ; Decimal
LDM R1, 0x0A    ; Hexadecimal (0x prefix)
LDM R1, 0Ah     ; Hexadecimal (h suffix)
LDM R1, 0b1010  ; Binary (0b prefix)
LDM R1, 1010b   ; Binary (b suffix)
```

## Instruction Set

### One Operand Instructions (1 Word)

Occupies 1 Memory Address.

| Instruction | Format | Description |
|-------------|--------|-------------|
| NOP | `NOP` | No operation |
| HLT | `HLT` | Halt processor |
| SETC | `SETC` | Set carry flag |
| NOT | `NOT Rdst` | Bitwise NOT |
| INC | `INC Rdst` | Increment register |
| OUT | `OUT Rdst` | Output to port |
| IN | `IN Rdst` | Input from port |
| RET | `RET` | Return from subroutine |
| RTI | `RTI` | Return from interrupt |
| INT | `INT index` | Software interrupt |

### Two/Three Operand Instructions (1 Word)

Occupies 1 Memory Address.

| Instruction | Format | Description |
|-------------|--------|-------------|
| MOV | `MOV Rsrc, Rdst` | Move register to register |
| SWAP | `SWAP Rsrc, Rdst` | Swap two registers |
| ADD | `ADD Rdst, Rsrc1, Rsrc2` | Add registers |
| SUB | `SUB Rdst, Rsrc1, Rsrc2` | Subtract registers |
| AND | `AND Rdst, Rsrc1, Rsrc2` | Bitwise AND |
| PUSH | `PUSH Rdst` | Push to stack |
| POP | `POP Rdst` | Pop from stack |

### Immediate & Memory Offset Instructions (2 Words)

Occupies **2 Consecutive Memory Addresses**.
1. **Header Word**: Contains Opcode and Registers.
2. **Immediate Word**: Contains the 32-bit sign-extended immediate/offset.

| Instruction | Format | Description |
|-------------|--------|-------------|
| IADD | `IADD Rdst, Rsrc, Imm` | Add immediate |
| LDM | `LDM Rdst, Imm` | Load immediate |
| LDD | `LDD Rdst, offset(Rsrc)` | Load with offset |
| STD | `STD Rsrc1, offset(Rsrc2)` | Store with offset |

### Branch Instructions (2 Words)

Occupies **2 Consecutive Memory Addresses**.
The second word contains the target address (sign-extended).

| Instruction | Format | Description |
|-------------|--------|-------------|
| JZ | `JZ address` | Jump if zero |
| JN | `JN address` | Jump if negative |
| JC | `JC address` | Jump if carry |
| JMP | `JMP address` | Unconditional jump |
| CALL | `CALL address` | Call subroutine |

## Instruction Encoding

### General Layout (32-bit)

All instructions are aligned to 32-bit boundaries.

**Word 1 (Header):**
```
| 31 ... 27 | 26 ... 24 | 23 ... 21 | 20 ... 18 | 17 ....... 0 |
|  OPCODE   |    R1     |    R2     |    R3     |    ZEROS     |
```

- **OPCODE**: 5 bits
- **R1**: Destination Register (usually)
- **R2**: Source Register 1
- **R3**: Source Register 2

**Word 2 (Immediate/Offset - Only for 2-Word Instructions):**
```
| 31 ........................................................ 0 |
|              IMMEDIATE VALUE (Sign Extended)                  |
```

### Encoding Mapping

| Instruction Type | R1 (26:24) | R2 (23:21) | R3 (20:18) | Example |
|------------------|------------|------------|------------|---------|
| `NOP`, `RET`     | 0          | 0          | 0          | `NOP` |
| `NOT Rdst`       | Rdst       | 0          | 0          | `NOT R1` |
| `MOV Rsrc, Rdst` | Rdst       | Rsrc       | 0          | `MOV R2, R1` |
| `ADD Rd, S1, S2` | Rdst       | Rsrc1      | Rsrc2      | `ADD R1, R2, R3` |
| `LDM Rdst, Imm`  | Rdst       | 0          | 0          | **Word 1**: Header<br>**Word 2**: Imm |
| `IADD Rd, Rs, I` | Rdst       | Rsrc       | 0          | **Word 1**: Header<br>**Word 2**: Imm |
| `LDD Rd, off(Rs)`| Rdst       | Rsrc       | 0          | **Word 1**: Header<br>**Word 2**: Offset |
| `STD Rs1,off(Rs2)`| Rsrc1     | Rsrc2      | 0          | **Word 1**: Header<br>**Word 2**: Offset |
| `JMP Address`    | 0          | 0          | 0          | **Word 1**: Header<br>**Word 2**: Address |

### Sign Extension Rule

The assembler accepts 16-bit immediate values from the assembly code (e.g., `-5`, `0xFFFB`). 
When generating the **Second Word**, these values are **Sign Extended** to 32 bits.

*   Input: `LDM R1, -1`
*   Header: Opcode for LDM | R1 | ...
*   Immediate Word: `0xFFFFFFFF` (not `0x0000FFFF`)

## Architecture Details

- **Memory Architecture**: Von Neumann (Single memory for instructions and data).
- **Addressing**: 32-bit Word Addressable.
    - Address 0 = Word 0 (Bits 0-31)
    - Address 1 = Word 1 (Bits 32-63)
- **Data Bus**: 32 bits.
- **Registers**: 8 general purpose (R0-R7), 32-bit wide.
- **Pipeline**: 5-stage (Fetch, Decode, Execute, Memory, Write Back).
- **Stack**: Initial value `(2^20 - 1)`.

## Example Program Trace

**Assembly:**
```asm
.ORG 0
    LDM R1, 5       ; Load 5 into R1
    INC R1          ; Increment R1
    HLT             ; Stop
```

**Memory Output (Hex):**
```
0000: 79000000      ; LDM Opcode(15)<<27 | R1(1)<<24
0001: 00000005      ; Immediate Value 5
0002: 21000000      ; INC Opcode(4)<<27 | R1(1)<<24
0003: 08000000      ; HLT Opcode(1)<<27
```

## License

Academic project for Cairo University CMP 3010 - Fall 2025

---

**Version:** 2.0
**Date:** December 5, 2025