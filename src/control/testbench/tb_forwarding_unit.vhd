LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_forwarding_unit IS
END tb_forwarding_unit;

ARCHITECTURE testbench OF tb_forwarding_unit IS
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL MemRegWrite : STD_LOGIC := '0';
    SIGNAL MemRdst : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL MemIsSwap : STD_LOGIC := '0';
    SIGNAL WBRegWrite : STD_LOGIC := '0';
    SIGNAL WBRdst : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Rsrc1 : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Rsrc2 : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ForwardA : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ForwardB : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    -- DUT Instantiation
    dut : ENTITY work.forwarding_unit
        PORT MAP(
            MemRegWrite => MemRegWrite,
            MemRdst => MemRdst,
            MemIsSwap => MemIsSwap,
            WBRegWrite => WBRegWrite,
            WBRdst => WBRdst,
            Rsrc1 => Rsrc1,
            Rsrc2 => Rsrc2,
            ForwardA => ForwardA,
            ForwardB => ForwardB
        );

    -- Test stimulus
    stimulus : PROCESS
    BEGIN
        -- Test 1: No forwarding needed (no match)
        REPORT "TEST 1: No forwarding - no register match";
        MemRegWrite <= '0';
        WBRegWrite <= '0';
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemRdst <= "011";
        WBRdst <= "100";
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "00" REPORT "Expected ForwardA = 00 (no forwarding)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (no forwarding)" SEVERITY error;

        -- Test 2: Forward from Memory stage for Rsrc1
        REPORT "TEST 2: Forward from Memory stage for Rsrc1";
        MemRegWrite <= '1';
        MemRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '0';
        WBRegWrite <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "01" REPORT "Expected ForwardA = 01 (Memory forward)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (no forwarding)" SEVERITY error;

        -- Test 3: Forward from Memory stage for Rsrc2
        REPORT "TEST 3: Forward from Memory stage for Rsrc2";
        MemRegWrite <= '1';
        MemRdst <= "010";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "00" REPORT "Expected ForwardA = 00 (no forwarding)" SEVERITY error;
        ASSERT ForwardB = "01" REPORT "Expected ForwardB = 01 (Memory forward)" SEVERITY error;

        -- Test 4: Forward from Memory stage for both operands
        REPORT "TEST 4: Forward from Memory stage for both Rsrc1 and Rsrc2";
        MemRegWrite <= '1';
        MemRdst <= "011";
        Rsrc1 <= "011";
        Rsrc2 <= "011";
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "01" REPORT "Expected ForwardA = 01 (Memory forward)" SEVERITY error;
        ASSERT ForwardB = "01" REPORT "Expected ForwardB = 01 (Memory forward)" SEVERITY error;

        -- Test 5: Forward from Writeback stage for Rsrc1
        REPORT "TEST 5: Forward from Writeback stage for Rsrc1";
        MemRegWrite <= '0';
        WBRegWrite <= '1';
        WBRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "10" REPORT "Expected ForwardA = 10 (Writeback forward)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (no forwarding)" SEVERITY error;

        -- Test 6: Forward from Writeback stage for Rsrc2
        REPORT "TEST 6: Forward from Writeback stage for Rsrc2";
        WBRegWrite <= '1';
        WBRdst <= "010";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "00" REPORT "Expected ForwardA = 00 (no forwarding)" SEVERITY error;
        ASSERT ForwardB = "10" REPORT "Expected ForwardB = 10 (Writeback forward)" SEVERITY error;

        -- Test 7: Memory stage priority over Writeback stage
        REPORT "TEST 7: Memory stage priority over Writeback";
        MemRegWrite <= '1';
        MemRdst <= "001";
        WBRegWrite <= '1';
        WBRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "01" REPORT "Expected ForwardA = 01 (Memory priority)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (no forwarding)" SEVERITY error;

        -- Test 8: SWAP instruction disables forwarding
        REPORT "TEST 8: SWAP disables forwarding";
        MemRegWrite <= '1';
        MemRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "001";
        MemIsSwap <= '1';
        WBRegWrite <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "00" REPORT "Expected ForwardA = 00 (SWAP disables forwarding)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (SWAP disables forwarding)" SEVERITY error;

        -- Test 9: SWAP only affects Memory stage, not Writeback
        REPORT "TEST 9: SWAP affects only Memory stage";
        MemRegWrite <= '1';
        MemRdst <= "001";
        WBRegWrite <= '1';
        WBRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "10" REPORT "Expected ForwardA = 10 (Writeback forward)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (no forwarding)" SEVERITY error;

        -- Test 10: RegWrite disabled, no forwarding
        REPORT "TEST 10: RegWrite disabled in both stages";
        MemRegWrite <= '0';
        WBRegWrite <= '0';
        MemRdst <= "001";
        WBRdst <= "010";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "00" REPORT "Expected ForwardA = 00 (no forwarding)" SEVERITY error;
        ASSERT ForwardB = "00" REPORT "Expected ForwardB = 00 (no forwarding)" SEVERITY error;

        -- Test 11: Different register combinations
        REPORT "TEST 11: Different register combinations";
        FOR i IN 0 TO 7 LOOP
            MemRegWrite <= '1';
            MemRdst <= STD_LOGIC_VECTOR(to_unsigned(i, 3));
            WBRegWrite <= '1';
            WBRdst <= STD_LOGIC_VECTOR(to_unsigned(i, 3));
            Rsrc1 <= STD_LOGIC_VECTOR(to_unsigned(i, 3));
            Rsrc2 <= STD_LOGIC_VECTOR(to_unsigned((i + 1) MOD 8, 3));
            MemIsSwap <= '0';
            WAIT FOR CLK_PERIOD;
            ASSERT ForwardA = "01" REPORT "Expected ForwardA = 01 for reg " & INTEGER'image(i) SEVERITY error;
        END LOOP;

        -- Test 12: Mixed scenarios
        REPORT "TEST 12: Mixed forwarding scenarios";
        MemRegWrite <= '1';
        MemRdst <= "011";
        WBRegWrite <= '1';
        WBRdst <= "100";
        Rsrc1 <= "011";
        Rsrc2 <= "100";
        MemIsSwap <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT ForwardA = "01" REPORT "Expected ForwardA = 01 (Memory forward)" SEVERITY error;
        ASSERT ForwardB = "10" REPORT "Expected ForwardB = 10 (Writeback forward)" SEVERITY error;

        REPORT "All tests completed!";
        WAIT;

    END PROCESS;

END ARCHITECTURE testbench;