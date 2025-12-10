Here's the updated documentation with emojis removed and the change regarding the register file to only one write port:

---

## 1. ALU (Arithmetic Logic Unit)

### Module: `alu.vhd`

**Purpose:** Performs arithmetic and logical operations with flag generation.

### Interface:

| Port       | Direction | Width | Description             |
| ---------- | --------- | ----- | ----------------------- |
| `OperandA` | IN        | 32    | First operand           |
| `OperandB` | IN        | 32    | Second operand          |
| `ALU_Op`   | IN        | 4     | Operation select code   |
| `Result`   | OUT       | 32    | Operation result        |
| `Zero`     | OUT       | 1     | Zero flag (Result = 0)  |
| `Negative` | OUT       | 1     | Negative flag (MSB = 1) |
| `Carry`    | OUT       | 1     | Carry/Borrow flag       |

### ALU Operation Codes:

| ALU_Op | Mnemonic | Operation | Description                       |
| ------ | -------- | --------- | --------------------------------- |
| 0000   | ADD      | A + B     | Addition with carry detection     |
| 0001   | SUB      | A - B     | Subtraction with borrow detection |
| 0010   | AND      | A & B     | Bitwise AND                       |
| 0011   | NOT      | ~A        | Bitwise NOT of OperandA           |
| 0100   | INC      | A + 1     | Increment OperandA                |
| 0101   | PASS     | A         | Pass-through OperandA             |

### Flag Generation Logic:

- **Zero Flag:** Set when `Result = 0x00000000`
- **Negative Flag:** Set when `Result[31] = 1` (MSB)
- **Carry Flag:**

  - ADD/INC: Set when 33rd bit = 1 (overflow)
  - SUB: Set when borrow occurs (underflow)

### Implementation Notes:

- Uses 33-bit intermediate arithmetic for accurate carry/borrow detection
- All operations complete in one combinational cycle
- OperandB is ignored for NOT, INC, and PASS operations

---

## 2. Register File

### Module: `register_file.vhd`

**Purpose:** Provides storage for 8 general-purpose 32-bit registers (R0-R7).

### Interface:

| Port          | Direction | Width | Description                 |
| ------------- | --------- | ----- | --------------------------- |
| `clk`         | IN        | 1     | Clock signal                |
| `reset`       | IN        | 1     | Asynchronous reset          |
| `Ra`          | IN        | 3     | Read port A address (R0-R7) |
| `Rb`          | IN        | 3     | Read port B address (R0-R7) |
| `ReadDataA`   | OUT       | 32    | Data from port A (async)    |
| `ReadDataB`   | OUT       | 32    | Data from port B (async)    |
| `Rdst`        | IN        | 3     | Write destination address   |
| `WriteData`   | IN        | 32    | Data to write               |
| `WriteEnable` | IN        | 1     | Write enable                |

### Behavior:

- **Read Ports:** Asynchronous (combinational) - data available immediately
- **Write Port:** Synchronous - writes occur on rising edge of `clk` when `WriteEnable = '1'`
- **Reset:** All registers cleared to 0x00000000

### Register Mapping:

| Address | Register |
| ------- | -------- |
| 000     | R0       |
| 001     | R1       |
| 010     | R2       |
| 011     | R3       |
| 100     | R4       |
| 101     | R5       |
| 110     | R6       |
| 111     | R7       |

---

## 3. Condition Code Register (CCR)

### Module: `ccr.vhd`

**Purpose:** Stores processor flags for conditional branching.

### Interface:

| Port           | Direction | Width | Description              |
| -------------- | --------- | ----- | ------------------------ |
| `clk`          | IN        | 1     | Clock signal             |
| `reset`        | IN        | 1     | Asynchronous reset       |
| `ALU_Zero`     | IN        | 1     | Zero flag from ALU       |
| `ALU_Negative` | IN        | 1     | Negative flag from ALU   |
| `ALU_Carry`    | IN        | 1     | Carry flag from ALU      |
| `CCRWrEn`      | IN        | 1     | Write enable             |
| `PassCCR`      | IN        | 1     | Restore from stack (RTI) |
| `StackFlags`   | IN        | 3     | Flags from stack [Z,N,C] |
| `CCR_Out`      | OUT       | 3     | Current flags [Z,N,C]    |

### CCR Bit Layout:

| Bit | Flag | Description   |
| --- | ---- | ------------- |
| 2   | Z    | Zero flag     |
| 1   | N    | Negative flag |
| 0   | C    | Carry flag    |

### Behavior:

- **Normal Operation:** When `CCRWrEn = '1'` and `PassCCR = '0'`, CCR updates from ALU flags
- **RTI Operation:** When `CCRWrEn = '1'` and `PassCCR = '1'`, CCR restores from `StackFlags`
- **Hold State:** When `CCRWrEn = '0'`, CCR maintains current value
- **Reset:** All flags cleared to 0

---

## 4. Execute Stage Integration

### Module: `execute_stage.vhd`

**Purpose:** Top-level wrapper integrating ALU, Register File, and CCR with forwarding logic.

### Key Features:

#### OperandA Multiplexer (4:1):

Controls data source for ALU OperandA:

| ForwardA / spToALU | Source                |
| ------------------ | --------------------- |
| spToALU = 1        | Stack Pointer (SP)    |
| 00                 | Register File Port A  |
| 01                 | Stack Pointer (SP)    |
| 10                 | Forwarded from EX/MEM |
| 11                 | Forwarded from MEM/WB |

#### OperandB Multiplexer (4:1):

