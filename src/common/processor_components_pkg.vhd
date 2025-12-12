LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

-- =====================================================================
-- Package: processor_components_pkg
-- Purpose: Component declarations for all processor modules
-- Benefit: Removes 300+ lines from processor_top.vhd
-- =====================================================================

PACKAGE processor_components_pkg IS

    -- ========== PIPELINE STAGE COMPONENTS ==========
    
    COMPONENT fetch_stage IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            stall : IN STD_LOGIC;
            BranchSelect : IN STD_LOGIC;
            BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            branch_targets : IN branch_targets_t;
            mem_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            fetch_out : OUT fetch_outputs_t;
            intr_in : IN STD_LOGIC;
            PushPCSelect : IN STD_LOGIC
        );
    END COMPONENT;
    
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
    
    COMPONENT execute_stage IS
        PORT (
            clk   : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            WB_RegWrite_in  : IN STD_LOGIC;
            WB_MemToReg_in  : IN STD_LOGIC;
            M_MemRead_in    : IN STD_LOGIC;
            M_MemWrite_in   : IN STD_LOGIC;
            M_SpToMem_in    : IN STD_LOGIC;
            M_PassInterrupt_in : IN STD_LOGIC;
            EX_ALU_Op       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            EX_PassImm      : IN STD_LOGIC;
            EX_CCRWrEn      : IN STD_LOGIC;
            EX_IsReturn     : IN STD_LOGIC;
            EX_PassCCR      : IN STD_LOGIC;
            OutA            : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            OutB            : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Immediate       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            PC_in           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Rsrc1           : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rsrc2           : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rdst1_in        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ForwardA        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            ForwardB        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            Forwarded_EXM   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Forwarded_MWB   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            StackFlags      : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            WB_RegWrite_out : OUT STD_LOGIC;
            WB_MemToReg_out : OUT STD_LOGIC;
            M_MemRead_out   : OUT STD_LOGIC;
            M_MemWrite_out  : OUT STD_LOGIC;
            M_SpToMem_out   : OUT STD_LOGIC;
            M_PassInterrupt_out : OUT STD_LOGIC;
            ALU_Result_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Primary_Data    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Secondary_Data  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Rdst1_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            CCR_Flags       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT MemoryStage IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            ex_mem_ctrl_in : IN pipeline_execute_memory_ctrl_t;
            ex_mem_data_in : IN pipeline_execute_memory_t;
            mem_wb_data_out : OUT pipeline_memory_writeback_t;
            mem_wb_ctrl_out : OUT pipeline_memory_writeback_ctrl_t;
            MemReadData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            MemRead : OUT STD_LOGIC;
            MemWrite : OUT STD_LOGIC;
            MemAddress : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
            MemWriteData : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT WritebackStage IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            mem_wb_ctrl : IN pipeline_memory_writeback_ctrl_t;
            mem_wb_data : IN pipeline_memory_writeback_t;
            PortEnable : OUT STD_LOGIC;
            RegWE : OUT STD_LOGIC;
            Data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            RdstOut : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;
    
    -- ========== PIPELINE REGISTER COMPONENTS ==========
    
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
    
    COMPONENT id_ex_register IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            flush : IN STD_LOGIC;
            data_in : IN pipeline_decode_excute_t;
            ctrl_in : IN pipeline_decode_excute_ctrl_t;
            data_out : OUT pipeline_decode_excute_t;
            ctrl_out : OUT pipeline_decode_excute_ctrl_t
        );
    END COMPONENT;
    
    COMPONENT ex_mem_register IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            flush : IN STD_LOGIC;
            data_in : IN pipeline_execute_memory_t;
            ctrl_in : IN pipeline_execute_memory_ctrl_t;
            data_out : OUT pipeline_execute_memory_t;
            ctrl_out : OUT pipeline_execute_memory_ctrl_t
        );
    END COMPONENT;
    
    COMPONENT mem_wb_register IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            flush : IN STD_LOGIC;
            data_in : IN pipeline_memory_writeback_t;
            ctrl_in : IN pipeline_memory_writeback_ctrl_t;
            data_out : OUT pipeline_memory_writeback_t;
            ctrl_out : OUT pipeline_memory_writeback_ctrl_t
        );
    END COMPONENT;
    
    -- ========== CONTROL UNIT COMPONENTS ==========
    
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
    
    COMPONENT forwarding_unit IS
        PORT (
            MemRegWrite : IN STD_LOGIC;
            MemRdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            MemIsSwap : IN STD_LOGIC;
            WBRegWrite : IN STD_LOGIC;
            WBRdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rsrc1 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rsrc2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ForwardA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            ForwardB : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
    END COMPONENT;

END PACKAGE processor_components_pkg;
