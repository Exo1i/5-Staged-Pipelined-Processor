library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity memory is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 18
    );
    port (
        clk              : in  std_logic;
        rst              : in  std_logic;

        Address          : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        WriteData        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        ReadData         : out std_logic_vector(DATA_WIDTH-1 downto 0);
        MemRead          : in  std_logic;
        MemWrite         : in  std_logic
    );
end entity;