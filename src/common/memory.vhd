LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY memory IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        Address : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        ReadData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        MemRead : IN STD_LOGIC;
        MemWrite : IN STD_LOGIC
    );
END ENTITY;