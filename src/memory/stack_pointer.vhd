LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY stack_pointer IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enb : IN STD_LOGIC;

        Increment : IN STD_LOGIC;
        Decrement : IN STD_LOGIC;

        Data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END stack_pointer;

ARCHITECTURE rtl OF stack_pointer IS
    CONSTANT STACK_TOP : INTEGER := (2 ** 18) - 1;

    SIGNAL sp : INTEGER RANGE 0 TO STACK_TOP := STACK_TOP;

    SIGNAL decremented_sp : INTEGER RANGE 0 TO STACK_TOP;
    SIGNAL sp_out : INTEGER RANGE 0 TO STACK_TOP;
BEGIN

    decremented_sp <= sp - 1;

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            sp <= STACK_TOP;

        ELSIF rising_edge(clk) AND enb = '1' THEN
            IF (Increment = '1') THEN
                sp <= sp + 1;
            ELSIF Decrement = '1' THEN
                sp <= decremented_sp;
            END IF;
        END IF;
    END PROCESS;
    
    sp_out <= sp when Increment = '1' ELSE decremented_sp;
    Data <= STD_LOGIC_VECTOR(to_unsigned( sp_out, Data'length));
END rtl; -- rtl