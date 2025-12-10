# Control Unit Quick Reference

## Instantiation Template

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;
use work.control_signals_pkg.all;

-- In your top-level processor entity
component control_unit is
    Port (
        clk                     : in  std_logic;
        rst                     : in  std_logic;
        -- ... (see full port list in control_unit.vhd)
    );
end component;

-- Instantiate in architecture
ctrl_inst : control_unit
    port map (
        clk                     => clk,
        rst                     => rst,
        opcode_DE               => opcode_from_instruction,
        -- ... (connect all signals)
    );
```

## Required Dependencies

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;           -- Instruction opcodes and constants
use work.control_signals_pkg.all;   -- Control signal record types
```

## Input Signals Checklist

### From Decode Stage (8 signals)

- [ ] `opcode_DE` - 5-bit instruction opcode
- [ ] `PC_DE` - 32-bit program counter
- [ ] `IsInterrupt_DE`, `IsHardwareInt_DE`, `IsCall_DE`, `IsReturn_DE`, `IsReti_DE`
- [ ] `IsJMP_DE`, `IsJMPConditional_DE`, `ConditionalType_DE`

### From Execute Stage (9 signals)

- [ ] `PC_EX` - 32-bit program counter
- [ ] `CCR_Flags_EX` - 3-bit condition flags (Z, N, C)
- [ ] `IsSwap_EX` - SWAP feedback
- [ ] `ActualBranchTaken_EX`, `ConditionalBranch_EX`
- [ ] `IsInterrupt_EX`, `IsHardwareInt_EX`, `IsReti_EX`

### From Memory Stage (3 signals)

- [ ] `MemRead_MEM`, `MemWrite_MEM`
- [ ] `IsHardwareInt_MEM`

### External (2 signals)

- [ ] `clk`, `rst`
- [ ] `HardwareInterrupt`

## Output Signals Checklist

### Control Signals (4 records)

- [ ] `decode_ctrl_out` - Record type with 10 fields
- [ ] `execute_ctrl_out` - Record type with 4 fields
- [ ] `memory_ctrl_out` - Record type with 8 fields
- [ ] `writeback_ctrl_out` - Record type with 3 fields

### Pipeline Control (5 signals)

- [ ] `PC_WriteEnable` - Enable PC register update
- [ ] `IFDE_WriteEnable` - Enable IF/DE pipeline register
- [ ] `InsertNOP_IFDE` - Insert bubble in IF/DE stage
- [ ] `FlushDE`, `FlushIF` - Flush stages

### Memory Control (3 signals)

- [ ] `PassPC_ToMem` - Allow fetch to access memory
- [ ] `MemRead_Out`, `MemWrite_Out` - Actual memory access

### Branch Control (2 signals)

- [ ] `BranchSelect` - Branch or PC+1
- [ ] `BranchTargetSelect` - 2-bit target source

### Interrupt Control (2 signals)

- [ ] `PassPC_NotPCPlus1` - Save current PC for HW interrupt
- [ ] `TakeInterrupt_ToIFDE` - Hardware interrupt flag

## Control Signal Records Usage

### Decode Control Record

```vhdl
signal decode_ctrl : decode_control_t;

-- Access individual fields:
OutBSelect          <= decode_ctrl.OutBSelect;          -- 2-bit
IsInterrupt         <= decode_ctrl.IsInterrupt;         -- 1-bit
IsHardwareInterrupt <= decode_ctrl.IsHardwareInterrupt; -- 1-bit
IsReturn            <= decode_ctrl.IsReturn;            -- 1-bit
IsCall              <= decode_ctrl.IsCall;              -- 1-bit
IsReti              <= decode_ctrl.IsReti;              -- 1-bit
IsJMP               <= decode_ctrl.IsJMP;               -- 1-bit
IsJMPConditional    <= decode_ctrl.IsJMPConditional;    -- 1-bit
ConditionalType     <= decode_ctrl.ConditionalType;     -- 2-bit
IsSwap              <= decode_ctrl.IsSwap;              -- 1-bit
```

### Execute Control Record

```vhdl
signal execute_ctrl : execute_control_t;

CCR_WriteEnable     <= execute_ctrl.CCR_WriteEnable;    -- 1-bit
PassCCR             <= execute_ctrl.PassCCR;            -- 1-bit
PassImm             <= execute_ctrl.PassImm;            -- 1-bit
ALU_Operation       <= execute_ctrl.ALU_Operation;      -- 3-bit
```

### Memory Control Record

```vhdl
signal memory_ctrl : memory_control_t;

SP_Enable           <= memory_ctrl.SP_Enable;           -- 1-bit
SP_Function         <= memory_ctrl.SP_Function;         -- 1-bit (0=dec, 1=inc)
SPtoMem             <= memory_ctrl.SPtoMem;             -- 1-bit
PassInterrupt       <= memory_ctrl.PassInterrupt;       -- 2-bit
MemRead             <= memory_ctrl.MemRead;             -- 1-bit
MemWrite            <= memory_ctrl.MemWrite;            -- 1-bit
FlagFromMem         <= memory_ctrl.FlagFromMem;         -- 1-bit
IsSwap              <= memory_ctrl.IsSwap;              -- 1-bit
```

