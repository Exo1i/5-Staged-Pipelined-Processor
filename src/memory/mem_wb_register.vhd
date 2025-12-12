LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY mem_wb_register IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC; -- For stall handling
        flush : IN STD_LOGIC; -- For control hazards
        
        -- Grouped data inputs from Memory Stage
        data_in : IN pipeline_memory_writeback_t;
        
        -- Grouped control inputs from Memory Stage
        ctrl_in : IN pipeline_memory_writeback_ctrl_t;
        
        -- Grouped data outputs to Writeback Stage
        data_out : OUT pipeline_memory_writeback_t;
        
        -- Grouped control outputs to Writeback Stage
        ctrl_out : OUT pipeline_memory_writeback_ctrl_t
    );
END ENTITY mem_wb_register;

ARCHITECTURE rtl OF mem_wb_register IS
    
    -- Grouped registers
    SIGNAL data_reg : pipeline_memory_writeback_t;
    SIGNAL ctrl_reg : pipeline_memory_writeback_ctrl_t;

BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Reset all registers
            data_reg <= PIPELINE_MEMORY_WRITEBACK_RESET;
            ctrl_reg <= PIPELINE_MEMORY_WRITEBACK_CTRL_NOP;

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                -- Insert NOP (bubble)
                data_reg <= PIPELINE_MEMORY_WRITEBACK_RESET;
                ctrl_reg <= PIPELINE_MEMORY_WRITEBACK_CTRL_NOP;

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
