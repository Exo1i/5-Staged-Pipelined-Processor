LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY freeze_control IS
    PORT (
        -- Inputs: Stall conditions from various sources
        PassPC_MEM : IN STD_LOGIC; -- From Memory Hazard Unit ('0' = stall due to memory conflict)
        Stall_Interrupt : IN STD_LOGIC; -- From Interrupt Unit ('1' = stall for interrupt processing)
        Stall_Branch : IN STD_LOGIC; -- From Branch Control ('1' = stall for branch misprediction) - Optional

        -- Outputs: Control signals for pipeline freeze
        PC_WriteEnable : OUT STD_LOGIC; -- Enable PC register update ('1' = allow update, '0' = freeze)
        IFDE_WriteEnable : OUT STD_LOGIC; -- Enable IF/DE pipeline register update
        InsertNOP_IFDE : OUT STD_LOGIC -- Insert NOP/bubble into IF/DE stage ('1' = insert NOP)
    );
END freeze_control;

ARCHITECTURE Behavioral OF freeze_control IS
    SIGNAL any_stall : STD_LOGIC;
BEGIN

    -- Combine all stall conditions
    -- Stall when:
    --   - PassPC_MEM = '0' (memory hazard, fetch blocked)
    --   - Stall_Interrupt = '1' (interrupt processing, freeze until new PC from memory)
    --   - Stall_Branch = '1' (branch misprediction handling)
    any_stall <= (NOT PassPC_MEM) OR Stall_Interrupt OR Stall_Branch;

    -- When stalling: freeze PC and IF/DE register, insert NOP
    -- When not stalling: allow normal operation
    PC_WriteEnable <= NOT any_stall; -- '0' when stalling, '1' when normal
    IFDE_WriteEnable <= NOT any_stall; -- '0' when stalling, '1' when normal
    InsertNOP_IFDE <= any_stall; -- '1' when stalling (insert bubble), '0' when normal

END Behavioral;