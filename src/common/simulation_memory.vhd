architecture simulation_memory of memory is
    constant MEM_FILENAME : string := "memory_data.mem";
    constant DEPTH      : integer := 2 ** ADDR_WIDTH; -- 262,144 words

    type mem_array_t is array(0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : mem_array_t := ((others => ((others => '0') )));
    
begin

    process (clk, rst)
        file f : text;
        variable l : line;
        variable tmp : std_logic_vector(DATA_WIDTH-1 downto 0);
        variable i : integer := 0;
    begin
        if rst = '1' then
            file_open(f, MEM_FILENAME, read_mode);
            while not endfile(f) loop
                readline(f, l);
                hread(l, tmp);
                mem(i) <= tmp;
                i := i + 1;
            end loop;
            file_close(f);

        elsif rising_edge(clk) then
            if MemWrite = '1' then
                mem(to_integer(unsigned(Address))) <= WriteData;
            end if;
        end if;


    end process;

    ReadData <= mem(to_integer(unsigned(Address))) when (MemRead = '1' and MemWrite = '0')
                else (others => 'Z');

end architecture simulation_memory;
