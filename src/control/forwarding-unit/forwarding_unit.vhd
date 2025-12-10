library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ForwardingUnit is
    generic(
        RSRC_WIDTH : integer := 3;
        FORWARD_WIDTH : integer := 2
    );
    port (
        -- Memory Stage
        MemRegWrite     : in std_logic;
        MemRdst         : in std_logic_vector(RSRC_WIDTH - 1 downto 0);
        MemIsSwap       : in std_logic;
        
        -- Writeback Stage
        WBRegWrite      : in std_logic;
        WBRdst          : in std_logic_vector(RSRC_WIDTH - 1 downto 0);
        
        -- Execution Stage
        Rsrc1           : in std_logic_vector(RSRC_WIDTH - 1 downto 0);
        Rsrc2           : in std_logic_vector(RSRC_WIDTH - 1 downto 0);
        
        -- Forwarding Control
        ForwardA        : out std_logic_vector(FORWARD_WIDTH - 1 downto 0);
        ForwardB        : out std_logic_vector(FORWARD_WIDTH - 1 downto 0)
    );
end ForwardingUnit;

architecture rtl of ForwardingUnit is
    
begin
    -- ForwardA mux control
    process(MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, Rsrc1)
    begin
        
        if MemRegWrite = '1' and MemRdst = Rsrc1 and MemIsSwap = '0' then
            -- Forward from Memory stage
            ForwardA <= "01";
        elsif WBRegWrite = '1' and WBRdst = Rsrc1 then
            -- Forward from Writeback stage
            ForwardA <= "10";
        else
            -- No forwarding needed
            ForwardA <= "00";
        end if;
    end process;
    
    -- ForwardB mux control
    process(MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, Rsrc2)
    begin
        if MemRegWrite = '1' and MemRdst = Rsrc2 and MemIsSwap = '0' then
            -- Forward from Memory stage
            ForwardB <= "01";
        elsif WBRegWrite = '1' and WBRdst = Rsrc2 then
            -- Forward from Writeback stage
            ForwardB <= "10";
        else
            -- No forwarding needed
            ForwardB <= "00";
        end if;
    end process;

end architecture rtl;
