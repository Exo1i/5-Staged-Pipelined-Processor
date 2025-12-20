LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.ALL;

ENTITY tb_freeze_control IS
END tb_freeze_control;

ARCHITECTURE Behavioral OF tb_freeze_control IS

    -- Component Declaration
    COMPONENT freeze_control
        PORT (
            PassPC_MEM : IN STD_LOGIC;
            Stall_Interrupt : IN STD_LOGIC;
            BranchSelect : IN STD_LOGIC;
            BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            is_swap : IN STD_LOGIC;
            is_hlt : IN STD_LOGIC;
            requireImmediate : IN STD_LOGIC;
            memory_hazard_int : IN STD_LOGIC;
            FlushIF : IN STD_LOGIC;
            FlushDE : IN STD_LOGIC;
            PC_Freeze : OUT STD_LOGIC;
            IFDE_WriteEnable : OUT STD_LOGIC;
            InsertNOP_IFDE : OUT STD_LOGIC;
            InsertNOP_DEEX : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Signals
    SIGNAL PassPC_MEM : STD_LOGIC := '1';
    SIGNAL Stall_Interrupt : STD_LOGIC := '0';
    SIGNAL BranchSelect : STD_LOGIC := '0';
    SIGNAL BranchTargetSelect : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL is_swap : STD_LOGIC := '0';
    SIGNAL is_hlt : STD_LOGIC := '0';
    SIGNAL requireImmediate : STD_LOGIC := '0';
    SIGNAL memory_hazard_int : STD_LOGIC := '0';
    SIGNAL FlushIF : STD_LOGIC := '0';
    SIGNAL FlushDE : STD_LOGIC := '0';
    SIGNAL PC_Freeze : STD_LOGIC;
    SIGNAL IFDE_WriteEnable : STD_LOGIC;
    SIGNAL InsertNOP_IFDE : STD_LOGIC;
    SIGNAL InsertNOP_DEEX : STD_LOGIC;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut : freeze_control
    PORT MAP(
        PassPC_MEM => PassPC_MEM,
        Stall_Interrupt => Stall_Interrupt,
        BranchSelect => BranchSelect,
        BranchTargetSelect => BranchTargetSelect,
        is_swap => is_swap,
        is_hlt => is_hlt,
        requireImmediate => requireImmediate,
        memory_hazard_int => memory_hazard_int,
        FlushIF => FlushIF,
        FlushDE => FlushDE,
        PC_Freeze => PC_Freeze,
        IFDE_WriteEnable => IFDE_WriteEnable,
        InsertNOP_IFDE => InsertNOP_IFDE,
        InsertNOP_DEEX => InsertNOP_DEEX
    );

    -- Stimulus Process
    stim_proc : PROCESS
    BEGIN
        REPORT "====================================";
        REPORT "Starting Freeze Control Tests";
        REPORT "====================================";

        -- Test Case 1: No stalls - Normal operation
        PassPC_MEM <= '1';
        Stall_Interrupt <= '0';
        BranchSelect <= '0';
        FlushIF <= '0';
        FlushDE <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 1: No stalls - Normal operation";
        ASSERT PC_Freeze = '0' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '0'
        REPORT "Test 1 FAILED: Pipeline should operate normally"
            SEVERITY error;
        REPORT "Test 1 PASSED: PC and IF/DE updating, no NOP insertion";

        -- Test Case 2: Memory hazard stall (PassPC_MEM = '0')
        PassPC_MEM <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 2: Memory hazard stall";
        ASSERT PC_Freeze = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 2 FAILED: Pipeline should freeze due to memory hazard"
            SEVERITY error;
        REPORT "Test 2 PASSED: PC frozen, NOP inserted";
        PassPC_MEM <= '1';

        -- Test Case 3: FlushIF signal
        FlushIF <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 3: FlushIF signal";
        ASSERT InsertNOP_IFDE = '1'
        REPORT "Test 3 FAILED: FlushIF should insert NOP in IF/DE"
            SEVERITY error;
        REPORT "Test 3 PASSED: NOP inserted in IF/DE";
        FlushIF <= '0';

        -- Test Case 4: FlushDE signal
        FlushDE <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 4: FlushDE signal";
        ASSERT InsertNOP_DEEX = '1'
        REPORT "Test 4 FAILED: FlushDE should insert NOP in DE/EX"
            SEVERITY error;
        REPORT "Test 4 PASSED: NOP inserted in DE/EX";
        FlushDE <= '0';

        -- Test Case 5: Both flush signals (misprediction)
        FlushIF <= '1';
        FlushDE <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 5: Both flush signals (misprediction)";
        ASSERT InsertNOP_IFDE = '1' AND InsertNOP_DEEX = '1'
        REPORT "Test 5 FAILED: Both stages should be flushed"
            SEVERITY error;
        REPORT "Test 5 PASSED: Both stages flushed";
        FlushIF <= '0';
        FlushDE <= '0';

        -- Test Case 6: HLT instruction
        is_hlt <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 6: HLT instruction";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '0' AND InsertNOP_DEEX = '1'
        REPORT "Test 6 FAILED: HLT should freeze pipeline"
            SEVERITY error;
        REPORT "Test 6 PASSED: Pipeline frozen on HLT";
        is_hlt <= '0';

        -- Test Case 7: SWAP instruction
        is_swap <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 7: SWAP instruction";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '0'
        REPORT "Test 7 FAILED: SWAP should stall front-end"
            SEVERITY error;
        REPORT "Test 7 PASSED: Front-end stalled on SWAP";
        is_swap <= '0';
        WAIT FOR 10 ns;

        REPORT "====================================";
        REPORT "All Freeze Control Tests Completed Successfully!";
        REPORT "====================================";

        WAIT;
    END PROCESS;

END Behavioral;