library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;

entity interrupt_unit is
    Port (
        -- Inputs from DECODE stage
        IsInterrupt_DE      : in  std_logic;  -- Software/Hardware interrupt in decode
        IsHardwareInt_DE    : in  std_logic;  -- Hardware interrupt flag in decode
        IsCall_DE           : in  std_logic;  -- CALL instruction in decode
        IsReturn_DE         : in  std_logic;  -- RET instruction in decode
        IsReti_DE           : in  std_logic;  -- RTI instruction in decode
        
        -- Inputs from DE/EX pipeline register (signals in EXECUTE stage)
        IsInterrupt_EX      : in  std_logic;  -- Software/Hardware interrupt in execute
        IsHardwareInt_EX    : in  std_logic;  -- Hardware interrupt flag in execute
        IsReti_EX           : in  std_logic;  -- RTI instruction in execute
        
        -- Inputs from EX/MEM pipeline register (signals in MEMORY stage)
        IsHardwareInt_MEM   : in  std_logic;  -- Hardware interrupt flag in memory
        
        -- External hardware interrupt
        HardwareInterrupt   : in  std_logic;  -- External hardware interrupt signal
        
        -- Outputs
        Stall               : out std_logic;                      -- Stall signal to Freeze Control
        PassPC_NotPCPlus1   : out std_logic;                      -- For hardware interrupt (pass current PC)
        TakeInterrupt       : out std_logic;                      -- Signal decoder to treat as interrupt
        IsHardwareIntMEM_Out: out std_logic;                      -- Hardware interrupt in memory (to decoder)
        OverrideOperation   : out std_logic;                      -- Enable override
        OverrideType        : out std_logic_vector(1 downto 0)    -- Type of override operation
    );
end interrupt_unit;

architecture Behavioral of interrupt_unit is
    signal any_interrupt_operation : std_logic;
begin
    
    -- Detect if any interrupt-related operation is active
    any_interrupt_operation <= IsInterrupt_DE or IsInterrupt_EX or 
                               IsReti_DE or IsReti_EX or 
                               IsCall_DE or IsReturn_DE or
                               HardwareInterrupt;
    
    -- Stall signal: active during any interrupt processing
    -- This goes to Freeze Control to freeze fetch and PC
    Stall <= any_interrupt_operation;
    
    -- Override operation: active when we need to force push/pop
    OverrideOperation <= any_interrupt_operation;
    
    -- Hardware interrupt handling
    -- When hardware interrupt occurs, signal decoder to treat as interrupt
    -- This will be written to IF/DE register
    TakeInterrupt <= HardwareInterrupt;
    
    -- For hardware interrupt, we want to save current PC (not PC+1)
    PassPC_NotPCPlus1 <= HardwareInterrupt;
    
    -- Pass hardware interrupt flag in memory stage to decoder
    IsHardwareIntMEM_Out <= IsHardwareInt_MEM;
    
    -- Determine override type based on priority
    process(IsInterrupt_DE, IsInterrupt_EX, IsReti_DE, IsReti_EX, 
            IsCall_DE, IsReturn_DE, HardwareInterrupt)
    begin
        -- Default to PUSH_PC (doesn't matter since OverrideOperation will be '0')
        OverrideType <= OVERRIDE_PUSH_PC;
        
        -- Priority: Hardware interrupt during fetch doesn't override yet (it goes through TakeInterrupt)
        -- Once interrupt is in decode/execute, handle normally
        
        if IsInterrupt_DE = '1' then
            -- Interrupt (SW or HW) in decode: First cycle - push PC
            OverrideType <= OVERRIDE_PUSH_PC;
            
        elsif IsInterrupt_EX = '1' then
            -- Interrupt (SW or HW) in execute: Second cycle - push FLAGS
            OverrideType <= OVERRIDE_PUSH_FLAGS;
            
        elsif IsReti_DE = '1' then
            -- Return from interrupt in decode: First cycle - pop FLAGS (opposite order!)
            OverrideType <= OVERRIDE_POP_FLAGS;
            
        elsif IsReti_EX = '1' then
            -- Return from interrupt in execute: Second cycle - pop PC
            OverrideType <= OVERRIDE_POP_PC;
            
        elsif IsCall_DE = '1' then
            -- CALL instruction: Only push PC (single cycle)
            OverrideType <= OVERRIDE_PUSH_PC;
            
        elsif IsReturn_DE = '1' then
            -- RET instruction: Only pop PC (single cycle)
            OverrideType <= OVERRIDE_POP_PC;
            
        end if;
    end process;

end Behavioral;
