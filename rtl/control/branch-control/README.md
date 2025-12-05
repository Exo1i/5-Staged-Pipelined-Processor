# Branch Control

## Overview

The Branch Control unit manages all branch-related operations in the 5-stage pipelined processor, consisting of two sub-modules: Branch Predictor and Branch Decision Unit.

## Purpose

- Predict branch outcomes to reduce pipeline stalls
- Detect and correct branch mispredictions
- Handle unconditional and conditional branches
- Coordinate with interrupt unit for control flow changes
- Generate flush signals for pipeline control

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Branch Control Unit                      │
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │  Branch Predictor    │      │  Branch Decision     │   │
│  │                      │      │       Unit           │   │
│  │  - 2-bit counters    │──────→  - Priority logic    │   │
│  │  - Prediction table  │      │  - Misprediction     │   │
│  │  - Strong/weak pred  │      │  - Target selection  │   │
│  └──────────────────────┘      │  - Flush control     │   │
│            ↓                    └──────────────────────┘   │
│      PredictedTaken                       ↓                 │
│                                     BranchSelect             │
│                                  BranchTargetSelect          │
│                                    FlushIF, FlushDE          │
└─────────────────────────────────────────────────────────────┘
```

## Sub-Modules

### 1. Branch Predictor

**File**: `branch-predictor/branch_predictor.vhd`

**Function**: Dynamic branch prediction using 2-bit saturating counters

**Key Features**:

- 2-bit counter per branch (4-entry table)
- States: Strongly Not Taken, Weakly Not Taken, Weakly Taken, Strongly Taken
- Strong predictions can be treated as unconditional
- Updates based on actual outcomes

**Inputs**:

- Branch type (JMP, CALL, conditional)
- Condition type and CCR flags
- PC (for table indexing)
- Actual outcome (for training)

**Outputs**:

- `PredictedTaken`: Prediction result
- `TreatConditionalAsUnconditional`: Strong prediction flag

### 2. Branch Decision Unit

**File**: `branch-decision-unit/branch_decision_unit.vhd`

**Function**: Final branch decision with priority handling and misprediction detection

**Key Features**:

- Priority-based decision (Reset > HW Int > SW Int > Branch)
- Misprediction detection (Predicted XOR Actual)
- Multi-source target selection
- Pipeline flush generation

**Inputs**:

- Interrupt signals
- Predicted and actual branch outcomes
- Branch types

**Outputs**:

- `BranchSelect`: Take branch or not
- `BranchTargetSelect`: Which target address to use
- `FlushIF`, `FlushDE`: Pipeline flush signals

## Operation Flow

### Prediction Phase (Early - DECODE Stage)

1. Branch detected in decode stage
2. Branch Predictor generates prediction
3. If strongly predicted or unconditional:
   - Speculatively fetch from target
   - Continue pipeline

### Resolution Phase (Late - EXECUTE Stage)

1. Condition evaluated with actual CCR flags
2. Actual outcome determined
3. Compare with prediction
4. Branch Decision Unit decides:
   - **Correct prediction**: Continue normally
   - **Misprediction**: Flush IF/DE, fetch correct path

### Update Phase (After Resolution)

1. Predictor table updated based on actual outcome
2. 2-bit counter incremented (taken) or decremented (not taken)
3. Adapts to program behavior

## Branch Types Handled

### Unconditional Branches

- **JMP**: Always branch to immediate address
- **CALL**: Always branch and push return address
- **Always predicted taken**

### Conditional Branches

- **JZ**: Jump if Zero flag set
- **JN**: Jump if Negative flag set
- **JC**: Jump if Carry flag set
- **Use 2-bit predictor**

### Special Control Flow

- **INT**: Software interrupt (via interrupt unit)
- **Hardware Interrupt**: External interrupt
- **RET/RTI**: Return from subroutine/interrupt
- **Handled by interrupt unit, coordinated with branch control**

## Branch Target Selection

### Four Target Sources

| Code | Source                   | Usage                                |
| ---- | ------------------------ | ------------------------------------ |
| 00   | Decode Stage Immediate   | Predicted/unconditional branches     |
| 01   | Execute Stage Immediate  | Resolved conditional, mispredictions |
| 10   | Memory Stage (Interrupt) | Interrupt handlers                   |
| 11   | Reset Address (0)        | System reset                         |

## Performance Optimization

### Prediction Benefits

- **Without prediction**: 2-3 cycle penalty per branch
- **With prediction** (85% accuracy):
  - Correct: 0 cycle penalty
  - Incorrect: 2-3 cycle penalty
  - **Average**: 0.45 cycles per branch

### Example: Loop with 100 iterations

```
Loop:
    ADD R1, R2, R3
    SUB R4, R5, R6
    JZ Loop          ; 99 times taken, 1 time not taken
