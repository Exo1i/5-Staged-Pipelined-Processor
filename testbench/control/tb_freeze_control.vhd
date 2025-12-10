library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_freeze_control is
end tb_freeze_control;

architecture Behavioral of tb_freeze_control is
    
    -- Component Declaration
    component freeze_control
        Port (
            PassPC_MEM       : in  std_logic;
            Stall_Interrupt  : in  std_logic;
            Stall_Branch     : in  std_logic;
            PC_WriteEnable   : out std_logic;
            IFDE_WriteEnable : out std_logic;
            InsertNOP_IFDE   : out std_logic
        );
    end component;
    
    -- Signals
    signal PassPC_MEM       : std_logic := '1';  -- Default: no memory hazard
    signal Stall_Interrupt  : std_logic := '0';  -- Default: no interrupt stall
    signal Stall_Branch     : std_logic := '0';  -- Default: no branch stall
    signal PC_WriteEnable   : std_logic;
    signal IFDE_WriteEnable : std_logic;
    signal InsertNOP_IFDE   : std_logic;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    uut: freeze_control
        port map (
            PassPC_MEM       => PassPC_MEM,
            Stall_Interrupt  => Stall_Interrupt,
            Stall_Branch     => Stall_Branch,
            PC_WriteEnable   => PC_WriteEnable,
            IFDE_WriteEnable => IFDE_WriteEnable,
            InsertNOP_IFDE   => InsertNOP_IFDE
        );
    
    -- Stimulus Process
    stim_proc: process
    begin
        report "====================================";
        report "Starting Freeze Control Tests";
        report "====================================";
        
        -- Test Case 1: No stalls - Normal operation
        PassPC_MEM      <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch    <= '0';
        wait for 10 ns;
        report "Test 1: No stalls - Normal operation";
        assert PC_WriteEnable = '1' and IFDE_WriteEnable = '1' and InsertNOP_IFDE = '0'
            report "Test 1 FAILED: Pipeline should operate normally" 
            severity error;
        report "Test 1 PASSED: PC and IF/DE updating, no NOP insertion";
        
        -- Test Case 2: Memory hazard stall (PassPC_MEM = '0')
        PassPC_MEM      <= '0';
        Stall_Interrupt <= '0';
        Stall_Branch    <= '0';
        wait for 10 ns;
        report "Test 2: Memory hazard stall";
        assert PC_WriteEnable = '0' and IFDE_WriteEnable = '0' and InsertNOP_IFDE = '1'
            report "Test 2 FAILED: Pipeline should freeze due to memory hazard" 
            severity error;
        report "Test 2 PASSED: PC frozen, IF/DE frozen, NOP inserted";
        
        -- Test Case 3: Interrupt stall
        PassPC_MEM      <= '1';
        Stall_Interrupt <= '1';
        Stall_Branch    <= '0';
        wait for 10 ns;
        report "Test 3: Interrupt stall";
        assert PC_WriteEnable = '0' and IFDE_WriteEnable = '0' and InsertNOP_IFDE = '1'
            report "Test 3 FAILED: Pipeline should freeze during interrupt processing" 
            severity error;
        report "Test 3 PASSED: PC frozen, IF/DE frozen, NOP inserted";
        
        -- Test Case 4: Branch stall
        PassPC_MEM      <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch    <= '1';
        wait for 10 ns;
        report "Test 4: Branch stall";
        assert PC_WriteEnable = '0' and IFDE_WriteEnable = '0' and InsertNOP_IFDE = '1'
            report "Test 4 FAILED: Pipeline should freeze due to branch" 
            severity error;
        report "Test 4 PASSED: PC frozen, IF/DE frozen, NOP inserted";
        
        -- Test Case 5: Multiple stalls (memory + interrupt)
        PassPC_MEM      <= '0';
        Stall_Interrupt <= '1';
        Stall_Branch    <= '0';
        wait for 10 ns;
        report "Test 5: Multiple stalls (memory + interrupt)";
        assert PC_WriteEnable = '0' and IFDE_WriteEnable = '0' and InsertNOP_IFDE = '1'
            report "Test 5 FAILED: Pipeline should freeze with multiple stalls" 
            severity error;
        report "Test 5 PASSED: PC frozen, IF/DE frozen, NOP inserted";
        
        -- Test Case 6: All stalls active
        PassPC_MEM      <= '0';
        Stall_Interrupt <= '1';
        Stall_Branch    <= '1';
        wait for 10 ns;
        report "Test 6: All stalls active";
        assert PC_WriteEnable = '0' and IFDE_WriteEnable = '0' and InsertNOP_IFDE = '1'
            report "Test 6 FAILED: Pipeline should freeze with all stalls" 
            severity error;
        report "Test 6 PASSED: PC frozen, IF/DE frozen, NOP inserted";
        
        -- Test Case 7: Return to normal after stalls
        PassPC_MEM      <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch    <= '0';
        wait for 10 ns;
        report "Test 7: Return to normal operation";
        assert PC_WriteEnable = '1' and IFDE_WriteEnable = '1' and InsertNOP_IFDE = '0'
            report "Test 7 FAILED: Pipeline should resume normal operation" 
            severity error;
        report "Test 7 PASSED: Pipeline resumed normally";
        
        -- Test Case 8: Rapid transitions
        PassPC_MEM      <= '0';
        wait for 5 ns;
        assert PC_WriteEnable = '0' report "Test 8a FAILED" severity error;
        
        PassPC_MEM      <= '1';
        wait for 5 ns;
        assert PC_WriteEnable = '1' report "Test 8b FAILED" severity error;
        
        Stall_Interrupt <= '1';
        wait for 5 ns;
        assert PC_WriteEnable = '0' report "Test 8c FAILED" severity error;
        
        Stall_Interrupt <= '0';
        wait for 5 ns;
        assert PC_WriteEnable = '1' report "Test 8d FAILED" severity error;
        report "Test 8 PASSED: Rapid transitions handled correctly";
        
        -- Test Case 9: Edge case - only interrupt and branch (no memory hazard)
        PassPC_MEM      <= '1';
        Stall_Interrupt <= '1';
        Stall_Branch    <= '1';
        wait for 10 ns;
        report "Test 9: Interrupt + Branch stalls";
        assert PC_WriteEnable = '0' and IFDE_WriteEnable = '0' and InsertNOP_IFDE = '1'
            report "Test 9 FAILED: Pipeline should freeze" 
            severity error;
        report "Test 9 PASSED: PC frozen, IF/DE frozen, NOP inserted";
        
        PassPC_MEM      <= '1';
        Stall_Interrupt <= '0';
        Stall_Branch    <= '0';
        wait for 10 ns;
        
        report "====================================";
        report "All Freeze Control Tests Completed Successfully!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;
