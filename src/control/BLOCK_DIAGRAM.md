# Control Unit Block Diagram

## Complete System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  CONTROL UNIT                                            │
│                                                                                          │
│  ┌────────────────────────────────────────────────────────────────────────────────────--┐│
│  │                              OPCODE DECODER                                          ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐                ││
│  │  │  5-bit   │  │ Override │  │  SWAP    │  │   Take   │  │ HW Int   │                ││
│  │  │ Opcode   │→ │ Logic    │← │ Feedback │← │Interrupt │← │  Flag    │                ││
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘                ││
│  │       ↓             ↑              ↑              ↑              ↑                   ││
│  │  Decode Table   Interrupt      Execute      Interrupt      Interrupt                 ││
│  │       ↓           Unit           Stage         Unit           Unit                   ││
│  │  ┌────────────────────────────────────────────────────────────────┐                  ││
│  │  │         Control Signal Records (decode/execute/memory/wb)      │                  ││
│  │  └────────────────────────────────────────────────────────────────┘                  ││
│  └───────────────────────────┬──────────────────────────────────────────────────────----┘│
│                               ↓                                                          │
│                    Control Signals to Pipeline                                           │
│                                                                                          │
│  ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐        │
│  │  MEMORY HAZARD UNIT  │    │   INTERRUPT UNIT     │    │   FREEZE CONTROL     │        │
│  │                      │    │                      │    │                      │        │
│  │  MemRead_MEM  ────┐  │    │  HW Interrupt  ────┐ │    │  PassPC_MEM  ─────┐  │        │
│  │  MemWrite_MEM ────┤  │    │  INT/CALL/RET  ────┤ │    │  Stall_Int   ─────┤  │        │
│  │                   │  │    │  Pipeline Prop ────┤ │    │  Stall_Branch ────┤  │        │
│  │  ┌────────────────▼┐ │    │  ┌─────────────────▼┐│    │  ┌────────────────▼ ┐│        │
│  │  │  Priority Logic  ││    │  │ Override Logic   ││    │  │  OR all stalls  │ │        │
│  │  └────────────────┬─┘│    │  └─────────────────┬┘│    │  └────────────────┬┘ │        │
│  │                   ↓  │    │                    ↓ │    │                   ↓  │        │
│  │  PassPC (to Freeze)  │    │  Override (to Dec.)  │    │  PC_WriteEnable      │        │
│  │  MemRead/Write_Out   │    │  Stall (to Freeze)   │    │  IFDE_WriteEnable    │        │
│  │                      │    │  TakeInterrupt       │    │  InsertNOP_IFDE      │        │
│  └──────────┬───────────┘    └──────────┬───────────┘    └──────────┬─────────-─┘        │
│             │                           │                           │                    │
│             └───────────────────────────┴───────────────────────────┘                    │
│                                         │                                                │
│                              Pipeline Control Signals                                    │
│                                                                                          │
│  ┌──────────────────────┐                        ┌──────────────────────┐                │
│  │  BRANCH PREDICTOR    │                        │  BRANCH DECISION     │                │
│  │                      │                        │       UNIT           │                │
│  │  ┌────────────────┐  │                        │  ┌────────────────┐  │                │
│  │  │ Prediction     │  │    PredictedTaken      │  │  Priority      │  │                │
│  │  │ Table (4-ent)  │  │  ─────────────────────→│  │  Encoder       │  │                │
│  │  └────────────────┘  │                        │  │                │  │                │
│  │  ┌────────────────┐  │                        │  │  Reset         │  │                │
│  │  │ 2-bit Saturate │  │                        │  │  HW Interrupt  │  │                │
│  │  │ Counter Logic  │  │                        │  │  SW Interrupt  │  │                │
│  │  └────────────────┘  │                        │  │  Uncond Branch │  │                │
│  │  ┌────────────────┐  │    ActualTaken         │  │  Misprediction │  │                │
│  │  │ CCR Condition  │  │  ─────────────────────→│  │                │  │                │
│  │  │ Evaluator      │  │                        │  └────────────────┘  │                │
│  │  └────────────────┘  │                        │          ↓           │                │
│  │         ↑            │                        │  BranchSelect        │                │
│  │   Update on Clock    │                        │  BranchTargetSelect  │                │
│  │                      │                        │  FlushIF, FlushDE    │                │
│  └──────────────────────┘                        └──────────────────────┘                │
│                                                                                          │
└────────────────────────────────────────────────────────────────────────────────────────-─┘
```

## Data Flow Diagram

```
                                    ┌────────────────--─┐
                                    │  External Input   │
                                    │  HardwareInterrupt|
                                    └────────┬─────────-┘
                                             ↓