### Writeback Control Record

```vhdl
signal writeback_ctrl : writeback_control_t;

MemToALU            <= writeback_ctrl.MemToALU;         -- 1-bit
RegWrite            <= writeback_ctrl.RegWrite;         -- 1-bit
OutPortWriteEn      <= writeback_ctrl.OutPortWriteEn;   -- 1-bit
```

## Common Constants

### Opcodes (from pkg_opcodes.vhd)

```vhdl
OP_NOP     : "00000"    OP_INC     : "00100"    OP_IADD    : "01010"
OP_HLT     : "00001"    OP_OUT     : "00101"    OP_PUSH    : "01011"
OP_SETC    : "00010"    OP_IN      : "00110"    OP_POP     : "01100"
OP_NOT     : "00011"    OP_MOV     : "00111"    OP_LDM     : "01101"
OP_SWAP    : "01000"    OP_LDD     : "01110"    OP_JMP     : "10100"
OP_ADD     : "01001"    OP_STD     : "01111"    OP_CALL    : "10101"
OP_SUB     : "01001"    OP_JZ      : "10000"    OP_RET     : "10110"
OP_AND     : "01001"    OP_JN      : "10001"    OP_INT     : "10111"
                        OP_JC      : "10010"    OP_RTI     : "11000"
```

### ALU Operations

```vhdl
ALU_ADD    : "000"      ALU_INC    : "100"
ALU_SUB    : "001"      ALU_NOT    : "101"
ALU_AND    : "010"      ALU_SETC   : "110"
ALU_PASS_A : "011"      ALU_NOP    : "111"
```

### Branch Target Select

```vhdl
TARGET_DECODE  : "00"   -- Immediate from decode stage
TARGET_EXECUTE : "01"   -- Immediate from execute stage
TARGET_MEMORY  : "10"   -- Interrupt vector from memory
TARGET_RESET   : "11"   -- Reset address (0)
```

### PassInterrupt Encoding

```vhdl
PASS_INT_NORMAL   : "00"   -- Normal operation (PC+1)
PASS_INT_RESET    : "01"   -- Reset vector
PASS_INT_SOFTWARE : "10"   -- Software interrupt (immediate)
PASS_INT_HARDWARE : "11"   -- Hardware interrupt (fixed)
```

### Condition Types

```vhdl
COND_ZERO     : "00"   -- JZ (Zero flag)
COND_NEGATIVE : "01"   -- JN (Negative flag)
COND_CARRY    : "10"   -- JC (Carry flag)
COND_UNCOND   : "11"   -- Unconditional (always true)
```

## Pipeline Register Example

### IF/DE Pipeline Register

```vhdl
-- Declare register signals
signal IFDE_instruction : std_logic_vector(31 downto 0);
signal IFDE_PC          : std_logic_vector(31 downto 0);
signal IFDE_valid       : std_logic;

-- On clock edge
process(clk, rst)
begin
    if rst = '1' then
        IFDE_instruction <= (others => '0');
        IFDE_PC          <= (others => '0');
        IFDE_valid       <= '0';
    elsif rising_edge(clk) then
        if IFDE_WriteEnable = '1' then
            if InsertNOP_IFDE = '1' or FlushIF = '1' then
                -- Insert NOP/bubble
                IFDE_instruction <= (others => '0');
                IFDE_valid       <= '0';
            else
                -- Normal operation
                IFDE_instruction <= instruction_from_IF;
                IFDE_PC          <= PC_from_IF;
                IFDE_valid       <= '1';
            end if;
        end if;
        -- If IFDE_WriteEnable = '0', register holds (freeze)
    end if;
end process;
```

### DE/EX Pipeline Register (with Control Signals)

```vhdl
-- Declare control signal registers
signal DEEX_execute_ctrl  : execute_control_t;
signal DEEX_memory_ctrl   : memory_control_t;
signal DEEX_writeback_ctrl: writeback_control_t;

-- On clock edge
process(clk, rst)
begin
    if rst = '1' then
        DEEX_execute_ctrl  <= EXECUTE_CTRL_DEFAULT;
        DEEX_memory_ctrl   <= MEMORY_CTRL_DEFAULT;
        DEEX_writeback_ctrl<= WRITEBACK_CTRL_DEFAULT;
    elsif rising_edge(clk) then
        if FlushDE = '1' then
            -- Flush: insert NOPs
            DEEX_execute_ctrl  <= EXECUTE_CTRL_DEFAULT;
            DEEX_memory_ctrl   <= MEMORY_CTRL_DEFAULT;
            DEEX_writeback_ctrl<= WRITEBACK_CTRL_DEFAULT;
        else
            -- Normal: propagate control signals
            DEEX_execute_ctrl  <= execute_ctrl_out;
            DEEX_memory_ctrl   <= memory_ctrl_out;
            DEEX_writeback_ctrl<= writeback_ctrl_out;
        end if;
    end if;
end process;
```

