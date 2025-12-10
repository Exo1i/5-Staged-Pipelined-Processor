# Top-Level Control Unit

## Overview

The top-level Control Unit integrates all control sub-modules to manage the 5-stage pipelined processor. It coordinates instruction decoding, hazard detection, interrupt handling, branch prediction, and pipeline control.

## Purpose

- Integrate all control sub-modules into a unified control system
- Route signals between sub-modules
- Generate control signals for all pipeline stages
- Manage pipeline freezing and flushing
- Coordinate hazard detection and resolution

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Control Unit (Top Level)                          │
│                                                                           │
│  ┌────────────────┐    ┌──────────────┐    ┌─────────────────┐         │
│  │    Opcode      │    │   Memory     │    │   Interrupt     │         │
│  │    Decoder     │    │   Hazard     │    │     Unit        │         │
│  │                │    │    Unit      │    │                 │         │
│  │  - 26 insts    │    │              │    │  - Override     │         │
│  │  - Overrides   │    │  - Priority  │    │  - HW/SW int   │         │
│  │  - Records     │───→│  - PassPC    │───→│  - Stall       │──┐      │
│  └────────────────┘    └──────────────┘    └─────────────────┘  │      │
│         ↑                                            ↑             │      │
│         │                                            │             ↓      │
│         │                                    ┌────────────────┐         │
│         │                                    │     Freeze     │         │
│         │                                    │    Control     │         │
│         │                                    │                │         │
│         │                                    │  - PC freeze   │         │
│         │                                    │  - NOP insert  │         │
│         │                                    └────────────────┘         │
│         │                                                                │
│  ┌────────────────┐    ┌──────────────┐                                │
│  │    Branch      │    │   Branch     │                                │
│  │   Predictor    │    │   Decision   │                                │
│  │                │    │     Unit     │                                │
│  │  - 2-bit pred  │───→│              │                                │
│  │  - Training    │    │  - Priority  │                                │
│  │  - CCR eval    │    │  - Mispredict│                                │
│  └────────────────┘    └──────────────┘                                │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

## Sub-Module Integration

### 1. Opcode Decoder

**File**: `opcode-decoder/opcode_decoder.vhd`

**Inputs to Decoder**:

- `opcode_DE`: 5-bit opcode from instruction
- `override_operation`: From interrupt unit
- `override_type`: From interrupt unit
- `isSwap_from_execute`: SWAP feedback
- `take_interrupt`: From interrupt unit (HW interrupt)
- `is_hardware_int_mem`: From interrupt unit

**Outputs from Decoder**:

- `decode_ctrl`: Decode stage control record
- `execute_ctrl`: Execute stage control record
- `memory_ctrl`: Memory stage control record
- `writeback_ctrl`: Writeback stage control record

**Connections**:

- Receives override signals from Interrupt Unit
- Outputs control signals to all pipeline stages

### 2. Memory Hazard Unit

**File**: `memory-hazard-unit/memory_hazard_unit.vhd`

**Inputs**:

- `MemRead_MEM`: Memory read request from memory stage
- `MemWrite_MEM`: Memory write request from memory stage

**Outputs**:

- `PassPC`: Allow fetch to access memory (to Freeze Control)
- `MemRead_Out`: Actual memory read signal
- `MemWrite_Out`: Actual memory write signal

**Connections**:

- Receives memory access requests from Memory stage
- Outputs PassPC to Freeze Control
- Controls actual memory access

### 3. Interrupt Unit

**File**: `interrupt-unit/interrupt_unit.vhd`

**Inputs**:

- From Decode: `IsInterrupt_DE`, `IsHardwareInt_DE`, `IsCall_DE`, `IsReturn_DE`, `IsReti_DE`
- From Execute: `IsInterrupt_EX`, `IsHardwareInt_EX`, `IsReti_EX`
- From Memory: `IsHardwareInt_MEM`
- External: `HardwareInterrupt`

**Outputs**:

- `Stall`: Stall signal to Freeze Control
- `PassPC_NotPCPlus1`: Save current PC for HW interrupt
- `TakeInterrupt`: Signal IF/DE to treat as interrupt
- `IsHardwareIntMEM_Out`: HW interrupt flag to decoder
- `OverrideOperation`: Enable override
- `OverrideType`: Type of override (PUSH_PC, PUSH_FLAGS, etc.)

**Connections**:

