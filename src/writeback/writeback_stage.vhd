LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY writeback_stage IS
    PORT (
        -- Pipeline inputs (MEM/WB bundles)
        mem_wb_ctrl : IN pipeline_memory_writeback_ctrl_t;
        mem_wb_data : IN pipeline_memory_writeback_t;

        -- Output data (as record)
        wb_out : OUT writeback_outputs_t
    );
END writeback_stage;

ARCHITECTURE rtl OF writeback_stage IS
    SIGNAL selected_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- MemToALU mux selects between:
    -- 0: ALU result (ALUData)
    -- 1: Memory data (MemoryData)
    PROCESS (mem_wb_ctrl.writeback_ctrl.MemToALU, mem_wb_data.memory_data, mem_wb_data.alu_data)
    BEGIN
        IF mem_wb_ctrl.writeback_ctrl.MemToALU = '1' THEN
            selected_data <= mem_wb_data.memory_data;
        ELSE
            selected_data <= mem_wb_data.alu_data;
        END IF;
    END PROCESS;

    -- Populate output record
    wb_out.port_enable <= mem_wb_ctrl.writeback_ctrl.OutPortWriteEn;
    wb_out.reg_we <= mem_wb_ctrl.writeback_ctrl.RegWrite;
    wb_out.data <= selected_data;
    wb_out.rdst <= mem_wb_data.rdst;

END ARCHITECTURE rtl;