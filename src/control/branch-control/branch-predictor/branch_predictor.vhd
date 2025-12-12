LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pkg_opcodes.ALL;

ENTITY branch_predictor IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Inputs from DECODE stage
        IsJMP : IN STD_LOGIC; -- Unconditional jump
        IsCall : IN STD_LOGIC; -- CALL instruction
        IsJMPConditional : IN STD_LOGIC; -- Conditional jump
        ConditionalType : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- Type of condition (Z/N/C)
        PC_DE : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- PC in decode stage

        -- Inputs from EXECUTE stage
        CCR_Flags : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- CCR flags (Z, N, C)
        ActualTaken : IN STD_LOGIC; -- Actual branch outcome
        UpdatePredictor : IN STD_LOGIC; -- Update predictor state
        PC_EX : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- PC in execute (for update)

        -- Outputs
        PredictedTaken : OUT STD_LOGIC; -- Prediction result
        TreatConditionalAsUnconditional : OUT STD_LOGIC -- Strong prediction flag
    );
END branch_predictor;

ARCHITECTURE Behavioral OF branch_predictor IS

    -- Simple prediction table (4 entries for demonstration)
    -- In a real implementation, this would be indexed by PC bits
    TYPE prediction_table_t IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL prediction_table : prediction_table_t := (OTHERS => WEAKLY_NOT_TAKEN);

    -- Extract index from PC (use lower bits)
    SIGNAL index_de : INTEGER RANGE 0 TO 3;
    SIGNAL index_ex : INTEGER RANGE 0 TO 3;

    -- Condition evaluation
    SIGNAL condition_met : STD_LOGIC;
    SIGNAL current_prediction : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    -- Extract table index from PC (using lower 2 bits)
    index_de <= to_integer(unsigned(PC_DE(1 DOWNTO 0)));
    index_ex <= to_integer(unsigned(PC_EX(1 DOWNTO 0)));

    -- Get current prediction for decode stage PC
    current_prediction <= prediction_table(index_de);

    -- Evaluate condition based on CCR flags
    PROCESS (ConditionalType, CCR_Flags)
    BEGIN
        CASE ConditionalType IS
            WHEN COND_ZERO =>
                -- JZ: Jump if Zero flag set
                condition_met <= CCR_Flags(2); -- Z flag

            WHEN COND_NEGATIVE =>
                -- JN: Jump if Negative flag set
                condition_met <= CCR_Flags(1); -- N flag

            WHEN COND_CARRY =>
                -- JC: Jump if Carry flag set
                condition_met <= CCR_Flags(0); -- C flag

            WHEN OTHERS =>
                -- Unconditional or invalid
                condition_met <= '1';
        END CASE;
    END PROCESS;

    -- Prediction logic (combinational)
    PROCESS (IsJMP, IsCall, IsJMPConditional, current_prediction)
    BEGIN
        -- Default values
        PredictedTaken <= '0';
        TreatConditionalAsUnconditional <= '0';

        IF IsJMP = '1' OR IsCall = '1' THEN
            -- Unconditional branches are always taken
            PredictedTaken <= '1';
            TreatConditionalAsUnconditional <= '1';

        ELSIF IsJMPConditional = '1' THEN
            -- Conditional branch: use 2-bit predictor
            CASE current_prediction IS
                WHEN STRONGLY_NOT_TAKEN =>
                    PredictedTaken <= '0';
                    TreatConditionalAsUnconditional <= '1'; -- Strong prediction

                WHEN WEAKLY_NOT_TAKEN =>
                    PredictedTaken <= '0';
                    TreatConditionalAsUnconditional <= '0'; -- Weak prediction

                WHEN WEAKLY_TAKEN =>
                    PredictedTaken <= '1';
                    TreatConditionalAsUnconditional <= '0'; -- Weak prediction

                WHEN STRONGLY_TAKEN =>
                    PredictedTaken <= '1';
                    TreatConditionalAsUnconditional <= '1'; -- Strong prediction

                WHEN OTHERS =>
                    PredictedTaken <= '0';
                    TreatConditionalAsUnconditional <= '0';
            END CASE;
        END IF;
    END PROCESS;

    -- Update predictor state (sequential)
    PROCESS (clk, rst)
        VARIABLE next_state : STD_LOGIC_VECTOR(1 DOWNTO 0);
    BEGIN
        IF rst = '1' THEN
            -- Reset all predictions to weakly not taken
            prediction_table <= (OTHERS => WEAKLY_NOT_TAKEN);

        ELSIF rising_edge(clk) THEN
            IF UpdatePredictor = '1' THEN
                -- Update the 2-bit saturating counter
                next_state := prediction_table(index_ex);

                IF ActualTaken = '1' THEN
                    -- Branch was taken: increment counter (saturate at 11)
                    CASE next_state IS
                        WHEN STRONGLY_NOT_TAKEN =>
                            next_state := WEAKLY_NOT_TAKEN;
                        WHEN WEAKLY_NOT_TAKEN =>
                            next_state := WEAKLY_TAKEN;
                        WHEN WEAKLY_TAKEN =>
                            next_state := STRONGLY_TAKEN;
                        WHEN STRONGLY_TAKEN =>
                            next_state := STRONGLY_TAKEN; -- Saturate
                        WHEN OTHERS =>
                            next_state := WEAKLY_NOT_TAKEN;
                    END CASE;
                ELSE
                    -- Branch was not taken: decrement counter (saturate at 00)
                    CASE next_state IS
                        WHEN STRONGLY_NOT_TAKEN =>
                            next_state := STRONGLY_NOT_TAKEN; -- Saturate
                        WHEN WEAKLY_NOT_TAKEN =>
                            next_state := STRONGLY_NOT_TAKEN;
                        WHEN WEAKLY_TAKEN =>
                            next_state := WEAKLY_NOT_TAKEN;
                        WHEN STRONGLY_TAKEN =>
                            next_state := WEAKLY_TAKEN;
                        WHEN OTHERS =>
                            next_state := WEAKLY_NOT_TAKEN;
                    END CASE;
                END IF;

                -- Write back updated state
                prediction_table(index_ex) <= next_state;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;