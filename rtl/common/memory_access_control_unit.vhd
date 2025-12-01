library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity MemoryAccessControlUnit is
    generic(
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 18
    );
    port (
        clk   : in std_logic;
        rst : in std_logic;
        
        MemStageRead : in STD_LOGIC;
        MemStageWrite : in STD_LOGIC;
        MemStageAddress : in STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
        MemStageData : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

        FetchStageAddress : in STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);

        OutData : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of MemoryAccessControlUnit is
    signal t_memAddress : STD_LOGIC_VECTOR(ADDR_WIDTH-1 downto 0);
    signal t_memRead : STD_LOGIC;
    signal t_memWrite : STD_LOGIC;
begin

    main_memory: entity work.memory
        port map (
            clk => clk,
            rst => rst,

            Address         => t_memAddress,
            WriteData       => MemStageData,
            ReadData        => OutData,
            MemRead         => t_memRead,
            MemWrite        => t_memWrite
        );


    t_memAddress <= MemStageAddress when (MemStageWrite = '1' or MemStageRead = '1') else FetchStageAddress;
    t_memRead <= MemStageRead when (MemStageWrite = '1' or MemStageRead = '1') else '1';
    t_memWrite <= MemStageWrite when (MemStageWrite = '1' or MemStageRead = '1') else '0';

end architecture;