- Receives interrupt signals from pipeline stages
- Outputs stall to Freeze Control
- Outputs override signals to Opcode Decoder
- Signals hardware interrupt handling

### 4. Freeze Control

**File**: `freeze-control/freeze_control.vhd`

**Inputs**:

- `PassPC_MEM`: From Memory Hazard Unit
- `Stall_Interrupt`: From Interrupt Unit
- `Stall_Branch`: From Branch Decision Unit

**Outputs**:

- `PC_WriteEnable`: Enable PC update
- `IFDE_WriteEnable`: Enable IF/DE register
- `InsertNOP_IFDE`: Insert NOP in IF/DE stage

**Connections**:

- Receives stall conditions from all hazard sources
- Outputs freeze signals to pipeline control
- Combines all stall conditions with OR logic

### 5. Branch Predictor

**File**: `branch-control/branch-predictor/branch_predictor.vhd`

**Inputs**:

- From Decode: `IsJMP`, `IsCall`, `IsJMPConditional`, `ConditionalType`, `PC_DE`
- From Execute: `CCR_Flags`, `ActualTaken`, `UpdatePredictor`, `PC_EX`
- Clock and Reset: `clk`, `rst`

**Outputs**:

- `PredictedTaken`: Prediction result
- `TreatConditionalAsUnconditional`: Strong prediction flag

**Connections**:

- Receives branch information from Decode stage
- Receives actual outcome from Execute stage
- Outputs prediction to Branch Decision Unit
- Updates internal state on clock edge

### 6. Branch Decision Unit

**File**: `branch-control/branch-decision-unit/branch_decision_unit.vhd`

**Inputs**:

- `IsSoftwareInterrupt`: Software interrupt active
- `IsHardwareInterrupt`: Hardware interrupt active
- `UnconditionalBranch`: JMP or CALL
- `ConditionalBranch`: Conditional branch in execute
- `PredictedTaken`: From Branch Predictor
- `ActualTaken`: Actual outcome
- `Reset`: System reset

**Outputs**:

- `BranchSelect`: Take branch or PC+1
- `BranchTargetSelect`: Which target source (2-bit)
- `FlushDE`: Flush decode stage
- `FlushIF`: Flush fetch stage
- `Stall_Branch`: Stall signal to Freeze Control

**Connections**:

- Receives prediction from Branch Predictor
- Receives interrupt flags
- Outputs branch decision to PC logic
- Outputs flush signals to pipeline
- Outputs stall to Freeze Control

## Signal Flow

### Instruction Execution Flow

```
1. Opcode → Decoder → Control Signals → Pipeline Stages
2. Memory Access → Hazard Unit → PassPC → Freeze Control
3. Interrupt → Interrupt Unit → Override → Decoder
4. Branch → Predictor → Prediction → Decision Unit → Flush/Branch
```

### Hazard Detection Flow

```
Memory Conflict:  MemRead/Write → Memory Hazard Unit → PassPC='0' → Freeze
Interrupt:        INT/CALL/RET → Interrupt Unit → Stall='1' → Freeze
Branch Mispredict: Predicted ≠ Actual → Branch Decision → Flush IF/DE
```

### Override Flow

```
INT/CALL/RET/RTI → Interrupt Unit → Override signals → Decoder → Forced operations
```

## Top-Level Interface

### Inputs

| Category          | Signal                 | Width | Description                |
| ----------------- | ---------------------- | ----- | -------------------------- |
| **System**        | `clk`                  | 1     | System clock               |
|                   | `rst`                  | 1     | Reset signal               |
| **Decode Stage**  | `opcode_DE`            | 5     | Opcode from instruction    |
|                   | `PC_DE`                | 32    | Program counter in decode  |
|                   | `IsInterrupt_DE`       | 1     | Interrupt instruction      |
|                   | `IsHardwareInt_DE`     | 1     | Hardware interrupt flag    |
|                   | `IsCall_DE`            | 1     | CALL instruction           |
|                   | `IsReturn_DE`          | 1     | RET instruction            |
|                   | `IsReti_DE`            | 1     | RTI instruction            |
|                   | `IsJMP_DE`             | 1     | Unconditional jump         |
|                   | `IsJMPConditional_DE`  | 1     | Conditional jump           |
|                   | `ConditionalType_DE`   | 2     | Condition type (Z/N/C)     |
| **Execute Stage** | `PC_EX`                | 32    | Program counter in execute |
|                   | `CCR_Flags_EX`         | 3     | Condition flags (Z, N, C)  |
|                   | `IsSwap_EX`            | 1     | SWAP in execute (feedback) |
|                   | `ActualBranchTaken_EX` | 1     | Actual branch outcome      |
|                   | `ConditionalBranch_EX` | 1     | Conditional branch active  |
|                   | `IsInterrupt_EX`       | 1     | Interrupt in execute       |
|                   | `IsHardwareInt_EX`     | 1     | HW interrupt in execute    |
|                   | `IsReti_EX`            | 1     | RTI in execute             |
| **Memory Stage**  | `MemRead_MEM`          | 1     | Memory read request        |
|                   | `MemWrite_MEM`         | 1     | Memory write request       |
|                   | `IsHardwareInt_MEM`    | 1     | HW interrupt in memory     |
| **External**      | `HardwareInterrupt`    | 1     | External HW interrupt      |

