library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_branch_decision_unit is
end tb_branch_decision_unit;

architecture Behavioral of tb_branch_decision_unit is
    
    component branch_decision_unit
        Port (
            IsSoftwareInterrupt     : in  std_logic;
            IsHardwareInterrupt     : in  std_logic;
            UnconditionalBranch     : in  std_logic;
            ConditionalBranch       : in  std_logic;
            PredictedTaken          : in  std_logic;
            ActualTaken             : in  std_logic;
            Reset                   : in  std_logic;
            BranchSelect            : out std_logic;
            BranchTargetSelect      : out std_logic_vector(1 downto 0);
            FlushDE                 : out std_logic;
            FlushIF                 : out std_logic;
            Stall_Branch            : out std_logic
        );
    end component;
    
    -- Signals
    signal IsSoftwareInterrupt     : std_logic := '0';
    signal IsHardwareInterrupt     : std_logic := '0';
    signal UnconditionalBranch     : std_logic := '0';
    signal ConditionalBranch       : std_logic := '0';
    signal PredictedTaken          : std_logic := '0';
    signal ActualTaken             : std_logic := '0';
    signal Reset                   : std_logic := '0';
    signal BranchSelect            : std_logic;
    signal BranchTargetSelect      : std_logic_vector(1 downto 0);
    signal FlushDE                 : std_logic;
    signal FlushIF                 : std_logic;
    signal Stall_Branch            : std_logic;
    
begin
    
    -- Instantiate UUT
    uut: branch_decision_unit
        port map (
            IsSoftwareInterrupt => IsSoftwareInterrupt,
            IsHardwareInterrupt => IsHardwareInterrupt,
            UnconditionalBranch => UnconditionalBranch,
            ConditionalBranch => ConditionalBranch,
            PredictedTaken => PredictedTaken,
            ActualTaken => ActualTaken,
            Reset => Reset,
            BranchSelect => BranchSelect,
            BranchTargetSelect => BranchTargetSelect,
            FlushDE => FlushDE,
            FlushIF => FlushIF,
            Stall_Branch => Stall_Branch
        );
    
    -- Test process
    stim_proc: process
    begin
        report "====================================";
        report "Starting Branch Decision Unit Tests";
        report "====================================";
        
        wait for 10 ns;
        
        -- Test 1: No branch
        report "Test 1: No branch - normal operation";
        wait for 10 ns;
        assert BranchSelect = '0' and FlushDE = '0' and FlushIF = '0'
            report "Test 1 FAILED" severity error;
        report "Test 1 PASSED";
        
        -- Test 2: Reset (highest priority)
        report "Test 2: Reset signal";
        Reset <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "11" and 
               FlushDE = '1' and FlushIF = '1'
            report "Test 2 FAILED: Reset should branch and flush" severity error;
        report "Test 2 PASSED";
        Reset <= '0';
        wait for 10 ns;
        
        -- Test 3: Hardware interrupt
        report "Test 3: Hardware interrupt";
        IsHardwareInterrupt <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "10" and
               FlushDE = '1' and FlushIF = '1'
            report "Test 3 FAILED" severity error;
        report "Test 3 PASSED";
        IsHardwareInterrupt <= '0';
        wait for 10 ns;
        
        -- Test 4: Software interrupt
        report "Test 4: Software interrupt";
        IsSoftwareInterrupt <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "10" and
               FlushDE = '1' and FlushIF = '1'
            report "Test 4 FAILED" severity error;
        report "Test 4 PASSED";
        IsSoftwareInterrupt <= '0';
        wait for 10 ns;
        
        -- Test 5: Unconditional branch
        report "Test 5: Unconditional branch (JMP/CALL)";
        UnconditionalBranch <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "00" and
               FlushDE = '1' and FlushIF = '1'
            report "Test 5 FAILED" severity error;
        report "Test 5 PASSED";
        UnconditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 6: Conditional branch - predicted taken, actually taken (correct)
        report "Test 6: Conditional branch - correct prediction (taken)";
        ConditionalBranch <= '1';
        PredictedTaken <= '1';
        ActualTaken <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "01"
            report "Test 6 FAILED" severity error;
        report "Test 6 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 7: Conditional branch - predicted not taken, actually not taken (correct)
        report "Test 7: Conditional branch - correct prediction (not taken)";
        ConditionalBranch <= '1';
        PredictedTaken <= '0';
        ActualTaken <= '0';
        wait for 10 ns;
        assert BranchSelect = '0'
            report "Test 7 FAILED" severity error;
        report "Test 7 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 8: Misprediction - predicted taken, actually not taken
        report "Test 8: Misprediction - predicted taken, actually not taken";
        ConditionalBranch <= '1';
        PredictedTaken <= '1';
        ActualTaken <= '0';
        wait for 10 ns;
        assert BranchSelect = '0' and FlushDE = '1' and FlushIF = '1'
            report "Test 8 FAILED: Should not branch but should flush" severity error;
        report "Test 8 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 9: Misprediction - predicted not taken, actually taken
        report "Test 9: Misprediction - predicted not taken, actually taken";
        ConditionalBranch <= '1';
        PredictedTaken <= '0';
        ActualTaken <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "01" and
               FlushDE = '1' and FlushIF = '1'
            report "Test 9 FAILED: Should branch and flush" severity error;
        report "Test 9 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 10: Priority test - Reset over interrupt
        report "Test 10: Priority - Reset should override interrupt";
        Reset <= '1';
        IsHardwareInterrupt <= '1';
        wait for 10 ns;
        assert BranchTargetSelect = "11"
            report "Test 10 FAILED: Reset should have priority" severity error;
        report "Test 10 PASSED";
        Reset <= '0';
        IsHardwareInterrupt <= '0';
        wait for 10 ns;
        
        report "====================================";
        report "All Branch Decision Unit Tests Completed!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;
