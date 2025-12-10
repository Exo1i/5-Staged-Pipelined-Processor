library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity memory_hazard_unit is
    Port (
        -- Inputs from MEMORY stage
        MemRead_MEM         : in  std_logic;  -- Memory stage wants to read
        MemWrite_MEM        : in  std_logic;  -- Memory stage wants to write
        
        -- Outputs
        PassPC              : out std_logic;  -- Allow fetch to access memory (also used by freeze control)
        MemRead_Out         : out std_logic;  -- Actual read signal to memory block
        MemWrite_Out        : out std_logic   -- Actual write signal to memory block
    );
end memory_hazard_unit;

architecture Behavioral of memory_hazard_unit is
begin
    
    -- Priority Logic: Memory stage has higher priority than Fetch stage
    -- If memory stage needs memory, block fetch; otherwise allow fetch
    PassPC <= not (MemRead_MEM or MemWrite_MEM);
    
    -- Pass memory stage signals to actual memory when needed
    MemRead_Out  <= MemRead_MEM;
    MemWrite_Out <= MemWrite_MEM;

end Behavioral;
