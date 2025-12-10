# Opcode Decoder

## Overview

The Opcode Decoder is the central control signal generator for the 5-stage pipelined processor. It decodes instruction opcodes and generates all necessary control signals for each pipeline stage.

## Purpose

- Decode 5-bit opcodes into control signals
- Generate signals for all 5 pipeline stages (IF, ID, EX, MEM, WB)
- Handle override operations for interrupt processing
- Support SWAP instruction as two-cycle operation
- Provide clean, organized control interface using VHDL records

## Architecture

### Entity Interface

```vhdl
Inputs:
  - opcode [4:0]              : Instruction opcode
  - override_operation        : Force specific operation (interrupts)
  - override_type [1:0]       : Type of forced operation
  - isSwap_from_execute       : SWAP second cycle feedback

Outputs (Records):
  - decode_ctrl    : Decode stage control signals
  - execute_ctrl   : Execute stage control signals
  - memory_ctrl    : Memory stage control signals
  - writeback_ctrl : Writeback stage control signals
```

## Instruction Set (26 Instructions)

### Arithmetic & Logic

| Opcode | Instruction       | Operation        | Signals                          |
| ------ | ----------------- | ---------------- | -------------------------------- |
| 00011  | NOT Rdst          | Rdst = ~Rdst     | ALU_OP=NOT, CCR_WE=1, RegWrite=1 |
| 00100  | INC Rdst          | Rdst = Rdst + 1  | ALU_OP=INC, CCR_WE=1, RegWrite=1 |
| 01001  | ADD Rdst,Rs1,Rs2  | Rdst = Rs1 + Rs2 | ALU_OP=ADD, CCR_WE=1, RegWrite=1 |
| 01010  | SUB Rdst,Rs1,Rs2  | Rdst = Rs1 - Rs2 | ALU_OP=SUB, CCR_WE=1, RegWrite=1 |
| 01011  | AND Rdst,Rs1,Rs2  | Rdst = Rs1 & Rs2 | ALU_OP=AND, CCR_WE=1, RegWrite=1 |
| 01100  | IADD Rdst,Rs1,Imm | Rdst = Rs1 + Imm | ALU_OP=ADD, PassImm=1, CCR_WE=1  |

### Data Movement

| Opcode | Instruction   | Operation       | Signals                       |
| ------ | ------------- | --------------- | ----------------------------- |
| 00101  | OUT Rdst      | OutPort = Rdst  | OutPortWriteEn=1              |
| 00110  | IN Rdst       | Rdst = InPort   | OutBSelect=11, RegWrite=1     |
| 00111  | MOV Rs1,Rdst  | Rdst = Rs1      | ALU_OP=PASS, RegWrite=1       |
| 01000  | SWAP Rs1,Rdst | Exchange values | IsSwap=1, Two-cycle operation |

### Memory Operations

| Opcode | Instruction      | Operation          | Signals                                   |
| ------ | ---------------- | ------------------ | ----------------------------------------- |
| 01101  | PUSH Rdst        | SP--, MEM[SP]=Rdst | SP_En=1, SP_Func=0, SPtoMem=1, MemWrite=1 |
| 01110  | POP Rdst         | Rdst=MEM[SP], SP++ | SP_En=1, SP_Func=1, SPtoMem=1, MemRead=1  |
| 01111  | LDM Rdst,Imm     | Rdst = Imm         | PassImm=1, RegWrite=1                     |
| 10000  | LDD Rdst,off(Rs) | Rdst = MEM[Rs+off] | PassImm=1, MemRead=1, MemToALU=1          |
| 10001  | STD Rs1,off(Rs2) | MEM[Rs2+off] = Rs1 | PassImm=1, MemWrite=1                     |

### Control Flow

| Opcode | Instruction | Operation             | Signals                        |
| ------ | ----------- | --------------------- | ------------------------------ |
| 10010  | JZ Imm      | Jump if Zero          | IsJMPCond=1, CondType=00       |
| 10011  | JN Imm      | Jump if Negative      | IsJMPCond=1, CondType=01       |
| 10100  | JC Imm      | Jump if Carry         | IsJMPCond=1, CondType=10       |
| 10101  | JMP Imm     | Unconditional Jump    | IsJMP=1                        |
| 10110  | CALL Imm    | Push PC, Jump         | IsCall=1, IsJMP=1              |
| 10111  | RET         | Pop PC, Jump          | IsReturn=1                     |
| 11000  | INT index   | Software Interrupt    | IsInterrupt=1, PassInterrupt=1 |
| 11001  | RTI         | Return from Interrupt | IsReti=1                       |

