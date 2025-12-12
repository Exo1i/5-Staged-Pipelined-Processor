LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;
USE work.pkg_opcodes.ALL;

ENTITY MemoryStage IS
    PORT (
        -- Clock and reset
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Pipeline inputs (EX/MEM bundles)
        ex_mem_ctrl_in : IN pipeline_execute_memory_ctrl_t;
        ex_mem_data_in : IN pipeline_execute_memory_t;

        -- Pipeline outputs (MEM/WB bundle)
        mem_wb_data_out : OUT pipeline_memory_writeback_t;
        mem_wb_ctrl_out : OUT pipeline_memory_writeback_ctrl_t;

        -- Memory interface ports
        --  input
        MemReadData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- outputs
        MemRead : OUT STD_LOGIC;
        MemWrite : OUT STD_LOGIC;
        MemAddress : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
        MemWriteData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END MemoryStage;

ARCHITECTURE rtl OF MemoryStage IS
    SIGNAL sp_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Stack Pointer Unit Instantiation
    sp_unit : ENTITY work.stack_pointer
        PORT MAP(
            clk => clk,
            rst => rst,
            enb => ex_mem_ctrl_in.memory_ctrl.SP_Enable,
            Increment => ex_mem_ctrl_in.memory_ctrl.SP_Function,
            Decrement => NOT ex_mem_ctrl_in.memory_ctrl.SP_Function,
            Data => sp_data
        );

    -- PassInterrupt and SPtoMem mux combined in one block
    PROCESS (ex_mem_ctrl_in.memory_ctrl.PassInterrupt, ex_mem_ctrl_in.memory_ctrl.SPtoMem, ex_mem_data_in.primary_data, sp_data)
    BEGIN
        IF ex_mem_ctrl_in.memory_ctrl.SPtoMem = '1' THEN
            MemAddress <= sp_data(17 DOWNTO 0);
        ELSE
            CASE ex_mem_ctrl_in.memory_ctrl.PassInterrupt IS
                WHEN PASS_INT_NORMAL =>
                    MemAddress <= ex_mem_data_in.alu_result(17 DOWNTO 0);
                WHEN PASS_INT_RESET =>
                    MemAddress <= (OTHERS => '0');
                WHEN PASS_INT_SOFTWARE =>
                    MemAddress <= STD_LOGIC_VECTOR(unsigned(ex_mem_data_in.primary_data(17 DOWNTO 0)) + 2);
                WHEN PASS_INT_HARDWARE =>
                    MemAddress <= STD_LOGIC_VECTOR(to_unsigned(1, 18));
                WHEN OTHERS =>
                    MemAddress <= (OTHERS => '0');
            END CASE;
        END IF;
    END PROCESS;

    -- Forward control signals
    MemRead <= ex_mem_ctrl_in.memory_ctrl.MemRead;
    MemWrite <= ex_mem_ctrl_in.memory_ctrl.MemWrite;

    -- Data to write comes from SecondaryData
    MemWriteData <= ex_mem_data_in.secondary_data;

    -- Populate MEM/WB bundles
    mem_wb_ctrl_out.writeback_ctrl <= ex_mem_ctrl_in.writeback_ctrl;
    mem_wb_data_out.memory_data <= MemReadData;
    mem_wb_data_out.alu_data <= ex_mem_data_in.primary_data;
    mem_wb_data_out.rdst <= ex_mem_data_in.rdst1;

END ARCHITECTURE rtl;