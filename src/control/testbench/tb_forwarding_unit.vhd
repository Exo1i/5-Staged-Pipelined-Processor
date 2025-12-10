library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_forwarding_unit is
end tb_forwarding_unit;

architecture testbench of tb_forwarding_unit is
    constant RSRC_WIDTH : integer := 3;
    constant FORWARD_WIDTH : integer := 2;
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal MemRegWrite  : std_logic := '0';
    signal MemRdst      : std_logic_vector(RSRC_WIDTH - 1 downto 0) := (others => '0');
    signal MemIsSwap    : std_logic := '0';
    signal WBRegWrite   : std_logic := '0';
    signal WBRdst       : std_logic_vector(RSRC_WIDTH - 1 downto 0) := (others => '0');
    signal Rsrc1        : std_logic_vector(RSRC_WIDTH - 1 downto 0) := (others => '0');
    signal Rsrc2        : std_logic_vector(RSRC_WIDTH - 1 downto 0) := (others => '0');
    signal ForwardA     : std_logic_vector(FORWARD_WIDTH - 1 downto 0);
    signal ForwardB     : std_logic_vector(FORWARD_WIDTH - 1 downto 0);
    
begin
    
    -- DUT Instantiation
    dut : entity work.ForwardingUnit
        generic map (
            RSRC_WIDTH => RSRC_WIDTH,
            FORWARD_WIDTH => FORWARD_WIDTH
        )
        port map (
            MemRegWrite => MemRegWrite,
            MemRdst     => MemRdst,
            MemIsSwap   => MemIsSwap,
            WBRegWrite  => WBRegWrite,
            WBRdst      => WBRdst,
            Rsrc1       => Rsrc1,
            Rsrc2       => Rsrc2,
            ForwardA    => ForwardA,
            ForwardB    => ForwardB
        );
    
    -- Test stimulus
    stimulus : process
    begin
        -- Test 1: No forwarding needed (no match)
        report "TEST 1: No forwarding - no register match";
        MemRegWrite <= '0';
        WBRegWrite <= '0';
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemRdst <= "011";
        WBRdst <= "100";
        wait for CLK_PERIOD;
        assert ForwardA = "00" report "Expected ForwardA = 00 (no forwarding)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (no forwarding)" severity error;
        
        -- Test 2: Forward from Memory stage for Rsrc1
        report "TEST 2: Forward from Memory stage for Rsrc1";
        MemRegWrite <= '1';
        MemRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '0';
        WBRegWrite <= '0';
        wait for CLK_PERIOD;
        assert ForwardA = "01" report "Expected ForwardA = 01 (Memory forward)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (no forwarding)" severity error;
        
        -- Test 3: Forward from Memory stage for Rsrc2
        report "TEST 3: Forward from Memory stage for Rsrc2";
        MemRegWrite <= '1';
        MemRdst <= "010";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        wait for CLK_PERIOD;
        assert ForwardA = "00" report "Expected ForwardA = 00 (no forwarding)" severity error;
        assert ForwardB = "01" report "Expected ForwardB = 01 (Memory forward)" severity error;
        
        -- Test 4: Forward from Memory stage for both operands
        report "TEST 4: Forward from Memory stage for both Rsrc1 and Rsrc2";
        MemRegWrite <= '1';
        MemRdst <= "011";
        Rsrc1 <= "011";
        Rsrc2 <= "011";
        wait for CLK_PERIOD;
        assert ForwardA = "01" report "Expected ForwardA = 01 (Memory forward)" severity error;
        assert ForwardB = "01" report "Expected ForwardB = 01 (Memory forward)" severity error;
        
        -- Test 5: Forward from Writeback stage for Rsrc1
        report "TEST 5: Forward from Writeback stage for Rsrc1";
        MemRegWrite <= '0';
        WBRegWrite <= '1';
        WBRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        wait for CLK_PERIOD;
        assert ForwardA = "10" report "Expected ForwardA = 10 (Writeback forward)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (no forwarding)" severity error;
        
        -- Test 6: Forward from Writeback stage for Rsrc2
        report "TEST 6: Forward from Writeback stage for Rsrc2";
        WBRegWrite <= '1';
        WBRdst <= "010";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        wait for CLK_PERIOD;
        assert ForwardA = "00" report "Expected ForwardA = 00 (no forwarding)" severity error;
        assert ForwardB = "10" report "Expected ForwardB = 10 (Writeback forward)" severity error;
        
        -- Test 7: Memory stage priority over Writeback stage
        report "TEST 7: Memory stage priority over Writeback";
        MemRegWrite <= '1';
        MemRdst <= "001";
        WBRegWrite <= '1';
        WBRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '0';
        wait for CLK_PERIOD;
        assert ForwardA = "01" report "Expected ForwardA = 01 (Memory priority)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (no forwarding)" severity error;
        
        -- Test 8: SWAP instruction disables forwarding
        report "TEST 8: SWAP disables forwarding";
        MemRegWrite <= '1';
        MemRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "001";
        MemIsSwap <= '1';
        WBRegWrite <= '0';
        wait for CLK_PERIOD;
        assert ForwardA = "00" report "Expected ForwardA = 00 (SWAP disables forwarding)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (SWAP disables forwarding)" severity error;
        
        -- Test 9: SWAP only affects Memory stage, not Writeback
        report "TEST 9: SWAP affects only Memory stage";
        MemRegWrite <= '1';
        MemRdst <= "001";
        WBRegWrite <= '1';
        WBRdst <= "001";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '1';
        wait for CLK_PERIOD;
        assert ForwardA = "10" report "Expected ForwardA = 10 (Writeback forward)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (no forwarding)" severity error;
        
        -- Test 10: RegWrite disabled, no forwarding
        report "TEST 10: RegWrite disabled in both stages";
        MemRegWrite <= '0';
        WBRegWrite <= '0';
        MemRdst <= "001";
        WBRdst <= "010";
        Rsrc1 <= "001";
        Rsrc2 <= "010";
        MemIsSwap <= '0';
        wait for CLK_PERIOD;
        assert ForwardA = "00" report "Expected ForwardA = 00 (no forwarding)" severity error;
        assert ForwardB = "00" report "Expected ForwardB = 00 (no forwarding)" severity error;
        
        -- Test 11: Different register combinations
        report "TEST 11: Different register combinations";
        for i in 0 to 7 loop
            MemRegWrite <= '1';
            MemRdst <= std_logic_vector(to_unsigned(i, RSRC_WIDTH));
            WBRegWrite <= '1';
            WBRdst <= std_logic_vector(to_unsigned(i, RSRC_WIDTH));
            Rsrc1 <= std_logic_vector(to_unsigned(i, RSRC_WIDTH));
            Rsrc2 <= std_logic_vector(to_unsigned((i+1) mod 8, RSRC_WIDTH));
            MemIsSwap <= '0';
            wait for CLK_PERIOD;
            assert ForwardA = "01" report "Expected ForwardA = 01 for reg " & integer'image(i) severity error;
        end loop;
        
        -- Test 12: Mixed scenarios
        report "TEST 12: Mixed forwarding scenarios";
        MemRegWrite <= '1';
        MemRdst <= "011";
        WBRegWrite <= '1';
        WBRdst <= "100";
        Rsrc1 <= "011";
        Rsrc2 <= "100";
        MemIsSwap <= '0';
        wait for CLK_PERIOD;
        assert ForwardA = "01" report "Expected ForwardA = 01 (Memory forward)" severity error;
        assert ForwardB = "10" report "Expected ForwardB = 10 (Writeback forward)" severity error;
        
        report "All tests completed!";
        wait;
        
    end process;

end architecture testbench;
