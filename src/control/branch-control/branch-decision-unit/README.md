# Branch Decision Unit

## Overview

The Branch Decision Unit makes final branch decisions, handles mispredictions, manages pipeline flushes, and coordinates branch target selection with proper priority handling.

## Purpose

- Make final branch/no-branch decision
- Detect branch mispredictions
- Generate flush signals for pipeline stages
- Select appropriate branch target address
- Handle priority between interrupts, resets, and branches

## Architecture

### Priority-Based Decision Logic

```
Priority (Highest to Lowest):
1. Reset
2. Hardware Interrupt
3. Software Interrupt
4. Unconditional Branch (JMP, CALL)
5. Conditional Branch Misprediction
6. Conditional Branch (correct prediction)
```

### Inputs

| Signal                | Source           | Description                        |
| --------------------- | ---------------- | ---------------------------------- |
| `Reset`               | System           | Reset signal (highest priority)    |
| `IsHardwareInterrupt` | Interrupt Unit   | Hardware interrupt active          |
| `IsSoftwareInterrupt` | Interrupt Unit   | Software interrupt (INT) active    |
| `UnconditionalBranch` | Branch Predictor | Unconditional jump (JMP/CALL)      |
| `ConditionalBranch`   | Execute Stage    | Conditional branch being resolved  |
| `PredictedTaken`      | Branch Predictor | Predicted outcome                  |
| `ActualTaken`         | Execute Stage    | Actual condition evaluation result |

### Outputs

| Signal                     | Destination    | Description                                  |
| -------------------------- | -------------- | -------------------------------------------- |
| `BranchSelect`             | PC Mux         | '0' = PC+1 (sequential), '1' = branch target |
| `BranchTargetSelect [1:0]` | Target Mux     | Select branch target source                  |
| `FlushDE`                  | Decode Stage   | '1' = insert NOP in decode stage             |
| `FlushIF`                  | Fetch Stage    | '1' = insert NOP in fetch stage              |
| `Stall_Branch`             | Freeze Control | Stall signal for branch handling             |

### Branch Target Select Encoding

| Value | Constant       | Source                       | Usage                                         |
| ----- | -------------- | ---------------------------- | --------------------------------------------- |
| 00    | TARGET_DECODE  | Immediate from DECODE        | Predicted branches, unconditional branches    |
| 01    | TARGET_EXECUTE | Immediate from EXECUTE       | Resolved conditional branches, mispredictions |
| 10    | TARGET_MEMORY  | Interrupt vector from MEMORY | Interrupts (SW/HW)                            |
| 11    | TARGET_RESET   | Reset address (0)            | Reset                                         |

## Operation Scenarios

### 1. Reset

**Priority**: Highest

```
Input:  Reset = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = "11" (TARGET_RESET)
        FlushDE = '1'
        FlushIF = '1'
```

- Branch to address 0
- Flush entire pipeline

### 2. Hardware Interrupt

**Priority**: 2nd highest

```
Input:  IsHardwareInterrupt = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = "10" (TARGET_MEMORY)
        FlushDE = '1'
        FlushIF = '1'
```

- Branch to hardware interrupt vector
- Fetch handler address from memory

### 3. Software Interrupt

**Priority**: 3rd

```
Input:  IsSoftwareInterrupt = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = "10" (TARGET_MEMORY)
        FlushDE = '1'
        FlushIF = '1'
```

- Branch to software interrupt vector
- Fetch handler address from memory

### 4. Unconditional Branch (JMP, CALL)

**Priority**: 4th

```
Input:  UnconditionalBranch = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = "00" (TARGET_DECODE)
        FlushDE = '1'
        FlushIF = '1'
```

- Always branch
- Use immediate from decode stage
- Flush IF and DE stages

### 5. Branch Misprediction

**Priority**: 5th

```
Input:  ConditionalBranch = '1'
        PredictedTaken ≠ ActualTaken
Output: BranchSelect = ActualTaken
        BranchTargetSelect = "01" (TARGET_EXECUTE)
        FlushDE = '1'
        FlushIF = '1'
```

- Detect misprediction: `misprediction = PredictedTaken XOR ActualTaken`
- Correct the pipeline
- Use immediate from execute stage
- Flush IF and DE stages

### 6. Correctly Predicted Branch (Taken)

```
Input:  ConditionalBranch = '1'
        PredictedTaken = '1'
        ActualTaken = '1'
Output: BranchSelect = '1'
        BranchTargetSelect = "01" (TARGET_EXECUTE)
        FlushDE = '0'
        FlushIF = '0'
```

