LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY stack_pointer IS
    GENERIC (
        DATA_WIDTH : INTEGER := 32;
        ADDR_WIDTH : INTEGER := 18
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enb : IN STD_LOGIC;

        Increment : IN STD_LOGIC;
        Decrement : IN STD_LOGIC;

        Data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );
END stack_pointer;

ARCHITECTURE rtl OF stack_pointer IS
    CONSTANT STACK_TOP : INTEGER := (2 ** ADDR_WIDTH) - 1;

    SIGNAL sp : INTEGER RANGE 0 TO STACK_TOP := STACK_TOP;
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            sp <= STACK_TOP;

        ELSIF rising_edge(clk) AND enb = '1' THEN
            IF (Increment = '1') THEN
                sp <= sp + 1;
            ELSIF Decrement = '1' THEN
                sp <= sp - 1;
            END IF;
        END IF;
    END PROCESS;

    Data <= STD_LOGIC_VECTOR(to_unsigned(sp, Data'length));
END rtl; -- rtl