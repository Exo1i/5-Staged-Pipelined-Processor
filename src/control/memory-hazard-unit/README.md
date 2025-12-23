# Memory Hazard Unit

## Overview

The Memory Hazard Unit handles structural hazards in the Von Neumann architecture where instruction fetch and data memory operations share a single memory resource.

## Purpose

- Manage priority between instruction fetch (IF stage) and data memory access (MEM stage)
- Prevent simultaneous memory accesses from different pipeline stages
- Implement priority scheme: Memory stage > Fetch stage
- Generate control signals for memory access arbitration

## Architecture

### Inputs

| Signal         | Source       | Description                                     |
| -------------- | ------------ | ----------------------------------------------- |
| `MemRead_MEM`  | Memory Stage | '1' = Memory stage wants to read (Load, Pop)    |
| `MemWrite_MEM` | Memory Stage | '1' = Memory stage wants to write (Store, Push) |

### Outputs

| Signal         | Destination    | Description                                                  |
| -------------- | -------------- | ------------------------------------------------------------ |
| `PassPC`       | Freeze Control | '1' = fetch allowed, '0' = fetch blocked (structural hazard) |
| `MemRead_Out`  | Memory Block   | Actual read signal to memory                                 |
| `MemWrite_Out` | Memory Block   | Actual write signal to memory                                |

## Logic

### Priority Decision

```vhdl
-- Memory stage has higher priority than Fetch stage
PassPC <= not (MemRead_MEM or MemWrite_MEM);

-- Pass memory stage signals directly
MemRead_Out  <= MemRead_MEM;
MemWrite_Out <= MemWrite_MEM;
```

### Signal Flow

```
Memory Stage Control → MemRead_MEM, MemWrite_MEM
                              ↓
                    Memory Hazard Unit
                    (Priority Logic)
                              ↓
            ┌─────────────────┴──────────────────┐
            ↓                                    ↓
    PassPC → Freeze Control          MemRead/Write_Out → Memory Block
```

## Structural Hazard Scenarios

### Scenario 1: Memory Stage Idle

- **Memory Stage**: NOP, arithmetic, branch, etc.
- **Effect**: `PassPC = '1'`, fetch proceeds normally
- **Cycles**: No stall

### Scenario 2: Load Instruction (LDD, POP)

- **Memory Stage**: Executing load operation
- **Effect**: `PassPC = '0'`, fetch stalled for 1 cycle
- **Memory Access**: Data read from memory
- **Cycles**: 1 cycle structural hazard stall

### Scenario 3: Store Instruction (STD, PUSH)

- **Memory Stage**: Executing store operation
- **Effect**: `PassPC = '0'`, fetch stalled for 1 cycle
- **Memory Access**: Data written to memory
- **Cycles**: 1 cycle structural hazard stall

## Integration

### Connections in Control Unit

```
Opcode Decoder → MemRead, MemWrite (to Memory stage)
                        ↓
                Memory Hazard Unit
                        ↓
                  PassPC → Freeze Control → PC_Freeze
```

### Pipeline Impact

When `PassPC = '0'`:

1. Freeze Control receives signal
2. PC register frozen (`PC_Freeze = '1'`)
3. Bubble inserted into pipeline
4. Fetch retries same instruction next cycle

## Design Decisions

### Why Memory Stage > Fetch Stage?

- Memory operations are committed (already in pipeline)
- Fetch can be retried without consequence
- Simpler control logic
- Better performance (fewer wasted cycles)

## Files

- `memory_hazard_unit.vhd` - Main hazard detection logic
- `README.md` - This documentation

## Notes

- Pure combinational logic (no state needed)
- Zero-cycle latency for hazard detection
- Critical for Von Neumann architecture correctness
- Simple OR-based logic for hazard detection