```

**Without prediction**: 300 cycles wasted (3 per iteration)
**With prediction**: ~6 cycles wasted (2 mispredictions × 3)
**Speedup**: 50x improvement for branch overhead

## Integration with Control Unit

### Inputs from Other Units

- **Opcode Decoder**: IsJMP, IsCall, IsJMPConditional, ConditionalType
- **Execute Stage**: CCR flags, actual condition evaluation
- **Interrupt Unit**: Software/hardware interrupt signals
- **System**: Reset signal

### Outputs to Other Units

- **Freeze Control**: Stall signal (optional)
- **PC Logic**: BranchSelect, target address
- **Pipeline Registers**: FlushIF, FlushDE

### Signal Flow

```
Decode → Branch Predictor → Predicted outcome
           ↓
Execute → Actual outcome → Branch Decision Unit
           ↓                        ↓
      Update predictor         BranchSelect
                                    ↓
                                 PC Mux
```

## Pipeline Interaction

### Normal Branch (Predicted Correctly)

```
Cycle 1 (IF):  Fetch branch instruction
Cycle 2 (DE):  Decode, predict taken, fetch target
Cycle 3 (EX):  Execute, verify prediction correct
Cycle 4+:      Continue from target (no penalty)
```

### Mispredicted Branch

```
Cycle 1 (IF):  Fetch branch instruction
Cycle 2 (DE):  Decode, predict not taken, fetch PC+1
Cycle 3 (EX):  Execute, detect misprediction
               Flush IF & DE, fetch correct target
Cycle 4 (IF):  Fetch from correct target
Cycle 5 (DE):  Decode correct instruction
Penalty: 2 cycles
```

## Design Decisions

### Why 2-Bit Predictor?

- 1-bit: Too sensitive (one miss changes prediction)
- 2-bit: Requires two misses to change direction
- **Balances** accuracy vs hardware cost

### Why Separate Predictor and Decision?

- **Modularity**: Clear separation of concerns
- **Timing**: Prediction early, decision late
- **Flexibility**: Easy to upgrade predictor without changing decision logic

### Flush Strategy

- **Aggressive**: Flush on any uncertainty
- **Safe**: Ensures correctness
- **Simple**: Easy to verify and debug

## Testing

Each sub-module has comprehensive testbenches:

- Branch Predictor: Tests state transitions, predictions
- Branch Decision: Tests priority, mispredictions, flushes

## Files Structure

```
branch-control/
├── branch-predictor/
│   ├── branch_predictor.vhd
│   ├── tb_branch_predictor.vhd
│   └── README.md
├── branch-decision-unit/
│   ├── branch_decision_unit.vhd
│   ├── tb_branch_decision_unit.vhd
│   └── README.md
└── README.md (this file)
```

## Future Enhancements

1. **Larger prediction table** (512+ entries)
2. **Two-level adaptive predictor** (global + local history)
3. **Branch Target Buffer (BTB)** to cache target addresses
4. **Return Address Stack (RAS)** for function returns
5. **Hybrid predictors** combining multiple prediction schemes

## References

- Branch Predictor README: `branch-predictor/README.md`
- Branch Decision Unit README: `branch-decision-unit/README.md`
- Opcode Decoder: `../../opcode-decoder/`
- Interrupt Unit: `../../interrupt-unit/`
