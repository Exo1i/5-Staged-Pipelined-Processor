library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ccr is
    Port (
        clk          : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        
        -- ALU flags input
        ALU_Zero     : in  STD_LOGIC;
        ALU_Negative : in  STD_LOGIC;
        ALU_Carry    : in  STD_LOGIC;
        
        -- Control signals
        CCRWrEn      : in  STD_LOGIC;  -- Write enable from control unit
        PassCCR      : in  STD_LOGIC;  -- Restore flag for RTI instruction
        
        -- Stack flags input (for RTI instruction)
        StackFlags   : in  STD_LOGIC_VECTOR(2 downto 0);  -- [Z, N, C]
        
        -- CCR output
        CCR_Out      : out STD_LOGIC_VECTOR(2 downto 0)  -- [Z, N, C]
    );
end ccr;

architecture Behavioral of ccr is
    signal ccr_reg : STD_LOGIC_VECTOR(2 downto 0) := "000";  -- [Z, N, C]
    
begin
    process(clk, reset)
    begin
        if reset = '1' then
            ccr_reg <= "000";  -- Clear all flags on reset
        elsif rising_edge(clk) then
            if CCRWrEn = '1' then
                if PassCCR = '1' then
                    -- RTI instruction: restore flags from stack
                    ccr_reg <= StackFlags;
                else
                    -- Normal operation: update from ALU
                    ccr_reg(2) <= ALU_Zero;      -- Z flag
                    ccr_reg(1) <= ALU_Negative;  -- N flag
                    ccr_reg(0) <= ALU_Carry;     -- C flag
                end if;
            end if;
        end if;
    end process;
    
    -- Output current CCR value
    CCR_Out <= ccr_reg;
    
end Behavioral;