LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pipeline_data_pkg.ALL;
USE work.pkg_opcodes.ALL;

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
        ExRsrc1 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ExRsrc2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        ExOutBSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        ExIsImm : IN STD_LOGIC;

        -- Forwarding Control
        ForwardA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        ForwardB : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        ForwardSecondary : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END forwarding_unit;

ARCHITECTURE rtl OF forwarding_unit IS

BEGIN
    -- ForwardA mux control
    PROCESS (MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, ExRsrc1)
    BEGIN
        IF MemRegWrite = '1' AND MemRdst = ExRsrc1 AND MemIsSwap = '0' THEN
            -- Forward from EX/MEM stage (higher priority)
            ForwardA <= FORWARD_EX_MEM;
        ELSIF WBRegWrite = '1' AND WBRdst = ExRsrc1 THEN
            -- Forward from MEM/WB stage
            ForwardA <= FORWARD_MEM_WB;
        ELSE
            -- No forwarding needed
            ForwardA <= FORWARD_NONE;
        END IF;
    END PROCESS;

    -- ForwardB mux control
    PROCESS (ExOutBSelect, ExIsImm, MemRegWrite, MemRdst, MemIsSwap, WBRegWrite, WBRdst, ExRsrc2)
    BEGIN
        ForwardB <= FORWARD_NONE;
        if ExOutBSelect = OUTB_REGFILE AND ExIsImm = '0' then
            IF MemRegWrite = '1' AND MemRdst = ExRsrc2 AND MemIsSwap = '0' THEN
                -- Forward from EX/MEM stage (higher priority)
                ForwardB <= FORWARD_EX_MEM;
            ELSIF WBRegWrite = '1' AND WBRdst = ExRsrc2 THEN
                -- Forward from MEM/WB stage
                ForwardB <= FORWARD_MEM_WB;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (MemRegWrite, ExOutBSelect, MemRdst, WBRegWrite, WBRdst, ExRsrc2)
    BEGIN
        ForwardSecondary <= FORWARD_NONE;
        if ExOutBSelect = OUTB_REGFILE then
            IF MemRegWrite = '1' AND MemRdst = ExRsrc2 THEN
                -- Forward from EX/MEM stage (higher priority)
                ForwardSecondary <= FORWARD_EX_MEM;
            ELSIF WBRegWrite = '1' AND WBRdst = ExRsrc2 THEN
                -- Forward from MEM/WB stage
                ForwardSecondary <= FORWARD_MEM_WB;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;