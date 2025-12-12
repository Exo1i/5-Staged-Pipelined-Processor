LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY WritebackStage IS
    generic(
        DATA_WIDTH : integer := 32;
        RDST_WIDTH : integer := 3
    );
    port (
        -- Clock and reset
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Pipeline inputs (MEM/WB bundles)
        mem_wb_ctrl     : in pipeline_memory_writeback_ctrl_t;
        mem_wb_data     : in pipeline_memory_writeback_t;
        
        -- Output data (as record)
        wb_out          : out writeback_outputs_t
    );
end WritebackStage;

architecture rtl of WritebackStage is
    signal selected_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
begin
    
    -- MemToALU mux selects between:
    -- 0: ALU result (ALUData)
    -- 1: Memory data (MemoryData)
    process(mem_wb_ctrl.writeback_ctrl.MemToALU, mem_wb_data.memory_data, mem_wb_data.alu_data)
    begin
        if mem_wb_ctrl.writeback_ctrl.MemToALU = '1' then
            selected_data <= mem_wb_data.memory_data;
        else
            selected_data <= mem_wb_data.alu_data;
        end if;
    end process;
    
    -- Populate output record
    wb_out.port_enable <= mem_wb_ctrl.writeback_ctrl.OutPortWriteEn;
    wb_out.reg_we <= mem_wb_ctrl.writeback_ctrl.RegWrite;
    wb_out.data <= selected_data;
    wb_out.rdst <= mem_wb_data.rdst;

end architecture rtl;
