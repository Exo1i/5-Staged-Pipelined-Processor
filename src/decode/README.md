# Decode Stage

The Decode Stage is the second stage of the 5-stage pipelined processor. It is responsible for instruction decoding, register file access, operand preparation, and control signal generation.

## Files

| File                 | Description                    |
| -------------------- | ------------------------------ |
| `decode_stage.vhd`   | Main decode stage module       |
| `id_ex_register.vhd` | ID/EX pipeline register        |
| `register_file.vhd`  | 8x32-bit register file (R0-R7) |

## Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │                   DECODE STAGE                       │
                    │                                                      │
  From IF/ID ──────►│  ┌──────────────┐    ┌─────────────────┐            │
  (instruction)     │  │  Instruction │───►│  Register File  │            │
                    │  │   Decoder    │    │    (8x32-bit)   │            │
                    │  └──────────────┘    └────────┬────────┘            │
                    │         │                     │                      │
                    │         ▼                     ▼                      │
                    │  ┌──────────────┐    ┌─────────────────┐            │
  From Control ────►│  │   Control    │    │  Operand Muxes  │────────────┼───► To ID/EX
  (ctrl signals)    │  │   Routing    │    │  (B select,     │            │
                    │  └──────────────┘    │   SWAP logic)   │            │
                    │                       └─────────────────┘            │
                    │                                                      │
  From Writeback ──►│  (Register write-back path)                         │
                    │                                                      │
                    └─────────────────────────────────────────────────────┘
                                          │
                                          ▼
                                   ┌──────────────┐
                                   │  ID/EX Reg   │
                                   └──────────────┘
                                          │
                                          ▼
                                    To Execute Stage
```

## Module Descriptions

### decode_stage.vhd

The main decode stage module that:

- **Extracts instruction fields**: Opcode, Rsrc1, Rsrc2, Rdst, immediate values
- **Reads register operands**: Via the register file using Rsrc1 and Rsrc2
- **Selects Operand B**: Chooses between register data, immediate, or IN port based on `OutBSelect`
- **Handles SWAP instruction**: Swaps Rsrc2 and Rdst when SWAP is in Execute stage
- **Routes control signals**: Passes control signals from the Control Unit to ID/EX register
- **Provides feedback**: Outputs opcode and instruction type flags for control unit

**Key Ports:**

| Port                             | Direction | Description                                                             |
| -------------------------------- | --------- | ----------------------------------------------------------------------- |
| `instruction_in`                 | IN        | 32-bit instruction from IF/ID register                                  |
| `immediate_from_fetch`           | IN        | 32-bit immediate value from Fetch stage (fetched in cycle after opcode) |
| `decode_ctrl`                    | IN        | Decode control signals from opcode decoder                              |
| `execute_ctrl`                   | IN        | Execute control signals from opcode decoder                             |
| `memory_ctrl`                    | IN        | Memory control signals from opcode decoder                              |
| `writeback_ctrl`                 | IN        | Writeback control signals from opcode decoder                           |
| `stall_control`                  | IN        | Stall signal from branch decision unit                                  |
| `in_port`                        | IN        | External input port data                                                |
| `is_swap_ex`                     | IN        | SWAP instruction in Execute stage (feedback)                            |
| `wb_rd`, `wb_data`, `wb_enable`  | IN        | Writeback signals for register file                                     |
| `operand_a_out`, `operand_b_out` | OUT       | Selected operands for Execute stage                                     |
| `immediate_out`                  | OUT       | 32-bit immediate value passed to ID/EX register                         |
| `opcode_out`                     | OUT       | Extracted opcode for control unit                                       |
| `is_*_out`                       | OUT       | Instruction type flags for control unit                                 |

**Immediate Value Handling:**

The immediate value is fetched in the cycle **after** the opcode. When an instruction with an immediate operand is in the Decode stage, the Fetch stage is simultaneously fetching the 32-bit immediate value. This immediate is passed directly via `immediate_from_fetch` rather than being extracted from the instruction word itself.

### id_ex_register.vhd

Pipeline register between Decode and Execute stages:

- **Stores all decoded data**: PC, operands, immediate, register addresses
- **Stores control signals**: All 4 control signal records
- **Stores instruction type flags**: For control unit feedback from Execute stage
- **Supports flush**: Inserts NOP on pipeline flush (branch misprediction, etc.)
- **Supports stall**: Hold values when `enable = '0'`

**Control Signal Records:**

| Record                | Purpose                                      |
| --------------------- | -------------------------------------------- |
| `decode_control_t`    | Operand selection, instruction type flags    |
| `execute_control_t`   | ALU operation, flags update control          |
| `memory_control_t`    | Memory read/write, stack operations          |
| `writeback_control_t` | Register write enable, data source selection |

**Feedback Signals (to Control Unit):**

| Signal                   | Purpose                                    |
| ------------------------ | ------------------------------------------ |
| `is_swap_out`            | SWAP instruction feedback for decode stage |
| `is_interrupt_out`       | Interrupt handling in interrupt unit       |
| `is_hardware_int_out`    | Hardware interrupt tracking                |
| `is_reti_out`            | Return from interrupt handling             |
| `is_return_out`          | Return instruction handling                |
| `is_call_out`            | Call instruction handling                  |
| `conditional_branch_out` | Branch predictor update                    |

### register_file.vhd

8x32-bit register file with:

- **8 registers**: R0 through R7
- **Dual read ports**: Asynchronous (combinational) reads via Ra and Rb
- **Single write port**: Synchronous write on rising clock edge
- **Reset support**: All registers cleared to 0 on reset

## Instruction Format

Instructions that require an immediate value use a **two-word format**:

**Word 1 (Opcode Word) - Fetched in Cycle N:**

```
31    27 26  24 23  21 20  18 17                                     0
┌───────┬──────┬──────┬──────┬────────────────────────────────────────┐
│ Opcode│ Rsrc1│ Rsrc2│ Rdst │              Reserved                  │
│ (5b)  │ (3b) │ (3b) │ (3b) │              (18 bits)                 │
└───────┴──────┴──────┴──────┴────────────────────────────────────────┘
```

**Word 2 (Immediate Word) - Fetched in Cycle N+1:**

```
31                                                                   0
┌────────────────────────────────────────────────────────────────────┐
│                      32-bit Immediate Value                         │
└────────────────────────────────────────────────────────────────────┘
```

**Timing:**

- Cycle N: Fetch stage fetches opcode word → stored in IF/ID register
- Cycle N+1: Fetch stage fetches immediate word → passed directly to Decode via `immediate_from_fetch`

This allows full 32-bit immediate values without limiting the opcode/register encoding space.

## Control Signal Flow

The **Opcode Decoder** takes its input directly from the **IF/ID Register** (instruction opcode) and generates:

1. Control signals for the Decode Stage
2. Instruction type signals for Interrupt Unit, Branch Predictor, and Freeze Control

```
                            IF/ID Register
                                  │
                                  │ instruction[31:27] (opcode)
                                  ▼
                     ┌─────────────────────────┐
                     │     Opcode Decoder      │
                     │  (in Control Unit area) │
                     └────────────┬────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Control Sigs   │    │ Instruction Type│    │ Instruction Type│
