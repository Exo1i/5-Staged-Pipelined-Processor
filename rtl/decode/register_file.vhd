LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY register_file IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    -- Read ports (asynchronous)
    Ra : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    Rb : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    ReadDataA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    ReadDataB : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Write port (synchronous)
    Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    WriteEnable : IN STD_LOGIC
  );
END register_file;

ARCHITECTURE Behavioral OF register_file IS
  -- Register array: R0-R7
  TYPE reg_array_t IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL registers : reg_array_t := (OTHERS => (OTHERS => '0'));

BEGIN
  -- Synchronous write process
  PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      -- Reset all registers to 0
      registers <= (OTHERS => (OTHERS => '0'));
    ELSIF rising_edge(clk) THEN
      -- Single write port
      IF WriteEnable = '1' THEN
        registers(to_integer(unsigned(Rdst))) <= WriteData;
      END IF;
    END IF;
  END PROCESS;

  -- Asynchronous read (combinational)
  ReadDataA <= registers(to_integer(unsigned(Ra)));
  ReadDataB <= registers(to_integer(unsigned(Rb)));

END Behavioral;