# Interrupt Unit

## Overview

The Interrupt Unit manages all interrupt-related operations (software interrupts, hardware interrupts, CALL/RET, and RTI) by generating override signals to force push/pop operations and coordinating with the freeze control.

## Purpose

- Handle software interrupts (INT instruction)
- Handle hardware interrupts (external signal)
- Manage subroutine calls (CALL/RET)
- Manage interrupt returns (RTI)
- Generate override signals for forced push/pop operations
- Provide stall signals during interrupt processing

## Architecture

### Combinational Logic (No State Machine)

The unit uses **combinational logic** based on signals from DECODE and EXECUTE stages. The key insight is using pipeline propagation to distinguish between first and second cycles of two-cycle operations.

### Inputs

#### From DECODE Stage

| Signal             | Description                                 |
| ------------------ | ------------------------------------------- |
| `IsInterrupt_DE`   | Software/Hardware interrupt in decode stage |
| `IsHardwareInt_DE` | Hardware interrupt flag in decode stage     |
| `IsCall_DE`        | CALL instruction in decode stage            |
| `IsReturn_DE`      | RET instruction in decode stage             |
| `IsReti_DE`        | RTI instruction in decode stage             |

#### From DE/EX Pipeline Register (EXECUTE Stage)

| Signal             | Description                                     |
| ------------------ | ----------------------------------------------- |
| `IsInterrupt_EX`   | Software/Hardware interrupt in execute stage    |
| `IsHardwareInt_EX` | Hardware interrupt flag in execute stage        |
| `IsReti_EX`        | RTI instruction in execute stage (second cycle) |

#### From EX/MEM Pipeline Register (MEMORY Stage)

| Signal              | Description                             |
| ------------------- | --------------------------------------- |
| `IsHardwareInt_MEM` | Hardware interrupt flag in memory stage |

#### External

| Signal              | Description                        |
| ------------------- | ---------------------------------- |
| `HardwareInterrupt` | External hardware interrupt signal |

### Outputs

| Signal                 | Destination    | Description                                              |
| ---------------------- | -------------- | -------------------------------------------------------- |
| `Stall`                | Freeze Control | '1' = freeze fetch and PC during interrupt processing    |
| `PassPC_NotPCPlus1`    | Fetch Stage    | '1' = save current PC (not PC+1) for hardware interrupts |
| `TakeInterrupt`        | IF/DE Register | '1' = treat as interrupt (for hardware interrupts)       |
| `IsHardwareIntMEM_Out` | Opcode Decoder | Hardware interrupt flag in memory stage                  |
| `OverrideOperation`    | Opcode Decoder | '1' = override normal decoding                           |
| `OverrideType [1:0]`   | Opcode Decoder | Type of forced operation                                 |

## Operation Sequences

### Software Interrupt (INT)

```
Cycle 1: INT in DECODE stage
  - IsInterrupt_DE = '1'
  - Override = PUSH_PC
  - Stall = '1'

Cycle 2: INT in EXECUTE stage (via DE/EX register)
  - IsInterrupt_EX = '1'
  - Override = PUSH_FLAGS
  - Stall = '1'

Cycle 3+: Fetch interrupt handler address from memory, branch
```

### Hardware Interrupt

```
Cycle 0: External hardware interrupt signal arrives
  - HardwareInterrupt = '1'
  - TakeInterrupt = '1' (written to IF/DE register)
  - PassPC_NotPCPlus1 = '1' (save current PC, not next)

Cycle 1: TakeInterrupt in DECODE stage
  - Opcode decoder sees take_interrupt = '1'
  - Sets IsInterrupt = '1', IsHardwareInterrupt = '1'
  - Signals propagate through pipeline

Cycle 2: Hardware interrupt in EXECUTE stage
  - IsInterrupt_EX = '1', IsHardwareInt_EX = '1'
  - Override = PUSH_PC
  - Stall = '1'

Cycle 3: Hardware interrupt in MEMORY stage
  - IsInterrupt_MEM = '1', IsHardwareInt_MEM = '1'
  - Override = PUSH_FLAGS
  - PassInterrupt = PASS_INT_HARDWARE (fetch from hardware vector)
  - Stall = '1'

Cycle 4+: Fetch interrupt handler address from hardware vector, branch
```

### Return from Interrupt (RTI)

```
Cycle 1: RTI in DECODE stage
  - IsReti_DE = '1'
  - Override = POP_FLAGS (opposite order from INT!)
  - Stall = '1'

Cycle 2: RTI in EXECUTE stage
  - IsReti_EX = '1'
  - Override = POP_PC
  - Stall = '1'

Cycle 3+: Branch to restored PC
```

**Important**: RTI pops in **reverse order** (FLAGS first, then PC) compared to how INT pushes (PC first, then FLAGS). This ensures correct stack ordering.

### Call (CALL)

```
Single-cycle operation:
  - IsCall_DE = '1'
  - Override = PUSH_PC
  - Stall = '1'
  - Branch handled separately
```

### Return (RET)

```
Single-cycle operation:
  - IsReturn_DE = '1'
  - Override = POP_PC
  - Stall = '1'
  - Branch to popped PC
```

## Override Type Encoding

