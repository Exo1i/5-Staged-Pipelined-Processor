library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_memory_hazard_unit is
end tb_memory_hazard_unit;

architecture Behavioral of tb_memory_hazard_unit is
    
    -- Component Declaration
    component memory_hazard_unit
        Port (
            MemRead_MEM     : in  std_logic;
            MemWrite_MEM    : in  std_logic;
            PassPC          : out std_logic;
            MemRead_Out     : out std_logic;
            MemWrite_Out    : out std_logic
        );
    end component;
    
    -- Signals
    signal MemRead_MEM  : std_logic := '0';
    signal MemWrite_MEM : std_logic := '0';
    signal PassPC       : std_logic;
    signal MemRead_Out  : std_logic;
    signal MemWrite_Out : std_logic;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    uut: memory_hazard_unit
        port map (
            MemRead_MEM  => MemRead_MEM,
            MemWrite_MEM => MemWrite_MEM,
            PassPC       => PassPC,
            MemRead_Out  => MemRead_Out,
            MemWrite_Out => MemWrite_Out
        );
    
    -- Stimulus Process
    stim_proc: process
    begin
        report "====================================";
        report "Starting Memory Hazard Unit Tests";
        report "====================================";
        
        -- Test Case 1: No memory operation (both Read and Write are 0)
        MemRead_MEM  <= '0';
        MemWrite_MEM <= '0';
        wait for 10 ns;
        report "Test 1: No memory operation";
        assert PassPC = '1' and MemRead_Out = '0' and MemWrite_Out = '0'
            report "Test 1 FAILED: Fetch should be allowed when memory stage idle" 
            severity error;
        report "Test 1 PASSED: PassPC='1', Fetch allowed";
        
        -- Test Case 2: Memory stage reading (Load instruction)
        MemRead_MEM  <= '1';
        MemWrite_MEM <= '0';
        wait for 10 ns;
        report "Test 2: Memory stage reading";
        assert PassPC = '0' and MemRead_Out = '1' and MemWrite_Out = '0'
            report "Test 2 FAILED: Fetch should be blocked during memory read" 
            severity error;
        report "Test 2 PASSED: PassPC='0', Fetch blocked, MemRead propagated";
        
        -- Test Case 3: Memory stage writing (Store instruction)
        MemRead_MEM  <= '0';
        MemWrite_MEM <= '1';
        wait for 10 ns;
        report "Test 3: Memory stage writing";
        assert PassPC = '0' and MemRead_Out = '0' and MemWrite_Out = '1'
            report "Test 3 FAILED: Fetch should be blocked during memory write" 
            severity error;
        report "Test 3 PASSED: PassPC='0', Fetch blocked, MemWrite propagated";
        
        -- Test Case 4: Both Read and Write signals active (shouldn't happen normally)
        MemRead_MEM  <= '1';
        MemWrite_MEM <= '1';
        wait for 10 ns;
        report "Test 4: Both Read and Write active";
        assert PassPC = '0' and MemRead_Out = '1' and MemWrite_Out = '1'
            report "Test 4 FAILED: Fetch should be blocked when memory busy" 
            severity error;
        report "Test 4 PASSED: PassPC='0', Fetch blocked";
        
        -- Test Case 5: Return to idle
        MemRead_MEM  <= '0';
        MemWrite_MEM <= '0';
        wait for 10 ns;
        report "Test 5: Return to idle";
        assert PassPC = '1' and MemRead_Out = '0' and MemWrite_Out = '0'
            report "Test 5 FAILED: Fetch should be allowed again" 
            severity error;
        report "Test 5 PASSED: PassPC='1', Fetch allowed again";
        
        -- Test Case 6: Rapid transitions (Read -> Idle -> Write)
        MemRead_MEM  <= '1';
        MemWrite_MEM <= '0';
        wait for 5 ns;
        assert PassPC = '0' report "Test 6a FAILED" severity error;
        
        MemRead_MEM  <= '0';
        MemWrite_MEM <= '0';
        wait for 5 ns;
        assert PassPC = '1' report "Test 6b FAILED" severity error;
        
        MemRead_MEM  <= '0';
        MemWrite_MEM <= '1';
        wait for 5 ns;
        assert PassPC = '0' report "Test 6c FAILED" severity error;
        report "Test 6 PASSED: Rapid transitions handled correctly";
        
        MemRead_MEM  <= '0';
        MemWrite_MEM <= '0';
        wait for 10 ns;
        
        report "====================================";
        report "All Memory Hazard Unit Tests Completed Successfully!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;