┌─────────────────┐              ┌──────────────────────┐
│  DECODE STAGE   │              │  INTERRUPT UNIT      │
│                 │              │                      │
│  Opcode ────────┼─────────────→│  Override Gen        │
│  IsInterrupt    │              │  HW Int Tracking     │
│  IsCall/Ret/RTI │              │  Stall Generation    │
│  PC_DE          │              └──────────┬───────────┘
└────────┬────────┘                         ↓
         │                          ┌───────────────────┐
         │                          │  Override signals │
         │                          └────────┬──────────┘
         │                                   ↓
         │                          ┌──────────────────────┐
         └─────────────────────────→│  OPCODE DECODER      │
                                    │                      │
┌─────────────────┐                 │  - Decode logic      │
│  EXECUTE STAGE  │                 │  - Override handling │
│                 │                 │  - SWAP handling     │
│  IsSwap_EX   ───┼────────────────→│  - PassInterrupt     │
│  CCR_Flags   ───┼──┐              └──────────┬───────────┘
│  ActualTaken ───┼──┼──┐                      ↓
│  PC_EX       ───┼──┼──┼──┐          ┌────────────────────┐
└─────────────────┘  │  │  │          │ Control Records    │
                     │  │  │          │ (decode/exec/      │
                     │  │  │          │  mem/wb)           │
                     │  │  │          └────────┬───────────┘
                     │  │  │                   │
                     │  │  │                   ↓
                     │  │  │          To Pipeline Stages
                     │  │  │
                     ↓  ↓  ↓
         ┌───────────────────────────┐
         │   BRANCH PREDICTOR        │
         │                           │
         │  Prediction Table         │
         │  ↓                        │
         │  PredictedTaken ──────────┼──┐
         │  TreatAsUnconditional     │  │
         └───────────────────────────┘  │
                                        │
┌─────────────────┐                     │
│  MEMORY STAGE   │                     │
│                 │                     ↓
│  MemRead_MEM ───┼──────┐     ┌───────────────────────┐
│  MemWrite_MEM ──┼──────┼────→│  BRANCH DECISION UNIT │
│                 │      │     │                       │
└─────────────────┘      │     │  Priority Logic       │
                         │     │  Misprediction Det    │
                         ↓     │  Flush Generation     │
              ┌────────────────┤                       │
              │  MEMORY HAZARD │  BranchSelect  ───────┼──┐
              │      UNIT      │  BranchTargetSel ─────┼──┼──┐
              │                │  FlushIF/DE  ─────────┼──┼──┼──┐
              │  PassPC  ──────┤                       │  │  │  │
              └────────┬───────┴───────────────────────┘  │  │  │
                       │                                  │  │  │
                       ↓                                  │  │  │
              ┌────────────────┐                          │  │  │
              │ FREEZE CONTROL │                          │  │  │
              │                │                          │  │  │
              │  OR all stalls │                          │  │  │
              │                │                          │  │  │
              │ PC_WriteEnable ─────────────────────────-┼──┼──┼──┐
              │ IFDE_WriteEnable ──────────────────────-─┼──┼──┼──┼──┐
              │ InsertNOP_IFDE ────────────────────────-─┼──┼──┼──┼──┼──┐
              └────────────────┘                          ↓  ↓  ↓  ↓  ↓  ↓
                                                    ┌────────────────────────┐
                                                    │   PIPELINE CONTROL     │
                                                    │   SIGNALS OUTPUT       │
                                                    └────────────────────────┘
