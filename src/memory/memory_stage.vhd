library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.control_signals_pkg.ALL;
use work.pipeline_data_pkg.ALL;

entity MemoryStage is
    generic(
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 18;
        RDST_WIDTH : integer := 3
    );
    port (
        -- Clock and reset
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Pipeline inputs (EX/MEM bundles)
        ex_mem_ctrl_in  : in pipeline_execute_memory_ctrl_t;
        ex_mem_data_in  : in pipeline_execute_memory_t;

        -- Pipeline outputs (MEM/WB bundle)
        mem_wb_data_out  : out pipeline_memory_writeback_t;
        mem_wb_ctrl_out  : out pipeline_memory_writeback_ctrl_t;

        -- Memory interface ports
        --  input
        MemReadData      : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        -- outputs
        MemRead         : out std_logic;
        MemWrite        : out std_logic;
        MemAddress      : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        MemWriteData    : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end MemoryStage;

architecture rtl of MemoryStage is
    signal sp_data        : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
begin
    
    -- Stack Pointer Unit Instantiation
    sp_unit : entity work.StackPointer
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            enb       => ex_mem_ctrl_in.memory_ctrl.SP_Enable,
            Increment => ex_mem_ctrl_in.memory_ctrl.SP_Function,
            Decrement => not ex_mem_ctrl_in.memory_ctrl.SP_Function,
            Data      => sp_data
        );
    
    -- PassInterrupt and SPtoMem mux combined in one block
    process(ex_mem_ctrl_in.memory_ctrl.PassInterrupt, ex_mem_ctrl_in.memory_ctrl.SPtoMem, ex_mem_data_in.primary_data, sp_data)
        variable interrupt_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    begin

        if ex_mem_ctrl_in.memory_ctrl.SPtoMem = '1' then
            MemAddress <= sp_data(ADDR_WIDTH - 1 downto 0);
        else
            case ex_mem_ctrl_in.memory_ctrl.PassInterrupt is
                when "00" =>
                    MemAddress <= (others => '0');
                when "01" =>
                    MemAddress <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
                when "10" =>
                    MemAddress <= std_logic_vector(unsigned(ex_mem_data_in.primary_data(ADDR_WIDTH - 1 downto 0)) + 2);
                when "11" =>
                    MemAddress <= ex_mem_data_in.primary_data(ADDR_WIDTH - 1 downto 0);
                when others =>
                    MemAddress <= (others => '0');
            end case;
        end if;
    end process;

    -- Forward control signals
    MemRead <= ex_mem_ctrl_in.memory_ctrl.MemRead;
    MemWrite <= ex_mem_ctrl_in.memory_ctrl.MemWrite;
    
    -- Data to write comes from SecondaryData
    MemWriteData <= ex_mem_data_in.secondary_data;

    -- Populate MEM/WB bundles
    mem_wb_ctrl_out.writeback_ctrl <= ex_mem_ctrl_in.writeback_ctrl;
    mem_wb_data_out.memory_data    <= MemReadData;
    mem_wb_data_out.alu_data       <= ex_mem_data_in.primary_data;
    mem_wb_data_out.rdst           <= ex_mem_data_in.rdst1;

end architecture rtl;
