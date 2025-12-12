LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.pipeline_data_pkg.ALL;
USE work.control_signals_pkg.ALL;

ENTITY fetch_decode_top IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;

    -- Simple I/O for decode stage
    in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END ENTITY fetch_decode_top;

ARCHITECTURE Structural OF fetch_decode_top IS

  -- ===== Fetch stage =====
  SIGNAL fetch_out : fetch_outputs_t;
  SIGNAL fetch_stall : STD_LOGIC;
  SIGNAL branch_targets : branch_targets_t;

  -- ===== IF/ID register =====
  SIGNAL ifid_in : pipeline_fetch_decode_t;
  SIGNAL ifid_out : pipeline_fetch_decode_t;

  -- ===== Decode stage =====
  SIGNAL decode_out : decode_outputs_t;
  SIGNAL decode_ctrl_out : decode_ctrl_outputs_t;
  SIGNAL decode_flags : decode_flags_t;

  -- Control coming from opcode decoder (into decode stage)
  SIGNAL decoder_ctrl : decode_ctrl_outputs_t;

  -- No writeback for now
  SIGNAL wb_stub : writeback_outputs_t;

  -- ===== Shared memory block (instruction fetch) =====
  SIGNAL mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_addr : STD_LOGIC_VECTOR(17 DOWNTO 0);

BEGIN

  -- No branches for this integration step
  branch_targets.target_decode <= (OTHERS => '0');
  branch_targets.target_execute <= (OTHERS => '0');
  branch_targets.target_memory <= (OTHERS => '0');

  -- No stalls / interrupts / overrides for now
  fetch_stall <= '0';
  ifid_in.take_interrupt <= '0';
  ifid_in.override_operation <= '0';
  ifid_in.override_op <= (OTHERS => '0');
  ifid_in.pc <= fetch_out.pc;
  ifid_in.pushed_pc <= fetch_out.pushed_pc;
  ifid_in.instruction <= fetch_out.instruction;

  -- No writeback activity in this minimal top
  wb_stub.data <= (OTHERS => '0');
  wb_stub.rdst <= (OTHERS => '0');
  wb_stub.reg_we <= '0';
  wb_stub.port_enable <= '0';

  -- Keep memory address known during reset to avoid X/Z address warnings
  mem_addr <= fetch_out.pc(17 DOWNTO 0) WHEN rst = '0' ELSE
    (OTHERS => '0');

  -- ===== Memory for instruction fetch =====
  mem_inst : ENTITY work.memory
    PORT MAP(
      clk => clk,
      rst => rst,
      Address => mem_addr,
      WriteData => (OTHERS => '0'),
      ReadData => mem_data,
      MemRead => '1',
      MemWrite => '0'
    );

  -- ===== Fetch stage =====
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

  -- ===== IF/ID register =====
  ifid_inst : ENTITY work.if_id_register
    PORT MAP(
      clk => clk,
      rst => rst,
      enable => '1',
      flush => '0',
      flush_instruction => '0',
      data_in => ifid_in,
      data_out => ifid_out
    );

  -- ===== Decode stage =====
  decode_inst : ENTITY work.decode_stage
    PORT MAP(
      clk => clk,
      rst => rst,
      pc_in => ifid_out.pc,
      pushed_pc_in => ifid_out.pushed_pc,
      instruction_in => ifid_out.instruction,
      take_interrupt_in => ifid_out.take_interrupt,
      ctrl_in => decoder_ctrl,
      stall_control => '0',
      in_port => in_port,
      immediate_from_fetch => mem_data,
      is_swap_ex => '0',
      wb_in => wb_stub,
      decode_out => decode_out,
      ctrl_out => decode_ctrl_out,
      flags_out => decode_flags
    );

  -- ===== Opcode decoder (control unit) =====
  opcode_decoder_inst : ENTITY work.opcode_decoder
    PORT MAP(
      opcode => decode_out.opcode,
      override_operation => ifid_out.override_operation,
      override_type => ifid_out.override_op,
      isSwap_from_execute => '0',
      take_interrupt => ifid_out.take_interrupt,
      is_hardware_int_mem => '0',
      decode_ctrl => decoder_ctrl.decode_ctrl,
      execute_ctrl => decoder_ctrl.execute_ctrl,
      memory_ctrl => decoder_ctrl.memory_ctrl,
      writeback_ctrl => decoder_ctrl.writeback_ctrl,
      is_interrupt_out => OPEN,
      is_call_out => OPEN,
      is_return_out => OPEN,
      is_reti_out => OPEN,
      is_jmp_out => OPEN,
      is_jmp_conditional_out => OPEN,
      is_swap_out => OPEN
    );

END ARCHITECTURE Structural;