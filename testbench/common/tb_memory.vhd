library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_memory is
end tb_memory;

architecture tb of tb_memory is

    -- DUT signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal Address   : std_logic_vector(17 downto 0) := (others => '0');
    signal WriteData : std_logic_vector(31 downto 0) := (others => '0');
    signal ReadData  : std_logic_vector(31 downto 0);
    signal MemRead   : std_logic := '0';
    signal MemWrite  : std_logic := '0';

    constant CLK_PERIOD : time := 20 ns;

begin

    -------------------------------------------------------------------------
    -- Clock generation
    -------------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;


    -------------------------------------------------------------------------
    -- Instantiate DUT
    -------------------------------------------------------------------------
    DUT : entity work.memory
        port map (
            clk       => clk,
            rst       => rst,
            Address   => Address,
            WriteData => WriteData,
            ReadData  => ReadData,
            MemRead   => MemRead,
            MemWrite  => MemWrite
        );


    -------------------------------------------------------------------------
    -- Stimulus Process
    -------------------------------------------------------------------------
    stim_proc : process
    begin
        report "=== Simulation Start ===";

        ---------------------------------------------------------------------
        -- 1) Assert reset → forces memory reload
        ---------------------------------------------------------------------
        rst <= '1';
        wait for 30 ns;
        rst <= '0';
        wait for 20 ns;

        ---------------------------------------------------------------------
        -- 2) READ test (async read)
        ---------------------------------------------------------------------
        Address <= STD_LOGIC_VECTOR(to_unsigned(1, Address'length));     -- read memory[1]
        MemRead <= '1';
        wait for 20 ns;            -- async read → immediate

        report "ReadData = " & to_hstring(ReadData);

        MemRead <= '0';
        wait for 20 ns;

        ---------------------------------------------------------------------
        -- 3) WRITE test (sync write)
        ---------------------------------------------------------------------
        Address <= std_logic_vector(to_unsigned(16, Address'length));            
        WriteData <= x"DEADBEEF";
        MemWrite <= '1';
        wait until rising_edge(clk);   -- write occurs here
        wait for 20 ns;
        
        MemWrite <= '0';
        wait for 20 ns;

        -- Read back the written word
        MemRead <= '1';
        wait for 20 ns;
        report "After write, ReadData = " & to_hstring(ReadData);

        MemRead <= '0';
        wait for 20 ns;

        ---------------------------------------------------------------------
        -- 4) Write priority test (MemWrite + MemRead both high)
        ---------------------------------------------------------------------
        Address <= std_logic_vector(to_unsigned(2, Address'length));
        WriteData <= x"CAFEBABE";
        MemRead <= '1';
        MemWrite <= '1';
        wait until rising_edge(clk);
        wait for 20 ns;

        MemWrite <= '0';
        wait for 20 ns;

        report "Write priority test ReadData = " & to_hstring(ReadData);

        MemRead <= '0';
        wait for 20 ns;

        ---------------------------------------------------------------------
        -- 20) Re-assert reset to reload .mem file again
        ---------------------------------------------------------------------
        report "Asserting reset again...";
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        report "=== Simulation Finished ===";
        wait;
    end process;

end tb;
