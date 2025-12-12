LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.textio.ALL;
USE IEEE.std_logic_textio.ALL;

ARCHITECTURE simulation_memory OF memory IS
    CONSTANT MEM_FILENAME : STRING := "memory_data.mem";
    CONSTANT DEPTH : INTEGER := 2 ** 18; -- 262,144 words

    TYPE mem_array_t IS ARRAY(0 TO DEPTH - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem : mem_array_t := (OTHERS => (OTHERS => '0'));

    -- Procedure to load memory from file
    IMPURE FUNCTION load_mem_from_file(filename : STRING) RETURN mem_array_t IS
        FILE f : text;
        VARIABLE l : line;
        VARIABLE tmp : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE i : INTEGER := 0;
        VARIABLE result : mem_array_t := (OTHERS => (OTHERS => '0'));
    BEGIN
        file_open(f, filename, read_mode);
        WHILE NOT endfile(f) AND i < DEPTH LOOP
            readline(f, l);
            hread(l, tmp);
            result(i) := tmp;
            i := i + 1;
        END LOOP;
        file_close(f);
        RETURN result;
    END FUNCTION;

    -- Store initial memory state
    CONSTANT initial_mem : mem_array_t := load_mem_from_file(MEM_FILENAME);

BEGIN

    -- Memory read/write process with reset
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            mem <= initial_mem;
        ELSIF rising_edge(clk) THEN
            IF MemWrite = '1' THEN
                mem(to_integer(unsigned(Address))) <= WriteData;
            END IF;
        END IF;
    END PROCESS;

    ReadData <= mem(to_integer(unsigned(Address))) WHEN (MemRead = '1' AND MemWrite = '0')
        ELSE
        (OTHERS => 'Z');

END ARCHITECTURE simulation_memory;