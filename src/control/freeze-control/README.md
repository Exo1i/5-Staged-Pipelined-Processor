# Freeze Control Unit

## Overview

The Freeze Control Unit manages pipeline stalls by combining multiple stall conditions from different sources and generating appropriate freeze signals for the fetch stage and PC register.

## Purpose

- Coordinates pipeline freezing across multiple hazard sources
- Prevents PC from advancing during stalls
- Inserts NOP bubbles into the pipeline when necessary
- Ensures fetch stage waits until hazards are resolved

## Architecture

### Inputs

| Signal            | Source             | Description                                                       |
| ----------------- | ------------------ | ----------------------------------------------------------------- |
| `PassPC_MEM`      | Memory Hazard Unit | '1' = fetch allowed, '0' = memory conflict, stall fetch           |
| `Stall_Interrupt` | Interrupt Unit     | '1' = freeze during interrupt processing until new PC from memory |
| `Stall_Branch`    | Branch Control     | '1' = stall for branch misprediction (optional)                   |

### Outputs

| Signal             | Destination             | Description                                     |
| ------------------ | ----------------------- | ----------------------------------------------- |
| `PC_WriteEnable`   | PC Register             | '1' = allow PC update, '0' = freeze PC          |
| `IFDE_WriteEnable` | IF/DE Pipeline Register | '1' = update register, '0' = hold current value |
| `InsertNOP_IFDE`   | IF/DE Stage Mux         | '1' = insert NOP bubble, '0' = pass instruction |

## Logic

### Stall Combination

```
any_stall = (NOT PassPC_MEM) OR Stall_Interrupt OR Stall_Branch
```

### Output Generation

When **any stall is active**:

- `PC_WriteEnable = '0'` → PC frozen
- `IFDE_WriteEnable = '0'` → IF/DE register frozen
- `InsertNOP_IFDE = '1'` → Bubble inserted

When **no stalls**:

- `PC_WriteEnable = '1'` → PC updates normally
- `IFDE_WriteEnable = '1'` → IF/DE register updates
- `InsertNOP_IFDE = '0'` → Normal instruction passes

## Stall Scenarios

### 1. Memory Hazard Stall

- **Cause**: Memory stage needs memory (Load/Store/Push/Pop)
- **Effect**: Fetch cannot access memory (Von Neumann architecture)
- **Duration**: Until memory stage completes operation

### 2. Interrupt Stall

- **Cause**: Processing interrupt (INT, Hardware interrupt, CALL, RET, RTI)
- **Effect**: Freeze fetch until new PC value arrives from memory stage
- **Duration**: Multiple cycles for interrupt handler address fetch

### 3. Branch Stall (Optional)

- **Cause**: Branch misprediction or branch resolution
- **Effect**: Freeze fetch until correct branch target known
- **Duration**: Depends on branch prediction mechanism

## Integration

### Connections

```
Memory Hazard Unit → PassPC_MEM → Freeze Control
Interrupt Unit → Stall_Interrupt → Freeze Control
Branch Control → Stall_Branch → Freeze Control

Freeze Control → PC_WriteEnable → PC Register
Freeze Control → IFDE_WriteEnable → IF/DE Pipeline Register
Freeze Control → InsertNOP_IFDE → IF/DE Stage Mux
```

### Usage in Control Unit

The Freeze Control sits between hazard detection units and the pipeline registers, acting as a central coordinator for all pipeline stalls.

## Testing

The testbench (`tb_freeze_control.vhd`) verifies:

1. Normal operation (no stalls)
2. Individual stall sources
3. Multiple simultaneous stalls
4. Return to normal operation
5. Rapid transitions between states

## Files

- `freeze_control.vhd` - Main freeze control logic
- `tb_freeze_control.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Notes

- Simple combinational logic (no state machine needed)
- All stall sources are OR'd together
- Any single stall source can freeze the entire fetch stage
- Critical path for pipeline performance
