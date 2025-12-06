library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
    Port (
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        
        -- Read ports (asynchronous)
        Ra        : in  STD_LOGIC_VECTOR(2 downto 0);
        Rb        : in  STD_LOGIC_VECTOR(2 downto 0);
        ReadDataA : out STD_LOGIC_VECTOR(31 downto 0);
        ReadDataB : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Write port (synchronous)
        Rdst      : in  STD_LOGIC_VECTOR(2 downto 0);
        WriteData : in  STD_LOGIC_VECTOR(31 downto 0);
        RegWrite  : in  STD_LOGIC;
        
        -- Optional: Second write port for SWAP instruction
        Rdst2      : in  STD_LOGIC_VECTOR(2 downto 0);
        WriteData2 : in  STD_LOGIC_VECTOR(31 downto 0);
        RegWrite2  : in  STD_LOGIC
    );
end register_file;

architecture Behavioral of register_file is
    -- Register array: R0-R7
    type reg_array_t is array (0 to 7) of STD_LOGIC_VECTOR(31 downto 0);
    signal registers : reg_array_t := (others => (others => '0'));
    
begin
    -- Synchronous write process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all registers to 0
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            -- Write port 1
            if RegWrite = '1' then
                registers(to_integer(unsigned(Rdst))) <= WriteData;
            end if;
            
            -- Write port 2 (for SWAP instruction)
            -- Only write if different register to avoid conflict
            if RegWrite2 = '1' and Rdst2 /= Rdst then
                registers(to_integer(unsigned(Rdst2))) <= WriteData2;
            end if;
        end if;
    end process;
    
    -- Asynchronous read (combinational)
    ReadDataA <= registers(to_integer(unsigned(Ra)));
    ReadDataB <= registers(to_integer(unsigned(Rb)));
    
end Behavioral;