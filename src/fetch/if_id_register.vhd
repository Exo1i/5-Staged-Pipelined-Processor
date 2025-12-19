LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY if_id_register IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC; -- Enable/Stall control
        flush : IN STD_LOGIC; -- Flush entire IF/ID stage (inserts NOP)
        flush_instruction : IN STD_LOGIC; -- Specific flush for instruction (inserts NOP)
        is_hardware: IN STD_LOGIC; -- Indicates hardware interrupt is being processed
        is_hardware_mem: IN STD_LOGIC; -- Indicates hardware interrupt in MEMORY stage

        -- Inputs from Fetch Stage
        data_in : IN pipeline_fetch_decode_t;

        -- Outputs to Decode Stage
        data_out : OUT pipeline_fetch_decode_t
    );
END ENTITY if_id_register;

ARCHITECTURE rtl OF if_id_register IS
    -- Internal register
    SIGNAL data_reg : pipeline_fetch_decode_t;

BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Reset all registers
            data_reg <= PIPELINE_FETCH_DECODE_RESET;

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                -- Flush entire IF/ID stage (insert NOP)
                data_reg <= PIPELINE_FETCH_DECODE_RESET;
            ELSIF enable = '1' THEN
                -- Update registers with new values
                IF flush_instruction = '1' THEN
                    -- Flush only instruction (insert NOP)
                    data_reg.instruction <= (OTHERS => '0');
                    data_reg.pc <= data_in.pc;
                    data_reg.pushed_pc <= data_in.pushed_pc;
                    data_reg.take_interrupt <= data_in.take_interrupt;
                ELSE
                    data_reg <= data_in;
                END IF; 
                
            END IF;
            -- If enable = '0', hold current values (stall)
                    IF is_hardware = '1' THEN
                        data_reg.take_interrupt <= '1';
                        data_reg.pc <= data_in.pc;
                        data_reg.pushed_pc <= data_in.pushed_pc;
                    ELSIF is_hardware_mem = '1' THEN
                        data_reg.take_interrupt <= '0';
                    ELSE 
                        data_reg.take_interrupt <= data_reg.take_interrupt;
                    END IF;
        END IF;
    

    END PROCESS;

    -- Output assignment
    data_out <= data_reg;

END ARCHITECTURE rtl;