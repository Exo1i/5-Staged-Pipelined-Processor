LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.pipeline_data_pkg.ALL;
USE work.control_signals_pkg.ALL;

ENTITY fetch_memory_top IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC
  );
END ENTITY fetch_memory_top;

ARCHITECTURE Structural OF fetch_memory_top IS

  -- ===== Fetch stage =====
  SIGNAL fetch_out : fetch_outputs_t;
  SIGNAL fetch_stall : STD_LOGIC;
  SIGNAL branch_targets : branch_targets_t;

  -- ===== Memory stage (kept for integration, but not requesting memory yet) =====
  SIGNAL ex_mem_ctrl_in : pipeline_execute_memory_ctrl_t;
  SIGNAL ex_mem_data_in : pipeline_execute_memory_t;
  SIGNAL mem_wb_data_out : pipeline_memory_writeback_t;
  SIGNAL mem_wb_ctrl_out : pipeline_memory_writeback_ctrl_t;

  SIGNAL mem_stage_read : STD_LOGIC;
  SIGNAL mem_stage_write : STD_LOGIC;
  SIGNAL mem_stage_addr : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL mem_stage_wdata : STD_LOGIC_VECTOR(31 DOWNTO 0);

  -- ===== Memory hazard unit =====
  SIGNAL pass_pc : STD_LOGIC;
  SIGNAL mem_read_out : STD_LOGIC;
  SIGNAL mem_write_out : STD_LOGIC;

  -- ===== Shared memory block =====
  SIGNAL mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

  -- No branches/targets for now
  branch_targets.target_decode <= (OTHERS => '0');
  branch_targets.target_execute <= (OTHERS => '0');
  branch_targets.target_memory <= (OTHERS => '0');

  -- Keep Memory-stage requests at 0 for now (basic flow)
  ex_mem_ctrl_in <= PIPELINE_EXECUTE_MEMORY_CTRL_NOP;
  ex_mem_data_in <= PIPELINE_EXECUTE_MEMORY_RESET;

  -- Memory hazard unit: keep MEM-stage wants read/write = 0 always
  -- This means PassPC = 1 => fetch always allowed to read instructions.
  memory_hazard_inst : ENTITY work.memory_hazard_unit
    PORT MAP(
      MemRead_MEM => '0',
      MemWrite_MEM => '0',
      PassPC => pass_pc,
      MemRead_Out => mem_read_out,
      MemWrite_Out => mem_write_out
    );

  -- Stall fetch only when memory stage has priority (future integration)
  fetch_stall <= NOT pass_pc;

  -- Fetch stage
  fetch_inst : ENTITY work.fetch_stage
    PORT MAP(
      clk => clk,
      rst => rst,
      stall => fetch_stall,
      BranchSelect => '0',
      BranchTargetSelect => "00",
      branch_targets => branch_targets,
      mem_data => mem_data,
      fetch_out => fetch_out,
      PushPCSelect => '0'
    );

  -- Memory stage (instantiated, but not active yet)
  memory_stage_inst : ENTITY work.memory_stage
    PORT MAP(
      clk => clk,
      rst => rst,
      ex_mem_ctrl_in => ex_mem_ctrl_in,
      ex_mem_data_in => ex_mem_data_in,
      mem_wb_data_out => mem_wb_data_out,
      mem_wb_ctrl_out => mem_wb_ctrl_out,
      MemReadData => mem_data,
      MemRead => mem_stage_read,
      MemWrite => mem_stage_write,
      MemAddress => mem_stage_addr,
      MemWriteData => mem_stage_wdata
    );

  -- Memory block: for now, always read using fetch PC address.
  -- Later, we will mux between fetch address and memory_stage address
  -- based on the hazard/arbitration signals.
  mem_inst : ENTITY work.memory
    PORT MAP(
      clk => clk,
      rst => rst,
      Address => fetch_out.pc(17 DOWNTO 0),
      WriteData => (OTHERS => '0'),
      ReadData => mem_data,
      MemRead => NOT rst,
      MemWrite => '0'
    );

END ARCHITECTURE Structural;