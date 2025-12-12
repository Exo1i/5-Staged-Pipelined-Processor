LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY if_id_register IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC; -- Enable/Stall control
        flush : IN STD_LOGIC; -- Flush control (for branches/interrupts) -- inserts NOP
        flush_instruction : IN STD_LOGIC; -- Specific flush for instruction (inserts NOP)

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
                -- Flush pipeline register (insert bubble/NOP)
                data_reg <= PIPELINE_FETCH_DECODE_RESET;

            ELSIF flush_instruction = '1' THEN
                -- Flush only instruction (insert NOP)
                data_reg.instruction <= (OTHERS => '0');
                data_reg.pc <= data_reg.pc;
                data_reg.pushed_pc <= data_reg.pushed_pc;
                data_reg.override_operation <= data_in.override_operation;
                data_reg.take_interrupt <= data_in.take_interrupt;
                data_reg.override_op <= data_in.override_op;

            ELSIF enable = '1' THEN
                -- Update registers with new values
                data_reg <= data_in;
            END IF;
            -- If enable = '0', hold current values (stall)
        END IF;
    END PROCESS;

    -- Output assignment
    data_out <= data_reg;

END ARCHITECTURE rtl;