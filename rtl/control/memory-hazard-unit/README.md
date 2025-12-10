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

```
memory_stage_needs_mem = MemRead_MEM OR MemWrite_MEM

IF memory_stage_needs_mem = '1' THEN
    PassPC = '0'  (Block fetch, structural hazard)
    Pass memory stage signals to memory
ELSE
    PassPC = '1'  (Allow fetch)
    Memory idle
END IF
```

### Signal Flow

```
Memory Stage Control → MemRead_MEM, MemWrite_MEM
                              ↓
                    Memory Hazard Unit
                    (Priority Logic)
                              ↓
            ┌─────────────────┴──────────────────┐
            ↓                                     ↓
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

### Scenario 4: Back-to-Back Memory Operations

- **Sequence**: Load → Store → Load
- **Effect**: Fetch stalled for 3 consecutive cycles
- **Impact**: Pipeline throughput reduced

## Performance Impact

### CPI Calculation

For a program with **X%** memory operations:

- **Base CPI**: 1 (ideal pipeline)
- **Structural hazard penalty**: X% × 1 cycle
- **Effective CPI**: 1 + (X/100)

Example: 30% memory operations → CPI = 1.3

## Integration

### Connections in Control Unit

```
Opcode Decoder → MemRead, MemWrite (to Memory stage)
                        ↓
                Memory Hazard Unit
                        ↓
                  PassPC → Freeze Control → PC_WriteEnable
```

### Pipeline Impact

When `PassPC = '0'`:

1. Freeze Control receives signal
2. PC register frozen (`PC_WriteEnable = '0'`)
3. IF/DE register frozen (`IFDE_WriteEnable = '0'`)
4. NOP inserted into pipeline (`InsertNOP_IFDE = '1'`)
5. Fetch retries same instruction next cycle

## Design Decisions

### Why Memory Stage > Fetch Stage?

- Memory operations are committed (already in pipeline)
- Fetch can be retried without consequence
- Simpler control logic
- Better performance (fewer wasted cycles)

### Alternative: Separate Instruction and Data Memory

- **Harvard Architecture**: Eliminates structural hazards
- **Trade-off**: Requires more hardware, less flexible
- **Not used**: Von Neumann architecture specified

## Testing

The testbench (`tb_memory_hazard_unit.vhd`) verifies:

1. Idle state (no memory operation)
2. Read operation (PassPC blocking)
3. Write operation (PassPC blocking)
4. Both signals active (edge case)
5. Rapid transitions
6. Signal propagation correctness

## Files

- `memory_hazard_unit.vhd` - Main hazard detection logic
- `tb_memory_hazard_unit.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Notes

- Pure combinational logic (no state needed)
- Zero-cycle latency for hazard detection
- Critical for Von Neumann architecture correctness
- Contributes to overall pipeline stall rate
