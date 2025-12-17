LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.pipeline_data_pkg.ALL;
USE work.control_signals_pkg.ALL;

ENTITY processor_top IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    out_port_en : OUT STD_LOGIC
  );
END ENTITY processor_top;

ARCHITECTURE Structural OF processor_top IS

  -- ===== Fetch stage =====
  SIGNAL fetch_out : fetch_outputs_t;
  SIGNAL branch_targets : branch_targets_t;

  -- ===== IF/ID =====
  SIGNAL ifid_in : pipeline_fetch_decode_t;
  SIGNAL ifid_out : pipeline_fetch_decode_t;

  -- ===== Decode + opcode decoder =====
  SIGNAL decode_out : decode_outputs_t;
  SIGNAL decode_ctrl_out : decode_ctrl_outputs_t;
  SIGNAL decode_flags : decode_flags_t;
  SIGNAL decoder_ctrl : decode_ctrl_outputs_t;

  -- ===== ID/EX =====
  SIGNAL idex_data_in : pipeline_decode_excute_t;
  SIGNAL idex_ctrl_in : pipeline_decode_excute_ctrl_t;
  SIGNAL idex_data_out : pipeline_decode_excute_t;
  SIGNAL idex_ctrl_out : pipeline_decode_excute_ctrl_t;

  -- ===== Execute =====
  SIGNAL execute_out : execute_outputs_t;
  SIGNAL execute_ctrl_out : execute_ctrl_outputs_t;

  -- Forwarding disabled for now
  SIGNAL forwarding : forwarding_ctrl_t;

  -- ===== EX/MEM =====
  SIGNAL exmem_data_in : pipeline_execute_memory_t;
  SIGNAL exmem_ctrl_in : pipeline_execute_memory_ctrl_t;
  SIGNAL exmem_data_out : pipeline_execute_memory_t;
  SIGNAL exmem_ctrl_out : pipeline_execute_memory_ctrl_t;

  -- ===== Memory stage =====
  SIGNAL mem_wb_data_comb : pipeline_memory_writeback_t;
  SIGNAL mem_wb_ctrl_comb : pipeline_memory_writeback_ctrl_t;

  SIGNAL mem_stage_read_req : STD_LOGIC;
  SIGNAL mem_stage_write_req : STD_LOGIC;
  SIGNAL mem_stage_addr : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL mem_stage_wdata : STD_LOGIC_VECTOR(31 DOWNTO 0);

  -- ===== MEM/WB register =====
  SIGNAL memwb_data : pipeline_memory_writeback_t;
  SIGNAL memwb_ctrl : pipeline_memory_writeback_ctrl_t;

  -- ===== Writeback stage =====
  SIGNAL wb_out : writeback_outputs_t;

  -- ===== Memory hazard arbiter =====
  SIGNAL pass_pc : STD_LOGIC;
  SIGNAL mem_read_out : STD_LOGIC;
  SIGNAL mem_write_out : STD_LOGIC;

  -- ===== Shared single-port memory =====
  SIGNAL mem_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_addr_mux : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL mem_wdata_mux : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_read_mux : STD_LOGIC;
  SIGNAL mem_write_mux : STD_LOGIC;

  -- Pipeline enable (stall front-end when MEM stage uses memory)
  SIGNAL front_enable : STD_LOGIC;

  -- ===== Freeze control =====
  SIGNAL pc_freeze : STD_LOGIC;
  SIGNAL ifde_write_enable : STD_LOGIC;
  SIGNAL insert_nop_ifde : STD_LOGIC;
  SIGNAL insert_nop_deex : STD_LOGIC;

