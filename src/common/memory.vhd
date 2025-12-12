LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY memory IS
    GENERIC (
        DATA_WIDTH : INTEGER := 32;
        ADDR_WIDTH : INTEGER := 18
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        Address : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        WriteData : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
        ReadData : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
        MemRead : IN STD_LOGIC;
        MemWrite : IN STD_LOGIC
    );
END ENTITY;