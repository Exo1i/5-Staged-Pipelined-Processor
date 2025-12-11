LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_pc IS
END ENTITY tb_pc;

ARCHITECTURE behavior OF tb_pc IS
    -- Component Declaration
    COMPONENT pc
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            BranchSelect : IN STD_LOGIC;
            BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            enable : IN STD_LOGIC;
            target_decode : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_execute : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_memory : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_reset : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_plus_one : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    -- Test signals
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL BranchSelect : STD_LOGIC := '0';
    SIGNAL BranchTargetSelect : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL enable : STD_LOGIC := '1';
    SIGNAL target_decode : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_execute : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_memory : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_reset : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pc_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_plus_one : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Branch target select encoding (matching branch_decision_unit)
    CONSTANT SEL_DECODE : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    CONSTANT SEL_EXECUTE : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT SEL_MEMORY : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT SEL_RESET : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";

    -- Clock period
    CONSTANT clk_period : TIME := 10 ns;

    -- Test control
    SIGNAL test_done : BOOLEAN := FALSE;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut : pc
    PORT MAP(
        clk => clk,
        rst => rst,
        BranchSelect => BranchSelect,
        BranchTargetSelect => BranchTargetSelect,
        enable => enable,
        target_decode => target_decode,
        target_execute => target_execute,
        target_memory => target_memory,
        target_reset => target_reset,
        pc_out => pc_out,
        pc_plus_one => pc_plus_one
    );

    -- Clock process
    clk_process : PROCESS
    BEGIN
        WHILE NOT test_done LOOP
            clk <= '0';
            WAIT FOR clk_period/2;
            clk <= '1';
            WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    -- Stimulus process
    stim_proc : PROCESS
    BEGIN
        -- Test 1: Reset
        REPORT "Test 1: Reset" SEVERITY NOTE;
        rst <= '1';
        WAIT FOR clk_period;
        rst <= '0';
        ASSERT pc_out = X"00000000"
        REPORT "Reset failed" SEVERITY ERROR;

        -- Test 2: Load reset vector from memory
        REPORT "Test 2: Load reset vector from memory" SEVERITY NOTE;
        target_reset <= X"00000100"; -- Reset vector address
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_RESET; -- Load from memory (reset vector)
        enable <= '1';
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000100"
        REPORT "Reset vector load failed" SEVERITY ERROR;

        -- Test 3: Normal increment
        REPORT "Test 3: Normal increment" SEVERITY NOTE;
        BranchSelect <= '0'; -- Normal increment (PC+1)
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000101"
        REPORT "PC increment failed" SEVERITY ERROR;
        ASSERT pc_plus_one = X"00000102"
        REPORT "PC+1 output incorrect" SEVERITY ERROR;

        -- Test 4: Multiple increments
        REPORT "Test 4: Multiple increments" SEVERITY NOTE;
        FOR i IN 0 TO 4 LOOP
            WAIT FOR clk_period;
        END LOOP;
        ASSERT pc_out = X"00000106"
        REPORT "Multiple increments failed" SEVERITY ERROR;

        -- Test 5: Unconditional Branch/Jump from decode stage
        REPORT "Test 5: Unconditional branch from decode (JMP/CALL)" SEVERITY NOTE;
        target_decode <= X"00000200";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_DECODE; -- Branch from decode stage
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000200"
        REPORT "Branch from decode failed" SEVERITY ERROR;

        -- Test 6: Conditional branch from execute stage
        REPORT "Test 6: Conditional branch from execute (JZ/JN/JC)" SEVERITY NOTE;
        target_execute <= X"00000300";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_EXECUTE; -- Branch from execute stage
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000300"
        REPORT "Branch from execute failed" SEVERITY ERROR;

        -- Test 7: Interrupt - Load PC from memory
        REPORT "Test 7: Interrupt - Load PC from memory" SEVERITY NOTE;
        target_memory <= X"00000400";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_MEMORY; -- Interrupt vector
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000400"
        REPORT "Interrupt vector load failed" SEVERITY ERROR;

        -- Test 8: HLT (disable PC)
        REPORT "Test 8: HLT - Freeze PC" SEVERITY NOTE;
        enable <= '0'; -- Disable PC update
        BranchSelect <= '0'; -- Try to increment
        WAIT FOR clk_period * 3;
        ASSERT pc_out = X"00000400"
        REPORT "HLT failed - PC should be frozen" SEVERITY ERROR;

        -- Test 9: Resume after HLT
        REPORT "Test 9: Resume after HLT" SEVERITY NOTE;
        enable <= '1';
        BranchSelect <= '0'; -- Normal increment
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000401"
        REPORT "Resume after HLT failed" SEVERITY ERROR;

        -- Test 10: Sequential increment from reset
        REPORT "Test 10: Sequential increment from reset vector" SEVERITY NOTE;
        rst <= '1';
        WAIT FOR clk_period;
        rst <= '0';
        target_reset <= X"00000000";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_RESET; -- Load reset vector
        WAIT FOR clk_period;
        BranchSelect <= '0'; -- Normal increment mode
        FOR i IN 1 TO 10 LOOP
            WAIT FOR clk_period;
            ASSERT pc_out = STD_LOGIC_VECTOR(TO_UNSIGNED(i, 32))
            REPORT "Sequential increment failed at iteration " & INTEGER'IMAGE(i) SEVERITY ERROR;
        END LOOP;

        -- Test 11: Branch prediction scenario - misprediction recovery
        REPORT "Test 11: Misprediction recovery from execute stage" SEVERITY NOTE;
        target_execute <= X"00000500";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_EXECUTE; -- Corrected branch target
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000500"
        REPORT "Misprediction recovery failed" SEVERITY ERROR;

        -- Test 12: CALL simulation (save PC+1)
        REPORT "Test 12: CALL - Check PC+1 output for saving" SEVERITY NOTE;
        target_decode <= X"00000600";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_DECODE; -- Jump to subroutine
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000600"
        REPORT "CALL jump failed" SEVERITY ERROR;
        ASSERT pc_plus_one = X"00000601"
        REPORT "CALL PC+1 incorrect" SEVERITY ERROR;

        -- End of tests
        REPORT "All tests completed successfully!" SEVERITY NOTE;
        test_done <= TRUE;
        WAIT;
    END PROCESS;

END ARCHITECTURE behavior;