BEGIN

  -- No branches for this step
  branch_targets.target_decode <= (OTHERS => '0');
  branch_targets.target_execute <= (OTHERS => '0');
  branch_targets.target_memory <= (OTHERS => '0');

  -- Forwarding disabled (use pipeline operands)
  -- forwarding.forward_a <= FORWARD_NONE;
  -- forwarding.forward_b <= FORWARD_NONE;
  -- Forwarding unit
  forwarding_unit_inst : ENTITY work.forwarding_unit
    PORT MAP(
      -- Memory Stage (EX/MEM outputs)
      MemRegWrite => exmem_ctrl_out.writeback_ctrl.RegWrite,
      MemRdst => exmem_data_out.rdst1,
      MemIsSwap => exmem_ctrl_out.memory_ctrl.IsSwap,
      -- Writeback Stage (MEM/WB outputs)
      WBRegWrite => memwb_ctrl.writeback_ctrl.RegWrite,
      WBRdst => memwb_data.rdst,
      -- Execution Stage (ID/EX outputs)
      ExRsrc1 => idex_data_out.rsrc1,
      ExRsrc2 => idex_data_out.rsrc2,
      ExOutBSelect => idex_ctrl_out.decode_ctrl.OutBSelect,
      ExIsImm => idex_ctrl_out.execute_ctrl.PassImm,
      -- Forwarding Control
      ForwardA => forwarding.forward_a,
      ForwardB => forwarding.forward_b,
      ForwardSecondary => forwarding.forward_secondary
    );

  -- Memory hazard unit arbitrates fetch vs memory stage access
  memory_hazard_inst : ENTITY work.memory_hazard_unit
    PORT MAP(
      MemRead_MEM => mem_stage_read_req,
      MemWrite_MEM => mem_stage_write_req,
      PassPC => pass_pc,
      MemRead_Out => mem_read_out,
      MemWrite_Out => mem_write_out
    );

  -- When MEM stage is using memory, stall the front-end (fetch + if/id + id/ex)
  front_enable <= pass_pc;

  -- IF/ID pack
  ifid_in.take_interrupt <= '0';
  ifid_in.override_operation <= '0';
  ifid_in.override_op <= (OTHERS => '0');
  ifid_in.pc <= fetch_out.pc;
  ifid_in.pushed_pc <= fetch_out.pushed_pc;
  ifid_in.instruction <= fetch_out.instruction;

  -- ===== Memory muxing =====
  -- If PassPC=1 -> Fetch uses memory. If PassPC=0 -> Memory stage uses memory.
  mem_addr_mux <= fetch_out.pc(17 DOWNTO 0) WHEN pass_pc = '1' ELSE
    mem_stage_addr;
  mem_wdata_mux <= (OTHERS => '0') WHEN pass_pc = '1' ELSE
    mem_stage_wdata;
  mem_read_mux <= (NOT rst) WHEN pass_pc = '1' ELSE
    mem_read_out;
  mem_write_mux <= '0' WHEN pass_pc = '1' ELSE
    mem_write_out;

  -- Shared memory
  mem_inst : ENTITY work.memory
    PORT MAP(
      clk => clk,
      rst => rst,
      Address => mem_addr_mux,
      WriteData => mem_wdata_mux,
      ReadData => mem_data,
      MemRead => mem_read_mux,
      MemWrite => mem_write_mux
    );

  -- ===== Fetch stage =====
  fetch_inst : ENTITY work.fetch_stage
    PORT MAP(
      clk => clk,
      rst => rst,
      stall => pc_freeze,
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
      enable => ifde_write_enable,
      flush => '0',
      flush_instruction => insert_nop_ifde,
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
      -- Immediate word comes from memory in the cycle after opcode fetch
      immediate_from_fetch => mem_data,
      is_swap_ex => idex_ctrl_out.decode_ctrl.IsSwap,
      wb_in => wb_out,
      decode_out => decode_out,
      ctrl_out => decode_ctrl_out,
      flags_out => decode_flags
    );
    
    
    -- ===== Opcode decoder =====
    opcode_decoder_inst : ENTITY work.opcode_decoder
      PORT MAP(
        opcode => decode_out.opcode,
        override_operation => ifid_out.override_operation,
        override_type => ifid_out.override_op,
        isSwap_from_execute => idex_ctrl_out.decode_ctrl.IsSwap,
        take_interrupt => ifid_out.take_interrupt,
        is_hardware_int_mem => '0',
        requireImmediate => idex_ctrl_out.decode_ctrl.RequireImmediate,
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
    -- ===== ID/EX pack =====
  idex_data_in.pc <= decode_out.pc;
  idex_data_in.operand_a <= decode_out.operand_a;
  idex_data_in.operand_b <= decode_out.operand_b;
  idex_data_in.rsrc1 <= decode_out.rsrc1;
  idex_data_in.rsrc2 <= decode_out.rsrc2;
  idex_data_in.rd <= decode_out.rd;
  
  idex_ctrl_in.decode_ctrl <= decode_ctrl_out.decode_ctrl;
  idex_ctrl_in.execute_ctrl <= decode_ctrl_out.execute_ctrl;
  idex_ctrl_in.memory_ctrl <= decode_ctrl_out.memory_ctrl;
  idex_ctrl_in.writeback_ctrl <= decode_ctrl_out.writeback_ctrl;

  idex_inst : ENTITY work.id_ex_register

    PORT MAP(
      clk => clk,
      rst => rst,
      enable => '1',
      flush => insert_nop_deex or '0',
      data_in => idex_data_in,
      ctrl_in => idex_ctrl_in,
      data_out => idex_data_out,
      ctrl_out => idex_ctrl_out
      );
      
      -- Freeze control unit manages pipeline stalls
      freeze_control_inst : ENTITY work.freeze_control
        PORT MAP(
          PassPC_MEM => pass_pc,
          Stall_Interrupt => '0',
          Stall_Branch => '0',
          is_swap => decode_ctrl_out.decode_ctrl.IsSwap,
          is_hlt => decode_ctrl_out.decode_ctrl.IsHLT,
          requireImmediate => decode_ctrl_out.decode_ctrl.RequireImmediate,
          PC_Freeze => pc_freeze,
          IFDE_WriteEnable => ifde_write_enable,
          InsertNOP_IFDE => insert_nop_ifde,
          InsertNOP_DEEX => insert_nop_deex
        );

  -- ===== Execute stage =====
  execute_inst : ENTITY work.execute_stage
    PORT MAP(
      clk => clk,
      reset => rst,
      idex_ctrl_in => idex_ctrl_out,
      idex_data_in => idex_data_out,
      immediate => ifid_out.instruction,
      forwarding => forwarding,
      Forwarded_EXM => exmem_data_out.primary_data,
      Forwarded_MWB => wb_out.data,
      StackFlags => (OTHERS => '0'),
      execute_out => execute_out,
      ctrl_out => execute_ctrl_out
    );

  -- ===== EX/MEM pack =====
  exmem_data_in.primary_data <= execute_out.primary_data;
  exmem_data_in.secondary_data <= execute_out.secondary_data;
  exmem_data_in.rdst1 <= execute_out.rdst;

  exmem_ctrl_in.memory_ctrl.MemRead <= execute_ctrl_out.m_memread;
  exmem_ctrl_in.memory_ctrl.MemWrite <= execute_ctrl_out.m_memwrite;
  exmem_ctrl_in.memory_ctrl.SPtoMem <= execute_ctrl_out.m_sptomem;
  exmem_ctrl_in.memory_ctrl.PassInterrupt(0) <= execute_ctrl_out.m_passinterrupt;
  exmem_ctrl_in.memory_ctrl.PassInterrupt(1) <= '0';
  exmem_ctrl_in.memory_ctrl.SP_Enable <= idex_ctrl_out.memory_ctrl.SP_Enable;
  exmem_ctrl_in.memory_ctrl.SP_Function <= idex_ctrl_out.memory_ctrl.SP_Function;
  exmem_ctrl_in.memory_ctrl.FlagFromMem <= idex_ctrl_out.memory_ctrl.FlagFromMem;
  exmem_ctrl_in.memory_ctrl.IsSwap <= idex_ctrl_out.memory_ctrl.IsSwap;

  exmem_ctrl_in.writeback_ctrl.RegWrite <= execute_ctrl_out.wb_regwrite;
  exmem_ctrl_in.writeback_ctrl.PassMem <= execute_ctrl_out.wb_memtoreg;
  exmem_ctrl_in.writeback_ctrl.OutPortWriteEn <= idex_ctrl_out.writeback_ctrl.OutPortWriteEn;

  exmem_reg_inst : ENTITY work.ex_mem_register
    PORT MAP(
      clk => clk,
      rst => rst,
      enable => '1',
      flush => '0',
      data_in => exmem_data_in,
      ctrl_in => exmem_ctrl_in,
      data_out => exmem_data_out,
      ctrl_out => exmem_ctrl_out
    );

  -- ===== Memory stage =====
  memory_stage_inst : ENTITY work.memory_stage
    PORT MAP(
      clk => clk,
      rst => rst,
      ex_mem_ctrl_in => exmem_ctrl_out,
      ex_mem_data_in => exmem_data_out,
      mem_wb_data_out => mem_wb_data_comb,
      mem_wb_ctrl_out => mem_wb_ctrl_comb,
      MemReadData => mem_data,
      MemRead => mem_stage_read_req,
      MemWrite => mem_stage_write_req,
      MemAddress => mem_stage_addr,
      MemWriteData => mem_stage_wdata
    );

  -- ===== MEM/WB register =====
  mem_wb_reg_inst : ENTITY work.mem_wb_register
    PORT MAP(
      clk => clk,
      rst => rst,
      enable => '1',
      flush => '0',
      data_in => mem_wb_data_comb,
      ctrl_in => mem_wb_ctrl_comb,
      data_out => memwb_data,
      ctrl_out => memwb_ctrl
    );

  -- ===== Writeback stage =====
  writeback_inst : ENTITY work.writeback_stage
    PORT MAP(
      mem_wb_ctrl => memwb_ctrl,
      mem_wb_data => memwb_data,
      wb_out => wb_out
    );

  -- Expose OUT port behavior for debugging
  out_port_en <= wb_out.port_enable;
  out_port <= wb_out.data;

END ARCHITECTURE Structural;