│  (decode/exec/  │    │ → Interrupt Unit│    │ → Branch Pred   │
│   mem/wb_ctrl)  │    │ → Freeze Control│    │   & Decision    │
└────────┬────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Decode Stage   │───────────────────────────────────────────────┐
│  (register file,│                                               │
│   operand mux)  │◄──── immediate_from_fetch (from Fetch Stage)  │
└────────┬────────┘                                               │
         │                                                        │
         │ immediate_out ─────────────────────────────────────────┼──► target_decode
         ▼                                                        │    (to Fetch Stage)
┌─────────────────┐                                               │
│  ID/EX Register │◄──────────────────────────────────────────────┘
└────────┬────────┘
         │
         ▼
   Execute Stage
```

**Key Signal Paths:**

1. **Opcode Decoder → Decode Stage**: Control signals (decode_ctrl, execute_ctrl, memory_ctrl, writeback_ctrl)
2. **Opcode Decoder → Interrupt Unit**: is_interrupt, is_call, is_return, is_reti
3. **Opcode Decoder → Branch Predictor**: is_jmp, is_call, is_jmp_conditional, conditional_type
4. **Decode Stage → Fetch Stage**: `immediate_out` (via `target_decode`) for branch target addresses
5. **Fetch Stage → Decode Stage**: `immediate_from_fetch` (current fetch word as immediate value)

## Testbenches

Located in `testbench/` subdirectory:

- `tb_control_unit.vhd` - Tests control signal generation
- `tb_register_file.vhd` - Tests register file read/write operations

## Dependencies

- `work.pkg_opcodes` - Opcode definitions (OP_NOP, OP_SWAP, etc.)
- `work.control_signals_pkg` - Control signal record types
