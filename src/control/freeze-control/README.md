# Freeze Control Unit

## Overview

The Freeze Control Unit manages pipeline stalls by combining multiple stall conditions from different sources and generating appropriate freeze signals for the fetch stage, PC register, and decode stage.

## Purpose

- Coordinates pipeline freezing across multiple hazard sources
- Prevents PC from advancing during stalls
- Inserts NOP bubbles into the pipeline when necessary
- Handles branch flushing with appropriate pipeline stage NOPs
- Supports HLT instruction by freezing the pipeline

## Architecture

### Inputs

| Signal               | Width | Source             | Description                                |
| -------------------- | ----- | ------------------ | ------------------------------------------ |
| `PassPC_MEM`         | 1     | Memory Hazard Unit | '0' = memory conflict, stall fetch         |
| `Stall_Interrupt`    | 1     | Interrupt Unit     | '1' = freeze during interrupt processing   |
| `BranchSelect`       | 1     | Branch Decision    | '1' = branch taken, need to flush          |
| `BranchTargetSelect` | 2     | Branch Decision    | Target mux select (determines flush depth) |
| `is_swap`            | 1     | Decode Stage       | '1' = SWAP operation in progress           |
| `is_hlt`             | 1     | Decode Stage       | '1' = HLT instruction, halt pipeline       |
| `requireImmediate`   | 1     | Decode Stage       | '1' = instruction needs immediate value    |
| `memory_hazard_int`  | 1     | Interrupt Unit     | '1' = memory hazard due to interrupt       |

### Outputs

| Signal             | Destination             | Description                                     |
| ------------------ | ----------------------- | ----------------------------------------------- |
| `PC_Freeze`        | PC Register             | '1' = freeze PC, '0' = allow PC update          |
| `IFDE_WriteEnable` | IF/DE Pipeline Register | '1' = update register, '0' = hold current value |
| `InsertNOP_IFDE`   | IF/DE Stage Mux         | '1' = insert NOP bubble, '0' = pass instruction |
| `InsertNOP_DEEX`   | DE/EX Stage Mux         | '1' = insert NOP in DE/EX stage                 |

## Logic

### HLT Instruction Handling (Highest Priority)

When `is_hlt = '1'`:

- `PC_Freeze = '1'` → PC frozen
- `IFDE_WriteEnable = '0'` → IF/DE register frozen
- `InsertNOP_DEEX = '1'` → NOP inserted in DE/EX stage

### Interrupt Stall Handling

When `Stall_Interrupt = '1'`:

- `IFDE_WriteEnable = '0'` → IF/DE register frozen

### SWAP Instruction Handling

When `is_swap = '1'`:

- `PC_Freeze = '1'` → PC frozen for second cycle
- `IFDE_WriteEnable = '0'` → Hold current instruction

### Branch Flush Handling

When `BranchSelect = '1'`:

- `IFDE_WriteEnable = '1'` → Allow IF/DE update
- `InsertNOP_IFDE = '1'` → Flush IF stage with NOP
- If `BranchTargetSelect = TARGET_EXECUTE`:
  - `InsertNOP_DEEX = '1'` → Also flush DE stage

### Memory Hazard Handling

When `PassPC_MEM = '0'`:

- `PC_Freeze = '1'` → PC frozen
- `InsertNOP_IFDE = '1'` → Insert bubble
- If `requireImmediate = '1'`:
  - `IFDE_WriteEnable = '0'` → Hold immediate instruction
  - `InsertNOP_DEEX = '1'` → Insert NOP in DE/EX

## Stall Scenarios

### 1. Memory Hazard Stall

- **Cause**: Memory stage needs memory (Load/Store/Push/Pop)
- **Effect**: Fetch cannot access memory (Von Neumann architecture)
- **Duration**: Until memory stage completes operation

### 2. Interrupt Stall

- **Cause**: Processing interrupt (INT, Hardware interrupt, CALL, RET, RTI)
- **Effect**: Freeze fetch until new PC value arrives from memory stage
- **Duration**: Multiple cycles for interrupt handler address fetch

### 3. SWAP Stall

- **Cause**: SWAP instruction requires two cycles
- **Effect**: Freeze PC and IF/DE for second swap cycle
- **Duration**: 1 cycle

### 4. HLT Stall

- **Cause**: HLT instruction executed
- **Effect**: Complete pipeline freeze until reset
- **Duration**: Until system reset

### 5. Branch Flush

- **Cause**: Branch taken or misprediction
- **Effect**: Flush pipeline stages with NOPs
- **Duration**: 1-2 cycles (depends on branch type)

## Integration

### Connections

```
Memory Hazard Unit → PassPC_MEM → Freeze Control
Interrupt Unit → Stall_Interrupt → Freeze Control
Branch Decision → BranchSelect/BranchTargetSelect → Freeze Control
Decode Stage → is_swap, is_hlt, requireImmediate → Freeze Control

Freeze Control → PC_Freeze → PC Register
Freeze Control → IFDE_WriteEnable → IF/DE Pipeline Register
Freeze Control → InsertNOP_IFDE → IF/DE Stage Mux
Freeze Control → InsertNOP_DEEX → DE/EX Stage Mux
```

## Testing

The testbench verifies:

1. Normal operation (no stalls)
2. HLT instruction freeze behavior
3. SWAP two-cycle operation
4. Memory hazard stalling
5. Interrupt stalling
6. Branch flushing (IF only vs IF+DE)
7. Immediate instruction handling with memory hazard
8. Priority handling between conditions

## Files

- `freeze_control.vhd` - Main freeze control logic
- `README.md` - This documentation

## Notes

- Combinational logic with conditional priority
- HLT has highest priority (halts everything)
- Branch flushing respects target select for proper flush depth
- Memory hazard with immediate instructions requires special handling
