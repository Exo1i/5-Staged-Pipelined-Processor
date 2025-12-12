LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pipeline_data_pkg.ALL;

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
            -- Forward from EX/MEM stage (higher priority)
            ForwardA <= FORWARD_EX_MEM;
        ELSIF WBRegWrite = '1' AND WBRdst = Rsrc1 THEN
            -- Forward from MEM/WB stage
            ForwardA <= FORWARD_MEM_WB;
        ELSE
            -- No forwarding needed
            ForwardA <= FORWARD_NONE;
        END IF;
    END PROCESS;

    -- ForwardB mux control
    PROCESS (MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, Rsrc2)
    BEGIN
        IF MemRegWrite = '1' AND MemRdst = Rsrc2 AND MemIsSwap = '0' THEN
            -- Forward from EX/MEM stage (higher priority)
            ForwardB <= FORWARD_EX_MEM;
        ELSIF WBRegWrite = '1' AND WBRdst = Rsrc2 THEN
            -- Forward from MEM/WB stage
            ForwardB <= FORWARD_MEM_WB;
        ELSE
            -- No forwarding needed
            ForwardB <= FORWARD_NONE;
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;