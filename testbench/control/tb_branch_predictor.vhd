library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;

entity tb_branch_predictor is
end tb_branch_predictor;

architecture Behavioral of tb_branch_predictor is
    
    component branch_predictor
        Port (
            clk                     : in  std_logic;
            rst                     : in  std_logic;
            IsJMP                   : in  std_logic;
            IsCall                  : in  std_logic;
            IsJMPConditional        : in  std_logic;
            ConditionalType         : in  std_logic_vector(1 downto 0);
            PC_DE                   : in  std_logic_vector(31 downto 0);
            CCR_Flags               : in  std_logic_vector(2 downto 0);
            ActualTaken             : in  std_logic;
            UpdatePredictor         : in  std_logic;
            PC_EX                   : in  std_logic_vector(31 downto 0);
            PredictedTaken          : out std_logic;
            TreatConditionalAsUnconditional : out std_logic
        );
    end component;
    
    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- Signals
    signal IsJMP                   : std_logic := '0';
    signal IsCall                  : std_logic := '0';
    signal IsJMPConditional        : std_logic := '0';
    signal ConditionalType         : std_logic_vector(1 downto 0) := "00";
    signal PC_DE                   : std_logic_vector(31 downto 0) := (others => '0');
    signal CCR_Flags               : std_logic_vector(2 downto 0) := "000";
    signal ActualTaken             : std_logic := '0';
    signal UpdatePredictor         : std_logic := '0';
    signal PC_EX                   : std_logic_vector(31 downto 0) := (others => '0');
    signal PredictedTaken          : std_logic;
    signal TreatConditionalAsUnconditional : std_logic;
    
begin
    
    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Instantiate UUT
    uut: branch_predictor
        port map (
            clk => clk,
            rst => rst,
            IsJMP => IsJMP,
            IsCall => IsCall,
            IsJMPConditional => IsJMPConditional,
            ConditionalType => ConditionalType,
            PC_DE => PC_DE,
            CCR_Flags => CCR_Flags,
            ActualTaken => ActualTaken,
            UpdatePredictor => UpdatePredictor,
            PC_EX => PC_EX,
            PredictedTaken => PredictedTaken,
            TreatConditionalAsUnconditional => TreatConditionalAsUnconditional
        );
    
    -- Test process
    stim_proc: process
    begin
        report "====================================";
        report "Starting Branch Predictor Tests";
        report "====================================";
        
        -- Reset
        rst <= '1';
        wait for clk_period * 2;
        rst <= '0';
        wait for clk_period;
        
        -- Test 1: Unconditional JMP
        report "Test 1: Unconditional JMP - always taken";
        IsJMP <= '1';
        PC_DE <= x"00000000";
        wait for clk_period;
        assert PredictedTaken = '1' and TreatConditionalAsUnconditional = '1'
            report "Test 1 FAILED" severity error;
        report "Test 1 PASSED";
        IsJMP <= '0';
        wait for clk_period;
        
        -- Test 2: Conditional branch - initial prediction (weakly not taken)
        report "Test 2: Conditional branch - initial prediction";
        IsJMPConditional <= '1';
        ConditionalType <= COND_ZERO;
        PC_DE <= x"00000004";
        CCR_Flags <= "100";  -- Z=1
        wait for clk_period;
        assert PredictedTaken = '0' and TreatConditionalAsUnconditional = '0'
            report "Test 2 FAILED: Should predict not taken (weak)" severity error;
        report "Test 2 PASSED: Predicted not taken";
        IsJMPConditional <= '0';
        
        -- Test 3: Update predictor - branch was taken
        report "Test 3: Update predictor - branch was actually taken";
        UpdatePredictor <= '1';
        ActualTaken <= '1';
        PC_EX <= x"00000004";
        wait for clk_period;
        UpdatePredictor <= '0';
        wait for clk_period;
        
        -- Test 4: Check updated prediction (should move to weakly taken)
        report "Test 4: After update - should predict weakly taken";
        IsJMPConditional <= '1';
        PC_DE <= x"00000004";
        wait for clk_period;
        assert PredictedTaken = '1' and TreatConditionalAsUnconditional = '0'
            report "Test 4 FAILED: Should predict taken (weak)" severity error;
        report "Test 4 PASSED: Now predicts taken";
        IsJMPConditional <= '0';
        
        -- Test 5: Train to strongly taken
        report "Test 5: Train predictor to strongly taken";
        UpdatePredictor <= '1';
        ActualTaken <= '1';
        PC_EX <= x"00000004";
        wait for clk_period;
        UpdatePredictor <= '0';
        wait for clk_period;
        
        -- Test 6: Check strongly taken state
        report "Test 6: Should be strongly taken now";
        IsJMPConditional <= '1';
        PC_DE <= x"00000004";
        wait for clk_period;
        assert PredictedTaken = '1' and TreatConditionalAsUnconditional = '1'
            report "Test 6 FAILED: Should be strongly taken" severity error;
        report "Test 6 PASSED: Strongly taken prediction";
        IsJMPConditional <= '0';
        
        report "====================================";
        report "All Branch Predictor Tests Completed!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;
