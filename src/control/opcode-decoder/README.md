# Opcode Decoder

## Overview

The Opcode Decoder is the central control signal generator for the 5-stage pipelined processor. It decodes instruction opcodes and generates all necessary control signals for each pipeline stage.

## Purpose

- Decode 5-bit opcodes into control signals
- Generate signals for all pipeline stages (DE, EX, MEM, WB)
- Handle override operations for interrupt processing
- Support SWAP instruction as two-cycle operation
- Provide instruction type detection for other units

## Architecture

### Entity Interface

```vhdl
Inputs:
  - opcode [4:0]              : Instruction opcode
  - override_operation        : Force specific operation (from interrupt unit)
  - override_type [1:0]       : Type of forced operation
  - isSwap_from_execute       : SWAP second cycle feedback
  - take_interrupt            : Hardware interrupt signal (from interrupt unit)
  - is_hardware_int_mem       : Hardware interrupt flag in memory stage
  - requireImmediate          : Signal from execute for immediate handling

Outputs (Records):
  - decode_ctrl    : Decode stage control signals
  - execute_ctrl   : Execute stage control signals
  - memory_ctrl    : Memory stage control signals
  - writeback_ctrl : Writeback stage control signals

Outputs (Instruction Type Detection):
  - is_jmp_out             : Unconditional jump detected
  - is_jmp_conditional_out : Conditional jump detected (JZ/JN/JC)
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
| 00110  | IN Rdst       | Rdst = InPort   | OutBSelect=INPUT_PORT         |
| 00111  | MOV Rs1,Rdst  | Rdst = Rs1      | ALU_OP=PASS_A, RegWrite=1     |
| 01000  | SWAP Rs1,Rdst | Exchange values | IsSwap=1, Two-cycle operation |

### Memory Operations

| Opcode | Instruction      | Operation          | Signals                         |
| ------ | ---------------- | ------------------ | ------------------------------- |
| 01101  | PUSH Rdst        | SP--, MEM[SP]=Rdst | SP_En=1, SP_Func=0, MemWrite=1  |
| 01110  | POP Rdst         | Rdst=MEM[SP], SP++ | SP_En=1, SP_Func=1, MemRead=1   |
| 01111  | LDM Rdst,Imm     | Rdst = Imm         | PassImm=1, RegWrite=1           |
| 10000  | LDD Rdst,off(Rs) | Rdst = MEM[Rs+off] | PassImm=1, MemRead=1, PassMem=1 |
| 10001  | STD Rs1,off(Rs2) | MEM[Rs2+off] = Rs1 | PassImm=1, MemWrite=1           |

### Control Flow

| Opcode | Instruction | Operation             | Signals                   |
| ------ | ----------- | --------------------- | ------------------------- |
| 10010  | JZ Imm      | Jump if Zero          | IsJMPCond=1, CCR_WE=1     |
| 10011  | JN Imm      | Jump if Negative      | IsJMPCond=1, CCR_WE=1     |
| 10100  | JC Imm      | Jump if Carry         | IsJMPCond=1, CCR_WE=1     |
| 10101  | JMP Imm     | Unconditional Jump    | IsJMP=1                   |
| 10110  | CALL Imm    | Push PC, Jump         | IsCall=1, IsJMP=1         |
| 10111  | RET         | Pop PC, Jump          | IsReturn=1                |
| 11000  | INT index   | Software Interrupt    | IsInterrupt=1, PassInt=SW |
| 11001  | RTI         | Return from Interrupt | IsReti=1                  |

### Special

| Opcode | Instruction | Operation      | Signals               |
| ------ | ----------- | -------------- | --------------------- |
| 00000  | NOP         | No Operation   | All defaults          |
| 00001  | HLT         | Halt           | IsHLT=1               |
| 00010  | SETC        | Set Carry Flag | ALU_OP=SETC, CCR_WE=1 |

## Override Operations

Used by Interrupt Unit to force specific operations:

| Override Type         | Purpose               | Signals Generated            |
| --------------------- | --------------------- | ---------------------------- |
| `OVERRIDE_PUSH_PC`    | Push PC to stack      | SP_En=1, MemWrite=1          |
| `OVERRIDE_PUSH_FLAGS` | Push CCR to stack     | SP_En=1, MemWrite=1, PassCCR |
| `OVERRIDE_POP_FLAGS`  | Pop CCR from stack    | SP_En=1, MemRead=1, MemToCCR |
| `OVERRIDE_NOP`        | No operation (bubble) | All defaults                 |

## SWAP Two-Cycle Operation

1. **Cycle 1**: SWAP opcode detected

   - Acts as MOV Rsrc1 → Rdst (via ALU_PASS_B)
   - Sets `decode_ctrl.IsSwap = '1'`
   - Signal propagates to memory stage

2. **Cycle 2**: `isSwap_from_execute = '1'`
   - Decoder generates second MOV (ALU_PASS_A)
   - Register addresses swapped by datapath

## Conditional Jump Handling

Conditional jumps (JZ, JN, JC) set:

- `IsJMPConditional = '1'`
- `RequireImmediate = '1'`
- `CCR_WriteEnable = '1'` (for flag reset after jump)
- `ConditionalType` to specify which flag to check

## Instruction Type Detection Outputs

Two combinational outputs for other control units:

- `is_jmp_out`: Active when opcode is JMP
- `is_jmp_conditional_out`: Active when opcode is JZ, JN, or JC

## Files

- `opcode_decoder.vhd` - Main decoder logic
- `README.md` - This documentation

## Notes

- Pure combinational logic
- Zero-cycle decode latency
- Override operations have highest priority (over SWAP feedback)
- SWAP feedback has priority over normal decoding
- Hardware interrupt (take_interrupt) generates interrupt signals
