LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;
USE work.processor_components_pkg.ALL; -- Component declarations
USE work.processor_interface_pkg.ALL; -- Interface record types

ENTITY processor_top IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- External Interrupt Signal
        intr : IN STD_LOGIC;

        -- Memory Interface
        mem_data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Data from memory (instruction/data)
        mem_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Memory address
        mem_data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Data to memory
        mem_read : OUT STD_LOGIC; -- Memory read enable
        mem_write : OUT STD_LOGIC; -- Memory write enable

        -- Input Port
        in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Output Port
        out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_port_enable : OUT STD_LOGIC
    );
END ENTITY processor_top;

ARCHITECTURE Structural OF processor_top IS

    -- ========== COMPONENT DECLARATIONS MOVED TO processor_components_pkg.vhd ==========rocessor_components_pkg.vhd ==========
    -- This eliminates 300+ lines from this file!
    -- Components are now imported via: USE work.processor_components_pkg.ALL;

    -- ========== FETCH STAGE SIGNALS ==========
    SIGNAL fetch_out : fetch_outputs_t;
    SIGNAL fetch_stall : STD_LOGIC;
    SIGNAL branch_targets : branch_targets_t;

    -- ========== IF/ID PIPELINE REGISTER SIGNALS ==========
    SIGNAL ifid_data_in : pipeline_fetch_decode_t;
    SIGNAL ifid_data_out : pipeline_fetch_decode_t;
    SIGNAL ifid_enable : STD_LOGIC;
    SIGNAL ifid_flush : STD_LOGIC;

    -- ========== DECODE STAGE SIGNALS ==========
    SIGNAL decode_out : decode_outputs_t;
    SIGNAL decode_ctrl : decode_ctrl_outputs_t;
    SIGNAL decode_flags : decode_flags_t;

    -- ========== ID/EX PIPELINE REGISTER SIGNALS ==========
    SIGNAL idex_data_in : pipeline_decode_excute_t;
    SIGNAL idex_ctrl_in : pipeline_decode_excute_ctrl_t;
    SIGNAL idex_data_out : pipeline_decode_excute_t;
    SIGNAL idex_ctrl_out : pipeline_decode_excute_ctrl_t;

    -- ========== EXECUTE STAGE SIGNALS ==========
    SIGNAL execute_out : execute_outputs_t;
    SIGNAL execute_ctrl_out : execute_ctrl_outputs_t;

    -- Forwarding signals (driven by forwarding unit)
    SIGNAL forwarding : forwarding_ctrl_t;

    -- ========== EX/MEM PIPELINE REGISTER SIGNALS ==========
    SIGNAL exmem_data_in : pipeline_execute_memory_t;
    SIGNAL exmem_ctrl_in : pipeline_execute_memory_ctrl_t;
    SIGNAL exmem_data_out : pipeline_execute_memory_t;
    SIGNAL exmem_ctrl_out : pipeline_execute_memory_ctrl_t;

    -- ========== MEMORY STAGE SIGNALS ==========
    SIGNAL mem_wb_data_from_mem : pipeline_memory_writeback_t;
    SIGNAL mem_wb_ctrl_from_mem : pipeline_memory_writeback_ctrl_t;
    SIGNAL mem_read_internal : STD_LOGIC;
    SIGNAL mem_write_internal : STD_LOGIC;
    SIGNAL mem_address_internal : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL mem_writedata_internal : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- ========== MEM/WB PIPELINE REGISTER SIGNALS ==========
    SIGNAL memwb_data_out : pipeline_memory_writeback_t;
    SIGNAL memwb_ctrl_out : pipeline_memory_writeback_ctrl_t;

    -- ========== WRITEBACK STAGE SIGNALS ==========
    SIGNAL wb_out : writeback_outputs_t;

    -- ========== CONTROL UNIT SIGNALS ==========

    -- Opcode Decoder outputs (using record)
    SIGNAL decoder_ctrl : decode_ctrl_outputs_t;

    -- Interrupt Unit signals
    SIGNAL interrupt_stall : STD_LOGIC;
    SIGNAL interrupt_push_pc_select : STD_LOGIC;
    SIGNAL interrupt_take_interrupt : STD_LOGIC;
    SIGNAL interrupt_override_operation : STD_LOGIC;
    SIGNAL interrupt_override_type : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL interrupt_is_hw_int_mem : STD_LOGIC;

    -- Branch Control signals
    SIGNAL branch_select : STD_LOGIC;
    SIGNAL branch_target_select : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL branch_flush_de : STD_LOGIC;
    SIGNAL branch_flush_if : STD_LOGIC;
    SIGNAL branch_stall : STD_LOGIC;

    -- Freeze Control signals
    SIGNAL freeze_pc_enable : STD_LOGIC;
    SIGNAL freeze_ifid_enable : STD_LOGIC;
    SIGNAL freeze_insert_nop : STD_LOGIC;

    -- Temporary feedback signals for stages not yet implemented
    SIGNAL is_hardware_int_mem : STD_LOGIC;
    SIGNAL predicted_taken : STD_LOGIC;
    SIGNAL actual_taken : STD_LOGIC;
    SIGNAL passpc_mem : STD_LOGIC;