### Outputs

| Category              | Signal                 | Width  | Description                  |
| --------------------- | ---------------------- | ------ | ---------------------------- |
| **Control Signals**   | `decode_ctrl_out`      | record | Decode stage controls        |
|                       | `execute_ctrl_out`     | record | Execute stage controls       |
|                       | `memory_ctrl_out`      | record | Memory stage controls        |
|                       | `writeback_ctrl_out`   | record | Writeback stage controls     |
| **Pipeline Control**  | `PC_WriteEnable`       | 1      | Enable PC update             |
|                       | `IFDE_WriteEnable`     | 1      | Enable IF/DE register        |
|                       | `InsertNOP_IFDE`       | 1      | Insert NOP in IF/DE          |
|                       | `FlushDE`              | 1      | Flush decode stage           |
|                       | `FlushIF`              | 1      | Flush fetch stage            |
| **Memory Control**    | `PassPC_ToMem`         | 1      | Allow fetch to access memory |
|                       | `MemRead_Out`          | 1      | Actual memory read           |
|                       | `MemWrite_Out`         | 1      | Actual memory write          |
| **Branch Control**    | `BranchSelect`         | 1      | Take branch or PC+1          |
|                       | `BranchTargetSelect`   | 2      | Branch target source         |
| **Interrupt Control** | `PassPC_NotPCPlus1`    | 1      | Pass current PC              |
|                       | `TakeInterrupt_ToIFDE` | 1      | Treat as interrupt           |

## Operation Scenarios

### Scenario 1: Normal Instruction (ADD)

```
Input:  opcode_DE = OP_ADD
        No hazards, no interrupts, no branches

Process:
1. Decoder generates control signals
2. All hazard units report no hazards
3. Freeze Control allows normal operation

Output: decode_ctrl, execute_ctrl, memory_ctrl, writeback_ctrl
        PC_WriteEnable = '1'
        IFDE_WriteEnable = '1'
        InsertNOP_IFDE = '0'
```

### Scenario 2: Memory Conflict (LDD in Memory Stage)

```
Input:  MemRead_MEM = '1'

Process:
1. Memory Hazard Unit detects conflict
2. PassPC = '0' (block fetch)
3. Freeze Control freezes pipeline

Output: PC_WriteEnable = '0'
        IFDE_WriteEnable = '0'
        InsertNOP_IFDE = '1'
        PassPC_ToMem = '0'
```

### Scenario 3: Software Interrupt (INT)

```
Input:  opcode_DE = OP_INT
        IsInterrupt_DE = '1'

Process:
1. Decoder generates interrupt controls
2. Interrupt Unit generates override for PUSH_PC
3. Freeze Control stalls pipeline

Output: memory_ctrl.PassInterrupt = PASS_INT_SOFTWARE
        OverrideOperation = '1'
        PC_WriteEnable = '0' (stalled)
```

### Scenario 4: Hardware Interrupt

```
Input:  HardwareInterrupt = '1'

Process:
1. Interrupt Unit sets TakeInterrupt
2. PassPC_NotPCPlus1 = '1' (save current PC)
3. Signal written to IF/DE register
4. Next cycle: Decoder treats as interrupt

Output: TakeInterrupt_ToIFDE = '1'
        PassPC_NotPCPlus1 = '1'
        Stall = '1'
```

### Scenario 5: Unconditional Branch (JMP)

