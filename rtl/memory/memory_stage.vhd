library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.control_signals_pkg.ALL;

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
        
        -- Control signals
        mem_ctrl        : in memory_control_t;
        
        -- PipeLine register
        -- Input data
        PrimaryData     : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        SecondaryData   : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        RdstIN          : in std_logic_vector(RDST_WIDTH - 1 downto 0);

        -- Output data
        MemoryData      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        ALUData         : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        RdstOut         : out std_logic_vector(RDST_WIDTH - 1 downto 0);
        

        -- Memory interface porst
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
            enb       => mem_ctrl.SP_Enable,
            Increment => mem_ctrl.SP_Function,
            Decrement => not mem_ctrl.SP_Function,
            Data      => sp_data
        );
    
    -- PassInterrupt and SPtoMem mux combined in one block
    process(mem_ctrl.PassInterrupt, mem_ctrl.SPtoMem, PrimaryData, sp_data)
        variable interrupt_addr : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    begin

        if mem_ctrl.SPtoMem = '1' then
            MemAddress <= sp_data(ADDR_WIDTH - 1 downto 0);
        else
            case mem_ctrl.PassInterrupt is
                when "00" =>
                    MemAddress <= (others => '0');
                when "01" =>
                    MemAddress <= std_logic_vector(to_unsigned(1, ADDR_WIDTH));
                when "10" =>
                    MemAddress <= std_logic_vector(unsigned(PrimaryData(ADDR_WIDTH - 1 downto 0)) + 2);
                when "11" =>
                    MemAddress <= PrimaryData(ADDR_WIDTH - 1 downto 0);
                when others =>
                    MemAddress <= (others => '0');
            end case;
        end if;
    end process;

    -- Forward control signals
    MemRead <= mem_ctrl.MemRead;
    MemWrite <= mem_ctrl.MemWrite;
    
    -- Data to write comes from SecondaryData
    MemWriteData <= SecondaryData;

    MemoryData <= MemReadData;
    ALUData <= PrimaryData;
    RdstOut <= RdstIN;

end architecture rtl;
