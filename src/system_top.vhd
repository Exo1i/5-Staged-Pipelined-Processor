LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Top-level system entity that integrates the processor and memory
ENTITY system_top IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;

    -- External Interrupt Signal
    intr : IN STD_LOGIC;

    -- Input Port
    in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Output Port
    out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    out_port_enable : OUT STD_LOGIC
  );
END ENTITY system_top;

ARCHITECTURE Structural OF system_top IS

  -- Component declarations
  COMPONENT processor_top IS
    PORT (
      clk : IN STD_LOGIC;
      rst : IN STD_LOGIC;
      intr : IN STD_LOGIC;
      mem_data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      mem_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      mem_data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      mem_read : OUT STD_LOGIC;
      mem_write : OUT STD_LOGIC;
      in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      out_port_enable : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT memory IS
    PORT (
      clk : IN STD_LOGIC;
      rst : IN STD_LOGIC;
      Address : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
      WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      ReadData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      MemRead : IN STD_LOGIC;
      MemWrite : IN STD_LOGIC
    );
  END COMPONENT;

  -- Internal signals to connect processor and memory
  SIGNAL mem_data_from_mem : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_addr_from_proc : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_data_to_mem : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_read_sig : STD_LOGIC;
  SIGNAL mem_write_sig : STD_LOGIC;

BEGIN

  -- Processor instantiation
  processor_inst : processor_top
  PORT MAP(
    clk => clk,
    rst => rst,
    intr => intr,
    mem_data_in => mem_data_from_mem,
    mem_addr => mem_addr_from_proc,
    mem_data_out => mem_data_to_mem,
    mem_read => mem_read_sig,
    mem_write => mem_write_sig,
    in_port => in_port,
    out_port => out_port,
    out_port_enable => out_port_enable
  );

  -- Memory instantiation (using lower 18 bits of 32-bit address)
  memory_inst : memory
  PORT MAP(
    clk => clk,
    rst => rst,
    Address => mem_addr_from_proc(17 DOWNTO 0),
    WriteData => mem_data_to_mem,
    ReadData => mem_data_from_mem,
    MemRead => mem_read_sig,
    MemWrite => mem_write_sig
  );

END ARCHITECTURE Structural;