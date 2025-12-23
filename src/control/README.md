# Top-Level Control Unit

## Overview

The top-level Control Unit integrates all control sub-modules to manage the 5-stage pipelined processor. It coordinates instruction decoding, hazard detection, interrupt handling, branch prediction, forwarding, and pipeline control.

## Purpose

- Integrate all control sub-modules into a unified control system
- Route signals between sub-modules
- Generate control signals for all pipeline stages
- Manage pipeline freezing and flushing
- Coordinate hazard detection and resolution
- Handle data forwarding for RAW hazards

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Control Unit (Top Level)                             │
│                                                                              │
│  ┌────────────────┐    ┌──────────────┐    ┌─────────────────┐               │
│  │    Opcode      │    │   Memory     │    │   Interrupt     │               │
│  │    Decoder     │    │   Hazard     │    │     Unit        │               │
│  │                │    │    Unit      │    │                 │               │
│  │  - 26 insts    │    │              │    │  - Override     │               │
│  │  - Overrides   │    │  - Priority  │    │  - HW/SW int    │               │
│  │  - Records     │───→│  - PassPC    │───→│  - freeze_fetch │──┐            │
│  └────────────────┘    └──────────────┘    └─────────────────┘  │            │
│         ↑                                            ↑          │            │
│         │                                            │          ↓            │
│         │                                    ┌────────────────┐              │
│         │                                    │     Freeze     │              │
│         │                                    │    Control     │              │
│         │                                    │                │              │
│         │                                    │  - PC freeze   │              │
│         │                                    │  - NOP insert  │              │
│         │                                    │  - HLT/SWAP    │              │
│         │                                    └────────────────┘              │
│         │                                                                    │
│  ┌────────────────┐    ┌──────────────┐    ┌─────────────────┐               │
│  │    Branch      │    │   Branch     │    │   Forwarding    │               │
│  │   Predictor    │    │   Decision   │    │      Unit       │               │
│  │                │    │     Unit     │    │                 │               │
│  │  - 2-bit pred  │───→│              │    │  - ForwardA/B   │               │
│  │  - Training    │    │  - Priority  │    │  - SWAP disable │               │
│  │  - CCR eval    │    │  - Static    │    │  - Secondary    │               │
│  └────────────────┘    └──────────────┘    └─────────────────┘               │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Sub-Module Integration

### 1. Opcode Decoder

**File**: `opcode-decoder/opcode_decoder.vhd`

**Inputs**:

- `opcode`: 5-bit opcode from IF/ID instruction
- `override_operation`, `override_type`: From interrupt unit
- `isSwap_from_execute`: SWAP feedback from execute stage
- `take_interrupt`: Hardware interrupt signal
- `is_hardware_int_mem`: Hardware interrupt flag in memory
- `requireImmediate`: Immediate instruction flag

**Outputs**:

- `decode_ctrl`, `execute_ctrl`, `memory_ctrl`, `writeback_ctrl`: Control records
- `is_jmp_out`, `is_jmp_conditional_out`: Instruction type detection

### 2. Memory Hazard Unit

**File**: `memory-hazard-unit/memory_hazard_unit.vhd`

**Inputs**: `MemRead_MEM`, `MemWrite_MEM`

**Outputs**: `PassPC`, `MemRead_Out`, `MemWrite_Out`

### 3. Interrupt Unit

**File**: `interrupt-unit/interrupt_unit.vhd`

**Inputs**:

- DE stage: `IsInterrupt_DE`, `IsRet_DE`, `IsReti_DE`
- EX stage: `IsInterrupt_EX`, `IsRet_EX`, `IsReti_EX`
- MEM stage: `IsInterrupt_MEM`, `IsReti_MEM`, `IsRet_MEM`, `IsHardwareInt_MEM`
- External: `HardwareInterrupt`

**Outputs**:

- `freeze_fetch`: Stall signal to Freeze Control
- `memory_hazard`: Memory hazard for interrupt/return
- `PassPC_NotPCPlus1`, `TakeInterrupt`, `IsHardwareIntMEM_Out`
- `OverrideOperation`, `OverrideType`

### 4. Freeze Control

**File**: `freeze-control/freeze_control.vhd`

**Inputs**:

- `PassPC_MEM`: From Memory Hazard Unit
- `Stall_Interrupt`: From Interrupt Unit
- `BranchSelect`, `BranchTargetSelect`: From Branch Decision
- `is_swap`, `is_hlt`, `requireImmediate`: From Decode Stage

**Outputs**: `PC_Freeze`, `IFDE_WriteEnable`, `InsertNOP_IFDE`, `InsertNOP_DEEX`

### 5. Branch Predictor

**File**: `branch-control/branch-predictor/branch_predictor.vhd`

**Inputs**:

- Decode: `IsJMP`, `IsCall`, `IsJMPConditional`, `ConditionalType`, `PC_DE`
- Execute: `CCR_Flags`, `ActualTaken`, `UpdatePredictor`, `PC_EX`

**Outputs**: `PredictedTaken`, `TreatConditionalAsUnconditional`

### 6. Branch Decision Unit

**File**: `branch-control/branch-decision-unit/branch_decision_unit.vhd`

**Inputs**:

- `IsSoftwareInterrupt`, `IsHardwareInterrupt`
- `IsRTI`, `IsReturn`, `IsCall`
- `UnconditionalBranch`, `ConditionalBranch`
- `PredictedTaken`, `ActualTaken`, `Reset`

**Outputs**: `BranchSelect`, `BranchTargetSelect`

### 7. Forwarding Unit

**File**: `forwarding-unit/forwarding_unit.vhd`

**Inputs**:

- MEM stage: `MemRegWrite`, `MemRdst`, `MemIsSwap`
- WB stage: `WBRegWrite`, `WBRdst`
- EX stage: `ExRsrc1`, `ExRsrc2`, `ExOutBSelect`, `ExIsImm`

**Outputs**: `ForwardA`, `ForwardB`, `ForwardSecondary`

## Priority Handling

### Priority Order

1. **Reset** (Highest)
2. **Hardware Interrupt** / Software Interrupt / RTI / RET
3. **CALL** / Unconditional Branch (JMP)
4. **Conditional Branch** (when taken)
5. **Memory Hazard**
6. **HLT Instruction**
7. **SWAP Instruction**
8. **Normal Operation** (Lowest)

## Sub-Module Documentation

- Opcode Decoder: `opcode-decoder/README.md`
- Memory Hazard Unit: `memory-hazard-unit/README.md`
- Interrupt Unit: `interrupt-unit/README.md`
- Freeze Control: `freeze-control/README.md`
- Branch Control: `branch-control/README.md`
  - Branch Predictor: `branch-control/branch-predictor/README.md`
  - Branch Decision Unit: `branch-control/branch-decision-unit/README.md`
- Forwarding Unit: `forwarding-unit/README.md`

## Files

- `README.md` - This documentation
- `BLOCK_DIAGRAM.md` - Visual diagrams
- `IMPLEMENTATION_SUMMARY.md` - Implementation overview
- `QUICK_REFERENCE.md` - Quick reference guide