BEGIN

    -- ========== MEMORY INTERFACE ==========
    -- PC output to memory for instruction fetch
    mem_addr <= fetch_out.pc;
    mem_read <= '1'; -- Always reading instructions
    mem_write <= mem_write_internal; -- Connected to memory stage
    mem_data_out <= mem_writedata_internal; -- Connected to memory stage

    -- Output port (connected to writeback stage)
    out_port <= wb_out.data;
    out_port_enable <= wb_out.port_enable;

    -- ========== FETCH STAGE INSTANTIATION ==========
    fetch_stage_inst : fetch_stage
    PORT MAP(
        clk => clk,
        rst => rst,
        stall => fetch_stall,
        BranchSelect => branch_select,
        BranchTargetSelect => branch_target_select,
        branch_targets => branch_targets,
        mem_data => mem_data_in,
        fetch_out => fetch_out,
        intr_in => intr,
        PushPCSelect => interrupt_push_pc_select
    );

    -- Fetch stall control (inverted PC enable from freeze control)
    fetch_stall <= NOT freeze_pc_enable;

    -- ========== IF/ID PIPELINE REGISTER DATA ASSEMBLY ==========
    ifid_data_in.take_interrupt <= interrupt_take_interrupt;
    ifid_data_in.override_operation <= interrupt_override_operation;
    ifid_data_in.override_op <= interrupt_override_type;
    ifid_data_in.pc <= fetch_out.pc;
    ifid_data_in.pushed_pc <= fetch_out.pushed_pc;
    ifid_data_in.instruction <= fetch_out.instruction;

    -- IF/ID enable and flush control
    ifid_enable <= freeze_ifid_enable;
    ifid_flush <= branch_flush_if OR freeze_insert_nop;

    -- ========== IF/ID PIPELINE REGISTER INSTANTIATION ==========
    if_id_reg_inst : if_id_register
    PORT MAP(
        clk => clk,
        rst => rst,
        enable => ifid_enable,
        flush => ifid_flush,
        data_in => ifid_data_in,
        data_out => ifid_data_out
    );

    -- ========== OPCODE DECODER INSTANTIATION ==========
    opcode_decoder_inst : opcode_decoder
    PORT MAP(
        opcode => decode_out.opcode,
        override_operation => ifid_data_out.override_operation,
        override_type => ifid_data_out.override_op,
        isSwap_from_execute => idex_ctrl_out.decode_ctrl.IsSwap,
        take_interrupt => ifid_data_out.take_interrupt,
        is_hardware_int_mem => is_hardware_int_mem,
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

    -- ========== DECODE STAGE INSTANTIATION ==========
    decode_stage_inst : decode_stage
    PORT MAP(
        clk => clk,
        rst => rst,
        pc_in => ifid_data_out.pc,
        pushed_pc_in => ifid_data_out.pushed_pc,
        instruction_in => ifid_data_out.instruction,
        take_interrupt_in => ifid_data_out.take_interrupt,
        override_op_in => ifid_data_out.override_op,
        ctrl_in => decoder_ctrl,
        stall_control => '0',
        in_port => in_port,
        immediate_from_fetch => mem_data_in,
        is_swap_ex => idex_ctrl_out.decode_ctrl.IsSwap,
        wb_in => wb_out,
        decode_out => decode_out,
        ctrl_out => decode_ctrl,
        flags_out => decode_flags
    );

    -- ========== ID/EX PIPELINE REGISTER DATA ASSEMBLY ==========
    -- Pack decode outputs into pipeline records
    idex_data_in.pc <= decode_out.pc;
    idex_data_in.operand_a <= decode_out.operand_a;
    idex_data_in.operand_b <= decode_out.operand_b;
    idex_data_in.immediate <= decode_out.immediate;
    idex_data_in.rsrc1 <= decode_out.rsrc1;
    idex_data_in.rsrc2 <= decode_out.rsrc2;
    idex_data_in.rd <= decode_out.rd;

    idex_ctrl_in.decode_ctrl <= decode_ctrl.decode_ctrl;
    idex_ctrl_in.execute_ctrl <= decode_ctrl.execute_ctrl;
    idex_ctrl_in.memory_ctrl <= decode_ctrl.memory_ctrl;
    idex_ctrl_in.writeback_ctrl <= decode_ctrl.writeback_ctrl;

    -- ========== ID/EX PIPELINE REGISTER INSTANTIATION ==========
    id_ex_reg_inst : id_ex_register
    PORT MAP(
        clk => clk,
        rst => rst,
        enable => '1',
        flush => branch_flush_de,
        data_in => idex_data_in,
        ctrl_in => idex_ctrl_in,
        data_out => idex_data_out,
        ctrl_out => idex_ctrl_out
    );

    -- ========== EXECUTE STAGE INSTANTIATION ==========

    -- ========== FORWARDING UNIT INSTANTIATION ==========
    forwarding_unit_inst : forwarding_unit
    PORT MAP(
        -- Memory Stage (from EX/MEM register)
        MemRegWrite => exmem_ctrl_out.writeback_ctrl.RegWrite,
        MemRdst => exmem_data_out.rdst1,
        MemIsSwap => exmem_ctrl_out.memory_ctrl.IsSwap,
        -- Writeback Stage (from MEM/WB register)
        WBRegWrite => memwb_ctrl_out.writeback_ctrl.RegWrite,
        WBRdst => memwb_data_out.rdst,
        -- Execute Stage (from ID/EX register)
        Rsrc1 => idex_data_out.rsrc1,
        Rsrc2 => idex_data_out.rsrc2,
        -- Forwarding Control Outputs
        ForwardA => forwarding.forward_a,
        ForwardB => forwarding.forward_b
    );

    execute_stage_inst : execute_stage
    PORT MAP(
        clk => clk,
        reset => rst,
        -- Control and data inputs from ID/EX (using records)
        idex_ctrl_in => idex_ctrl_out,
        idex_data_in => idex_data_out,
        -- Forwarding control
        forwarding => forwarding,
        -- Forwarded data from later stages
        Forwarded_EXM => exmem_data_out.primary_data,
        Forwarded_MWB => wb_out.data,
        StackFlags => exmem_ctrl_out.memory_ctrl.FlagFromMem & execute_out.ccr_flags(1 DOWNTO 0),
        -- Outputs (using records)
        execute_out => execute_out,
        ctrl_out => execute_ctrl_out
    );

    -- ========== EX/MEM PIPELINE REGISTER DATA ASSEMBLY ==========
    -- Pack Execute Stage outputs into pipeline records
    exmem_data_in.primary_data <= execute_out.alu_result;
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
    exmem_ctrl_in.writeback_ctrl.MemToALU <= execute_ctrl_out.wb_memtoreg;
    exmem_ctrl_in.writeback_ctrl.OutPortWriteEn <= idex_ctrl_out.writeback_ctrl.OutPortWriteEn;

    -- ========== EX/MEM PIPELINE REGISTER INSTANTIATION ==========
    ex_mem_reg_inst : ex_mem_register
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

    -- ========== MEMORY STAGE INSTANTIATION ==========
    memory_stage_inst : MemoryStage
    PORT MAP(
        clk => clk,
        rst => rst,
        -- Pipeline inputs (using records)
        ex_mem_ctrl_in => exmem_ctrl_out,
        ex_mem_data_in => exmem_data_out,
        -- Pipeline outputs (using records)
        mem_wb_data_out => mem_wb_data_from_mem,
        mem_wb_ctrl_out => mem_wb_ctrl_from_mem,
        -- Memory interface
        MemReadData => mem_data_in,
        MemRead => mem_read_internal,
        MemWrite => mem_write_internal,
        MemAddress => mem_address_internal,
        MemWriteData => mem_writedata_internal
    );

    -- ========== MEM/WB PIPELINE REGISTER INSTANTIATION ==========
    mem_wb_reg_inst : mem_wb_register
    PORT MAP(
        clk => clk,
        rst => rst,
        enable => '1',
        flush => '0',
        -- Pipeline data and control (using records)
        data_in => mem_wb_data_from_mem,
        ctrl_in => mem_wb_ctrl_from_mem,
        data_out => memwb_data_out,
        ctrl_out => memwb_ctrl_out
    );

    -- ========== WRITEBACK STAGE INSTANTIATION ==========
    writeback_stage_inst : writeback_stage
    PORT MAP(
        clk => clk,
        rst => rst,
        -- Pipeline inputs (using records)
        mem_wb_ctrl => memwb_ctrl_out,
        mem_wb_data => memwb_data_out,
        -- Output (using record)
        wb_out => wb_out
    );

    -- ========== INTERRUPT UNIT INSTANTIATION ==========
    interrupt_unit_inst : interrupt_unit
    PORT MAP(
        IsInterrupt_DE => decode_flags.is_interrupt,
        IsHardwareInt_DE => decode_flags.is_hardware_int,
        IsCall_DE => decode_flags.is_call,
        IsReturn_DE => decode_flags.is_return,
        IsReti_DE => decode_flags.is_reti,
        IsInterrupt_EX => idex_ctrl_out.decode_ctrl.IsInterrupt,
        IsHardwareInt_EX => idex_ctrl_out.decode_ctrl.IsHardwareInterrupt,
        IsReti_EX => idex_ctrl_out.decode_ctrl.IsReti,
        IsHardwareInt_MEM => is_hardware_int_mem,
        HardwareInterrupt => intr,
        Stall => interrupt_stall,
        PassPC_NotPCPlus1 => interrupt_push_pc_select,
        TakeInterrupt => interrupt_take_interrupt,
        IsHardwareIntMEM_Out => interrupt_is_hw_int_mem,
        OverrideOperation => interrupt_override_operation,
        OverrideType => interrupt_override_type
    );

    -- ========== BRANCH DECISION UNIT INSTANTIATION ==========
    branch_decision_unit_inst : branch_decision_unit
    PORT MAP(
        IsSoftwareInterrupt => decode_flags.is_interrupt AND NOT decode_flags.is_hardware_int,
        IsHardwareInterrupt => decode_flags.is_interrupt AND decode_flags.is_hardware_int,
        UnconditionalBranch => decode_flags.is_jmp OR decode_flags.is_call,
        ConditionalBranch => idex_ctrl_out.decode_ctrl.IsJMPConditional,
        PredictedTaken => predicted_taken,
        ActualTaken => actual_taken,
        Reset => rst,
        BranchSelect => branch_select,
        BranchTargetSelect => branch_target_select,
        FlushDE => branch_flush_de,
        FlushIF => branch_flush_if,
        Stall_Branch => branch_stall
    );

    -- ========== FREEZE CONTROL INSTANTIATION ==========
    freeze_control_inst : freeze_control
    PORT MAP(
        PassPC_MEM => passpc_mem,
        Stall_Interrupt => interrupt_stall,
        Stall_Branch => branch_stall,
        PC_WriteEnable => freeze_pc_enable,
        IFDE_WriteEnable => freeze_ifid_enable,
        InsertNOP_IFDE => freeze_insert_nop
    );

    -- ========== TEMPORARY SIGNAL ASSIGNMENTS ==========

    -- Branch targets bundle
    branch_targets.target_decode <= decode_out.immediate;
    branch_targets.target_execute <= idex_data_out.operand_b;
    branch_targets.target_memory <= mem_wb_data_from_mem.memory_data;

    -- Temporary signals for stages not yet implemented
    predicted_taken <= '0';
    actual_taken <= '0';
    is_hardware_int_mem <= '0';
    passpc_mem <= '1'; -- No memory hazard for now

END ARCHITECTURE Structural;