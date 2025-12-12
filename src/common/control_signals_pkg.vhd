LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE control_signals_pkg IS

    -- DECODE Stage Control Signals
    TYPE decode_control_t IS RECORD
        OutBSelect : STD_LOGIC_VECTOR(1 DOWNTO 0); -- Selects source for operand B
        IsInterrupt : STD_LOGIC; -- Software interrupt
        IsHardwareInterrupt : STD_LOGIC; -- Hardware interrupt (from external)
        IsReturn : STD_LOGIC; -- RET instruction
        IsCall : STD_LOGIC; -- CALL instruction
        IsReti : STD_LOGIC; -- RTI instruction
        IsJMP : STD_LOGIC; -- Unconditional jump
        IsJMPConditional : STD_LOGIC; -- Conditional jump
        IsSwap : STD_LOGIC; -- SWAP instruction (first cycle)
    END RECORD;

    -- EXECUTE Stage Control Signals
    TYPE execute_control_t IS RECORD
        CCR_WriteEnable : STD_LOGIC; -- Enable writing to CCR
        PassCCR : STD_LOGIC; -- Pass CCR to memory (PUSH FLAGS)
        PassImm : STD_LOGIC; -- Pass immediate value to ALU
        ALU_Operation : STD_LOGIC_VECTOR(2 DOWNTO 0); -- ALU operation code
        ConditionalType : STD_LOGIC_VECTOR(1 DOWNTO 0); -- Type of condition (Z/N/C) for branch predictor
    END RECORD;

    -- MEMORY Stage Control Signals
    TYPE memory_control_t IS RECORD
        SP_Enable : STD_LOGIC; -- Enable SP update
        SP_Function : STD_LOGIC; -- 0=decrement, 1=increment
        SPtoMem : STD_LOGIC; -- Use SP as memory address
        PassInterrupt : STD_LOGIC_VECTOR(1 DOWNTO 0); -- Pass interrupt address (00=normal, 01=reset, 10=SW int, 11=HW int)
        MemRead : STD_LOGIC; -- Memory read enable
        MemWrite : STD_LOGIC; -- Memory write enable
        FlagFromMem : STD_LOGIC; -- Load flags from memory (POP FLAGS)
        IsSwap : STD_LOGIC; -- SWAP in memory (disable forwarding)
    END RECORD;

    -- WRITEBACK Stage Control Signals
    TYPE writeback_control_t IS RECORD
        MemToALU : STD_LOGIC; -- 0=ALU result, 1=Memory data
        RegWrite : STD_LOGIC; -- Register file write enable
        OutPortWriteEn : STD_LOGIC; -- Output port write enable
    END RECORD;

    -- Default/Reset values for control signals
    CONSTANT DECODE_CTRL_DEFAULT : decode_control_t := (
        OutBSelect => "00",
        IsInterrupt => '0',
        IsHardwareInterrupt => '0',
        IsReturn => '0',
        IsCall => '0',
        IsReti => '0',
        IsJMP => '0',
        IsJMPConditional => '0',
        IsSwap => '0'
    );

    CONSTANT EXECUTE_CTRL_DEFAULT : execute_control_t := (
        CCR_WriteEnable => '0',
        PassCCR => '0',
        PassImm => '0',
        ALU_Operation => "000",
        ConditionalType => "00"
    );

    CONSTANT MEMORY_CTRL_DEFAULT : memory_control_t := (
        SP_Enable => '0',
        SP_Function => '0',
        SPtoMem => '0',
        PassInterrupt => "00",
        MemRead => '0',
        MemWrite => '0',
        FlagFromMem => '0',
        IsSwap => '0'
    );

    CONSTANT WRITEBACK_CTRL_DEFAULT : writeback_control_t := (
        MemToALU => '0',
        RegWrite => '0',
        OutPortWriteEn => '0'
    );

END PACKAGE control_signals_pkg;