LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY id_ex_register IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        flush : IN STD_LOGIC;
        -- Grouped data inputs from Decode Stage
        data_in : IN pipeline_decode_excute_t;
        
        -- Grouped control inputs from Decode Stage
        ctrl_in : IN pipeline_decode_excute_ctrl_t;

        -- Grouped data outputs to Execute Stage
        data_out : OUT pipeline_decode_excute_t;
        
        -- Grouped control outputs to Execute Stage
        ctrl_out : OUT pipeline_decode_excute_ctrl_t
    );
END ENTITY id_ex_register;

ARCHITECTURE rtl OF id_ex_register IS
    
    -- Grouped registers
    SIGNAL data_reg : pipeline_decode_excute_t;
    SIGNAL ctrl_reg : pipeline_decode_excute_ctrl_t;

BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Reset all registers
            data_reg <= PIPELINE_DECODE_EXCUTE_RESET;
            ctrl_reg <= PIPELINE_DECODE_EXCUTE_CTRL_NOP;

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                -- Insert NOP (bubble)
                data_reg <= PIPELINE_DECODE_EXCUTE_RESET;
                ctrl_reg <= PIPELINE_DECODE_EXCUTE_CTRL_NOP;

            ELSIF enable = '1' THEN
                -- Update with new values
                data_reg <= data_in;
                ctrl_reg <= ctrl_in;
            END IF;
            -- If enable = '0', hold current values (stall)
        END IF;
    END PROCESS;

    -- Output assignments
    data_out <= data_reg;
    ctrl_out <= ctrl_reg;

END ARCHITECTURE rtl;
