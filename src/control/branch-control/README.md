# Branch Control

## Overview

The Branch Control unit manages all branch-related operations in the 5-stage pipelined processor, consisting of two sub-modules: Branch Predictor and Branch Decision Unit.

## Purpose

- Predict branch outcomes to reduce pipeline stalls
- Handle unconditional and conditional branches
- Coordinate with interrupt unit for control flow changes
- Select appropriate branch target addresses

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Branch Control Unit                     │
│                                                             │
│  ┌──────────────────────┐      ┌──────────────────────┐     │
│  │  Branch Predictor    │      │  Branch Decision     │     │
│  │                      │      │       Unit           │     │
│  │  - 2-bit counters    │──────→  - Priority logic    │     │
│  │  - Prediction table  │      │  - Target selection  │     │
│  │  - Strong/weak pred  │      │  - Static prediction │     │
│  └──────────────────────┘      └──────────────────────┘     │
│            ↓                            ↓                   │
│      PredictedTaken              BranchSelect               │
│                                BranchTargetSelect           │
└─────────────────────────────────────────────────────────────┘
```

## Sub-Modules

### 1. Branch Predictor

**File**: `branch-predictor/branch_predictor.vhd`

**Function**: Dynamic branch prediction using 2-bit saturating counters (currently not fully utilized - static prediction is used)

**Key Features**:

- 2-bit counter per branch (4-entry table)
- States: Strongly Not Taken, Weakly Not Taken, Weakly Taken, Strongly Taken
- CCR flag evaluation for condition types

**Outputs**:

- `PredictedTaken`: Prediction result
- `TreatConditionalAsUnconditional`: Strong prediction flag

### 2. Branch Decision Unit

**File**: `branch-decision-unit/branch_decision_unit.vhd`

**Function**: Final branch decision with priority handling

**Key Features**:

- Priority-based decision (Reset > Interrupts/Returns > Branches)
- Static prediction for conditional branches (always predict not-taken)
- Multi-source target selection

**Inputs**:

- Interrupt signals (hardware/software)
- Return signals (RET, RTI)
- Branch types (unconditional, conditional)
- Actual branch outcome

**Outputs**:

- `BranchSelect`: Take branch or not
- `BranchTargetSelect`: Which target address to use

## Branch Types Handled

### Unconditional Branches

- **JMP**: Always branch to immediate address
- **CALL**: Always branch and push return address
- **Always taken, target from decode stage**

### Conditional Branches

- **JZ**: Jump if Zero flag set
- **JN**: Jump if Negative flag set
- **JC**: Jump if Carry flag set
- **Static prediction: always predict not-taken**
- **Target from execute stage when taken**

### Special Control Flow

- **INT**: Software interrupt (via interrupt unit)
- **Hardware Interrupt**: External interrupt
- **RET/RTI**: Return from subroutine/interrupt
- **Target from memory stage**

## Branch Target Selection

| Code | Source                  | Usage                           |
| ---- | ----------------------- | ------------------------------- |
| 00   | Decode Stage Immediate  | JMP, CALL (unconditional)       |
| 01   | Execute Stage Immediate | Conditional branches when taken |
| 10   | Memory Stage Address    | Interrupts, RET, RTI            |

## Static Prediction Strategy

The processor uses **static prediction** (always predict not-taken):

1. Conditional branches initially continue sequential fetch
2. In execute stage, actual condition is evaluated
3. If taken, pipeline is flushed and redirected

**Benefits**:

- Simple implementation
- No misprediction penalty for not-taken branches
- Good performance for short forward branches

**Penalty**:

- 2-3 cycles when conditional branch is actually taken

## Integration with Control Unit

### Inputs from Other Units

- **Opcode Decoder**: IsJMP, IsCall, IsJMPConditional
- **Execute Stage**: ConditionalBranch, ActualTaken
- **Memory Stage**: IsRTI, IsReturn
- **Interrupt Unit**: IsHardwareInterrupt, IsSoftwareInterrupt

### Outputs to Other Units

- **PC Logic**: BranchSelect, BranchTargetSelect
- **Freeze Control**: (via branch signals for flush handling)

## Files Structure

```
branch-control/
├── branch-predictor/
│   ├── branch_predictor.vhd
│   └── README.md
├── branch-decision-unit/
│   ├── branch_decision_unit.vhd
│   └── README.md
└── README.md (this file)
```

## References

- Branch Predictor README: `branch-predictor/README.md`
- Branch Decision Unit README: `branch-decision-unit/README.md`
