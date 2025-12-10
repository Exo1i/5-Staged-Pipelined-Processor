library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.control_signals_pkg.ALL;

entity tb_writeback_stage is
end tb_writeback_stage;

architecture testbench of tb_writeback_stage is
    constant DATA_WIDTH : integer := 32;
    constant RDST_WIDTH : integer := 3;
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal wb_ctrl      : writeback_control_t := WRITEBACK_CTRL_DEFAULT;
    signal MemoryData   : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ALUData      : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal Rdst         : std_logic_vector(RDST_WIDTH - 1 downto 0) := (others => '0');
    
    -- Output signals
    signal PortEnable   : std_logic;
    signal RegWE        : std_logic;
    signal Data         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal RdstOut      : std_logic_vector(RDST_WIDTH - 1 downto 0);
    
begin
    
    -- DUT Instantiation
    dut : entity work.WritebackStage
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            RDST_WIDTH => RDST_WIDTH
        )
        port map (
            clk         => clk,
            rst         => rst,
            wb_ctrl     => wb_ctrl,
            MemoryData  => MemoryData,
            ALUData     => ALUData,
            Rdst        => Rdst,
            PortEnable  => PortEnable,
            RegWE       => RegWE,
            Data        => Data,
            RdstOut     => RdstOut
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
        
        -- Test 2: MemToALU = '0' (ALU data selection)
        report "TEST 2: MemToALU = 0 (select ALUData)";
        wb_ctrl.MemToALU <= '0';
        wb_ctrl.RegWrite <= '1';
        wb_ctrl.OutPortWriteEn <= '0';
        ALUData <= x"12345678";
        MemoryData <= x"DEADBEEF";
        Rdst <= "011";
        wait for CLK_PERIOD;
        assert Data = x"12345678" report "Expected Data = ALUData (0x12345678)" severity error;
        assert RdstOut = "011" report "Expected RdstOut = 011" severity error;
        assert RegWE = '1' report "Expected RegWE = 1" severity error;
        assert PortEnable = '0' report "Expected PortEnable = 0" severity error;
        
        -- Test 3: MemToALU = '1' (Memory data selection)
        report "TEST 3: MemToALU = 1 (select MemoryData)";
        wb_ctrl.MemToALU <= '1';
        MemoryData <= x"CAFEBABE";
        ALUData <= x"11111111";
        wait for CLK_PERIOD;
        assert Data = x"CAFEBABE" report "Expected Data = MemoryData (0xCAFEBABE)" severity error;
        assert RdstOut = "011" report "Expected RdstOut = 011" severity error;
        
        -- Test 4: Register write disable
        report "TEST 4: RegWrite = 0 (register write disabled)";
        wb_ctrl.RegWrite <= '0';
        wait for CLK_PERIOD;
        assert RegWE = '0' report "Expected RegWE = 0" severity error;
        
        -- Test 5: Output port write enable
        report "TEST 5: OutPortWriteEn = 1 (output port enabled)";
        wb_ctrl.OutPortWriteEn <= '1';
        wait for CLK_PERIOD;
        assert PortEnable = '1' report "Expected PortEnable = 1" severity error;
        
        -- Test 6: Different register destinations
        report "TEST 6: Test different register destinations";
        wb_ctrl.MemToALU <= '0';
        wb_ctrl.RegWrite <= '1';
        wb_ctrl.OutPortWriteEn <= '0';
        ALUData <= x"AABBCCDD";
        
        for i in 0 to 7 loop
            Rdst <= std_logic_vector(to_unsigned(i, RDST_WIDTH));
            wait for CLK_PERIOD;
            assert RdstOut = std_logic_vector(to_unsigned(i, RDST_WIDTH)) report "Expected RdstOut = " & integer'image(i) severity error;
        end loop;
        
        -- Test 7: Data mux with varying inputs
        report "TEST 7: Data mux with varying inputs";
        for i in 0 to 3 loop
            if i mod 2 = 0 then
                wb_ctrl.MemToALU <= '0';
                MemoryData <= x"00000000";
                ALUData <= std_logic_vector(to_unsigned(i * 256, DATA_WIDTH));
                wait for CLK_PERIOD;
                assert Data = std_logic_vector(to_unsigned(i * 256, DATA_WIDTH)) report "Expected ALUData" severity error;
            else
                wb_ctrl.MemToALU <= '1';
                MemoryData <= std_logic_vector(to_unsigned(i * 256, DATA_WIDTH));
                wait for CLK_PERIOD;
                assert Data = std_logic_vector(to_unsigned(i * 256, DATA_WIDTH)) report "Expected MemoryData" severity error;
            end if;
        end loop;
        
        -- Test 8: Control signal forwarding
        report "TEST 8: Control signal forwarding";
        wb_ctrl.RegWrite <= '1';
        wb_ctrl.OutPortWriteEn <= '1';
        wait for CLK_PERIOD;
        assert RegWE = '1' report "RegWrite forward failed" severity error;
        assert PortEnable = '1' report "OutPortWriteEn forward failed" severity error;
        
        wb_ctrl.RegWrite <= '0';
        wb_ctrl.OutPortWriteEn <= '0';
        wait for CLK_PERIOD;
        assert RegWE = '0' report "RegWrite forward failed" severity error;
        assert PortEnable = '0' report "OutPortWriteEn forward failed" severity error;
        
        -- Test 9: All signals together
        report "TEST 9: All signals integrated";
        wb_ctrl.MemToALU <= '1';
        wb_ctrl.RegWrite <= '1';
        wb_ctrl.OutPortWriteEn <= '1';
        MemoryData <= x"FEDCBA98";
        ALUData <= x"01234567";
        Rdst <= "110";
        wait for CLK_PERIOD;
        assert Data = x"FEDCBA98" report "Expected MemoryData" severity error;
        assert RdstOut = "110" report "Expected RdstOut = 110" severity error;
        assert RegWE = '1' report "Expected RegWE = 1" severity error;
        assert PortEnable = '1' report "Expected PortEnable = 1" severity error;
        
        report "All tests completed!";
        wait;
        
    end process;

end architecture testbench;
