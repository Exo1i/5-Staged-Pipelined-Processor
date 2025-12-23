# Forwarding Unit

## Overview

The Forwarding Unit resolves data hazards by detecting when operands in the execute stage depend on results from instructions still in the pipeline, and selecting the most recent value.

## Purpose

- Detect Read-After-Write (RAW) data hazards
- Forward results from MEM and WB stages to execute stage
- Support forwarding for both operand A (Rsrc1) and operand B (Rsrc2)
- Handle SWAP instruction special case (disable forwarding during SWAP)
- Provide secondary forwarding path for store instructions

## Architecture

### Inputs

#### From Memory Stage (EX/MEM Pipeline Register)

| Signal        | Width | Description                              |
| ------------- | ----- | ---------------------------------------- |
| `MemRegWrite` | 1     | Register write enable in memory stage    |
| `MemRdst`     | 3     | Destination register in memory stage     |
| `MemIsSwap`   | 1     | SWAP instruction flag (disables forward) |

#### From Writeback Stage (MEM/WB Pipeline Register)

| Signal       | Width | Description                              |
| ------------ | ----- | ---------------------------------------- |
| `WBRegWrite` | 1     | Register write enable in writeback stage |
| `WBRdst`     | 3     | Destination register in writeback stage  |

#### From Execute Stage (Current Instruction)

| Signal         | Width | Description                |
| -------------- | ----- | -------------------------- |
| `ExRsrc1`      | 3     | Source register 1 address  |
| `ExRsrc2`      | 3     | Source register 2 address  |
| `ExOutBSelect` | 2     | Operand B source select    |
| `ExIsImm`      | 1     | Using immediate value flag |

### Outputs

| Signal             | Width | Description                             |
| ------------------ | ----- | --------------------------------------- |
| `ForwardA`         | 2     | Forwarding select for operand A (Rsrc1) |
| `ForwardB`         | 2     | Forwarding select for operand B (Rsrc2) |
| `ForwardSecondary` | 2     | Secondary forwarding for store data     |

### Forwarding Select Encoding

| Value | Constant       | Source                                           |
| ----- | -------------- | ------------------------------------------------ |
| 00    | FORWARD_NONE   | No forwarding, use register file value           |
| 01    | FORWARD_EX_MEM | Forward from EX/MEM pipeline register (1 cycle)  |
| 10    | FORWARD_MEM_WB | Forward from MEM/WB pipeline register (2 cycles) |

## Logic

### ForwardA (Operand A - Rsrc1)

```vhdl
IF MemRegWrite = '1' AND MemRdst = ExRsrc1 AND MemIsSwap = '0' THEN
    ForwardA <= FORWARD_EX_MEM;  -- From memory stage (priority)
ELSIF WBRegWrite = '1' AND WBRdst = ExRsrc1 THEN
    ForwardA <= FORWARD_MEM_WB;  -- From writeback stage
ELSE
    ForwardA <= FORWARD_NONE;    -- Use register file
END IF;
```

### ForwardB (Operand B - Rsrc2)

Only forwards when operand B comes from register file (not immediate):

```vhdl
IF ExOutBSelect = OUTB_REGFILE AND ExIsImm = '0' THEN
    -- Same priority logic as ForwardA for ExRsrc2
END IF;
```

### ForwardSecondary (Store Data Path)

Used for STD instruction where Rsrc2 provides memory address and separate path needed:

```vhdl
IF ExOutBSelect = OUTB_REGFILE THEN
    -- Forward for Rsrc2 data path
END IF;
```

## Priority Rules

1. **EX/MEM has priority over MEM/WB**: If same register is written in both stages, use the more recent value (from EX/MEM)
2. **SWAP disables forwarding**: When `MemIsSwap = '1'`, no forwarding from memory stage to prevent incorrect SWAP behavior
3. **Immediate disables ForwardB**: When using immediate value, no forwarding needed for operand B

## Data Hazard Examples

### Example 1: Simple RAW Hazard

```
ADD R1, R2, R3    ; Writes R1
SUB R4, R1, R5    ; Reads R1 - needs forwarding!
```

- ForwardA detects R1 dependency
- Forwards from EX/MEM stage

### Example 2: Two-Cycle Hazard

```
ADD R1, R2, R3    ; Writes R1 (now in WB)
NOP
SUB R4, R1, R5    ; Reads R1 - needs forwarding from WB
```

- ForwardA detects R1 in WB stage
- Forwards from MEM/WB stage

### Example 3: Immediate Instruction

```
ADD R1, R2, R3    ; Writes R1
IADD R4, R5, #10  ; Uses immediate - no forward needed for B
```

- ForwardB checks ExIsImm
- No forwarding since operand B is immediate

## Integration

### Signal Flow

```
EX/MEM Register → MemRegWrite, MemRdst, MemIsSwap ─┐
MEM/WB Register → WBRegWrite, WBRdst ──────────────┤
Execute Stage → ExRsrc1, ExRsrc2, ExOutBSelect ────┼──→ Forwarding Unit
                                                   │           ↓
                                                   └── ForwardA, ForwardB, ForwardSecondary
                                                                ↓
                                                    Execute Stage Muxes
```

## Files

- `forwarding_unit.vhd` - Main forwarding logic
- `README.md` - This documentation

## Notes

- Pure combinational logic (no clock)
- Three independent forward paths
- SWAP handling prevents incorrect register exchange
- Critical for maintaining single-cycle execution where possible
