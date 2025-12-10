library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freeze_control is
    Port (
        -- Inputs: Stall conditions from various sources
        PassPC_MEM          : in  std_logic;  -- From Memory Hazard Unit ('0' = stall due to memory conflict)
        Stall_Interrupt     : in  std_logic;  -- From Interrupt Unit ('1' = stall for interrupt processing)
        Stall_Branch        : in  std_logic;  -- From Branch Control ('1' = stall for branch misprediction) - Optional
        
        -- Outputs: Control signals for pipeline freeze
        PC_WriteEnable      : out std_logic;  -- Enable PC register update ('1' = allow update, '0' = freeze)
        IFDE_WriteEnable    : out std_logic;  -- Enable IF/DE pipeline register update
        InsertNOP_IFDE      : out std_logic   -- Insert NOP/bubble into IF/DE stage ('1' = insert NOP)
    );
end freeze_control;

architecture Behavioral of freeze_control is
    signal any_stall : std_logic;
begin
    
    -- Combine all stall conditions
    -- Stall when:
    --   - PassPC_MEM = '0' (memory hazard, fetch blocked)
    --   - Stall_Interrupt = '1' (interrupt processing, freeze until new PC from memory)
    --   - Stall_Branch = '1' (branch misprediction handling)
    any_stall <= (not PassPC_MEM) or Stall_Interrupt or Stall_Branch;
    
    -- When stalling: freeze PC and IF/DE register, insert NOP
    -- When not stalling: allow normal operation
    PC_WriteEnable   <= not any_stall;  -- '0' when stalling, '1' when normal
    IFDE_WriteEnable <= not any_stall;  -- '0' when stalling, '1' when normal
    InsertNOP_IFDE   <= any_stall;      -- '1' when stalling (insert bubble), '0' when normal

end Behavioral;
