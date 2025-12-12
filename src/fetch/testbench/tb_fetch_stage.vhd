LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_fetch_stage IS
END ENTITY tb_fetch_stage;

ARCHITECTURE behavior OF tb_fetch_stage IS
    COMPONENT fetch_stage
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            stall : IN STD_LOGIC;
            BranchSelect : IN STD_LOGIC;
            BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            target_decode : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_execute : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_memory : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            mem_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            intr_in : IN STD_LOGIC;
            PushPCSelect : IN STD_LOGIC
        );
    END COMPONENT;

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL stall : STD_LOGIC := '0';
    SIGNAL BranchSelect : STD_LOGIC := '0';
    SIGNAL BranchTargetSelect : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL target_decode : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_execute : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL target_memory : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pc_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pushed_pc_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL instruction_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL intr_in : STD_LOGIC := '0';
    SIGNAL PushPCSelect : STD_LOGIC := '0';

    -- Branch target select encoding
    CONSTANT SEL_DECODE : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    CONSTANT SEL_EXECUTE : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT SEL_MEMORY : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT SEL_RESET : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";

    CONSTANT clk_period : TIME := 10 ns;

    SIGNAL test_done : BOOLEAN := FALSE;

BEGIN
    uut : fetch_stage
    PORT MAP(
        clk => clk,
        rst => rst,
        stall => stall,
        BranchSelect => BranchSelect,
        BranchTargetSelect => BranchTargetSelect,
        target_decode => target_decode,
        target_execute => target_execute,
        target_memory => target_memory,
        mem_data => mem_data,
        pc_out => pc_out,
        pushed_pc_out => pushed_pc_out,
        instruction_out => instruction_out,
        intr_in => intr_in,
        PushPCSelect => PushPCSelect
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
        -- Test 1: Reset Sequence
        REPORT "Test 1: Reset Sequence" SEVERITY NOTE;
        rst <= '1';
        WAIT FOR clk_period;
        rst <= '0';

        -- Expect PC to be 0, Memory returns M[0]
        mem_data <= X"00000100"; -- M[0] = Reset Vector
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_RESET;
        WAIT FOR clk_period;

        ASSERT pc_out = X"00000100"
        REPORT "Reset vector load failed" SEVERITY ERROR;

        -- Test 2: Normal Fetch
        REPORT "Test 2: Normal Fetch" SEVERITY NOTE;
        BranchSelect <= '0'; -- Normal increment
        mem_data <= X"12345678"; -- Instruction at 0x100
        WAIT FOR clk_period;

        ASSERT pc_out = X"00000101"
        REPORT "PC increment failed" SEVERITY ERROR;
        ASSERT instruction_out = X"12345678"
        REPORT "Instruction fetch failed" SEVERITY ERROR;

        -- Test 3: Stall
        REPORT "Test 3: Stall" SEVERITY NOTE;
        stall <= '1';
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000101"
        REPORT "Stall failed - PC changed" SEVERITY ERROR;

        stall <= '0';
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000102"
        REPORT "Resume after stall failed" SEVERITY ERROR;

        -- Test 4: Branch from Decode
        REPORT "Test 4: Branch from Decode" SEVERITY NOTE;
        target_decode <= X"00000200";
        BranchSelect <= '1';
        BranchTargetSelect <= SEL_DECODE;
        WAIT FOR clk_period;
        ASSERT pc_out = X"00000200"
        REPORT "Branch from decode failed" SEVERITY ERROR;

        -- Test 5: Interrupt Input and PushedPC Selection
        REPORT "Test 5: Interrupt Input and PushedPC Selection" SEVERITY NOTE;
        intr_in <= '1';

        -- Case 1: PushPCSelect = '0' (Default, PC+1)
        PushPCSelect <= '0';
        WAIT FOR clk_period;
        -- Current PC is 0x200 (from previous test), so PC+1 is 0x201
        ASSERT pushed_pc_out = X"00000201"
        REPORT "PushedPC (PC+1) selection failed" SEVERITY ERROR;

        -- Case 2: PushPCSelect = '1' (Push Current PC)
        PushPCSelect <= '1';
        WAIT FOR clk_period;
        -- Current PC is 0x201 (incremented), so PushedPC should be 0x201
        ASSERT pushed_pc_out = X"00000201"
        REPORT "PushedPC (Current PC) selection failed" SEVERITY ERROR;

        intr_in <= '0';
        PushPCSelect <= '0';

        -- End of tests
        REPORT "All tests completed successfully!" SEVERITY NOTE;
        test_done <= TRUE;
        WAIT;
    END PROCESS;

END ARCHITECTURE behavior;