### Special

| Opcode | Instruction | Operation      | Signals               |
| ------ | ----------- | -------------- | --------------------- |
| 00000  | NOP         | No Operation   | All defaults          |
| 00001  | HLT         | Halt           | Special handling      |
| 00010  | SETC        | Set Carry Flag | ALU_OP=SETC, CCR_WE=1 |

## Control Signal Groups

### DECODE Stage Signals

```vhdl
OutBSelect [1:0]       : Select operand B source
  00 = Register File
  01 = Pushed PC
  10 = Immediate
  11 = Input Port

IsInterrupt            : Software interrupt flag
IsHardwareInterrupt    : Hardware interrupt flag
IsReturn               : RET instruction
IsCall                 : CALL instruction
IsReti                 : RTI instruction
IsJMP                  : Unconditional jump
IsJMPConditional       : Conditional jump
ConditionalType [1:0]  : 00=Zero, 01=Negative, 10=Carry
IsSwap                 : SWAP instruction (first cycle)
```

### EXECUTE Stage Signals

```vhdl
CCR_WriteEnable        : Enable CCR update
PassCCR                : Pass CCR to memory (PUSH FLAGS)
PassImm                : Pass immediate value to ALU
ALU_Operation [2:0]    : ALU operation code
  000 = ADD
  001 = SUB
  010 = AND
  011 = NOT
  100 = INC
  101 = PASS
  110 = SWAP
  111 = SETC
```

### MEMORY Stage Signals

```vhdl
SP_Enable              : Enable SP update
SP_Function            : 0=decrement, 1=increment
SPtoMem                : Use SP as memory address
PassInterrupt          : Pass interrupt address
MemRead                : Memory read enable
MemWrite               : Memory write enable
FlagFromMem            : Load flags from memory (POP FLAGS)
IsSwap                 : SWAP in memory (for forwarding unit)
```

### WRITEBACK Stage Signals

```vhdl
MemToALU               : 0=ALU result, 1=Memory data
RegWrite               : Register file write enable
OutPortWriteEn         : Output port write enable
```

## Special Features

### Override Operations

Used by Interrupt Unit to force specific operations:

- **OVERRIDE_PUSH_PC**: Force push PC to stack
- **OVERRIDE_PUSH_FLAGS**: Force push flags to stack
- **OVERRIDE_POP_PC**: Force pop PC from stack
- **OVERRIDE_POP_FLAGS**: Force pop flags from stack

### SWAP Two-Cycle Operation

1. **Cycle 1**: SWAP opcode detected

   - Acts as MOV Rs1 → Rdst
   - Sets `IsSwap = '1'`
   - Signal propagates through pipeline

2. **Cycle 2**: `isSwap_from_execute = '1'`
   - Overrides current opcode
   - Completes second MOV
   - Register addresses swapped by datapath

### Default Values

All control records have defined default values to prevent undefined behavior and ensure safe operation when no specific control is needed.

## Design Patterns

### Instruction Decoding

1. Initialize all signals to defaults
2. Check for override operations first
3. Decode normal opcode if no override
4. Handle SWAP feedback
5. Assign outputs

### Signal Organization

Using VHDL records provides:

- Clean interface
- Easy pipeline register propagation
- Type safety
- Self-documenting code
- Simplified connections

## Integration

### Connections

```
Opcode Decoder Outputs → Pipeline Registers → Stage Logic

decode_ctrl → IF/DE Register → Decode Stage
execute_ctrl → DE/EX Register → Execute Stage
memory_ctrl → EX/MEM Register → Memory Stage
writeback_ctrl → MEM/WB Register → Writeback Stage
```

### Feedback Signals

- `isSwap_from_execute`: EXECUTE → Decoder (SWAP handling)
- `override_operation/type`: Interrupt Unit → Decoder (forced ops)

## Testing

The testbench (`testbench_decoder.vhd`) verifies:

1. All 26 normal instructions
2. Correct control signal generation for each
3. Override operations (PUSH/POP PC/FLAGS)
4. SWAP two-cycle behavior
5. Default value safety

## Files

- `opcode_decoder.vhd` - Main decoder logic
- `pkg_opcodes.vhd` - Opcode and constant definitions
- `control_signals_pkg.vhd` - Control signal records and defaults
- `testbench_decoder.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Notes

- Pure combinational logic
- Zero-cycle decode latency
- Organized using VHDL records
- Supports complex multi-cycle operations
- Foundation for entire control unit
