# Branch Decision Unit

## Overview

The Branch Decision Unit makes final branch decisions, handles pipeline flushes, and coordinates branch target selection with proper priority handling for interrupts, returns, and branches.

## Purpose

- Make final branch/no-branch decision
- Determine correct branch target source
- Handle priority between reset, interrupts, returns, and branches
- Generate appropriate pipeline flush signals

## Architecture

### Priority-Based Decision Logic

```
Priority (Highest to Lowest):
1. Reset
2. Hardware Interrupt / Software Interrupt / RTI / RET
3. CALL / Unconditional Branch (JMP)
4. Conditional Branch (when condition is true)
```

### Inputs

| Signal                | Width | Source           | Description                          |
| --------------------- | ----- | ---------------- | ------------------------------------ |
| `Reset`               | 1     | System           | Reset signal (highest priority)      |
| `IsHardwareInterrupt` | 1     | Interrupt Unit   | Hardware interrupt active            |
| `IsSoftwareInterrupt` | 1     | Decode Stage     | Software interrupt (INT) active      |
| `IsRTI`               | 1     | Memory Stage     | Return from interrupt                |
| `IsReturn`            | 1     | Memory Stage     | RET instruction (PC from stack)      |
| `IsCall`              | 1     | Decode Stage     | CALL instruction                     |
| `UnconditionalBranch` | 1     | Decode Stage     | Unconditional jump (JMP)             |
| `ConditionalBranch`   | 1     | Execute Stage    | Conditional branch being resolved    |
| `PredictedTaken`      | 1     | Branch Predictor | Predicted outcome (unused in static) |
| `ActualTaken`         | 1     | Execute Stage    | Actual condition evaluation result   |

### Outputs

| Signal                     | Width | Destination | Description                                  |
| -------------------------- | ----- | ----------- | -------------------------------------------- |
| `BranchSelect`             | 1     | PC Mux      | '0' = PC+1 (sequential), '1' = branch target |
| `BranchTargetSelect [1:0]` | 2     | Target Mux  | Select branch target source                  |

### Branch Target Select Encoding

| Value | Constant       | Source                 | Usage                                     |
| ----- | -------------- | ---------------------- | ----------------------------------------- |
| 00    | TARGET_DECODE  | Immediate from DECODE  | CALL, JMP (unconditional branches)        |
| 01    | TARGET_EXECUTE | Immediate from EXECUTE | Resolved conditional branches             |
| 10    | TARGET_MEMORY  | Address from MEMORY    | Interrupts, RET, RTI (address from stack) |

## Operation Scenarios

### 1. Reset

**Priority**: Highest

```
Input:  Reset = '1'
Output: BranchSelect = '0' (neutral during reset)
        BranchTargetSelect = TARGET_DECODE
        (PC module handles reset internally)
```

### 2. Hardware/Software Interrupt, RTI, or RET

**Priority**: 2nd highest

```
Input:  IsHardwareInterrupt = '1' OR IsSoftwareInterrupt = '1'
        OR IsRTI = '1' OR IsReturn = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = TARGET_MEMORY ("10")
```

- Branch to address from memory stage (interrupt vector or return address)

### 3. CALL or Unconditional Branch (JMP)

**Priority**: 3rd

```
Input:  IsCall = '1' OR UnconditionalBranch = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = TARGET_DECODE ("00")
```

- Branch to immediate address from decode stage

### 4. Conditional Branch (when actually taken)

**Priority**: 4th (static prediction - always predict not-taken)

```
Input:  ConditionalBranch = '1' AND ActualTaken = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = TARGET_EXECUTE ("01")
```

- Static prediction: always predict not-taken
- When actually taken, flush and redirect

### 5. No Branch

```
Input:  No branch conditions active
        OR ConditionalBranch = '1' AND ActualTaken = '0'
Output: BranchSelect = '0'
        BranchTargetSelect = TARGET_DECODE (don't care)
```

## Static vs Dynamic Prediction

The current implementation uses **static prediction** (always predict not-taken):

- Simpler implementation
- Conditional branches resolved in execute stage
- Dynamic prediction code is commented but available for future use

## Integration

### Signal Flow

```
Interrupt Unit → IsHardwareInterrupt/IsSoftwareInterrupt ─┐
Memory Stage → IsRTI/IsReturn ────────────────────────────┤
Decode Stage → IsCall/UnconditionalBranch ────────────────┼──→ Branch Decision Unit
Execute Stage → ConditionalBranch/ActualTaken ────────────┤               ↓
Branch Predictor → PredictedTaken ────────────────────────┘        Decision Logic
                                                                         ↓
                                                         ┌───────────────┴────────────────┐
                                                         ↓                                ↓
                                                   BranchSelect                  BranchTargetSelect
                                                         ↓                                ↓
                                                      PC Mux                       Target Address Mux
```

## Design Decisions

### Why Priority-Based?

- **Clear precedence**: Reset > Interrupts/Returns > Branches
- **Deterministic**: No ambiguity when multiple conditions occur
- **Simple logic**: Priority encoder, easy to verify

### Static Prediction Strategy

- Always predict not-taken for conditional branches
- Branch resolution happens in execute stage
- If taken, flush IF and DE stages
- Simpler than dynamic prediction with good performance for short backward loops

## Files

- `branch_decision_unit.vhd` - Main decision logic
- `README.md` - This documentation

## Notes

- Pure combinational logic
- Critical path: Priority logic → output generation
- Coordinates with interrupt unit for proper interrupt/return handling
- Reset handled internally by PC module (this unit outputs neutral signals)
