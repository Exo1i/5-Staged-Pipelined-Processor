LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;

ENTITY fetch_decode_top IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Memory Interface
        mem_address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        mem_read : OUT STD_LOGIC;
        mem_write : OUT STD_LOGIC;

        -- External Interrupt
        hardware_interrupt : IN STD_LOGIC;

        -- Input Port
        in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Branch/Jump inputs from Execute Stage
        branch_target_ex : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        actual_branch_taken_ex : IN STD_LOGIC;
        ccr_flags_ex : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Memory Stage inputs
        mem_read_mem : IN STD_LOGIC;
        mem_write_mem : IN STD_LOGIC;
        is_hardware_int_mem : IN STD_LOGIC;

        -- Writeback inputs
        wb_rd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        wb_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wb_enable : IN STD_LOGIC;

        -- Outputs to Execute Stage (via ID/EX register)
        pc_to_ex : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_to_ex : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_a_to_ex : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_b_to_ex : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_to_ex : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc1_to_ex : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rsrc2_to_ex : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_to_ex : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        decode_ctrl_to_ex : OUT decode_control_t;
        execute_ctrl_to_ex : OUT execute_control_t;
        memory_ctrl_to_ex : OUT memory_control_t;
        writeback_ctrl_to_ex : OUT writeback_control_t;

        -- Instruction type outputs for Execute stage feedback
        is_swap_to_ex : OUT STD_LOGIC;
        is_interrupt_to_ex : OUT STD_LOGIC;
        is_hardware_int_to_ex : OUT STD_LOGIC;
        is_reti_to_ex : OUT STD_LOGIC;
        is_return_to_ex : OUT STD_LOGIC;
        is_call_to_ex : OUT STD_LOGIC;
        conditional_branch_to_ex : OUT STD_LOGIC
    );
END ENTITY fetch_decode_top;

