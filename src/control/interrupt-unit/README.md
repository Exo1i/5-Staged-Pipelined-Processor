# Interrupt Unit

## Overview

The Interrupt Unit manages all interrupt-related operations (software interrupts, hardware interrupts, RET, and RTI) by generating override signals to force push/pop operations and coordinating with the freeze control.

## Purpose

- Handle software interrupts (INT instruction)
- Handle hardware interrupts (external signal)
- Manage return instructions (RET)
- Manage interrupt returns (RTI)
- Generate override signals for forced push/pop operations
- Provide stall signals during interrupt processing
- Track interrupt flags through pipeline stages

## Architecture

### Inputs

#### From DECODE Stage

| Signal           | Description                           |
| ---------------- | ------------------------------------- |
| `IsInterrupt_DE` | Software/Hardware interrupt in decode |
| `IsRet_DE`       | RET instruction in decode             |
| `IsReti_DE`      | RTI instruction in decode             |

#### From DE/EX Pipeline Register (EXECUTE Stage)

| Signal           | Description                            |
| ---------------- | -------------------------------------- |
| `IsInterrupt_EX` | Software/Hardware interrupt in execute |
| `IsRet_EX`       | RET instruction in execute             |
| `IsReti_EX`      | RTI instruction in execute             |

#### From EX/MEM Pipeline Register (MEMORY Stage)

| Signal              | Description                       |
| ------------------- | --------------------------------- |
| `IsInterrupt_MEM`   | Interrupt in memory stage         |
| `IsReti_MEM`        | RTI in memory stage               |
| `IsRet_MEM`         | RET in memory stage               |
| `IsHardwareInt_MEM` | Hardware interrupt flag in memory |

#### External

| Signal              | Description                        |
| ------------------- | ---------------------------------- |
| `HardwareInterrupt` | External hardware interrupt signal |

### Outputs

| Signal                 | Destination    | Description                                        |
| ---------------------- | -------------- | -------------------------------------------------- |
| `freeze_fetch`         | Freeze Control | '1' = freeze fetch during interrupt/ret processing |
| `memory_hazard`        | Hazard Unit    | '1' = memory hazard due to interrupt/ret in memory |
| `PassPC_NotPCPlus1`    | Fetch Stage    | '0' = pass current PC (for hardware interrupt)     |
| `TakeInterrupt`        | IF/DE Register | '1' = treat next instruction as interrupt          |
| `IsHardwareIntMEM_Out` | Opcode Decoder | Hardware interrupt flag from memory stage          |
| `OverrideOperation`    | Opcode Decoder | '1' = enable override decoding                     |
| `OverrideType [1:0]`   | Opcode Decoder | Type of forced operation                           |

## Operation Sequences

### Software Interrupt (INT)

```
Cycle 1: INT in EXECUTE stage (IsInterrupt_EX = '1')
  - Override = PUSH_FLAGS
  - freeze_fetch = '1'

Cycle 2: INT in MEMORY stage (IsInterrupt_MEM = '1')
  - Override = PUSH_PC
  - memory_hazard = '1'
  - Fetch interrupt handler address from memory
```

### Hardware Interrupt

```
Cycle 0: External hardware interrupt arrives
  - TakeInterrupt = '1' (written to IF/DE register)
  - PassPC_NotPCPlus1 = '0' (save current PC, not next)

Subsequent cycles: Same as software interrupt
```

### Return from Interrupt (RTI)

```
Cycle 1: RTI in EXECUTE stage (IsReti_EX = '1')
  - Override = POP_FLAGS (restore flags first)
  - freeze_fetch = '1'

Cycle 2: RTI in MEMORY stage (IsReti_MEM = '1')
  - Override = NOP
  - memory_hazard = '1'
  - Return address fetched from stack
```

### Return (RET)

```
Cycle 1: RET in EXECUTE stage (IsRet_EX = '1')
  - Override = NOP
  - freeze_fetch = '1'

Cycle 2: RET in MEMORY stage (IsRet_MEM = '1')
  - Override = NOP
  - memory_hazard = '1'
```

## freeze_fetch Signal Generation

```vhdl
freeze_fetch <= IsInterrupt_EX   OR
                IsReti_MEM       OR IsReti_EX    OR
                IsRet_MEM        OR IsRet_EX     OR
                IsInterrupt_MEM  OR
                IsInterrupt_DE   OR IsReti_DE    OR
                IsRet_DE;
```

## memory_hazard Signal Generation

```vhdl
memory_hazard <= IsInterrupt_MEM OR
                 IsReti_MEM      OR
                 IsRet_MEM;
```

## Override Type Encoding

| Value | Constant            | Operation                  |
| ----- | ------------------- | -------------------------- |
| 00    | OVERRIDE_PUSH_PC    | Force push PC to stack     |
| 01    | OVERRIDE_PUSH_FLAGS | Force push FLAGS to stack  |
| 10    | OVERRIDE_POP_FLAGS  | Force pop FLAGS from stack |
| 11    | OVERRIDE_NOP        | No override operation      |

## Key Design Decisions

### Pipeline Propagation Tracking

- Signals move from DECODE → EXECUTE → MEMORY through pipeline registers
- First cycle detected by `*_EX` signal, second cycle by `*_MEM` signal
- No explicit state machine needed

### RTI Reverse Order

RTI pops in **reverse order** (FLAGS first, then PC):

```
INT:  PUSH PC    [SP--]    PC at lower address
      PUSH FLAGS [SP--]    FLAGS at lowest address

RTI:  POP FLAGS  [SP++]    Restore FLAGS first
      POP PC     [SP++]    Restore PC second
```

### Hardware Interrupt Handling

- `TakeInterrupt` written to IF/DE register tells decoder to generate interrupt signals
- `PassPC_NotPCPlus1 = '0'` ensures we save the **current** PC, not the next one
- `IsHardwareIntMEM_Out` passed to decoder for proper PassInterrupt encoding

## Integration

### Signal Flow

```
External HW Interrupt → Interrupt Unit → TakeInterrupt → IF/DE Register
                                       → PassPC_NotPCPlus1

Pipeline Stages (DE/EX/MEM) → Interrupt Unit → freeze_fetch → Freeze Control
                                             → memory_hazard → Hazard Control
                                             → Override signals → Opcode Decoder
```

## Files

- `interrupt_unit.vhd` - Main interrupt control logic
- `README.md` - This documentation

## Notes

- Pure combinational logic, no clock dependency
- Uses pipeline natural propagation instead of FSM
- Critical for interrupt response time
- Coordinates with opcode decoder via override mechanism
- Must maintain correct stack order for nested interrupts
