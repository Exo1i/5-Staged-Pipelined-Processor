LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pkg_opcodes.ALL;

ENTITY interrupt_unit IS
    PORT (
        -- Inputs from DECODE stage
        IsInterrupt_DE : IN STD_LOGIC; -- Software/Hardware interrupt in fetch
        IsRet_DE : IN STD_LOGIC; -- RET instruction in fetch
        IsReti_DE : IN STD_LOGIC; -- RTI instruction in fetch

        IsInterrupt_EX : IN STD_LOGIC; -- Software/Hardware interrupt in decode
        IsRet_EX : IN STD_LOGIC; -- RET instruction in decode
        IsReti_EX : IN STD_LOGIC; -- RTI instruction in decode

        -- Inputs from DE/EX pipeline register (signals in EXECUTE stage)
        IsInterrupt_MEM : IN STD_LOGIC; -- Software/Hardware interrupt in execute
        IsReti_MEM : IN STD_LOGIC; -- RTI instruction in execute
        IsRet_MEM : IN STD_LOGIC; -- RET instruction in execute

        -- Inputs from EX/MEM pipeline register (signals in MEMORY stage)
        IsHardwareInt_MEM : IN STD_LOGIC; -- Hardware interrupt flag in memory

        -- External hardware interrupt
        HardwareInterrupt : IN STD_LOGIC; -- External hardware interrupt signal

        -- Outputs
        freeze_fetch : OUT STD_LOGIC; -- Stall signal to Freeze Control
        memory_hazard : OUT STD_LOGIC; -- Memory hazard signal to Hazard Unit
        PassPC_NotPCPlus1 : OUT STD_LOGIC; -- For hardware interrupt (pass current PC)
        TakeInterrupt : OUT STD_LOGIC; -- Signal decoder to treat as interrupt
        IsHardwareIntMEM_Out : OUT STD_LOGIC; -- Hardware interrupt in memory (to decoder)
        OverrideOperation : OUT STD_LOGIC; -- Enable override
        OverrideType : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) -- Type of override operation
    );
END interrupt_unit;

ARCHITECTURE Behavioral OF interrupt_unit IS
BEGIN

    -- Stall signal: active during any interrupt processing
    -- This goes to Freeze Control to freeze fetch and PC
    freeze_fetch <= IsInterrupt_EX    OR
                IsReti_MEM     OR IsReti_EX         OR
                IsRet_MEM      OR IsRet_EX          OR
                IsInterrupt_MEM  OR
                IsInterrupt_DE OR IsReti_DE         OR  
                IsRet_DE;

    memory_hazard <=  IsInterrupt_MEM   OR
                      IsReti_MEM        OR
                      IsRet_MEM;
        
    -- Hardware interrupt handling
    -- When hardware interrupt occurs, signal decoder to treat as interrupt
    -- This will be written to IF/DE register
    TakeInterrupt <= HardwareInterrupt;

    -- For hardware interrupt, we want to save current PC (not PC+1)
    PassPC_NotPCPlus1 <= not HardwareInterrupt;

    -- Pass hardware interrupt flag in memory stage to decoder
    IsHardwareIntMEM_Out <= IsHardwareInt_MEM;

    -- Determine override type based on priority
    PROCESS (IsInterrupt_EX,
             IsInterrupt_MEM,
             IsReti_EX,
             IsReti_MEM,
             IsRet_EX,
             IsRet_MEM)
    BEGIN
        -- Default to PUSH_PC (doesn't matter since OverrideOperation will be '0')
        OverrideType <= OVERRIDE_PUSH_PC;
        OverrideOperation <= '0';

        -- Priority: Hardware interrupt during fetch doesn't override yet (it goes through TakeInterrupt)
        -- Once interrupt is in decode/execute, handle normally

        IF IsInterrupt_EX = '1' THEN
            -- Interrupt (SW or HW) in decode: First cycle - push PC
            OverrideType <= OVERRIDE_PUSH_FLAGS;
            OverrideOperation <= '1';

        ELSIF IsInterrupt_MEM = '1' THEN
            -- Interrupt (SW or HW) in execute: Second cycle - push FLAGS
            OverrideType <= OVERRIDE_PUSH_PC;
            OverrideOperation <= '1';

        ELSIF IsReti_EX = '1'  THEN
            -- Return from interrupt in decode: First cycle - pop FLAGS (opposite order!)
            OverrideType <= OVERRIDE_POP_FLAGS;
            OverrideOperation <= '1';

        ElSIF IsReti_MEM = '1' THEN
            -- Return from interrupt in execute: Second cycle - pop PC
            OverrideType <= OVERRIDE_NOP;
            OverrideOperation <= '1';

        ELSIF IsRet_EX = '1' THEN
            -- RET instruction: Only pop PC (single cycle)
            OverrideType <= OVERRIDE_NOP;
            OverrideOperation <= '1';

        ELSIF IsRet_MEM = '1' THEN
            -- RET instruction in execute: Only pop PC (single cycle)
            OverrideType <= OVERRIDE_NOP;
            OverrideOperation <= '1';
        END IF;
    END PROCESS;

END Behavioral;