```

## Signal Interconnection Matrix

| From Module      | To Module       | Signal                    | Purpose                    |
| ---------------- | --------------- | ------------------------- | -------------------------- |
| Interrupt Unit   | Opcode Decoder  | `OverrideOperation`       | Enable forced operation    |
| Interrupt Unit   | Opcode Decoder  | `OverrideType[1:0]`       | Type of forced operation   |
| Interrupt Unit   | Opcode Decoder  | `TakeInterrupt`           | Treat as interrupt         |
| Interrupt Unit   | Opcode Decoder  | `IsHardwareIntMEM_Out`    | HW int in memory stage     |
| Interrupt Unit   | Freeze Control  | `Stall`                   | Stall for interrupt        |
| Memory Hazard    | Freeze Control  | `PassPC`                  | Memory available for fetch |
| Branch Decision  | Freeze Control  | `Stall_Branch`            | Stall for branch           |
| Opcode Decoder   | Pipeline Stages | `decode_ctrl`             | Decode stage controls      |
| Opcode Decoder   | Pipeline Stages | `execute_ctrl`            | Execute stage controls     |
| Opcode Decoder   | Pipeline Stages | `memory_ctrl`             | Memory stage controls      |
| Opcode Decoder   | Pipeline Stages | `writeback_ctrl`          | Writeback stage controls   |
| Branch Predictor | Branch Decision | `PredictedTaken`          | Branch prediction          |
| Branch Decision  | PC Logic        | `BranchSelect`            | Take branch or not         |
| Branch Decision  | PC Logic        | `BranchTargetSelect[1:0]` | Target source select       |
| Branch Decision  | Pipeline        | `FlushIF`                 | Flush fetch stage          |
| Branch Decision  | Pipeline        | `FlushDE`                 | Flush decode stage         |
| Freeze Control   | PC              | `PC_WriteEnable`          | Allow PC update            |
| Freeze Control   | IF/DE Register  | `IFDE_WriteEnable`        | Allow register update      |
| Freeze Control   | IF/DE Register  | `InsertNOP_IFDE`          | Insert NOP                 |
| Memory Hazard    | Memory          | `MemRead_Out`             | Actual memory read         |
| Memory Hazard    | Memory          | `MemWrite_Out`            | Actual memory write        |

## Pipeline Stage Control Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                            PIPELINE STAGES                                  │
└────────────────────────────────────────────────────────────────────────────┘
     │            │            │            │            │
     ↓            ↓            ↓            ↓            ↓
┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
│   IF   │  │   DE   │  │   EX   │  │  MEM   │  │   WB   │
└───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘
    │           │           │           │           │
    │           │           │           │           │
    │           ↓           │           │           │
    │    ┌──────────────┐   │           │           │
    │    │ decode_ctrl  │   │           │           │
    │    └──────────────┘   │           │           │
    │                       │           │           │
    │                       ↓           │           │
    │                ┌──────────────┐   │           │
    │                │ execute_ctrl │   │           │
    │                └──────────────┘   │           │
    │                                   │           │
    │                                   ↓           │
    │                            ┌──────────────┐   │
    │                            │ memory_ctrl  │   │
    │                            └──────────────┘   │
    │                                               │
    │                                               ↓
    │                                        ┌──────────────┐
    │                                        │writeback_ctrl│
    │                                        └──────────────┘
    │
    ↓
┌─────────────────────┐
│  PC_WriteEnable     │ ← Freeze/Allow PC update
│  PassPC_ToMem       │ ← Memory access priority
│  TakeInterrupt      │ ← Hardware interrupt flag
└─────────────────────┘

┌─────────────────────┐
│  IFDE_WriteEnable   │ ← Freeze/Allow IF/DE register
│  InsertNOP_IFDE     │ ← Insert bubble
│  FlushIF            │ ← Clear IF stage
└─────────────────────┘

┌─────────────────────┐
│  FlushDE            │ ← Clear DE stage
└─────────────────────┘
```

## Timing Diagram Example: Branch Misprediction