Controls data source for ALU OperandB:

| ForwardB / ImmToALU | Source                 |
| ------------------- | ---------------------- |
| ImmToALU = 1        | Immediate/Offset value |
| 00                  | Register File Port B   |
| 01                  | Immediate/Offset value |
| 10                  | Forwarded from EX/MEM  |
| 11                  | Forwarded from MEM/WB  |

### Control Signal Dependencies:

**From Member 2 (Control Unit):**

- `ALU_Op[3:0]` - Selects ALU operation
- `spToALU` - Routes SP to OperandA
- `ImmToALU` - Routes immediate to OperandB
- `CCRWrEn` - Enables CCR update
- `PassCCR` - Selects CCR restore mode
- `ForwardA[1:0]` - OperandA forwarding select
- `ForwardB[1:0]` - OperandB forwarding select

**From Member 4 (Memory Stage):**

- `SP[31:0]` - Stack pointer value

**To Member 2 (Control Unit):**

- `CCR_Out[2:0]` - Current flags for branch decisions

**To Member 1 (Pipeline Register):**

- `ALU_Result[31:0]` - Computation result
- `RegB_Out[31:0]` - Register B data for memory write

---

## 5. EX/MEM Pipeline Register

### Module: `ex_mem_register.vhd`

**Purpose:** Latches execute stage outputs and control signals for memory stage.

### Interface:

**Data Signals:**

- `ALU_Result` [32] - ALU computation result
- `RegB_Data` [32] - Data for memory write operations
- `CCR` [3] - Condition code flags
- `PC` [32] - Program counter value

**Control Signals:**

- `MemRead` - Memory read enable
- `MemWrite` - Memory write enable
- `RegWrite` - Register write enable
- `MemToReg` - Select memory data for writeback
- `SpToMem` - Use SP for memory address
- `MemDataSel[1:0]` - Memory write data selector
- `Rdst[2:0]` - Destination register address
- `RegWrite2` - Second write enable (SWAP)

**Pipeline Control:**

- `enable` - Freeze for stalls (hold current values)
- `flush` - Insert bubble (clear all control signals)

---

## 6. Testing Requirements

### Unit Tests Completed:

1. **tb_alu.vhd** - Tests all ALU operations and flag generation

   - ADD with and without carry
   - SUB with and without borrow
   - AND, NOT, INC, PASS operations
   - Zero flag detection
   - Negative flag detection
   - Carry/borrow detection

2. **tb_register_file.vhd** - Tests register file operations

   - Reset functionality
   - Single port reads
   - Write operations
   - SWAP instruction support
   - Write conflict resolution
   - Read-after-write behavior

### Integration Tests Required:

1. **Simple ALU Test** (with Member 1 & 2):

   - Test: `MOV R1, R2; ADD R3, R1, R2`
   - Verify: Control signals propagate, ALU computes, registers update

2. **Forwarding Test** (with Member 1 & 2):

   - Test: Back-to-back dependent instructions from `test_hazards.asm`
   - Verify: ForwardA

/ForwardB signals route correct data

3. **CCR Branch Test** (with Member 2):

   - Test: `SUB R1, R1, R1; JZ target`
   - Verify: Zero flag sets, branch decision correct

---

## 7. Critical Path Analysis

### Timing Considerations:

**Critical Path:** ALU → CCR → Branch Decision

- ALU computation: ~5ns (33-bit add/sub)
- CCR register setup: ~1ns
- Branch condition evaluation: ~2ns (Member 2)
- **Total:** ~8ns critical path

### Optimization Strategies:

1. Use fast carry-lookahead in ALU for addition
2. Pipeline CCR update if timing violations occur
3. Consider early branch prediction (before CCR update)

---

## 8. Edge Cases Handled

### ALU Edge Cases:

- Overflow on ADD (0xFFFFFFFF + 0x00000001)
- Underflow on SUB (0x00000000 - 0x00000001)
- Zero result detection
- Negative result with MSB set
- NOT operation on all ones (0xFFFFFFFF)

### Register File Edge Cases:

- Simultaneous reads from the same register
- Write conflict (both ports write the same register)
- Read-after-write in the same cycle
- Reset during active write

### CCR Edge Cases:

- RTI flag restoration
- CCR hold during non-ALU instructions
- Flag preservation across pipeline bubbles

---

## 9. Dependencies and Coordination

### With Member 1 (Testing Lead):

- Defined `ex_mem_register.vhd` interface
- Provide execute stage outputs for pipeline register
- Coordinate wave configuration for debugging

### With Member 2 (Control Unit):

- Receive all control signals (ALU_Op, spToALU, ImmToALU, CCRWrEn, ForwardA, ForwardB)
- Provide CCR flags for conditional branch unit
- Coordinate SWAP instruction handling (stall vs dual-write)

### With Member 4 (Memory):

- Receive SP value for stack operations
- Receive StackFlags for RTI instruction
- Provide ALU_Result and RegB_Data to memory stage

---

## 10. File Checklist

### Implementation Files:

- `rtl/execute/alu.vhd`
- `rtl/execute/register_file.vhd`
- `rtl/execute/ccr.vhd`
- `rtl/execute/execute_stage.vhd`
- `rtl/execute/ex_mem_register.vhd`

### Testbench Files:

- `testbench/tb_alu.vhd`
- `testbench/tb_register_file.vhd`
- `testbench/tb_execute_stage.vhd` (integration test needed)

### Wave Configuration:

- `simulation/wave_configs/wave_execute.do`
