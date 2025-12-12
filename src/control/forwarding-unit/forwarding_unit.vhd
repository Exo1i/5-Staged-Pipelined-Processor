LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY forwarding_unit IS
    PORT (
        -- Memory Stage
        MemRegWrite : IN STD_LOGIC;
        MemRdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        MemIsSwap : IN STD_LOGIC;

        -- Writeback Stage
        WBRegWrite : IN STD_LOGIC;
        WBRdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Execution Stage
        Rsrc1 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rsrc2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Forwarding Control
        ForwardA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        ForwardB : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END forwarding_unit;

ARCHITECTURE rtl OF forwarding_unit IS

BEGIN
    -- ForwardA mux control
    PROCESS (MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, Rsrc1)
    BEGIN

        IF MemRegWrite = '1' AND MemRdst = Rsrc1 AND MemIsSwap = '0' THEN
            -- Forward from Memory stage
            ForwardA <= "01";
        ELSIF WBRegWrite = '1' AND WBRdst = Rsrc1 THEN
            -- Forward from Writeback stage
            ForwardA <= "10";
        ELSE
            -- No forwarding needed
            ForwardA <= "00";
        END IF;
    END PROCESS;

    -- ForwardB mux control
    PROCESS (MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, Rsrc2)
    BEGIN
        IF MemRegWrite = '1' AND MemRdst = Rsrc2 AND MemIsSwap = '0' THEN
            -- Forward from Memory stage
            ForwardB <= "01";
        ELSIF WBRegWrite = '1' AND WBRdst = Rsrc2 THEN
            -- Forward from Writeback stage
            ForwardB <= "10";
        ELSE
            -- No forwarding needed
            ForwardB <= "00";
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;