```
Clock:     │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │

IF Stage:  │ JZ  │ A   │ B   │ C   │Flush│ X   │ Y   │ Z   │
           │     │     │     │     │     │(tgt)│     │     │
                               ↑         ↑
                               │         │
DE Stage:  │ ... │ JZ  │ A   │ B   │Flush│Flush│ X   │ Y   │
                       │     │     │     │     │     │     │
                       │Pred:│     │     │     │     │     │
                       │NotTk│     │     │     │     │     │

EX Stage:  │ ... │ ... │ JZ  │ A   │ B   │Flush│Flush│ X   │
                               │     │     │     │     │     │
                               │Eval:│     │     │     │     │
                               │Taken│     │     │     │     │
                               ↓     │     │     │     │     │
Branch Decision:          Misprediction!

Signals:
BranchSelect:              0     0     1     0     0     0
FlushIF:                   0     0     1     0     0     0
FlushDE:                   0     0     1     0     0     0
BranchTargetSel:          00    00    01    00    00    00
PC:                       JZ    A     B     C     X     X+1

Penalty: 2 cycles (fetched A and B incorrectly)
```

## Module Dependencies

```
                  ┌──────────────────┐
                  │  pkg_opcodes     │ (Constants)
                  └────────┬─────────┘
                           │
                           ↓
                  ┌──────────────────┐
                  │control_signals   │ (Record types)
                  │    _pkg          │
                  └────────┬─────────┘
                           │
                           ↓
         ┌─────────────────┴─────────────────┐
         │                                   │
         ↓                                   ↓
┌─────────────────┐                 ┌─────────────────┐
│ Opcode Decoder  │                 │ Branch Predictor│
└────────┬────────┘                 └────────┬────────┘
         │                                   │
         │    ┌─────────────────┐            │
         │    │ Memory Hazard   │            │
         │    │     Unit        │            │
         │    └────────┬────────┘            │
         │             │                     │
         │    ┌────────┴────────┐            │
         │    │ Interrupt Unit  │            │
         │    └────────┬────────┘            │
         │             │                     │
         │    ┌────────┴────────┐            │
         │    │ Freeze Control  │            │
         │    └────────┬────────┘            │
         │             │                     │
         │    ┌────────┴────────┐            │
         │    │ Branch Decision │←────────--─┘
         │    │     Unit        │
         │    └────────┬────────┘
         │             │
         └─────────────┴─────────────────┐
                                         │
                                         ↓
                              ┌──────────────────┐
                              │  Control Unit    │
                              │   (Top Level)    │
                              └──────────────────┘
```

## Critical Paths

### Path 1: Opcode to Control Signals

```
opcode_DE → Opcode Decoder → Control Records → Pipeline Stages
Critical: Must complete within single cycle
```

### Path 2: Memory Hazard Detection

```
MemRead/Write_MEM → Memory Hazard Unit → PassPC → Freeze Control → PC/IFDE
Critical: Must resolve before next clock edge
```

### Path 3: Branch Decision

```
ActualTaken_EX → Branch Decision Unit → BranchSelect/Flush → PC/Pipeline
Critical: Affects next instruction fetch
```

### Path 4: Interrupt Processing

```
HardwareInterrupt → Interrupt Unit → Override → Opcode Decoder → Controls
Critical: Must generate override within cycle
```

## Testing Strategy

### Unit Testing (Individual Modules)

- ✓ Opcode Decoder: 26 instructions + overrides
- ✓ Memory Hazard Unit: Priority logic
- ✓ Interrupt Unit: All interrupt types
- ✓ Freeze Control: Stall combinations
- ✓ Branch Predictor: Prediction states
- ✓ Branch Decision: Priority and mispredictions

### Integration Testing (Top Level)

- ✓ Normal instruction flow
- ✓ Hazard detection and stalling
- ✓ Interrupt handling (SW/HW)
- ✓ Branch prediction and mispredictions
- ✓ Priority conflicts
- ✓ Edge cases (simultaneous events)

### System Testing (With Processor)

- Complete programs
- Mixed instruction sequences
- Stress tests (nested interrupts, back-to-back branches)
- Performance benchmarks
