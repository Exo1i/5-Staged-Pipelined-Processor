library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.control_signals_pkg.ALL;

entity tb_memory_stage is
end tb_memory_stage;

architecture testbench of tb_memory_stage is
    constant DATA_WIDTH : integer := 32;
    constant ADDR_WIDTH : integer := 18;
    constant RDST_WIDTH : integer := 3;
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal mem_ctrl     : memory_control_t := MEMORY_CTRL_DEFAULT;
    signal PrimaryData  : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal SecondaryData: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal RdstIN       : std_logic_vector(RDST_WIDTH - 1 downto 0) := (others => '0');
    
    -- Output signals
    signal MemoryData   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ALUData      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal RdstOut      : std_logic_vector(RDST_WIDTH - 1 downto 0);
    signal MemReadData  : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal MemRead      : std_logic;
    signal MemWrite     : std_logic;
    signal MemAddress   : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal MemWriteData : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
begin
    
    -- DUT Instantiation
    dut : entity work.MemoryStage
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH,
            RDST_WIDTH => RDST_WIDTH
        )
        port map (
            clk           => clk,
            rst           => rst,
            mem_ctrl      => mem_ctrl,
            PrimaryData   => PrimaryData,
            SecondaryData => SecondaryData,
            RdstIN        => RdstIN,
            MemoryData    => MemoryData,
            ALUData       => ALUData,
            RdstOut       => RdstOut,
            MemReadData   => MemReadData,
            MemRead       => MemRead,
            MemWrite      => MemWrite,
            MemAddress    => MemAddress,
            MemWriteData  => MemWriteData
        );
    
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    -- Test stimulus
    stimulus : process
    begin
        -- Test 1: Reset
        report "TEST 1: Reset sequence";
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test 2: PassInterrupt = "00" (reset vector)
        report "TEST 2: PassInterrupt = 00 (reset vector)";
        mem_ctrl.SPtoMem <= '0';
        mem_ctrl.PassInterrupt <= "00";
        mem_ctrl.MemRead <= '1';
        mem_ctrl.MemWrite <= '0';
        PrimaryData <= x"00001000";
        SecondaryData <= x"DEADBEEF";
        wait for CLK_PERIOD;
        assert MemAddress = std_logic_vector(to_unsigned(0, ADDR_WIDTH)) report "Expected address 0" severity error;
        assert MemRead = '1' report "Expected MemRead = 1" severity error;
        assert MemWrite = '0' report "Expected MemWrite = 0" severity error;
        assert MemWriteData = x"DEADBEEF" report "Expected MemWriteData = DEADBEEF" severity error;
        
        -- Test 3: PassInterrupt = "01" (value 1)
        report "TEST 3: PassInterrupt = 01 (value 1)";
        mem_ctrl.PassInterrupt <= "01";
        wait for CLK_PERIOD;
        assert MemAddress = std_logic_vector(to_unsigned(1, ADDR_WIDTH)) report "Expected address 1" severity error;
        
        -- Test 4: PassInterrupt = "10" (PrimaryData + 2)
        report "TEST 4: PassInterrupt = 10 (PrimaryData + 2)";
        mem_ctrl.PassInterrupt <= "10";
        PrimaryData <= x"00000100";
        wait for CLK_PERIOD;
        assert MemAddress = std_logic_vector(to_unsigned(258, ADDR_WIDTH)) report "Expected address 258 (256 + 2)" severity error;
        
        -- Test 5: PassInterrupt = "11" (PrimaryData)
        report "TEST 5: PassInterrupt = 11 (PrimaryData)";
        mem_ctrl.PassInterrupt <= "11";
        PrimaryData <= x"00005678";
        wait for CLK_PERIOD;
        assert MemAddress = std_logic_vector(to_unsigned(16#5678#, ADDR_WIDTH)) report "Expected address 0x5678" severity error;
        
        -- Test 6: SPtoMem = '1' (use stack pointer)
        report "TEST 6: SPtoMem = 1 (use stack pointer)";
        mem_ctrl.SPtoMem <= '1';
        mem_ctrl.SP_Enable <= '1';
        mem_ctrl.SP_Function <= '0';  -- Decrement (to stay within range)
        wait for CLK_PERIOD;
        wait for CLK_PERIOD;
        wait for CLK_PERIOD;
        -- After 2 decrements from reset (which is 2^18 - 1)
        -- SP should be 2^18 - 3
        report "Stack pointer decremented";
        
        -- Test 7: Memory write operation
        report "TEST 7: Memory write operation";
        mem_ctrl.SPtoMem <= '1';
        mem_ctrl.MemRead <= '0';
        mem_ctrl.MemWrite <= '1';
        mem_ctrl.SP_Enable <= '0';
        SecondaryData <= x"CAFEBABE";
        wait for CLK_PERIOD;
        assert MemWrite = '1' report "Expected MemWrite = 1" severity error;
        assert MemWriteData = x"CAFEBABE" report "Expected MemWriteData = CAFEBABE" severity error;
        
        -- Test 8: SP Increment
        report "TEST 8: SP Increment";
        mem_ctrl.SP_Enable <= '1';
        mem_ctrl.SP_Function <= '1';  -- Increment
        mem_ctrl.MemWrite <= '0';
        wait for CLK_PERIOD;
        wait for CLK_PERIOD;
        report "Stack pointer incremented";
        
        -- Test 9: PassInterrupt with different values
        report "TEST 9: Test all PassInterrupt values";
        mem_ctrl.SPtoMem <= '0';
        mem_ctrl.SP_Enable <= '0';
        
        for i in 0 to 3 loop
            mem_ctrl.PassInterrupt <= std_logic_vector(to_unsigned(i, 2));
            PrimaryData <= x"00000200";
            wait for CLK_PERIOD;
            case i is
                when 0 =>
                    assert MemAddress = std_logic_vector(to_unsigned(0, ADDR_WIDTH)) report "PassInterrupt 00 failed" severity error;
                when 1 =>
                    assert MemAddress = std_logic_vector(to_unsigned(1, ADDR_WIDTH)) report "PassInterrupt 01 failed" severity error;
                when 2 =>
                    assert MemAddress = std_logic_vector(to_unsigned(514, ADDR_WIDTH)) report "PassInterrupt 10 failed" severity error;
                when others =>
                    assert MemAddress = std_logic_vector(to_unsigned(16#200#, ADDR_WIDTH)) report "PassInterrupt 11 failed" severity error;
            end case;
        end loop;
        
        -- Test 10: Control signal forwarding
        report "TEST 10: Control signal forwarding";
        mem_ctrl.MemRead <= '0';
        mem_ctrl.MemWrite <= '0';
        wait for CLK_PERIOD;
        assert MemRead = '0' report "MemRead forward failed" severity error;
        assert MemWrite = '0' report "MemWrite forward failed" severity error;
        
        mem_ctrl.MemRead <= '1';
        mem_ctrl.MemWrite <= '1';
        wait for CLK_PERIOD;
        assert MemRead = '1' report "MemRead forward failed" severity error;
        assert MemWrite = '1' report "MemWrite forward failed" severity error;
        
        -- Test 11: Pipeline register pass-through (ALUData = PrimaryData)
        report "TEST 11: Pipeline register - ALUData pass-through";
        PrimaryData <= x"12345678";
        wait for CLK_PERIOD;
        assert ALUData = x"12345678" report "ALUData should equal PrimaryData" severity error;
        
        -- Test 12: Pipeline register pass-through (RdstOut = RdstIN)
        report "TEST 12: Pipeline register - RdstOut pass-through";
        RdstIN <= "101";
        wait for CLK_PERIOD;
        assert RdstOut = "101" report "RdstOut should equal RdstIN" severity error;
        
        -- Test 13: MemReadData to MemoryData pass-through
        report "TEST 13: MemReadData to MemoryData pass-through";
        MemReadData <= x"ABCDEF00";
        wait for CLK_PERIOD;
        assert MemoryData = x"ABCDEF00" report "MemoryData should equal MemReadData" severity error;
        
        report "All tests completed!";
        wait;
        
    end process;

end architecture testbench;
