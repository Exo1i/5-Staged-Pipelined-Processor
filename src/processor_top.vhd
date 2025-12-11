LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY processor_top IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        
        -- External Interrupt Signal
        intr : IN STD_LOGIC;
        
        -- Memory Interface
        mem_data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- Data from memory (instruction/data)
        mem_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);    -- Memory address
        mem_data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Data to memory
        mem_read : OUT STD_LOGIC;                         -- Memory read enable
        mem_write : OUT STD_LOGIC;                        -- Memory write enable
        
        -- Input Port
        in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Output Port
        out_port : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_port_enable : OUT STD_LOGIC
    );
END ENTITY processor_top;

ARCHITECTURE Structural OF processor_top IS

    -- ========== COMPONENT DECLARATIONS ==========
    
    -- Fetch Stage
    COMPONENT fetch_stage IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            stall : IN STD_LOGIC;
            BranchSelect : IN STD_LOGIC;
            BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            target_decode : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_execute : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_memory : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            mem_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            intr_in : IN STD_LOGIC;
            PushPCSelect : IN STD_LOGIC
        );
    END COMPONENT;
    
    -- IF/ID Pipeline Register
    COMPONENT if_id_register IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            flush : IN STD_LOGIC;
            data_in : IN pipeline_fetch_decode_t;
            data_out : OUT pipeline_fetch_decode_t
        );
    END COMPONENT;
    
    -- Decode Stage
    COMPONENT decode_stage IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            instruction_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            take_interrupt_in : IN STD_LOGIC;
            override_op_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            decode_ctrl : IN decode_control_t;
            execute_ctrl : IN execute_control_t;
            memory_ctrl : IN memory_control_t;
            writeback_ctrl : IN writeback_control_t;
            stall_control : IN STD_LOGIC;
            in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_from_fetch : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            is_swap_ex : IN STD_LOGIC;
            wb_rd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            wb_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            wb_enable : IN STD_LOGIC;
            pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            operand_a_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            operand_b_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            rsrc1_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            rsrc2_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            rd_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            decode_ctrl_out : OUT decode_control_t;
            execute_ctrl_out : OUT execute_control_t;
            memory_ctrl_out : OUT memory_control_t;
            writeback_ctrl_out : OUT writeback_control_t;
            opcode_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            is_interrupt_out : OUT STD_LOGIC;
            is_hardware_int_out : OUT STD_LOGIC;
            is_call_out : OUT STD_LOGIC;
            is_return_out : OUT STD_LOGIC;
            is_reti_out : OUT STD_LOGIC;
            is_jmp_out : OUT STD_LOGIC;
            is_jmp_conditional_out : OUT STD_LOGIC;
            conditional_type_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Opcode Decoder
    COMPONENT opcode_decoder IS
        PORT (
            opcode : IN std_logic_vector(4 DOWNTO 0);
            override_operation : IN std_logic;
            override_type : IN std_logic_vector(1 DOWNTO 0);
            isSwap_from_execute : IN std_logic;
            take_interrupt : IN std_logic;
            is_hardware_int_mem : IN std_logic;
            decode_ctrl : OUT decode_control_t;
            execute_ctrl : OUT execute_control_t;
            memory_ctrl : OUT memory_control_t;
            writeback_ctrl : OUT writeback_control_t;
            is_interrupt_out : OUT std_logic;
            is_call_out : OUT std_logic;
            is_return_out : OUT std_logic;
            is_reti_out : OUT std_logic;
            is_jmp_out : OUT std_logic;
            is_jmp_conditional_out : OUT std_logic;
            is_swap_out : OUT std_logic
        );
    END COMPONENT;
    
    -- Interrupt Unit
    COMPONENT interrupt_unit IS
        PORT (
            IsInterrupt_DE : IN std_logic;
            IsHardwareInt_DE : IN std_logic;
            IsCall_DE : IN std_logic;
            IsReturn_DE : IN std_logic;
            IsReti_DE : IN std_logic;
            IsInterrupt_EX : IN std_logic;
            IsHardwareInt_EX : IN std_logic;
            IsReti_EX : IN std_logic;
            IsHardwareInt_MEM : IN std_logic;
            HardwareInterrupt : IN std_logic;
            Stall : OUT std_logic;
            PassPC_NotPCPlus1 : OUT std_logic;
            TakeInterrupt : OUT std_logic;
            IsHardwareIntMEM_Out : OUT std_logic;
            OverrideOperation : OUT std_logic;
            OverrideType : OUT std_logic_vector(1 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Branch Decision Unit
    COMPONENT branch_decision_unit IS
        PORT (
            IsSoftwareInterrupt : IN std_logic;
            IsHardwareInterrupt : IN std_logic;
            UnconditionalBranch : IN std_logic;
            ConditionalBranch : IN std_logic;
            PredictedTaken : IN std_logic;
            ActualTaken : IN std_logic;
            Reset : IN std_logic;
            BranchSelect : OUT std_logic;
            BranchTargetSelect : OUT std_logic_vector(1 DOWNTO 0);
            FlushDE : OUT std_logic;
            FlushIF : OUT std_logic;
            Stall_Branch : OUT std_logic
        );
    END COMPONENT;
    
    -- Freeze Control
    COMPONENT freeze_control IS
        PORT (
            PassPC_MEM : IN std_logic;
            Stall_Interrupt : IN std_logic;
            Stall_Branch : IN std_logic;
            PC_WriteEnable : OUT std_logic;
            IFDE_WriteEnable : OUT std_logic;
            InsertNOP_IFDE : OUT std_logic
        );
    END COMPONENT;
    
    -- ========== FETCH STAGE SIGNALS ==========
    SIGNAL fetch_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetch_pushed_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetch_instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetch_stall : STD_LOGIC;
    
    -- ========== IF/ID PIPELINE REGISTER SIGNALS ==========
    SIGNAL ifid_data_in : pipeline_fetch_decode_t;
    SIGNAL ifid_data_out : pipeline_fetch_decode_t;
    SIGNAL ifid_enable : STD_LOGIC;
    SIGNAL ifid_flush : STD_LOGIC;
    
    -- ========== DECODE STAGE SIGNALS ==========
    SIGNAL decode_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_pushed_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_operand_a : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_operand_b : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_immediate : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_rsrc1 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_rsrc2 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_rd : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);
    
    -- Control signals from decode
    SIGNAL decode_ctrl_out : decode_control_t;
    SIGNAL execute_ctrl_out : execute_control_t;
    SIGNAL memory_ctrl_out : memory_control_t;
    SIGNAL writeback_ctrl_out : writeback_control_t;
    
    -- Instruction type signals from decode
    SIGNAL is_interrupt_de : STD_LOGIC;
    SIGNAL is_hardware_int_de : STD_LOGIC;
    SIGNAL is_call_de : STD_LOGIC;
    SIGNAL is_return_de : STD_LOGIC;
    SIGNAL is_reti_de : STD_LOGIC;
    SIGNAL is_jmp_de : STD_LOGIC;
    SIGNAL is_jmp_conditional_de : STD_LOGIC;
    SIGNAL conditional_type_de : STD_LOGIC_VECTOR(1 DOWNTO 0);
    
    -- ========== CONTROL UNIT SIGNALS ==========
    
    -- Opcode Decoder outputs
    SIGNAL decoder_decode_ctrl : decode_control_t;
    SIGNAL decoder_execute_ctrl : execute_control_t;
    SIGNAL decoder_memory_ctrl : memory_control_t;
    SIGNAL decoder_writeback_ctrl : writeback_control_t;
    
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
    
    -- Branch target placeholders (will be connected to execute/memory stages)
    SIGNAL target_decode : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL target_execute : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL target_memory : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Writeback signals (placeholder - will be connected to WB stage)
    SIGNAL wb_rd : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL wb_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL wb_enable : STD_LOGIC;
    
    -- Temporary signals for stages not yet implemented
    SIGNAL is_swap_ex : STD_LOGIC;
    SIGNAL is_interrupt_ex : STD_LOGIC;
    SIGNAL is_hardware_int_ex : STD_LOGIC;
    SIGNAL is_reti_ex : STD_LOGIC;
    SIGNAL is_hardware_int_mem : STD_LOGIC;
    SIGNAL predicted_taken : STD_LOGIC;
    SIGNAL actual_taken : STD_LOGIC;
    SIGNAL conditional_branch_ex : STD_LOGIC;
    SIGNAL passpc_mem : STD_LOGIC;
    
BEGIN

    -- ========== MEMORY INTERFACE ==========
    -- PC output to memory for instruction fetch
    mem_addr <= fetch_pc;
    mem_read <= '1';  -- Always reading instructions
    mem_write <= '0'; -- Memory writes will be handled by memory stage
    mem_data_out <= (OTHERS => '0'); -- Placeholder
    
    -- Output port (placeholder)
    out_port <= (OTHERS => '0');
    out_port_enable <= '0';
    
    -- ========== FETCH STAGE INSTANTIATION ==========
    fetch_stage_inst : fetch_stage
        PORT MAP (
            clk => clk,
            rst => rst,
            stall => fetch_stall,
            BranchSelect => branch_select,
            BranchTargetSelect => branch_target_select,
            target_decode => target_decode,
            target_execute => target_execute,
            target_memory => target_memory,
            mem_data => mem_data_in,
            pc_out => fetch_pc,
            pushed_pc_out => fetch_pushed_pc,
            instruction_out => fetch_instruction,
            intr_in => intr,
            PushPCSelect => interrupt_push_pc_select
        );
    
    -- Fetch stall control (inverted PC enable from freeze control)
    fetch_stall <= NOT freeze_pc_enable;
    
    -- ========== IF/ID PIPELINE REGISTER DATA ASSEMBLY ==========
    ifid_data_in.take_interrupt <= interrupt_take_interrupt;
    ifid_data_in.override_operation <= interrupt_override_operation;
    ifid_data_in.override_op <= interrupt_override_type;
    ifid_data_in.pc <= fetch_pc;
    ifid_data_in.pushed_pc <= fetch_pushed_pc;
    ifid_data_in.instruction <= fetch_instruction;
    
    -- IF/ID enable and flush control
    ifid_enable <= freeze_ifid_enable;
    ifid_flush <= branch_flush_if OR freeze_insert_nop;
    
    -- ========== IF/ID PIPELINE REGISTER INSTANTIATION ==========
    if_id_reg_inst : if_id_register
        PORT MAP (
            clk => clk,
            rst => rst,
            enable => ifid_enable,
            flush => ifid_flush,
            data_in => ifid_data_in,
            data_out => ifid_data_out
        );
    
    -- ========== OPCODE DECODER INSTANTIATION ==========
    opcode_decoder_inst : opcode_decoder
        PORT MAP (
            opcode => decode_opcode,
            override_operation => ifid_data_out.override_operation,
            override_type => ifid_data_out.override_op,
            isSwap_from_execute => is_swap_ex,
            take_interrupt => ifid_data_out.take_interrupt,
            is_hardware_int_mem => is_hardware_int_mem,
            decode_ctrl => decoder_decode_ctrl,
            execute_ctrl => decoder_execute_ctrl,
            memory_ctrl => decoder_memory_ctrl,
            writeback_ctrl => decoder_writeback_ctrl,
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
        PORT MAP (
            clk => clk,
            rst => rst,
            pc_in => ifid_data_out.pc,
            pushed_pc_in => ifid_data_out.pushed_pc,
            instruction_in => ifid_data_out.instruction,
            take_interrupt_in => ifid_data_out.take_interrupt,
            override_op_in => ifid_data_out.override_op,
            decode_ctrl => decoder_decode_ctrl,
            execute_ctrl => decoder_execute_ctrl,
            memory_ctrl => decoder_memory_ctrl,
            writeback_ctrl => decoder_writeback_ctrl,
            stall_control => '0', -- No stall from branch decision for now
            in_port => in_port,
            immediate_from_fetch => mem_data_in, -- Next cycle fetch data as immediate
            is_swap_ex => is_swap_ex,
            wb_rd => wb_rd,
            wb_data => wb_data,
            wb_enable => wb_enable,
            pc_out => decode_pc,
            pushed_pc_out => decode_pushed_pc,
            operand_a_out => decode_operand_a,
            operand_b_out => decode_operand_b,
            immediate_out => decode_immediate,
            rsrc1_out => decode_rsrc1,
            rsrc2_out => decode_rsrc2,
            rd_out => decode_rd,
            decode_ctrl_out => decode_ctrl_out,
            execute_ctrl_out => execute_ctrl_out,
            memory_ctrl_out => memory_ctrl_out,
            writeback_ctrl_out => writeback_ctrl_out,
            opcode_out => decode_opcode,
            is_interrupt_out => is_interrupt_de,
            is_hardware_int_out => is_hardware_int_de,
            is_call_out => is_call_de,
            is_return_out => is_return_de,
            is_reti_out => is_reti_de,
            is_jmp_out => is_jmp_de,
            is_jmp_conditional_out => is_jmp_conditional_de,
            conditional_type_out => conditional_type_de
        );
    
    -- ========== INTERRUPT UNIT INSTANTIATION ==========
    interrupt_unit_inst : interrupt_unit
        PORT MAP (
            IsInterrupt_DE => is_interrupt_de,
            IsHardwareInt_DE => is_hardware_int_de,
            IsCall_DE => is_call_de,
            IsReturn_DE => is_return_de,
            IsReti_DE => is_reti_de,
            IsInterrupt_EX => is_interrupt_ex,
            IsHardwareInt_EX => is_hardware_int_ex,
            IsReti_EX => is_reti_ex,
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
        PORT MAP (
            IsSoftwareInterrupt => is_interrupt_de AND NOT is_hardware_int_de,
            IsHardwareInterrupt => is_interrupt_de AND is_hardware_int_de,
            UnconditionalBranch => is_jmp_de OR is_call_de,
            ConditionalBranch => conditional_branch_ex,
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
        PORT MAP (
            PassPC_MEM => passpc_mem,
            Stall_Interrupt => interrupt_stall,
            Stall_Branch => branch_stall,
            PC_WriteEnable => freeze_pc_enable,
            IFDE_WriteEnable => freeze_ifid_enable,
            InsertNOP_IFDE => freeze_insert_nop
        );
    
    -- ========== TEMPORARY SIGNAL ASSIGNMENTS ==========
    -- These will be connected when execute/memory/writeback stages are added
    
    -- Branch targets (from decode immediate for now)
    target_decode <= decode_immediate;
    target_execute <= (OTHERS => '0'); -- Placeholder
    target_memory <= (OTHERS => '0');  -- Placeholder
    
    -- Writeback signals (no writeback yet)
    wb_rd <= (OTHERS => '0');
    wb_data <= (OTHERS => '0');
    wb_enable <= '0';
    
    -- Execute stage feedback (not implemented yet)
    is_swap_ex <= '0';
    is_interrupt_ex <= '0';
    is_hardware_int_ex <= '0';
    is_reti_ex <= '0';
    conditional_branch_ex <= '0';
    predicted_taken <= '0';
    actual_taken <= '0';
    
    -- Memory stage feedback
    is_hardware_int_mem <= '0';
    passpc_mem <= '1'; -- No memory hazard for now
    
END ARCHITECTURE Structural;