ARCHITECTURE Structural OF fetch_decode_top IS

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
            pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            instruction_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            take_interrupt_in : IN STD_LOGIC;
            override_op_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            override_operation_in : IN STD_LOGIC;
            pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            take_interrupt_out : OUT STD_LOGIC;
            override_op_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            override_operation_out : OUT STD_LOGIC
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

    -- ID/EX Pipeline Register
    COMPONENT id_ex_register IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            flush : IN STD_LOGIC;
            pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            operand_a_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            operand_b_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            rsrc1_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            rsrc2_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            rd_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            decode_ctrl_in : IN decode_control_t;
            execute_ctrl_in : IN execute_control_t;
            memory_ctrl_in : IN memory_control_t;
            writeback_ctrl_in : IN writeback_control_t;
            is_swap_in : IN STD_LOGIC;
            is_interrupt_in : IN STD_LOGIC;
            is_hardware_int_in : IN STD_LOGIC;
            is_reti_in : IN STD_LOGIC;
            is_return_in : IN STD_LOGIC;
            is_call_in : IN STD_LOGIC;
            conditional_branch_in : IN STD_LOGIC;
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
            is_swap_out : OUT STD_LOGIC;
            is_interrupt_out : OUT STD_LOGIC;
            is_hardware_int_out : OUT STD_LOGIC;
            is_reti_out : OUT STD_LOGIC;
            is_return_out : OUT STD_LOGIC;
            is_call_out : OUT STD_LOGIC;
            conditional_branch_out : OUT STD_LOGIC
        );
    END COMPONENT;

    -- ========== CONTROL UNIT SUB-COMPONENTS ==========

    -- Opcode Decoder
    COMPONENT opcode_decoder IS
        PORT (
            opcode : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            override_operation : IN STD_LOGIC;
            override_type : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            isSwap_from_execute : IN STD_LOGIC;
            take_interrupt : IN STD_LOGIC;
            is_hardware_int_mem : IN STD_LOGIC;
            decode_ctrl : OUT decode_control_t;
            execute_ctrl : OUT execute_control_t;
            memory_ctrl : OUT memory_control_t;
            writeback_ctrl : OUT writeback_control_t;
            -- Instruction Type Outputs
            is_interrupt_out : OUT STD_LOGIC;
            is_call_out : OUT STD_LOGIC;
            is_return_out : OUT STD_LOGIC;
            is_reti_out : OUT STD_LOGIC;
            is_jmp_out : OUT STD_LOGIC;
            is_jmp_conditional_out : OUT STD_LOGIC;
            is_swap_out : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Memory Hazard Unit
    COMPONENT memory_hazard_unit IS
        PORT (
            MemRead_MEM : IN STD_LOGIC;
            MemWrite_MEM : IN STD_LOGIC;
            PassPC : OUT STD_LOGIC;
            MemRead_Out : OUT STD_LOGIC;
            MemWrite_Out : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Interrupt Unit
    COMPONENT interrupt_unit IS
        PORT (
            IsInterrupt_DE : IN STD_LOGIC;
            IsHardwareInt_DE : IN STD_LOGIC;
            IsCall_DE : IN STD_LOGIC;
            IsReturn_DE : IN STD_LOGIC;
            IsReti_DE : IN STD_LOGIC;
            IsInterrupt_EX : IN STD_LOGIC;
            IsHardwareInt_EX : IN STD_LOGIC;
            IsReti_EX : IN STD_LOGIC;
            IsHardwareInt_MEM : IN STD_LOGIC;
            HardwareInterrupt : IN STD_LOGIC;
            Stall : OUT STD_LOGIC;
            PassPC_NotPCPlus1 : OUT STD_LOGIC;
            TakeInterrupt : OUT STD_LOGIC;
            IsHardwareIntMEM_Out : OUT STD_LOGIC;
            OverrideOperation : OUT STD_LOGIC;
            OverrideType : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
    END COMPONENT;

    -- Freeze Control
    COMPONENT freeze_control IS
        PORT (
            PassPC_MEM : IN STD_LOGIC;
            Stall_Interrupt : IN STD_LOGIC;
            Stall_Branch : IN STD_LOGIC;
            PC_WriteEnable : OUT STD_LOGIC;
            IFDE_WriteEnable : OUT STD_LOGIC;
            InsertNOP_IFDE : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Branch Predictor
    COMPONENT branch_predictor IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            IsJMP : IN STD_LOGIC;
            IsCall : IN STD_LOGIC;
            IsJMPConditional : IN STD_LOGIC;
            ConditionalType : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            PC_DE : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            CCR_Flags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ActualTaken : IN STD_LOGIC;
            UpdatePredictor : IN STD_LOGIC;
            PC_EX : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            PredictedTaken : OUT STD_LOGIC;
            TreatConditionalAsUnconditional : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Branch Decision Unit
    COMPONENT branch_decision_unit IS
        PORT (
            IsSoftwareInterrupt : IN STD_LOGIC;
            IsHardwareInterrupt : IN STD_LOGIC;
            UnconditionalBranch : IN STD_LOGIC;
            ConditionalBranch : IN STD_LOGIC;
            PredictedTaken : IN STD_LOGIC;
            ActualTaken : IN STD_LOGIC;
            Reset : IN STD_LOGIC;
            BranchSelect : OUT STD_LOGIC;
            BranchTargetSelect : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            FlushDE : OUT STD_LOGIC;
            FlushIF : OUT STD_LOGIC;
            Stall_Branch : OUT STD_LOGIC
        );
    END COMPONENT;

    -- ========== INTERNAL SIGNALS ==========

    -- Fetch Stage signals
    SIGNAL fetch_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetch_pushed_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetch_instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL fetch_stall : STD_LOGIC;

    -- IF/ID Register outputs
    SIGNAL ifid_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ifid_pushed_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ifid_instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ifid_take_interrupt : STD_LOGIC;
    SIGNAL ifid_override_op : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ifid_override_operation : STD_LOGIC;

    -- Decode Stage outputs
    SIGNAL decode_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_pushed_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_operand_a : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_operand_b : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_immediate : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL decode_rsrc1 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_rsrc2 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_rd : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL decode_opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL decode_is_interrupt : STD_LOGIC;
    SIGNAL decode_is_hardware_int : STD_LOGIC;
    SIGNAL decode_is_call : STD_LOGIC;
    SIGNAL decode_is_return : STD_LOGIC;
    SIGNAL decode_is_reti : STD_LOGIC;
    SIGNAL decode_is_jmp : STD_LOGIC;
    SIGNAL decode_is_jmp_conditional : STD_LOGIC;
    SIGNAL decode_conditional_type : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL decode_decode_ctrl : decode_control_t;
    SIGNAL decode_execute_ctrl : execute_control_t;
    SIGNAL decode_memory_ctrl : memory_control_t;
    SIGNAL decode_writeback_ctrl : writeback_control_t;

    -- Opcode Decoder outputs
    SIGNAL decoder_decode_ctrl : decode_control_t;
    SIGNAL decoder_execute_ctrl : execute_control_t;
    SIGNAL decoder_memory_ctrl : memory_control_t;
    SIGNAL decoder_writeback_ctrl : writeback_control_t;
    -- Opcode Decoder instruction type outputs (directly from IF/ID instruction)
    SIGNAL decoder_is_interrupt : STD_LOGIC;
    SIGNAL decoder_is_call : STD_LOGIC;
    SIGNAL decoder_is_return : STD_LOGIC;
    SIGNAL decoder_is_reti : STD_LOGIC;
    SIGNAL decoder_is_jmp : STD_LOGIC;
    SIGNAL decoder_is_jmp_conditional : STD_LOGIC;
    SIGNAL decoder_is_swap : STD_LOGIC;
    
    -- Opcode extracted from IF/ID instruction
    SIGNAL ifid_opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);

    -- Memory Hazard Unit signals
    SIGNAL passpc_mem : STD_LOGIC;
    SIGNAL mem_read_out : STD_LOGIC;
    SIGNAL mem_write_out : STD_LOGIC;

    -- Interrupt Unit signals
    SIGNAL stall_interrupt : STD_LOGIC;
    SIGNAL take_interrupt : STD_LOGIC;
    SIGNAL is_hardware_int_mem_out : STD_LOGIC;
    SIGNAL override_operation : STD_LOGIC;
    SIGNAL override_type : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL pass_pc_not_pcplus1 : STD_LOGIC;

    -- Freeze Control signals
    SIGNAL pc_write_enable : STD_LOGIC;
    SIGNAL ifde_write_enable : STD_LOGIC;
    SIGNAL insert_nop_ifde : STD_LOGIC;

    -- Branch Predictor signals
    SIGNAL predicted_taken : STD_LOGIC;
    SIGNAL treat_cond_as_uncond : STD_LOGIC;
    SIGNAL update_predictor : STD_LOGIC;

    -- Branch Decision Unit signals
    SIGNAL stall_branch : STD_LOGIC;
    SIGNAL branch_select : STD_LOGIC;
    SIGNAL branch_target_select : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL flush_de : STD_LOGIC;
    SIGNAL flush_if : STD_LOGIC;

    -- Intermediate control signals
    SIGNAL software_interrupt : STD_LOGIC;
    SIGNAL hardware_interrupt_active : STD_LOGIC;
    SIGNAL unconditional_branch : STD_LOGIC;

    -- Execute stage feedback signals (from ID/EX outputs)
    SIGNAL pc_ex : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL is_swap_ex : STD_LOGIC;
    SIGNAL is_interrupt_ex : STD_LOGIC;
    SIGNAL is_hardware_int_ex : STD_LOGIC;
    SIGNAL is_reti_ex : STD_LOGIC;
    SIGNAL is_return_ex : STD_LOGIC;
    SIGNAL is_call_ex : STD_LOGIC;
    SIGNAL conditional_branch_ex : STD_LOGIC;

BEGIN

    -- ========== FETCH STAGE ==========
    
    fetch_stall <= NOT pc_write_enable;

    fetch_inst : fetch_stage
        PORT MAP (
            clk => clk,
            rst => rst,
            stall => fetch_stall,
            BranchSelect => branch_select,
            BranchTargetSelect => branch_target_select,
            target_decode => decode_immediate,  -- Immediate from decode stage is branch target
            target_execute => branch_target_ex,
            target_memory => (OTHERS => '0'),
            mem_data => mem_data_in,
            pc_out => fetch_pc,
            pushed_pc_out => fetch_pushed_pc,
            instruction_out => fetch_instruction,
            intr_in => hardware_interrupt,
            PushPCSelect => pass_pc_not_pcplus1
        );

    -- ========== IF/ID PIPELINE REGISTER ==========
    
    ifid_reg : if_id_register
        PORT MAP (
            clk => clk,
            rst => rst,
            enable => ifde_write_enable,
            flush => insert_nop_ifde,
            pc_in => fetch_pc,
            pushed_pc_in => fetch_pushed_pc,
            instruction_in => fetch_instruction,
            take_interrupt_in => take_interrupt,
            override_op_in => override_type,
            override_operation_in => override_operation,
            pc_out => ifid_pc,
            pushed_pc_out => ifid_pushed_pc,
            instruction_out => ifid_instruction,
            take_interrupt_out => ifid_take_interrupt,
            override_op_out => ifid_override_op,
            override_operation_out => ifid_override_operation
        );

    -- ========== DECODE STAGE ==========
    
    decode_inst : decode_stage
        PORT MAP (
            clk => clk,
            rst => rst,
            pc_in => ifid_pc,
            pushed_pc_in => ifid_pushed_pc,
            instruction_in => ifid_instruction,
            take_interrupt_in => ifid_take_interrupt,
            override_op_in => ifid_override_op,
            decode_ctrl => decoder_decode_ctrl,
            execute_ctrl => decoder_execute_ctrl,
            memory_ctrl => decoder_memory_ctrl,
            writeback_ctrl => decoder_writeback_ctrl,
            stall_control => stall_branch,
            in_port => in_port,
            immediate_from_fetch => fetch_instruction,
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
            decode_ctrl_out => decode_decode_ctrl,
            execute_ctrl_out => decode_execute_ctrl,
            memory_ctrl_out => decode_memory_ctrl,
            writeback_ctrl_out => decode_writeback_ctrl,
            opcode_out => decode_opcode,
            is_interrupt_out => decode_is_interrupt,
            is_hardware_int_out => decode_is_hardware_int,
            is_call_out => decode_is_call,
            is_return_out => decode_is_return,
            is_reti_out => decode_is_reti,
            is_jmp_out => decode_is_jmp,
            is_jmp_conditional_out => decode_is_jmp_conditional,
            conditional_type_out => decode_conditional_type
        );

    -- ========== CONTROL UNIT SUB-MODULES ==========

    -- Extract opcode from IF/ID instruction for opcode decoder
    ifid_opcode <= ifid_instruction(31 DOWNTO 27);

    -- Opcode Decoder: Generates control signals from IF/ID instruction opcode
    opcode_decoder_inst : opcode_decoder
        PORT MAP (
            opcode => ifid_opcode,
            override_operation => ifid_override_operation,
            override_type => ifid_override_op,
            isSwap_from_execute => is_swap_ex,
            take_interrupt => ifid_take_interrupt,
            is_hardware_int_mem => is_hardware_int_mem_out,
            decode_ctrl => decoder_decode_ctrl,
            execute_ctrl => decoder_execute_ctrl,
            memory_ctrl => decoder_memory_ctrl,
            writeback_ctrl => decoder_writeback_ctrl,
            -- Instruction type outputs
            is_interrupt_out => decoder_is_interrupt,
            is_call_out => decoder_is_call,
            is_return_out => decoder_is_return,
            is_reti_out => decoder_is_reti,
            is_jmp_out => decoder_is_jmp,
            is_jmp_conditional_out => decoder_is_jmp_conditional,
            is_swap_out => decoder_is_swap
        );

    -- Memory Hazard Unit: Handles Von Neumann memory conflicts
    mem_hazard_inst : memory_hazard_unit
        PORT MAP (
            MemRead_MEM => mem_read_mem,
            MemWrite_MEM => mem_write_mem,
            PassPC => passpc_mem,
            MemRead_Out => mem_read_out,
            MemWrite_Out => mem_write_out
        );

    -- Interrupt Unit: Manages interrupts and override operations
    -- Uses opcode decoder outputs for instruction type detection
    interrupt_inst : interrupt_unit
        PORT MAP (
            IsInterrupt_DE => decoder_is_interrupt,
            IsHardwareInt_DE => ifid_take_interrupt,  -- Hardware int from IF/ID register
            IsCall_DE => decoder_is_call,
            IsReturn_DE => decoder_is_return,
            IsReti_DE => decoder_is_reti,
            IsInterrupt_EX => is_interrupt_ex,
            IsHardwareInt_EX => is_hardware_int_ex,
            IsReti_EX => is_reti_ex,
            IsHardwareInt_MEM => is_hardware_int_mem,
            HardwareInterrupt => hardware_interrupt,
            Stall => stall_interrupt,
            PassPC_NotPCPlus1 => pass_pc_not_pcplus1,
            TakeInterrupt => take_interrupt,
            IsHardwareIntMEM_Out => is_hardware_int_mem_out,
            OverrideOperation => override_operation,
            OverrideType => override_type
        );

    -- Freeze Control: Combines stall conditions
    freeze_inst : freeze_control
        PORT MAP (
            PassPC_MEM => passpc_mem,
            Stall_Interrupt => stall_interrupt,
            Stall_Branch => stall_branch,
            PC_WriteEnable => pc_write_enable,
            IFDE_WriteEnable => ifde_write_enable,
            InsertNOP_IFDE => insert_nop_ifde
        );

    -- Branch Predictor: Predicts branch outcomes
    -- Uses opcode decoder outputs for branch instruction detection
    -- ConditionalType comes from Execute stage control signals (via ID/EX register)
    predictor_inst : branch_predictor
        PORT MAP (
            clk => clk,
            rst => rst,
            IsJMP => decoder_is_jmp,
            IsCall => decoder_is_call,
            IsJMPConditional => decoder_is_jmp_conditional,
            ConditionalType => execute_ctrl_to_ex.ConditionalType,  -- From execute control in EX stage
            PC_DE => ifid_pc,  -- PC from IF/ID register (decode stage PC)
            CCR_Flags => ccr_flags_ex,
            ActualTaken => actual_branch_taken_ex,
            UpdatePredictor => update_predictor,
            PC_EX => pc_ex,
            PredictedTaken => predicted_taken,
            TreatConditionalAsUnconditional => treat_cond_as_uncond
        );

    -- Branch Decision Unit: Final branch decisions and flush generation
    branch_decision_inst : branch_decision_unit
        PORT MAP (
            IsSoftwareInterrupt => software_interrupt,
            IsHardwareInterrupt => hardware_interrupt_active,
            UnconditionalBranch => unconditional_branch,
            ConditionalBranch => conditional_branch_ex,
            PredictedTaken => predicted_taken,
            ActualTaken => actual_branch_taken_ex,
            Reset => rst,
            BranchSelect => branch_select,
            BranchTargetSelect => branch_target_select,
            FlushDE => flush_de,
            FlushIF => flush_if,
            Stall_Branch => stall_branch
        );

    -- Control logic signals (use opcode decoder outputs)
    unconditional_branch <= decoder_is_jmp OR decoder_is_call;
    software_interrupt <= decoder_is_interrupt AND NOT ifid_take_interrupt;
    hardware_interrupt_active <= ifid_take_interrupt OR is_hardware_int_ex OR is_hardware_int_mem;
    update_predictor <= conditional_branch_ex;

    -- ========== ID/EX PIPELINE REGISTER ==========
    
    idex_reg : id_ex_register
        PORT MAP (
            clk => clk,
            rst => rst,
            enable => '1',
            flush => flush_de,
            pc_in => decode_pc,
            pushed_pc_in => decode_pushed_pc,
            operand_a_in => decode_operand_a,
            operand_b_in => decode_operand_b,
            immediate_in => decode_immediate,
            rsrc1_in => decode_rsrc1,
            rsrc2_in => decode_rsrc2,
            rd_in => decode_rd,
            decode_ctrl_in => decode_decode_ctrl,
            execute_ctrl_in => decode_execute_ctrl,
            memory_ctrl_in => decode_memory_ctrl,
            writeback_ctrl_in => decode_writeback_ctrl,
            is_swap_in => decoder_is_swap,
            is_interrupt_in => decoder_is_interrupt,
            is_hardware_int_in => ifid_take_interrupt,
            is_reti_in => decoder_is_reti,
            is_return_in => decoder_is_return,
            is_call_in => decoder_is_call,
            conditional_branch_in => decoder_is_jmp_conditional,
            pc_out => pc_to_ex,
            pushed_pc_out => pushed_pc_to_ex,
            operand_a_out => operand_a_to_ex,
            operand_b_out => operand_b_to_ex,
            immediate_out => immediate_to_ex,
            rsrc1_out => rsrc1_to_ex,
            rsrc2_out => rsrc2_to_ex,
            rd_out => rd_to_ex,
            decode_ctrl_out => decode_ctrl_to_ex,
            execute_ctrl_out => execute_ctrl_to_ex,
            memory_ctrl_out => memory_ctrl_to_ex,
            writeback_ctrl_out => writeback_ctrl_to_ex,
            is_swap_out => is_swap_to_ex,
            is_interrupt_out => is_interrupt_to_ex,
            is_hardware_int_out => is_hardware_int_to_ex,
            is_reti_out => is_reti_to_ex,
            is_return_out => is_return_to_ex,
            is_call_out => is_call_to_ex,
            conditional_branch_out => conditional_branch_to_ex
        );

    -- ========== FEEDBACK SIGNALS ==========
    -- Connect ID/EX outputs back for control unit feedback
    
    pc_ex <= pc_to_ex;
    is_swap_ex <= is_swap_to_ex;
    is_interrupt_ex <= is_interrupt_to_ex;
    is_hardware_int_ex <= is_hardware_int_to_ex;
    is_reti_ex <= is_reti_to_ex;
    is_return_ex <= is_return_to_ex;
    is_call_ex <= is_call_to_ex;
    conditional_branch_ex <= conditional_branch_to_ex;

    -- ========== MEMORY INTERFACE CONTROL ==========
    
    mem_address <= fetch_pc;
    mem_read <= mem_read_out WHEN passpc_mem = '0' ELSE '1';
    mem_write <= mem_write_out;

END ARCHITECTURE Structural;
