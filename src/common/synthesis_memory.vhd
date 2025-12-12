LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Synthesizable memory architecture for Quartus
ARCHITECTURE synthesis_memory OF memory IS
  CONSTANT DEPTH : INTEGER := 2 ** 18; -- 262,144 words (1MB)

  TYPE mem_array_t IS ARRAY(0 TO DEPTH - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem : mem_array_t := (OTHERS => (OTHERS => '0'));

  ATTRIBUTE ram_init_file : STRING;
  ATTRIBUTE ram_init_file OF mem : SIGNAL IS "memory_data.mif";

  ATTRIBUTE ramstyle : STRING;
  ATTRIBUTE ramstyle OF mem : SIGNAL IS "M10K";

BEGIN

  -- Memory read/write process
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF MemWrite = '1' THEN
        mem(to_integer(unsigned(Address))) <= WriteData;
      END IF;

      -- Registered read output (required for inferred RAM)
      ReadData <= mem(to_integer(unsigned(Address)));
    END IF;
  END PROCESS;

END ARCHITECTURE synthesis_memory;