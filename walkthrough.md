# Running and Verifying Processor Test Cases

I have created a [run_tests.do](file:///d:/CMP/third-year-term1/ARCH/project/5-Staged-Pipelined-Processor/simulation/scripts/run_tests.do) script and updated the assembler to support your test cases.

## Key Features
- **Integrated Workflow**: The [run_tests.do](file:///d:/CMP/third-year-term1/ARCH/project/5-Staged-Pipelined-Processor/simulation/scripts/run_tests.do) script handles compilation, assembly, and simulation in one go.
- **Enhanced Assembler**: 
    - Supports Hex numbers by default (`--hex` flag).
    - Supports `#` and `//` comments.
    - Implements macro for `JMP Rx` -> `PUSH Rx; RET`.
    - Supports `INT0`/`INT1` aliases.
    - Supports 32-bit immediates for `LDM`.

## How to Run Tests

### Option 1: From ModelSim Transcript
1. Load the script:
   ```tcl
   do simulation/scripts/run_tests.do
   ```
2. Run a specific test case:
   ```tcl
   run_test "Branch.asm"
   ```
   Available tests: `Branch.asm`, `BranchPrediction.asm`, `Memory.asm`, `OneOperand.asm`, `TwoOperand.asm`.

### Option 2: From PowerShell (Launch ModelSim)
```powershell
vsim -do simulation/scripts/run_tests.do
```

## Verification Guide
The `run_test` command will run the simulation for a set duration. You should inspect the **Wave** window to verify the results against the expected values found in the ASM comments.

### 1. OneOperand.asm
**Goal**: Test basic ALU operations (NOT, INC) and Input/Output.
**Expected Results**:
- **R1**: Starts at `FFFF`, increments to `0000` (overflow), input `000E`.
- **R2**: Input `0010`, NOT becomes `FFEF`.
- **Final Output (R2)**: `FFEA`.

### 2. TwoOperand.asm
**Goal**: Test MOV, SWAP, ADD, SUB, AND.
**Expected Results**:
- **R4**: `F322` + `0006` (from input) = `F328`.
- **R6**: `FFFE` - `F328` = `0CD6`.
- **SWAP R6, R1**: `R1` becomes `0CD6`, `R6` becomes `0006` (from prev R1).
- **MOV R1, R3**: R3 gets overwritten? No, syntax is MOV Src, Dst or Dst, Src?
  - *Note*: Project ISA usually defines `MOV Rsrc, Rdst` -> Rdst = Rsrc.
  - ASM comment says `R1, R3 #R3=0000000`. This suggests `MOV Rdst, Rsrc` syntax or `MOV Rsrc, Rdst`.
  - Let's check `opcode_decoder.vhd`: `MOV Rsrc1, Rdst: Rdst = Rsrc1`.
  - So `MOV R1, R3` means `R3 = R1`.
  - Wait, comment says `#R3=0000000`. If `R1` was `0006` (from SWAP), then `R3` should be `0006`.
  - *Correction*: The comment says `R3=0000000`. Maybe `R1` was 0?
  - Ah, `SWAP R6, R1`. Previous R1 was `0006` (from input). R6 was `0CD6`.
  - After SWAP: R6=`0006`, R1=`0CD6`.
  - `MOV R1, R3`. `R3 = R1` -> `R3 = 0CD6`.
  - Verify this in simulation.

### 3. Branch.asm
**Goal**: Test JMP, JZ, CALL, RET, INT, RTI, Forwarding with Branches.
**Expected Results**:
- **INT0 (Address 800)**: `R0` becomes `0`. Output `R6`.
- **INT1 (Address A00)**: Output `R1`.
- **Main Program**:
  - `JZ 50`: Should be NOT TAKEN? Comment says "Jump Not taken".
  - `JZ 400`: Should be TAKEN.
  - `CALL 300`: `SP` decrements, `PC` (return addr) pushed.
  - Inside `300`: `ADD` operations, then `RET`.
  - `RET`: Pop PC, return to `400`.
- **Final Checks**: Look for `R7` increments - they should NOT execute if jumps work correctly.

### 4. Memory.asm
**Goal**: Test LDM (32-bit), PUSH, POP, STD, LDD.
**Expected Results**:
- **LDM**: Check `R2=0010FE19`, `R3=0021FFFF`, `R4=00E5F320`.
- **Stack**: `PUSH` R1, R2. Check Memory at `3FFFF`, `3FFFE`.
- **POP**: Restore R1, R2 flipped.
- **STD/LDD**:
  - `STD R2, 50(R0)`: Store `FFF5` at `10200` (`101B0` + `50`).
  - Check Memory `10200` = `0010FE19`? No, check register values.
- **Forwarding in MEM**: `STD R3, 0(R4)` immediately following `LDD`.

### 5. BranchPrediction.asm
**Goal**: Test Branch Prediction Logic (if implemented).
**Expected Results**:
- Loops `JMP 20`.
- `OUT R4`: Should see sequence `2, 4, 8, 10, ...`.
- `JZ 60`: Jump if `R0 < R2`.

## Files Created/Modified
- `simulation/scripts/run_tests.do`: Main automation script.
- `src/assembler/assembler.py`: Updated python assembler.