## PC Update Logic Example

```vhdl
process(clk, rst)
begin
    if rst = '1' then
        PC <= (others => '0');
    elsif rising_edge(clk) then
        if PC_WriteEnable = '1' then
            if BranchSelect = '1' then
                -- Branch: select target based on BranchTargetSelect
                case BranchTargetSelect is
                    when "00" => PC <= immediate_from_decode;
                    when "01" => PC <= immediate_from_execute;
                    when "10" => PC <= interrupt_vector_from_memory;
                    when "11" => PC <= (others => '0');  -- Reset
                    when others => PC <= PC + 1;
                end case;
            else
                -- Normal: PC + 1
                PC <= PC + 1;
            end if;
        end if;
        -- If PC_WriteEnable = '0', PC stays same (freeze)
    end if;
end process;
```

## Memory Access Arbitration Example

```vhdl
-- Memory multiplexer
process(PassPC_ToMem, MemRead_Out, MemWrite_Out, PC, memory_address_MEM)
begin
    if PassPC_ToMem = '1' then
        -- Fetch has priority (no memory stage conflict)
        memory_address <= PC;
        memory_read    <= '1';
        memory_write   <= '0';
    else
        -- Memory stage has priority
        memory_address <= memory_address_MEM;
        memory_read    <= MemRead_Out;
        memory_write   <= MemWrite_Out;
    end if;
end process;
```

## Debugging Tips

### Check Control Signal Values

```vhdl
-- In simulation, monitor these critical signals:
assert PC_WriteEnable = '1' or IFDE_WriteEnable = '0'
    report "PC frozen but IFDE not frozen - inconsistency!"
    severity warning;

assert not (FlushIF = '1' and InsertNOP_IFDE = '0')
    report "Flush requested but NOP not inserted"
    severity error;
```

### Verify Flush Logic

```vhdl
-- After branch misprediction:
-- Cycle N:   Misprediction detected
-- Cycle N+1: FlushIF='1', FlushDE='1', BranchSelect='1'
-- Cycle N+2: NOPs in IF and DE stages, fetch from correct target
```

### Monitor Hazard Conditions

```vhdl
-- Watch for multiple simultaneous stalls:
if (PassPC_ToMem = '0' and Stall_Interrupt = '1') then
    report "Both memory hazard and interrupt stall active"
    severity note;
end if;
```

## Performance Monitoring

### Stall Cycle Counter

```vhdl
signal stall_cycles : integer := 0;

process(clk)
begin
    if rising_edge(clk) then
        if PC_WriteEnable = '0' then
            stall_cycles <= stall_cycles + 1;
        end if;
    end if;
end process;
```

### Branch Prediction Accuracy

```vhdl
signal predictions     : integer := 0;
signal mispredictions  : integer := 0;

process(clk)
begin
    if rising_edge(clk) then
        if ConditionalBranch_EX = '1' then
            predictions <= predictions + 1;
            if PredictedTaken /= ActualBranchTaken_EX then
                mispredictions <= mispredictions + 1;
            end if;
        end if;
    end if;
end process;

-- Accuracy = 1 - (mispredictions / predictions)
```

## Common Issues and Solutions

### Issue: PC not updating

**Check**:

- `PC_WriteEnable = '1'`?
- Any stall conditions active?
- `PassPC_ToMem` value?

### Issue: Instructions not executing

**Check**:

- `InsertNOP_IFDE = '0'`?
- Flush signals cleared?
- Valid instruction in pipeline?

### Issue: Memory conflicts

**Check**:

- `MemRead_MEM` or `MemWrite_MEM` active?
- `PassPC_ToMem = '0'` causing fetch block?
- Expected behavior for Von Neumann architecture

### Issue: Branch misprediction not recovering

**Check**:

- `FlushIF` and `FlushDE` asserted?
- `BranchSelect` and `BranchTargetSelect` correct?
- PC updated to correct target?

### Issue: Interrupt not handling correctly

**Check**:

- Override signals generated?
- PassInterrupt encoding correct?
- Hardware interrupt propagating through pipeline?

## File Locations Reference

```
Implementation:  rtl/control/control_unit.vhd
Testbench:      testbench/tb_control_unit.vhd
Constants:      rtl/control/opcode-decoder/pkg_opcodes.vhd
Records:        rtl/control/opcode-decoder/control_signals_pkg.vhd
Documentation:  rtl/control/README.md
Diagrams:       rtl/control/BLOCK_DIAGRAM.md
Summary:        rtl/control/IMPLEMENTATION_SUMMARY.md
```

## Support Documents

- **README.md**: Complete system documentation
- **BLOCK_DIAGRAM.md**: Visual diagrams and timing
- **IMPLEMENTATION_SUMMARY.md**: Project completion summary
- Sub-module READMEs in each directory

---

For detailed information on any sub-module, refer to its specific README file in the corresponding directory.
