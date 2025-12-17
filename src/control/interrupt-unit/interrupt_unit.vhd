LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pkg_opcodes.ALL;

ENTITY interrupt_unit IS
    PORT (
        -- Inputs from DECODE stage
        IsInterrupt_DE : IN STD_LOGIC; -- Software/Hardware interrupt in decode
        IsCall_DE : IN STD_LOGIC; -- CALL instruction in decode
        IsReturn_DE : IN STD_LOGIC; -- RET instruction in decode
        IsReti_DE : IN STD_LOGIC; -- RTI instruction in decode

        -- Inputs from DE/EX pipeline register (signals in EXECUTE stage)
        IsInterrupt_EX : IN STD_LOGIC; -- Software/Hardware interrupt in execute
        IsReti_EX : IN STD_LOGIC; -- RTI instruction in execute

        -- Inputs from EX/MEM pipeline register (signals in MEMORY stage)
        IsHardwareInt_MEM : IN STD_LOGIC; -- Hardware interrupt flag in memory

        -- External hardware interrupt
        HardwareInterrupt : IN STD_LOGIC; -- External hardware interrupt signal

        -- Outputs
        Stall : OUT STD_LOGIC; -- Stall signal to Freeze Control
        PassPC_NotPCPlus1 : OUT STD_LOGIC; -- For hardware interrupt (pass current PC)
        TakeInterrupt : OUT STD_LOGIC; -- Signal decoder to treat as interrupt
        IsHardwareIntMEM_Out : OUT STD_LOGIC; -- Hardware interrupt in memory (to decoder)
        OverrideOperation : OUT STD_LOGIC; -- Enable override
        OverrideType : OUT STD_LOGIC_VECTOR(1 DOWNTO 0) -- Type of override operation
    );
END interrupt_unit;

ARCHITECTURE Behavioral OF interrupt_unit IS
    SIGNAL any_interrupt_operation : STD_LOGIC;
BEGIN

    -- Detect if any interrupt-related operation is active
    any_interrupt_operation <= IsInterrupt_DE OR IsInterrupt_EX OR
        IsReti_DE OR IsReti_EX OR
        IsCall_DE OR IsReturn_DE OR
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
    PassPC_NotPCPlus1 <= not HardwareInterrupt;

    -- Pass hardware interrupt flag in memory stage to decoder
    IsHardwareIntMEM_Out <= IsHardwareInt_MEM;

    -- Determine override type based on priority
    PROCESS (IsInterrupt_DE, IsInterrupt_EX, IsReti_DE, IsReti_EX,
        IsCall_DE, IsReturn_DE)
    BEGIN
        -- Default to PUSH_PC (doesn't matter since OverrideOperation will be '0')
        OverrideType <= OVERRIDE_PUSH_PC;

        -- Priority: Hardware interrupt during fetch doesn't override yet (it goes through TakeInterrupt)
        -- Once interrupt is in decode/execute, handle normally

        IF IsInterrupt_DE = '1' THEN
            -- Interrupt (SW or HW) in decode: First cycle - push PC
            OverrideType <= OVERRIDE_PUSH_FLAGS;

        ELSIF IsInterrupt_EX = '1' THEN
            -- Interrupt (SW or HW) in execute: Second cycle - push FLAGS
            OverrideType <= OVERRIDE_PUSH_PC;

        ELSIF IsReti_DE = '1' THEN
            -- Return from interrupt in decode: First cycle - pop FLAGS (opposite order!)
            OverrideType <= OVERRIDE_POP_FLAGS;

        ELSIF IsReti_EX = '1' THEN
            -- Return from interrupt in execute: Second cycle - pop PC
            OverrideType <= OVERRIDE_POP_PC;

        ELSIF IsCall_DE = '1' THEN
            -- CALL instruction: Only push PC (single cycle)
            OverrideType <= OVERRIDE_PUSH_PC;

        ELSIF IsReturn_DE = '1' THEN
            -- RET instruction: Only pop PC (single cycle)
            OverrideType <= OVERRIDE_POP_PC;

        END IF;
    END PROCESS;

END Behavioral;