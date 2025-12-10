LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.env.ALL;

ENTITY tb_register_file IS
END tb_register_file;

ARCHITECTURE Behavioral OF tb_register_file IS

    COMPONENT register_file IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            Ra : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rb : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ReadDataA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            ReadDataB : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            WriteEnable : IN STD_LOGIC
        );
    END COMPONENT;

    -- Clock period
    CONSTANT clk_period : TIME := 20 ns; -- 50 MHz

    -- Test signals
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL Ra : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Rb : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ReadDataA : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ReadDataB : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL Rdst : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL WriteData : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL WriteEnable : STD_LOGIC := '0';

BEGIN

    UUT : register_file PORT MAP(
        clk => clk,
        reset => reset,
        Ra => Ra,
        Rb => Rb,
        ReadDataA => ReadDataA,
        ReadDataB => ReadDataB,
        Rdst => Rdst,
        WriteData => WriteData,
        WriteEnable => WriteEnable
    );

    -- Clock generation
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period/2;
        clk <= '1';
        WAIT FOR clk_period/2;
    END PROCESS;

    stimulus : PROCESS
    BEGIN
        REPORT "Starting Register File Testbench";

        -- Test 1: Reset
        REPORT "Test 1: Reset all registers";
        reset <= '1';
        WAIT FOR clk_period;
        reset <= '0';
        WAIT FOR clk_period;

        -- Read all registers (should be 0)
        FOR i IN 0 TO 7 LOOP
            Ra <= STD_LOGIC_VECTOR(to_unsigned(i, 3));
            WAIT FOR 5 ns;
            ASSERT ReadDataA = X"00000000"
            REPORT "Register " & INTEGER'image(i) & " not reset" SEVERITY error;
        END LOOP;

        -- Test 2: Write to R1
        REPORT "Test 2: Write 0xDEADBEEF to R1";
        Rdst <= "001"; -- R1
        WriteData <= X"DEADBEEF";
        WriteEnable <= '1';
        WAIT FOR clk_period;
        WriteEnable <= '0';

        -- Read R1
        Ra <= "001";
        WAIT FOR 5 ns;
        ASSERT ReadDataA = X"DEADBEEF" REPORT "Write to R1 failed" SEVERITY error;

        -- Test 3: Write to all registers
        REPORT "Test 3: Write unique values to all registers";
        FOR i IN 0 TO 7 LOOP
            Rdst <= STD_LOGIC_VECTOR(to_unsigned(i, 3));
            WriteData <= STD_LOGIC_VECTOR(to_unsigned(i * 100, 32));
            WriteEnable <= '1';
            WAIT FOR clk_period;
        END LOOP;
        WriteEnable <= '0';

        -- Verify all registers
        FOR i IN 0 TO 7 LOOP
            Ra <= STD_LOGIC_VECTOR(to_unsigned(i, 3));
            WAIT FOR clk_period;
            ASSERT ReadDataA = STD_LOGIC_VECTOR(to_unsigned(i * 100, 32))
            REPORT "Register " & INTEGER'image(i) & " value incorrect" SEVERITY error;
        END LOOP;

        -- Test 4: Simultaneous read from two ports
        REPORT "Test 4: Simultaneous read from R2 and R5";
        Ra <= "010"; -- R2
        Rb <= "101"; -- R5
        WAIT FOR 5 ns;
        ASSERT ReadDataA = STD_LOGIC_VECTOR(to_unsigned(200, 32))
        REPORT "Read port A failed" SEVERITY error;
        ASSERT ReadDataB = STD_LOGIC_VECTOR(to_unsigned(500, 32))
        REPORT "Read port B failed" SEVERITY error;

        -- Test 5: Read-after-write (asynchronous read)
        REPORT "Test 5: Read immediately after write";
        Rdst <= "011"; -- R3
        WriteData <= X"CAFEBABE";
        Ra <= "011"; -- Read R3 on port A
        WriteEnable <= '1';
        WAIT FOR clk_period;
        WriteEnable <= '0';
        WAIT FOR 5 ns;
        ASSERT ReadDataA = X"CAFEBABE"
        REPORT "Read-after-write failed" SEVERITY error;

        -- Test 6: Multiple sequential writes
        REPORT "Test 6: Multiple sequential writes";
        Rdst <= "100"; -- R4
        WriteData <= X"11111111";
        WriteEnable <= '1';
        WAIT FOR clk_period;

        Rdst <= "110"; -- R6
        WriteData <= X"22222222";
        WAIT FOR clk_period;
        WriteEnable <= '0';

        -- Verify both writes
        Ra <= "100";
        Rb <= "110";
        WAIT FOR 5 ns;
        ASSERT ReadDataA = X"11111111" REPORT "Write to R4 failed" SEVERITY error;
        ASSERT ReadDataB = X"22222222" REPORT "Write to R6 failed" SEVERITY error;

        -- Test 7: Overwrite same register
        REPORT "Test 7: Overwrite R7 multiple times";
        Rdst <= "111"; -- R7
        WriteData <= X"AAAA0000";
        WriteEnable <= '1';
        WAIT FOR clk_period;

        WriteData <= X"0000BBBB";
        WAIT FOR clk_period;
        WriteEnable <= '0';

        -- Read R7 (should have last written value)
        Ra <= "111";
        WAIT FOR 5 ns;
        ASSERT ReadDataA = X"0000BBBB"
        REPORT "Overwrite failed" SEVERITY error;

        -- Test 8: Write disabled
        REPORT "Test 8: Write with WriteEnable = 0";
        Rdst <= "010"; -- R2
        WriteData <= X"BADBAD00";
        WriteEnable <= '0'; -- Disabled
        WAIT FOR clk_period;

        Ra <= "010";
        WAIT FOR 5 ns;
        ASSERT ReadDataA = STD_LOGIC_VECTOR(to_unsigned(200, 32))
        REPORT "Write occurred when disabled" SEVERITY error;

        REPORT "Register File Testbench Completed Successfully";
        finish;
    END PROCESS;

END Behavioral;