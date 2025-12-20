LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.pipeline_data_pkg.ALL;
USE work.control_signals_pkg.ALL;
USE work.pkg_opcodes.ALL;

ENTITY processor_top IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    hardware_interrupt : IN STD_LOGIC;
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

  -- ===== Branch decision unit =====
  SIGNAL branch_select : STD_LOGIC;
  SIGNAL branch_target_select : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL actual_taken : STD_LOGIC;

  -- ===== Interrupt unit =====
  SIGNAL int_stall : STD_LOGIC;
  SIGNAL int_pass_pc_not_plus1 : STD_LOGIC;
  SIGNAL int_take_interrupt : STD_LOGIC;
  SIGNAL int_is_hardware_int_mem : STD_LOGIC;
  SIGNAL int_override_operation : STD_LOGIC;
  SIGNAL int_override_type : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL memory_hazard_int : STD_LOGIC;

  -- Pending hardware interrupt register
  SIGNAL pending_hw_interrupt : STD_LOGIC := '0';
  SIGNAL TakeHWInterrupt : STD_LOGIC;
  SIGNAL is_blocking_hardware_interrupts : STD_LOGIC;

  -- ===== Debug signals =====
  SIGNAL clk_count : INTEGER := 0;
BEGIN

  -- Clock counter for debugging
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst = '1' THEN
        clk_count <= 0;
      ELSE
        clk_count <= clk_count + 1;
      END IF;
    END IF;
  END PROCESS;

  is_blocking_hardware_interrupts <= '1' when decode_ctrl_out.decode_ctrl.IsInterrupt = '1' or 
           decode_ctrl_out.decode_ctrl.IsCall = '1' or 
           decode_ctrl_out.decode_ctrl.IsReturn = '1' or 
           decode_ctrl_out.decode_ctrl.IsReti = '1' or 
           idex_ctrl_out.decode_ctrl.IsInterrupt = '1' or 
           idex_ctrl_out.decode_ctrl.IsCall = '1' or 
           idex_ctrl_out.decode_ctrl.IsReturn = '1' or 
           idex_ctrl_out.decode_ctrl.IsReti = '1' or 
           decode_ctrl_out.decode_ctrl.IsJMPConditional = '1' else '0';

  -- Pending hardware interrupt logic
  process(clk, rst)
  begin
    if rst = '1' then
      pending_hw_interrupt <= '0';

    elsif rising_edge(clk) then
      -- If hardware interrupt is received and any blocking condition is active
      if hardware_interrupt = '1' then
        pending_hw_interrupt <= '1';
      end if;

      if is_blocking_hardware_interrupts = '0' and pending_hw_interrupt = '1' then
        pending_hw_interrupt <= '0';
      END IF;
    end if;
  end process;

  TakeHWInterrupt <= '1' when pending_hw_interrupt = '1' and is_blocking_hardware_interrupts = '0' else '0';


  -- Branch targets from different pipeline stages
  branch_targets.target_decode <= decode_out.immediate; -- Immediate from decode (for JMP/CALL target)
  branch_targets.target_execute <= idex_data_out.operand_b; -- Target computed in execute
  branch_targets.target_memory <= mem_data;

  -- Compute actual branch taken based on CCR flags and conditional type
  -- CCR format: [2] = Zero, [1] = Negative, [0] = Carry
  -- ConditionalType from ID/EX: 00 = JZ (Zero), 01 = JN (Negative), 10 = JC (Carry)
  -- Note: Both CCR flags and ConditionalType must come from the same pipeline stage
  actual_taken <= execute_out.ccr_flags(2) WHEN idex_ctrl_out.execute_ctrl.ConditionalType = COND_ZERO ELSE -- JZ: check Zero flag
    execute_out.ccr_flags(1) WHEN idex_ctrl_out.execute_ctrl.ConditionalType = COND_NEGATIVE ELSE -- JN: check Negative flag
    execute_out.ccr_flags(0) WHEN idex_ctrl_out.execute_ctrl.ConditionalType = COND_CARRY ELSE -- JC: check Carry flag
    '0'; -- Default

  -- Forwarding disabled (use pipeline operands)
  -- forwarding.forward_a <= FORWARD_NONE;
  -- forwarding.forward_b <= FORWARD_NONE;
  -- Forwarding unit
  forwarding_unit_inst : ENTITY work.forwarding_unit
    PORT MAP
    (
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
    PORT MAP
    (
      MemRead_MEM => mem_stage_read_req,
      MemWrite_MEM => mem_stage_write_req,
      PassPC => pass_pc,
      MemRead_Out => mem_read_out,
      MemWrite_Out => mem_write_out
    );

  -- When MEM stage is using memory, stall the front-end (fetch + if/id + id/ex)
  front_enable <= pass_pc;



  -- ===== Memory muxing =====
  -- If PassPC=1 -> Fetch uses memory. If PassPC=0 -> Memory stage uses memory.
  mem_addr_mux <= fetch_out.pc(17 DOWNTO 0) WHEN pass_pc = '1' ELSE
    mem_stage_addr;
  mem_wdata_mux <= (OTHERS => '0') WHEN pass_pc = '1' ELSE
    mem_stage_wdata;
  -- Memory read enabled during fetch (including during reset to read reset vector)
  mem_read_mux <= '1' WHEN pass_pc = '1' ELSE
    mem_read_out;
  mem_write_mux <= '0' WHEN pass_pc = '1' ELSE
    mem_write_out;

  -- Shared memory
  mem_inst : ENTITY work.memory
    PORT MAP
    (
      clk => clk,
      rst => rst,
      Address => mem_addr_mux,
      WriteData => mem_wdata_mux,
      ReadData => mem_data,
      MemRead => mem_read_mux,
      MemWrite => mem_write_mux
    );

  -- ===== Interrupt unit =====
  interrupt_unit_inst : ENTITY work.interrupt_unit
    PORT MAP(
      IsInterrupt_DE => decode_ctrl_out.decode_ctrl.IsInterrupt,
      IsCall_DE => decode_ctrl_out.decode_ctrl.IsCall,
      IsRet_DE => decode_ctrl_out.decode_ctrl.IsReturn, 
      IsReti_DE => decode_ctrl_out.decode_ctrl.IsReti,
      IsInterrupt_EX => idex_ctrl_out.decode_ctrl.IsInterrupt,
      IsReti_EX => idex_ctrl_out.decode_ctrl.IsReti,
      IsRet_EX => idex_ctrl_out.decode_ctrl.IsReturn,
      IsCall_EX => idex_ctrl_out.decode_ctrl.IsCall,
      IsInterrupt_MEM => exmem_ctrl_out.memory_ctrl.IsInterrupt,
      IsCall_MEM => exmem_ctrl_out.memory_ctrl.IsCall,
      IsRet_MEM => exmem_ctrl_out.memory_ctrl.IsReturn,
      IsReti_MEM => exmem_ctrl_out.memory_ctrl.IsReti,
      IsHardwareInt_MEM => exmem_ctrl_out.memory_ctrl.PassInterrupt(0),
      HardwareInterrupt => TakeHWInterrupt,
      freeze_fetch => int_stall,
      memory_hazard => memory_hazard_int,
      PassPC_NotPCPlus1 => int_pass_pc_not_plus1,
      TakeInterrupt => int_take_interrupt,
      IsHardwareIntMEM_Out => int_is_hardware_int_mem,
      OverrideOperation => int_override_operation,
      OverrideType => int_override_type
    );

  -- ===== Fetch stage =====
  fetch_inst : ENTITY work.fetch_stage
    PORT MAP(
      clk => clk,
      rst => rst,
      stall => pc_freeze,
      BranchSelect => branch_select,
      BranchTargetSelect => branch_target_select,
      branch_targets => branch_targets,
      mem_data => mem_data,
      fetch_out => fetch_out,
      PushPCSelect => int_pass_pc_not_plus1
    );

  ifid_in.take_interrupt <= TakeHWInterrupt; 
  ifid_in.override_operation <= int_override_operation;
  ifid_in.override_op <= int_override_type;
  ifid_in.pc <= fetch_out.pc;
  ifid_in.pushed_pc <= fetch_out.pushed_pc;
  ifid_in.instruction <= fetch_out.instruction;
  -- ===== IF/ID register =====
  ifid_inst : ENTITY work.if_id_register
    PORT MAP(
      clk => clk,
      rst => rst,
      enable => ifde_write_enable,
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
        override_operation => int_override_operation,
        override_type => int_override_type,
        isSwap_from_execute => idex_ctrl_out.decode_ctrl.IsSwap,
        take_interrupt => ifid_out.take_interrupt,
        is_hardware_int_mem => int_is_hardware_int_mem,
        requireImmediate => idex_ctrl_out.decode_ctrl.RequireImmediate,
        decode_ctrl => decoder_ctrl.decode_ctrl,
        execute_ctrl => decoder_ctrl.execute_ctrl,
        memory_ctrl => decoder_ctrl.memory_ctrl,
        writeback_ctrl => decoder_ctrl.writeback_ctrl,
        is_jmp_out => OPEN,
        is_jmp_conditional_out => OPEN
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
      flush => insert_nop_deex,
      data_in => idex_data_in,
      ctrl_in => idex_ctrl_in,
      data_out => idex_data_out,
      ctrl_out => idex_ctrl_out
      );
      -- Freeze control unit manages pipeline stalls
      freeze_control_inst : ENTITY work.freeze_control
        PORT MAP(
          PassPC_MEM => pass_pc,
          Stall_Interrupt => int_stall,
          BranchSelect => branch_select,
          BranchTargetSelect => branch_target_select,
          is_swap => decode_ctrl_out.decode_ctrl.IsSwap,
          is_hlt => decode_ctrl_out.decode_ctrl.IsHLT,
          requireImmediate => idex_ctrl_out.decode_ctrl.RequireImmediate,
          memory_hazard_int => memory_hazard_int,
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
      exmem_mem_to_ccr => exmem_ctrl_out.memory_ctrl.MemToCCR,
      StackFlags => mem_data(2 DOWNTO 0),
      execute_out => execute_out,
      ctrl_out => execute_ctrl_out
    );

  -- ===== EX/MEM pack =====
  exmem_data_in.primary_data <= execute_out.primary_data;
  exmem_data_in.secondary_data <= execute_out.secondary_data;
  exmem_data_in.rdst1 <= execute_out.rdst;

  exmem_ctrl_in.memory_ctrl <= idex_ctrl_out.memory_ctrl;
  exmem_ctrl_in.writeback_ctrl <= idex_ctrl_out.writeback_ctrl;

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


  -- ===== Branch decision unit =====
  branch_decision_inst : ENTITY work.branch_decision_unit
    PORT MAP
    (
      -- Inputs
      IsSoftwareInterrupt => exmem_ctrl_out.memory_ctrl.PassInterrupt(1) and not exmem_ctrl_out.memory_ctrl.PassInterrupt(0), -- Software interrupt from EX/MEM
      IsHardwareInterrupt => exmem_ctrl_out.memory_ctrl.PassInterrupt(1) and  exmem_ctrl_out.memory_ctrl.PassInterrupt(0), -- Hardware interrupt from EX/MEM
      IsRTI => exmem_ctrl_out.memory_ctrl.IsRetI, -- Return from interrupt
      IsReturn => exmem_ctrl_out.memory_ctrl.IsReturn, -- RET instruction from EX/MEM
      IsCall => decode_flags.is_call, -- CALL from opcode detection (not affected by override)
      UnconditionalBranch => decode_ctrl_out.decode_ctrl.IsJMP, -- JMP from decode (early detection)
      ConditionalBranch => idex_ctrl_out.decode_ctrl.IsJMPConditional, -- Conditional branch from ID/EX (needs CCR)
      PredictedTaken => '0', -- Static prediction: always not-taken
      ActualTaken => actual_taken, -- Actual outcome computed from CCR flags
      Reset => rst,
      -- Outputs
      BranchSelect => branch_select,
      BranchTargetSelect => branch_target_select
    );


  -- Expose OUT port behavior for debugging
  out_port_en <= wb_out.port_enable;
  out_port <= wb_out.data when wb_out.port_enable = '1' else (others => '0');

END ARCHITECTURE Structural;