LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.textio.ALL;
USE IEEE.std_logic_textio.ALL;

ARCHITECTURE simulation_memory OF memory IS
    CONSTANT DUMP_START_ADDR : INTEGER := 2**18-256; -- adjust as needed
    CONSTANT DUMP_END_ADDR   : INTEGER := 2**18 - 1; -- adjust as needed

    SIGNAL clk_count : INTEGER := 0;

    CONSTANT MEM_FILENAME : STRING := "memory_data.mem";
    CONSTANT DEPTH : INTEGER := 2 ** 18; -- 262,144 words

    TYPE mem_array_t IS ARRAY(0 TO DEPTH - 1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem : mem_array_t := (OTHERS => (OTHERS => '0'));

    -- Function to load memory from file
    IMPURE FUNCTION load_mem_from_file(filename : STRING) RETURN mem_array_t IS
        FILE mem_file : text;
        VARIABLE l : line;
        VARIABLE tmp : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE i : INTEGER := 0;
        VARIABLE result : mem_array_t := (OTHERS => (OTHERS => '0'));
        VARIABLE status : file_open_status;
    BEGIN
        file_open(status, mem_file, filename, read_mode);
        IF status = open_ok THEN
            WHILE NOT endfile(mem_file) AND i < DEPTH LOOP
                readline(mem_file, l);
                hread(l, tmp);
                result(i) := tmp;
                i := i + 1;
            END LOOP;
            file_close(mem_file);
        END IF;
        RETURN result;
    END FUNCTION;

    FUNCTION min_int(a, b : INTEGER) RETURN INTEGER IS
    BEGIN
        IF a < b THEN
            RETURN a;
        ELSE
            RETURN b;
        END IF;
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

    
dump_mem_each_clk : PROCESS(clk)
    FILE dump_file : text;
    VARIABLE l      : line;
    VARIABLE fname  : line;
    VARIABLE status : file_open_status;
BEGIN
    IF rising_edge(clk) AND rst = '0' THEN

        -- Clear filename buffer
        fname := null;

        -- Build filename
        write(fname, string'("memory_temp/mem_data_clk_"));
        write(fname, clk_count);
        write(fname, string'(".mem"));

        -- Ensure the file will be created/truncated
        file_open(status, dump_file, fname.all, write_mode);

        IF status /= open_ok THEN
            -- Report warning, file could not open (directory may not exist)
            REPORT "Failed to open dump file: " & fname.all SEVERITY warning;
        ELSE
            -- Dump memory range safely
            IF DUMP_START_ADDR <= DUMP_END_ADDR THEN
                FOR i IN DUMP_START_ADDR TO min_int(DUMP_END_ADDR, DEPTH - 1) LOOP
                    l := null;
                    hwrite(l, mem(i));
                    writeline(dump_file, l);
                END LOOP;
            END IF;

            file_close(dump_file);
        END IF;

        -- Increment clock counter
        clk_count <= clk_count + 1;
    END IF;
END PROCESS;




END ARCHITECTURE simulation_memory;