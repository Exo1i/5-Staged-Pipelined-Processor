library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_register_file is
end tb_register_file;

architecture Behavioral of tb_register_file is
    
    component register_file is
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            Ra         : in  STD_LOGIC_VECTOR(2 downto 0);
            Rb         : in  STD_LOGIC_VECTOR(2 downto 0);
            ReadDataA  : out STD_LOGIC_VECTOR(31 downto 0);
            ReadDataB  : out STD_LOGIC_VECTOR(31 downto 0);
            Rdst       : in  STD_LOGIC_VECTOR(2 downto 0);
            WriteData  : in  STD_LOGIC_VECTOR(31 downto 0);
            RegWrite   : in  STD_LOGIC;
            Rdst2      : in  STD_LOGIC_VECTOR(2 downto 0);
            WriteData2 : in  STD_LOGIC_VECTOR(31 downto 0);
            RegWrite2  : in  STD_LOGIC
        );
    end component;
    
    -- Clock period
    constant clk_period : time := 20 ns;  -- 50 MHz
    
    -- Test signals
    signal clk        : STD_LOGIC := '0';
    signal reset      : STD_LOGIC := '0';
    signal Ra         : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal Rb         : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal ReadDataA  : STD_LOGIC_VECTOR(31 downto 0);
    signal ReadDataB  : STD_LOGIC_VECTOR(31 downto 0);
    signal Rdst       : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal WriteData  : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal RegWrite   : STD_LOGIC := '0';
    signal Rdst2      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal WriteData2 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal RegWrite2  : STD_LOGIC := '0';
    
begin
    
    UUT: register_file port map (
        clk        => clk,
        reset      => reset,
        Ra         => Ra,
        Rb         => Rb,
        ReadDataA  => ReadDataA,
        ReadDataB  => ReadDataB,
        Rdst       => Rdst,
        WriteData  => WriteData,
        RegWrite   => RegWrite,
        Rdst2      => Rdst2,
        WriteData2 => WriteData2,
        RegWrite2  => RegWrite2
    );
    
    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    stimulus: process
    begin
        report "Starting Register File Testbench";
        
        -- Test 1: Reset
        report "Test 1: Reset all registers";
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait for clk_period;
        
        -- Read all registers (should be 0)
        for i in 0 to 7 loop
            Ra <= std_logic_vector(to_unsigned(i, 3));
            wait for 5 ns;
            assert ReadDataA = X"00000000" 
                report "Register " & integer'image(i) & " not reset" severity error;
        end loop;
        
        -- Test 2: Write to R1
        report "Test 2: Write 0xDEADBEEF to R1";
        Rdst      <= "001";  -- R1
        WriteData <= X"DEADBEEF";
        RegWrite  <= '1';
        wait for clk_period;
        RegWrite  <= '0';
        
        -- Read R1
        Ra <= "001";
        wait for 5 ns;
        assert ReadDataA = X"DEADBEEF" report "Write to R1 failed" severity error;
        
        -- Test 3: Write to all registers
        report "Test 3: Write unique values to all registers";
        for i in 0 to 7 loop
            Rdst      <= std_logic_vector(to_unsigned(i, 3));
            WriteData <= std_logic_vector(to_unsigned(i * 100, 32));
            RegWrite  <= '1';
            wait for clk_period;
        end loop;
        RegWrite <= '0';
        
        -- Verify all registers
        for i in 0 to 7 loop
            Ra <= std_logic_vector(to_unsigned(i, 3));
            wait for 5 ns;
            assert ReadDataA = std_logic_vector(to_unsigned(i * 100, 32))
                report "Register " & integer'image(i) & " value incorrect" severity error;
        end loop;
        
        -- Test 4: Simultaneous read from two ports
        report "Test 4: Simultaneous read from R2 and R5";
        Ra <= "010";  -- R2
        Rb <= "101";  -- R5
        wait for 5 ns;
        assert ReadDataA = std_logic_vector(to_unsigned(200, 32))
            report "Read port A failed" severity error;
        assert ReadDataB = std_logic_vector(to_unsigned(500, 32))
            report "Read port B failed" severity error;
        
        -- Test 5: Read-after-write (asynchronous read)
        report "Test 5: Read immediately after write";
        Rdst      <= "011";  -- R3
        WriteData <= X"CAFEBABE";
        Ra        <= "011";  -- Read R3 on port A
        RegWrite  <= '1';
        wait for clk_period;
        RegWrite  <= '0';
        wait for 5 ns;
        assert ReadDataA = X"CAFEBABE" 
            report "Read-after-write failed" severity error;
        
        -- Test 6: Write to same register on both ports (SWAP test)
        report "Test 6: SWAP test - write to R4 and R6";
        Rdst       <= "100";  -- R4
        WriteData  <= X"11111111";
        Rdst2      <= "110";  -- R6
        WriteData2 <= X"22222222";
        RegWrite   <= '1';
        RegWrite2  <= '1';
        wait for clk_period;
        RegWrite   <= '0';
        RegWrite2  <= '0';
        
        -- Verify both writes
        Ra <= "100";
        Rb <= "110";
        wait for 5 ns;
        assert ReadDataA = X"11111111" report "SWAP write to R4 failed" severity error;
        assert ReadDataB = X"22222222" report "SWAP write to R6 failed" severity error;
        
        -- Test 7: Attempt write to same register from both ports
        report "Test 7: Write conflict - both ports write to R7";
        Rdst       <= "111";  -- R7
        WriteData  <= X"AAAA0000";
        Rdst2      <= "111";  -- R7 (same)
        WriteData2 <= X"0000BBBB";
        RegWrite   <= '1';
        RegWrite2  <= '1';
        wait for clk_period;
        RegWrite   <= '0';
        RegWrite2  <= '0';
        
        -- Read R7 (should have value from port 1 due to conflict handling)
        Ra <= "111";
        wait for 5 ns;
        assert ReadDataA = X"AAAA0000" 
            report "Write conflict resolution failed" severity error;
        
        -- Test 8: Write disabled
        report "Test 8: Write with RegWrite = 0";
        Rdst      <= "010";  -- R2
        WriteData <= X"BADBAD00";
        RegWrite  <= '0';  -- Disabled
        wait for clk_period;
        
        Ra <= "010";
        wait for 5 ns;
        assert ReadDataA = std_logic_vector(to_unsigned(200, 32))
            report "Write occurred when disabled" severity error;
        
        report "Register File Testbench Completed Successfully";
        wait;
    end process;
    
end Behavioral;