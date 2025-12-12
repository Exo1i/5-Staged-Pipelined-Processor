library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package control_signals_pkg is
    
    -- DECODE Stage Control Signals
    type decode_control_t is record
        OutBSelect          : std_logic_vector(1 downto 0);  -- Selects source for operand B
        IsInterrupt         : std_logic;                      -- Software interrupt
        IsHardwareInterrupt : std_logic;                      -- Hardware interrupt (from external)
        IsReturn            : std_logic;                      -- RET instruction
        IsCall              : std_logic;                      -- CALL instruction
        IsReti              : std_logic;                      -- RTI instruction
        IsJMP               : std_logic;                      -- Unconditional jump
        IsJMPConditional    : std_logic;                      -- Conditional jump
        IsSwap              : std_logic;                      -- SWAP instruction (first cycle)
    end record;
    
    -- EXECUTE Stage Control Signals
    type execute_control_t is record
        CCR_WriteEnable     : std_logic;                      -- Enable writing to CCR
        PassCCR             : std_logic;                      -- Pass CCR to memory (PUSH FLAGS)
        PassImm             : std_logic;                      -- Pass immediate value to ALU
        ALU_Operation       : std_logic_vector(2 downto 0);   -- ALU operation code
        ConditionalType     : std_logic_vector(1 downto 0);   -- Type of condition (Z/N/C) for branch predictor
    end record;
    
    -- MEMORY Stage Control Signals
    type memory_control_t is record
        SP_Enable           : std_logic;                      -- Enable SP update
        SP_Function         : std_logic;                      -- 0=decrement, 1=increment
        SPtoMem             : std_logic;                      -- Use SP as memory address
        PassInterrupt       : std_logic_vector(1 downto 0);  -- Pass interrupt address (00=normal, 01=reset, 10=SW int, 11=HW int)
        MemRead             : std_logic;                      -- Memory read enable
        MemWrite            : std_logic;                      -- Memory write enable
        FlagFromMem         : std_logic;                      -- Load flags from memory (POP FLAGS)
        IsSwap              : std_logic;                      -- SWAP in memory (disable forwarding)
    end record;
    
    -- WRITEBACK Stage Control Signals
    type writeback_control_t is record
        MemToALU            : std_logic;                      -- 0=ALU result, 1=Memory data
        RegWrite            : std_logic;                      -- Register file write enable
        OutPortWriteEn      : std_logic;                      -- Output port write enable
    end record;
    
    -- Default/Reset values for control signals
    constant DECODE_CTRL_DEFAULT : decode_control_t := (
        OutBSelect          => "00",
        IsInterrupt         => '0',
        IsHardwareInterrupt => '0',
        IsReturn            => '0',
        IsCall              => '0',
        IsReti              => '0',
        IsJMP               => '0',
        IsJMPConditional    => '0',
        IsSwap              => '0'
    );
    
    constant EXECUTE_CTRL_DEFAULT : execute_control_t := (
        CCR_WriteEnable     => '0',
        PassCCR             => '0',
        PassImm             => '0',
        ALU_Operation       => "000",
        ConditionalType     => "00"
    );
    
    constant MEMORY_CTRL_DEFAULT : memory_control_t := (
        SP_Enable           => '0',
        SP_Function         => '0',
        SPtoMem             => '0',
        PassInterrupt       => "00",
        MemRead             => '0',
        MemWrite            => '0',
        FlagFromMem         => '0',
        IsSwap              => '0'
    );
    
    constant WRITEBACK_CTRL_DEFAULT : writeback_control_t := (
        MemToALU            => '0',
        RegWrite            => '0',
        OutPortWriteEn      => '0'
    );
    
end package control_signals_pkg;
