library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_branch_decision_unit is
end tb_branch_decision_unit;

architecture Behavioral of tb_branch_decision_unit is
    
    component branch_decision_unit
        Port (
            IsSoftwareInterrupt     : in  std_logic;
            IsHardwareInterrupt     : in  std_logic;
            IsRTI                   : in  std_logic;
            UnconditionalBranch     : in  std_logic;
            ConditionalBranch       : in  std_logic;
            PredictedTaken          : in  std_logic;
            ActualTaken             : in  std_logic;
            Reset                   : in  std_logic;
            BranchSelect            : out std_logic;
            BranchTargetSelect      : out std_logic_vector(1 downto 0);
            Misprediction           : out std_logic;
            UpdatePredictor         : out std_logic;
            FlushIF                 : out std_logic;
            FlushDE                 : out std_logic
        );
    end component;
    
    -- Signals
    signal IsSoftwareInterrupt     : std_logic := '0';
    signal IsHardwareInterrupt     : std_logic := '0';
    signal IsRTI                   : std_logic := '0';
    signal UnconditionalBranch     : std_logic := '0';
    signal ConditionalBranch       : std_logic := '0';
    signal PredictedTaken          : std_logic := '0';
    signal ActualTaken             : std_logic := '0';
    signal Reset                   : std_logic := '0';
    signal BranchSelect            : std_logic;
    signal BranchTargetSelect      : std_logic_vector(1 downto 0);
    signal Misprediction           : std_logic;
    signal UpdatePredictor         : std_logic;
    signal FlushIF                 : std_logic;
    signal FlushDE                 : std_logic;
    
begin
    
    -- Instantiate UUT
    uut: branch_decision_unit
        port map (
            IsSoftwareInterrupt => IsSoftwareInterrupt,
            IsHardwareInterrupt => IsHardwareInterrupt,
            IsRTI => IsRTI,
            UnconditionalBranch => UnconditionalBranch,
            ConditionalBranch => ConditionalBranch,
            PredictedTaken => PredictedTaken,
            ActualTaken => ActualTaken,
            Reset => Reset,
            BranchSelect => BranchSelect,
            BranchTargetSelect => BranchTargetSelect,
            Misprediction => Misprediction,
            UpdatePredictor => UpdatePredictor,
            FlushIF => FlushIF,
            FlushDE => FlushDE
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
        
        -- Test 2: Reset (neutral - PC handles reset internally)
        report "Test 2: Reset signal";
        Reset <= '1';
        wait for 10 ns;
        assert BranchSelect = '0' and FlushDE = '0' and FlushIF = '0'
            report "Test 2 FAILED: Reset should be neutral" severity error;
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
        
        -- Test 5: RTI
        report "Test 5: Return from interrupt (RTI)";
        IsRTI <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "10" and
               FlushDE = '1' and FlushIF = '1'
            report "Test 5 FAILED" severity error;
        report "Test 5 PASSED";
        IsRTI <= '0';
        wait for 10 ns;
        
        -- Test 6: Unconditional branch
        report "Test 6: Unconditional branch (JMP/CALL)";
        UnconditionalBranch <= '1';
        wait for 10 ns;
        assert BranchSelect = '1' and BranchTargetSelect = "00" and
               FlushIF = '1' and FlushDE = '0'
            report "Test 6 FAILED" severity error;
        report "Test 6 PASSED";
        UnconditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 7: Conditional branch - predicted taken, actually taken (correct)
        report "Test 7: Conditional branch - correct prediction (taken)";
        ConditionalBranch <= '1';
        PredictedTaken <= '1';
        ActualTaken <= '1';
        wait for 10 ns;
        assert Misprediction = '0' and FlushDE = '0' and FlushIF = '0'
            report "Test 7 FAILED: Should not be misprediction" severity error;
        report "Test 7 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 8: Conditional branch - predicted not taken, actually not taken (correct)
        report "Test 8: Conditional branch - correct prediction (not taken)";
        ConditionalBranch <= '1';
        PredictedTaken <= '0';
        ActualTaken <= '0';
        wait for 10 ns;
        assert Misprediction = '0' and BranchSelect = '0'
            report "Test 8 FAILED" severity error;
        report "Test 8 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 9: Misprediction - predicted taken, actually not taken
        report "Test 9: Misprediction - predicted taken, actually not taken";
        ConditionalBranch <= '1';
        PredictedTaken <= '1';
        ActualTaken <= '0';
        wait for 10 ns;
        assert Misprediction = '1' and BranchSelect = '0' and FlushDE = '1' and FlushIF = '1'
            report "Test 9 FAILED: Should be misprediction and flush" severity error;
        report "Test 9 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 10: Misprediction - predicted not taken, actually taken
        report "Test 10: Misprediction - predicted not taken, actually taken";
        ConditionalBranch <= '1';
        PredictedTaken <= '0';
        ActualTaken <= '1';
        wait for 10 ns;
        assert Misprediction = '1' and BranchSelect = '1' and BranchTargetSelect = "01" and
               FlushDE = '1' and FlushIF = '1'
            report "Test 10 FAILED: Should branch and flush" severity error;
        report "Test 10 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        -- Test 11: UpdatePredictor signal
        report "Test 11: UpdatePredictor should be active during conditional branch";
        ConditionalBranch <= '1';
        wait for 10 ns;
        assert UpdatePredictor = '1'
            report "Test 11 FAILED: UpdatePredictor should be 1" severity error;
        report "Test 11 PASSED";
        ConditionalBranch <= '0';
        wait for 10 ns;
        
        report "====================================";
        report "All Branch Decision Unit Tests Completed!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;