| Value | Constant            | Operation                  |
| ----- | ------------------- | -------------------------- |
| 01    | OVERRIDE_PUSH_PC    | Force push PC to stack     |
| 10    | OVERRIDE_PUSH_FLAGS | Force push FLAGS to stack  |
| 11    | OVERRIDE_POP_PC     | Force pop PC from stack    |
| 11    | OVERRIDE_POP_FLAGS  | Force pop FLAGS from stack |

Note: POP_PC and POP_FLAGS share the same encoding; context (source signal) distinguishes them.

## Logic Flow

### Priority Logic

```
if HardwareInterrupt then
    PUSH_PC, TakeInterrupt='1', PassPC_NotPCPlus1='1'
elsif IsInterrupt_DE then
    PUSH_PC (first cycle of INT)
elsif IsInterrupt_EX then
    PUSH_FLAGS (second cycle of INT)
elsif IsReti_DE then
    POP_FLAGS (first cycle of RTI - reverse order!)
elsif IsReti_EX then
    POP_PC (second cycle of RTI)
elsif IsCall_DE then
    PUSH_PC (single cycle)
elsif IsReturn_DE then
    POP_PC (single cycle)
end if
```

### Stall Signal

```
Stall = IsInterrupt_DE OR IsInterrupt_EX OR
        IsReti_DE OR IsReti_EX OR
        IsCall_DE OR IsReturn_DE OR
        HardwareInterrupt
```

## Key Design Decisions

### Why No State Machine?

- **Pipeline propagation** naturally provides state tracking
- Signals move from DECODE → EXECUTE through pipeline registers
- First cycle detected by `*_DE` signal, second cycle by `*_EX` signal
- Simpler design, no explicit state tracking needed

### Hardware Interrupt Special Handling

- **TakeInterrupt**: Written to IF/DE register, tells decoder to generate IsInterrupt signal
- **PassPC_NotPCPlus1**: Ensures we save the **current** PC (of interrupted instruction), not the next one
- **IsHardwareInt_MEM**: Propagated to memory stage to distinguish hardware vs software interrupt for PassInterrupt signal
- Hardware interrupt can occur asynchronously, so current instruction hasn't completed
- Hardware interrupt follows same 2-cycle push sequence (PUSH_PC, PUSH_FLAGS) as software interrupt
- **PassInterrupt signal** (2-bit):
  - `00` = Normal address from EX/MEM
  - `01` = Reset vector (address 0)
  - `10` = Software interrupt (from immediate value)
  - `11` = Hardware interrupt (fixed vector, e.g., address 1)

```
INT:  PUSH PC    [SP--]    PC at lower address
      PUSH FLAGS [SP--]    FLAGS at lowest address

RTI:  POP FLAGS  [SP++]    Restore FLAGS first
      POP PC     [SP++]    Restore PC second
```

This maintains LIFO (Last In, First Out) semantics.

### Hardware Interrupt Special Handling

### Signal Flow

```
External HW Interrupt → Interrupt Unit → TakeInterrupt → IF/DE Register
                                       → PassPC_NotPCPlus1
                                                ↓
DECODE Stage → IsInterrupt_DE, IsHardwareInt_DE → Interrupt Unit
                                                       ↓
DE/EX Register → IsInterrupt_EX, IsHardwareInt_EX → Interrupt Unit
                                                       ↓
EX/MEM Register → IsHardwareInt_MEM → Interrupt Unit → IsHardwareIntMEM_Out
                                                       ↓
Interrupt Unit → Stall → Freeze Control → PC, IF/DE control
               → Override signals → Opcode Decoder → Forced operations
               → IsHardwareIntMEM_Out → Opcode Decoder → PassInterrupt selection
```

DECODE Stage → IsInterrupt_DE, IsCall_DE, etc. → Interrupt Unit
↓
DE/EX Register → IsInterrupt_EX, IsReti_EX → Interrupt Unit
↓
Interrupt Unit → Stall → Freeze Control → PC, IF/DE control
→ Override signals → Opcode Decoder → Forced operations

```

### Freeze Control Integration

Special freeze behavior during interrupts:

- **Insert NOP** to IF/DE stage (InsertNOP_IFDE = '1')
- **Disable PC update** (PC_WriteEnable = '0')
- **BUT keep IF/DE register enabled** (IFDE_WriteEnable = '1') - Different from memory hazards!

This allows the interrupt signals to propagate through the pipeline properly.

## Testing

The testbench (`tb_interrupt_unit.vhd`) verifies:

1. Normal operation (no interrupts)
2. Software interrupt two-cycle sequence
3. Hardware interrupt with special signals
4. RTI two-cycle sequence (reverse order)
5. CALL single-cycle operation
6. RET single-cycle operation
7. Priority handling (hardware > software)
8. Complete INT sequence simulation
9. Complete RTI sequence simulation with reverse order verification

## Performance Impact

- **INT/RTI**: 2-cycle overhead for stack operations + handler fetch
- **CALL/RET**: 1-cycle overhead for stack operation + branch
- **Hardware Interrupt**: 2-cycle overhead + interrupt latency

## Files

- `interrupt_unit.vhd` - Main interrupt control logic
- `tb_interrupt_unit.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Notes

- Pure combinational logic, no clock dependency
- Uses pipeline natural propagation instead of FSM
- Critical for interrupt response time
- Coordinates with opcode decoder via override mechanism
- Must maintain correct stack order for nested interrupts
```
