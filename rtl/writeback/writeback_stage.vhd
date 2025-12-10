library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.control_signals_pkg.ALL;

entity WritebackStage is
    generic(
        DATA_WIDTH : integer := 32;
        RDST_WIDTH : integer := 3
    );
    port (
        -- Clock and reset
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Control signals
        wb_ctrl         : in writeback_control_t;
        
        -- Input data
        MemoryData      : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        ALUData         : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        Rdst            : in std_logic_vector(RDST_WIDTH - 1 downto 0);
        
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
    process(wb_ctrl.MemToALU, MemoryData, ALUData)
    begin
        if wb_ctrl.MemToALU = '1' then
            selected_data <= MemoryData;
        else
            selected_data <= ALUData;
        end if;
    end process;
    
    -- Forward output port write enable
    PortEnable <= wb_ctrl.OutPortWriteEn;
    
    -- Forward register write enable
    RegWE <= wb_ctrl.RegWrite;
    
    -- Assign selected data to output
    Data <= selected_data;
    
    -- Forward Rdst
    RdstOut <= Rdst;

end architecture rtl;
