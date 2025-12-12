LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY tb_freeze_control IS
END tb_freeze_control;

ARCHITECTURE Behavioral OF tb_freeze_control IS

    -- Component Declaration
    COMPONENT freeze_control
        PORT (
            PassPC_MEM : IN STD_LOGIC;
            Stall_Interrupt : IN STD_LOGIC;
            Stall_Branch : IN STD_LOGIC;
            PC_Freeze : OUT STD_LOGIC;
            IFDE_WriteEnable : OUT STD_LOGIC;
            InsertNOP_IFDE : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Signals
    SIGNAL PassPC_MEM : STD_LOGIC := '1'; -- Default: no memory hazard
    SIGNAL Stall_Interrupt : STD_LOGIC := '0'; -- Default: no interrupt stall
    SIGNAL Stall_Branch : STD_LOGIC := '0'; -- Default: no branch stall
    SIGNAL PC_Freeze : STD_LOGIC;
    SIGNAL IFDE_WriteEnable : STD_LOGIC;
    SIGNAL InsertNOP_IFDE : STD_LOGIC;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut : freeze_control
    PORT MAP(
        PassPC_MEM => PassPC_MEM,
        Stall_Interrupt => Stall_Interrupt,
        Stall_Branch => Stall_Branch,
        PC_Freeze => PC_Freeze,
        IFDE_WriteEnable => IFDE_WriteEnable,
        InsertNOP_IFDE => InsertNOP_IFDE
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
        Stall_Branch <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 1: No stalls - Normal operation";
        ASSERT PC_Freeze = '0' AND IFDE_WriteEnable = '0' AND InsertNOP_IFDE = '0'
        REPORT "Test 1 FAILED: Pipeline should operate normally"
            SEVERITY error;
        REPORT "Test 1 PASSED: PC and IF/DE updating, no NOP insertion";

        -- Test Case 2: Memory hazard stall (PassPC_MEM = '0')
        PassPC_MEM <= '0';
        Stall_Interrupt <= '0';
        Stall_Branch <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 2: Memory hazard stall";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 2 FAILED: Pipeline should freeze due to memory hazard"
            SEVERITY error;
        REPORT "Test 2 PASSED: PC frozen, IF/DE frozen, NOP inserted";

        -- Test Case 3: Interrupt stall
        PassPC_MEM <= '1';
        Stall_Interrupt <= '1';
        Stall_Branch <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 3: Interrupt stall";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 3 FAILED: Pipeline should freeze during interrupt processing"
            SEVERITY error;
        REPORT "Test 3 PASSED: PC frozen, IF/DE frozen, NOP inserted";

        -- Test Case 4: Branch stall
        PassPC_MEM <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 4: Branch stall";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 4 FAILED: Pipeline should freeze due to branch"
            SEVERITY error;
        REPORT "Test 4 PASSED: PC frozen, IF/DE frozen, NOP inserted";

        -- Test Case 5: Multiple stalls (memory + interrupt)
        PassPC_MEM <= '0';
        Stall_Interrupt <= '1';
        Stall_Branch <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 5: Multiple stalls (memory + interrupt)";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 5 FAILED: Pipeline should freeze with multiple stalls"
            SEVERITY error;
        REPORT "Test 5 PASSED: PC frozen, IF/DE frozen, NOP inserted";

        -- Test Case 6: All stalls active
        PassPC_MEM <= '0';
        Stall_Interrupt <= '1';
        Stall_Branch <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 6: All stalls active";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 6 FAILED: Pipeline should freeze with all stalls"
            SEVERITY error;
        REPORT "Test 6 PASSED: PC frozen, IF/DE frozen, NOP inserted";

        -- Test Case 7: Return to normal after stalls
        PassPC_MEM <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch <= '0';
        WAIT FOR 10 ns;
        REPORT "Test 7: Return to normal operation";
        ASSERT PC_Freeze = '0' AND IFDE_WriteEnable = '0' AND InsertNOP_IFDE = '0'
        REPORT "Test 7 FAILED: Pipeline should resume normal operation"
            SEVERITY error;
        REPORT "Test 7 PASSED: Pipeline resumed normally";

        -- Test Case 8: Rapid transitions
        PassPC_MEM <= '0';
        WAIT FOR 5 ns;
        ASSERT PC_Freeze = '1' REPORT "Test 8a FAILED" SEVERITY error;

        PassPC_MEM <= '1';
        WAIT FOR 5 ns;
        ASSERT PC_Freeze = '0' REPORT "Test 8b FAILED" SEVERITY error;

        Stall_Interrupt <= '1';
        WAIT FOR 5 ns;
        ASSERT PC_Freeze = '1' REPORT "Test 8c FAILED" SEVERITY error;

        Stall_Interrupt <= '0';
        WAIT FOR 5 ns;
        ASSERT PC_Freeze = '0' REPORT "Test 8d FAILED" SEVERITY error;
        REPORT "Test 8 PASSED: Rapid transitions handled correctly";

        -- Test Case 9: Edge case - only interrupt and branch (no memory hazard)
        PassPC_MEM <= '1';
        Stall_Interrupt <= '1';
        Stall_Branch <= '1';
        WAIT FOR 10 ns;
        REPORT "Test 9: Interrupt + Branch stalls";
        ASSERT PC_Freeze = '1' AND IFDE_WriteEnable = '1' AND InsertNOP_IFDE = '1'
        REPORT "Test 9 FAILED: Pipeline should freeze"
            SEVERITY error;
        REPORT "Test 9 PASSED: PC frozen, IF/DE frozen, NOP inserted";

        PassPC_MEM <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch <= '0';
        WAIT FOR 10 ns;

        REPORT "====================================";
        REPORT "All Freeze Control Tests Completed Successfully!";
        REPORT "====================================";

        WAIT;
    END PROCESS;

END Behavioral;