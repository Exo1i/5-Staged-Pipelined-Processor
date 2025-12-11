library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.control_signals_pkg.ALL;
use work.pipeline_data_pkg.ALL;

entity WritebackStage is
    generic(
        DATA_WIDTH : integer := 32;
        RDST_WIDTH : integer := 3
    );
    port (
        -- Clock and reset
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Pipeline inputs (MEM/WB bundle)
        mem_wb_ctrl     : in pipeline_memory_writeback_ctrl_t;
        mem_wb_data     : in pipeline_memory_writeback_t;
        
        -- Output data
        PortEnable      : out std_logic;
        RegWE           : out std_logic;
        Data            : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        RdstOut         : out std_logic_vector(RDST_WIDTH - 1 downto 0)
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
    
    -- Forward output port write enable
    PortEnable <= mem_wb_ctrl.writeback_ctrl.OutPortWriteEn;
    
    -- Forward register write enable
    RegWE <= mem_wb_ctrl.writeback_ctrl.RegWrite;
    
    -- Assign selected data to output
    Data <= selected_data;
    
    -- Forward Rdst
    RdstOut <= mem_wb_data.rdst;

end architecture rtl;
