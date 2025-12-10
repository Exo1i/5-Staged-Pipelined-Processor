library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_opcodes.all;

entity branch_predictor is
    Port (
        clk                     : in  std_logic;
        rst                     : in  std_logic;
        
        -- Inputs from DECODE stage
        IsJMP                   : in  std_logic;                      -- Unconditional jump
        IsCall                  : in  std_logic;                      -- CALL instruction
        IsJMPConditional        : in  std_logic;                      -- Conditional jump
        ConditionalType         : in  std_logic_vector(1 downto 0);  -- Type of condition (Z/N/C)
        PC_DE                   : in  std_logic_vector(31 downto 0); -- PC in decode stage
        
        -- Inputs from EXECUTE stage
        CCR_Flags               : in  std_logic_vector(2 downto 0);  -- CCR flags (Z, N, C)
        ActualTaken             : in  std_logic;                      -- Actual branch outcome
        UpdatePredictor         : in  std_logic;                      -- Update predictor state
        PC_EX                   : in  std_logic_vector(31 downto 0); -- PC in execute (for update)
        
        -- Outputs
        PredictedTaken          : out std_logic;                      -- Prediction result
        TreatConditionalAsUnconditional : out std_logic               -- Strong prediction flag
    );
end branch_predictor;

architecture Behavioral of branch_predictor is
    
    -- 2-bit saturating counter states
    constant STRONGLY_NOT_TAKEN : std_logic_vector(1 downto 0) := "00";
    constant WEAKLY_NOT_TAKEN   : std_logic_vector(1 downto 0) := "01";
    constant WEAKLY_TAKEN       : std_logic_vector(1 downto 0) := "10";
    constant STRONGLY_TAKEN     : std_logic_vector(1 downto 0) := "11";
    
    -- Simple prediction table (4 entries for demonstration)
    -- In a real implementation, this would be indexed by PC bits
    type prediction_table_t is array (0 to 3) of std_logic_vector(1 downto 0);
    signal prediction_table : prediction_table_t := (others => WEAKLY_NOT_TAKEN);
    
    -- Extract index from PC (use lower bits)
    signal index_de : integer range 0 to 3;
    signal index_ex : integer range 0 to 3;
    
    -- Condition evaluation
    signal condition_met : std_logic;
    signal current_prediction : std_logic_vector(1 downto 0);
    
begin
    
    -- Extract table index from PC (using lower 2 bits)
    index_de <= to_integer(unsigned(PC_DE(1 downto 0)));
    index_ex <= to_integer(unsigned(PC_EX(1 downto 0)));
    
    -- Get current prediction for decode stage PC
    current_prediction <= prediction_table(index_de);
    
    -- Evaluate condition based on CCR flags
    process(ConditionalType, CCR_Flags)
    begin
        case ConditionalType is
            when COND_ZERO =>
                -- JZ: Jump if Zero flag set
                condition_met <= CCR_Flags(2);  -- Z flag
                
            when COND_NEGATIVE =>
                -- JN: Jump if Negative flag set
                condition_met <= CCR_Flags(1);  -- N flag
                
            when COND_CARRY =>
                -- JC: Jump if Carry flag set
                condition_met <= CCR_Flags(0);  -- C flag
                
            when others =>
                -- Unconditional or invalid
                condition_met <= '1';
        end case;
    end process;
    
    -- Prediction logic (combinational)
    process(IsJMP, IsCall, IsJMPConditional, current_prediction, condition_met)
    begin
        -- Default values
        PredictedTaken <= '0';
        TreatConditionalAsUnconditional <= '0';
        
        if IsJMP = '1' or IsCall = '1' then
            -- Unconditional branches are always taken
            PredictedTaken <= '1';
            TreatConditionalAsUnconditional <= '1';
            
        elsif IsJMPConditional = '1' then
            -- Conditional branch: use 2-bit predictor
            case current_prediction is
                when STRONGLY_NOT_TAKEN =>
                    PredictedTaken <= '0';
                    TreatConditionalAsUnconditional <= '1';  -- Strong prediction
                    
                when WEAKLY_NOT_TAKEN =>
                    PredictedTaken <= '0';
                    TreatConditionalAsUnconditional <= '0';  -- Weak prediction
                    
                when WEAKLY_TAKEN =>
                    PredictedTaken <= '1';
                    TreatConditionalAsUnconditional <= '0';  -- Weak prediction
                    
                when STRONGLY_TAKEN =>
                    PredictedTaken <= '1';
                    TreatConditionalAsUnconditional <= '1';  -- Strong prediction
                    
                when others =>
                    PredictedTaken <= '0';
                    TreatConditionalAsUnconditional <= '0';
            end case;
        end if;
    end process;
    
    -- Update predictor state (sequential)
    process(clk, rst)
        variable next_state : std_logic_vector(1 downto 0);
    begin
        if rst = '1' then
            -- Reset all predictions to weakly not taken
            prediction_table <= (others => WEAKLY_NOT_TAKEN);
            
        elsif rising_edge(clk) then
            if UpdatePredictor = '1' then
                -- Update the 2-bit saturating counter
                next_state := prediction_table(index_ex);
                
                if ActualTaken = '1' then
                    -- Branch was taken: increment counter (saturate at 11)
                    case next_state is
                        when STRONGLY_NOT_TAKEN =>
                            next_state := WEAKLY_NOT_TAKEN;
                        when WEAKLY_NOT_TAKEN =>
                            next_state := WEAKLY_TAKEN;
                        when WEAKLY_TAKEN =>
                            next_state := STRONGLY_TAKEN;
                        when STRONGLY_TAKEN =>
                            next_state := STRONGLY_TAKEN;  -- Saturate
                        when others =>
                            next_state := WEAKLY_NOT_TAKEN;
                    end case;
                else
                    -- Branch was not taken: decrement counter (saturate at 00)
                    case next_state is
                        when STRONGLY_NOT_TAKEN =>
                            next_state := STRONGLY_NOT_TAKEN;  -- Saturate
                        when WEAKLY_NOT_TAKEN =>
                            next_state := STRONGLY_NOT_TAKEN;
                        when WEAKLY_TAKEN =>
                            next_state := WEAKLY_NOT_TAKEN;
                        when STRONGLY_TAKEN =>
                            next_state := WEAKLY_TAKEN;
                        when others =>
                            next_state := WEAKLY_NOT_TAKEN;
                    end case;
                end if;
                
                -- Write back updated state
                prediction_table(index_ex) <= next_state;
            end if;
        end if;
    end process;

end Behavioral;