- Continue with branch
- No flush needed (prediction was correct)

### 7. Correctly Predicted Branch (Not Taken)

```
Input:  ConditionalBranch = '1'
        PredictedTaken = '0'
        ActualTaken = '0'
Output: BranchSelect = '0'
        FlushDE = '0'
        FlushIF = '0'
```

- Continue sequentially (PC+1)
- No flush needed

## Misprediction Handling

### Detection

```vhdl
misprediction = ConditionalBranch AND (PredictedTaken XOR ActualTaken)
```

### Four Misprediction Cases

#### Case 1: Predicted Taken, Actually Not Taken

- **Action**: Don't branch, flush pipeline
- **Penalty**: 2-3 cycles (wasted fetch/decode of wrong path)

#### Case 2: Predicted Not Taken, Actually Taken

- **Action**: Branch, flush pipeline
- **Penalty**: 2-3 cycles (need to fetch from branch target)

#### Case 3: Predicted Taken, Actually Taken

- **No misprediction**: Continue normally

#### Case 4: Predicted Not Taken, Actually Not Taken

- **No misprediction**: Continue normally

## Flush Signal Usage

### FlushIF (Fetch Stage)

- Insert NOP into IF/DE register
- Discard fetched instruction
- Used when: Branch taken, misprediction, interrupt, reset

### FlushDE (Decode Stage)

- Insert NOP into DE/EX register
- Discard decoded instruction
- Used when: Branch taken, misprediction, interrupt, reset

### Why Flush Both Stages?

When branch is taken or mispredicted:

- **IF stage**: Already fetched wrong instruction (PC+1)
- **DE stage**: Already decoding wrong instruction
- Both must be flushed and replaced with NOPs

## Performance Impact

### Branch Penalty Summary

| Scenario                        | Penalty (cycles) | Frequency     |
| ------------------------------- | ---------------- | ------------- |
| Unconditional branch            | 2-3              | Low-Medium    |
| Correctly predicted conditional | 0                | High (80-90%) |
| Mispredicted conditional        | 2-3              | Low (10-20%)  |
| Interrupt                       | 2-3 + handler    | Very Low      |

### CPI Impact

For a program with 20% branches, 85% prediction accuracy:

- Base CPI: 1.0
- Misprediction penalty: 0.20 × 0.15 × 2.5 = 0.075
- **Effective CPI**: ~1.075

## Integration

### Signal Flow

```
Branch Predictor → PredictedTaken ──────┐
                                         ↓
Execute Stage → ActualTaken ──→ Branch Decision Unit
Interrupt Unit → Interrupts ───────────→ ↓
                                    Decision Logic
                                         ↓
                    ┌────────────────────┴────────────────┐
                    ↓                    ↓                 ↓
              BranchSelect        BranchTargetSelect   Flush signals
                    ↓                    ↓                 ↓
                 PC Mux           Target Address Mux   Pipeline
```

### With Other Control Units

- **Freeze Control**: Receives `Stall_Branch` signal
- **Interrupt Unit**: Provides interrupt flags
- **Branch Predictor**: Provides prediction, receives update signal

## Design Decisions

### Why Priority-Based?

- **Clear precedence**: Reset > Interrupts > Branches
- **Deterministic**: No ambiguity when multiple conditions occur
- **Simple logic**: Priority encoder, easy to verify

### Why Separate Target Select?

- **Flexibility**: Different sources for different branch types
- **Timing**: Some targets available earlier than others
- **Correctness**: Interrupts need special address handling

### Flush Strategy

- **Aggressive flushing**: Flush on any branch/misprediction
- **Alternative**: Speculative execution (more complex)
- **Tradeoff**: Correctness vs performance

## Testing

Testbench verifies:

1. No branch (normal operation)
2. Reset priority
3. Hardware/software interrupt handling
4. Unconditional branch
5. Correct prediction (taken and not taken)
6. Misprediction handling (both directions)
7. Priority enforcement
8. Proper flush signal generation
9. Correct target selection

## Files

- `branch_decision_unit.vhd` - Main decision logic
- `tb_branch_decision_unit.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Notes

- Pure combinational logic (except `Stall_Branch` might need timing)
- Critical path: Priority logic → output generation
- Must coordinate with interrupt unit for proper interrupt handling
- Flush signals are critical for correctness