```
Input:  opcode_DE = OP_JMP
        IsJMP_DE = '1'

Process:
1. Branch Decision Unit detects unconditional branch
2. Flush IF and DE stages
3. Select branch target from decode

Output: BranchSelect = '1'
        BranchTargetSelect = "00" (TARGET_DECODE)
        FlushDE = '1'
        FlushIF = '1'
```

### Scenario 6: Branch Misprediction

```
Input:  ConditionalBranch_EX = '1'
        PredictedTaken = '0'
        ActualTaken = '1'

Process:
1. Branch Decision detects misprediction
2. Flush pipeline stages
3. Branch to correct target
4. Update predictor

Output: BranchSelect = '1'
        BranchTargetSelect = "01" (TARGET_EXECUTE)
        FlushDE = '1'
        FlushIF = '1'
```

### Scenario 7: SWAP Instruction

```
Cycle 1:
Input:  opcode_DE = OP_SWAP

Process:
1. Decoder sets IsSwap = '1'
2. Normal SWAP execution

Output: decode_ctrl.IsSwap = '1'

Cycle 2:
Input:  IsSwap_EX = '1' (feedback)

Process:
1. Decoder generates second MOV cycle
2. Uses swapped operand

Output: decode_ctrl.OutBSelect = OUTB_SWAPPED
```

## Priority Handling

### Priority Order

1. **Reset** (Highest)
2. **Hardware Interrupt**
3. **Software Interrupt**
4. **Unconditional Branch** (JMP, CALL)
5. **Branch Misprediction**
6. **Memory Hazard**
7. **Normal Operation** (Lowest)

### Implementation

- Priority implemented in Branch Decision Unit
- Reset overrides everything
- Interrupts override branches
- Hazards cause stalls, not overrides

## Design Decisions

### Why Separate Sub-Modules?

- **Modularity**: Each unit has single responsibility
- **Testability**: Each unit can be tested independently
- **Maintainability**: Easy to modify individual units
- **Reusability**: Units can be reused in other designs

### Signal Routing Philosophy

- **Direct connections**: Outputs of one unit directly to inputs of another
- **Minimal top-level logic**: Top level is mostly wiring
- **Clear data flow**: Easy to trace signal paths

### Control Signal Organization

- **Record types**: Group related signals
- **Stage-based**: Separate records per pipeline stage
- **Default values**: All signals have safe defaults

## Testing

### Test Coverage

1. **Normal Instructions**: All 26 instructions
2. **Hazards**: Memory conflicts, data hazards
3. **Interrupts**: Software, hardware, RTI
4. **Branches**: Unconditional, conditional, predictions, mispredictions
5. **Special Cases**: SWAP, CALL/RET, priority handling
6. **Edge Cases**: Simultaneous hazards, nested interrupts

### Testbench Features

- Comprehensive stimulus for all scenarios
- Assertions for critical outputs
- Clear test reporting
- Clock-based timing

## Integration with Processor

### Connection to Pipeline Stages

```
Control Unit → decode_ctrl → IF/DE Register → Decode Stage
            → execute_ctrl → DE/EX Register → Execute Stage
            → memory_ctrl → EX/MEM Register → Memory Stage
            → writeback_ctrl → MEM/WB Register → Writeback Stage
```

### Freeze and Flush Handling

```
Freeze: PC_WriteEnable='0' → PC stays same
        IFDE_WriteEnable='0' → IF/DE register holds
        InsertNOP_IFDE='1' → Override with NOP

Flush: FlushIF='1' → Clear IF/DE register
       FlushDE='1' → Clear DE/EX register
```

## Files

- `control_unit.vhd` - Top-level integration module
- `tb_control_unit.vhd` - Comprehensive testbench
- `README.md` - This documentation

## Sub-Module Documentation

- Opcode Decoder: `opcode-decoder/README.md`
- Memory Hazard Unit: `memory-hazard-unit/README.md`
- Interrupt Unit: `interrupt-unit/README.md`
- Freeze Control: `freeze-control/README.md`
- Branch Control: `branch-control/README.md`
  - Branch Predictor: `branch-control/branch-predictor/README.md`
  - Branch Decision Unit: `branch-control/branch-decision-unit/README.md`

## Next Steps

1. **Integration Testing**: Test with complete processor
2. **Timing Analysis**: Verify critical paths
3. **Power Optimization**: Analyze and optimize power consumption
4. **Documentation**: Complete system-level documentation
