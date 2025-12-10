# Branch Predictor

## Overview

The Branch Predictor uses a 2-bit saturating counter mechanism to predict whether conditional branches will be taken, improving pipeline performance by reducing branch penalties.

## Purpose

- Predict conditional branch outcomes early (in DECODE stage)
- Reduce pipeline stalls due to branch resolution
- Use dynamic prediction with 2-bit saturating counters
- Support strong/weak prediction states

## Architecture

### 2-Bit Saturating Counter States

```
00 (Strongly Not Taken) → 01 (Weakly Not Taken) → 10 (Weakly Taken) → 11 (Strongly Taken)
     ↑                                                                      ↓
     └──────────────────────────── Saturates ───────────────────────────────┘
```

- **Strongly Not Taken (00)**: High confidence - not taken
- **Weakly Not Taken (01)**: Low confidence - not taken
- **Weakly Taken (10)**: Low confidence - taken
- **Strongly Taken (11)**: High confidence - taken

### Prediction Table

- Simple 4-entry table indexed by PC lower bits
- Can be expanded to larger tables for better accuracy
- Each entry stores a 2-bit state

### Inputs

#### From DECODE Stage

| Signal                  | Description                             |
| ----------------------- | --------------------------------------- |
| `IsJMP`                 | Unconditional jump                      |
| `IsCall`                | CALL instruction                        |
| `IsJMPConditional`      | Conditional jump flag                   |
| `ConditionalType [1:0]` | Type of condition (00=Z, 01=N, 10=C)    |
| `PC_DE [31:0]`          | PC in decode stage (for table indexing) |

#### From EXECUTE Stage

| Signal            | Description                              |
| ----------------- | ---------------------------------------- |
| `CCR_Flags [2:0]` | Condition flags (Z, N, C) for evaluation |
| `ActualTaken`     | Actual branch outcome (for training)     |
| `UpdatePredictor` | Enable signal to update prediction table |
| `PC_EX [31:0]`    | PC in execute stage (for table update)   |

### Outputs

| Signal                            | Description                                   |
| --------------------------------- | --------------------------------------------- |
| `PredictedTaken`                  | '1' = predict taken, '0' = predict not taken  |
| `TreatConditionalAsUnconditional` | '1' for strong predictions (can branch early) |

## Operation

### Prediction Phase (Combinational)

**Unconditional Branches (JMP, CALL)**:

- Always predict taken
- `PredictedTaken = '1'`
- `TreatConditionalAsUnconditional = '1'`

**Conditional Branches**:

1. Index prediction table using PC_DE lower bits
2. Read 2-bit state from table
3. Generate prediction:
   - **00 (Strongly Not Taken)**: Predict not taken, strong
   - **01 (Weakly Not Taken)**: Predict not taken, weak
   - **10 (Weakly Taken)**: Predict taken, weak
   - **11 (Strongly Taken)**: Predict taken, strong

**Strong vs Weak Predictions**:

- **Strong (00, 11)**: `TreatConditionalAsUnconditional = '1'`
  - Can commit to branch decision early
  - Less likely to be wrong
- **Weak (01, 10)**: `TreatConditionalAsUnconditional = '0'`
  - Should wait for condition evaluation
  - More likely to change state

### Update Phase (Sequential)

After branch resolves in EXECUTE stage:

1. Check `UpdatePredictor` signal
2. Index table using PC_EX
3. Update state based on actual outcome:

**If Branch Taken** (increment counter):

- 00 → 01 (Strongly NT → Weakly NT)
- 01 → 10 (Weakly NT → Weakly T)
- 10 → 11 (Weakly T → Strongly T)
- 11 → 11 (Strongly T stays, saturated)

**If Branch Not Taken** (decrement counter):

- 00 → 00 (Strongly NT stays, saturated)
- 01 → 00 (Weakly NT → Strongly NT)
- 10 → 01 (Weakly T → Weakly NT)
- 11 → 10 (Strongly T → Weakly T)

## Condition Evaluation

Based on `ConditionalType` and `CCR_Flags`:

| Type | Condition | CCR Flag   | Meaning          |
| ---- | --------- | ---------- | ---------------- |
| 00   | JZ        | Z (bit 2)  | Jump if Zero     |
| 01   | JN        | N (bit 1)  | Jump if Negative |
| 10   | JC        | C (bit 0)  | Jump if Carry    |
| 11   | -         | Always '1' | Unconditional    |

## Performance Impact

### Benefits

- **Early prediction**: Branch decision made in DECODE
- **Reduced stalls**: Correct predictions avoid pipeline flushes
- **Adaptive**: Learns branch behavior over time

### Prediction Accuracy

Typical 2-bit predictor accuracy: **80-90%** for regular loops

### Misprediction Penalty

- **Correct prediction**: 0 cycle penalty
- **Misprediction**: 2-3 cycle penalty (flush IF + DE)

### Example: Loop Performance

```assembly
Loop:
    ADD R1, R2, R3
    SUB R4, R5, R6
    JZ Loop        ; Taken 99 times, not taken 1 time
```

**Without prediction**: 3 cycles per iteration (wait for condition)
**With 2-bit predictor**:

- First iteration: Misprediction (state 01→10)
- Next 98 iterations: Correct prediction (state stays 10 or 11)
- Last iteration: Misprediction (exit loop)
- **Average**: ~1 cycle per iteration after training

## Integration

### With Branch Decision Unit

```
Branch Predictor → PredictedTaken → Branch Decision Unit
                 ↓
           Comparison with ActualTaken
                 ↓
         Misprediction Detection
                 ↓
            Pipeline Flush
```

### Pipeline Flow

1. **DECODE**: Predictor generates prediction
2. **EXECUTE**: Condition evaluated, actual outcome determined
3. **UPDATE**: Predictor state updated based on actual outcome

## Design Decisions

### Why 2-Bit Counter?

- 1-bit predictor: Too sensitive to noise (single misprediction changes state)
- 2-bit predictor: Requires two consecutive mispredictions to change direction
- Good balance between accuracy and complexity

### Table Size (4 entries)

- **Tradeoff**: Larger table = better accuracy but more hardware
- 4 entries: Demonstration/simple implementation
- Production: 512-2048 entries typical

### PC-Based Indexing

- Use PC lower bits to index table
- **Aliasing**: Different branches may map to same entry
- Larger tables reduce aliasing

## Testing

Testbench verifies:

1. Unconditional branches always taken
2. Initial conditional prediction (weakly not taken)
3. State transitions based on actual outcomes
4. Strong vs weak prediction flags
5. Saturating counter behavior
6. Multiple branches to same table entry

## Files

- `branch_predictor.vhd` - Main predictor logic
- `tb_branch_predictor.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Future Enhancements

1. **Larger prediction table** (512+ entries)
2. **Two-level adaptive predictor** (global + local history)
3. **Branch Target Buffer (BTB)** to store target addresses
4. **Return Address Stack (RAS)** for function returns
