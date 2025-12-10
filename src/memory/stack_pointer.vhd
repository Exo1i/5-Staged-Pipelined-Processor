library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity StackPointer is
    generic(
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 18
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        enb : in std_logic;

        Increment : in std_logic;
        Decrement : in std_logic;

        Data : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end StackPointer;

architecture rtl of StackPointer is
    constant STACK_TOP : INTEGER := (2 ** ADDR_WIDTH) - 1;
    
    signal sp : integer range 0 to STACK_TOP := STACK_TOP;
begin

    process (clk, rst)
    begin
        if rst = '1' then
            sp <= STACK_TOP;

        elsif rising_edge(clk) and enb = '1' then
            if(Increment = '1') then 
                sp <= sp + 1;
            elsif Decrement = '1' then
                sp <= sp - 1;
            end if;
        end if;
    end process;

    Data <= STD_LOGIC_VECTOR(to_unsigned(sp, Data'length));
end rtl ; -- rtl