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
            ctrl_in : IN decode_ctrl_outputs_t;
            stall_control : IN STD_LOGIC;
            in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            immediate_from_fetch : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            is_swap_ex : IN STD_LOGIC;
            wb_in : IN writeback_outputs_t;
            decode_out : OUT decode_outputs_t;
            ctrl_out : OUT decode_ctrl_outputs_t;
            flags_out : OUT decode_flags_t
        );
    END COMPONENT;

    COMPONENT execute_stage IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            idex_ctrl_in : IN pipeline_decode_excute_ctrl_t;
            idex_data_in : IN pipeline_decode_excute_t;
            forwarding : IN forwarding_ctrl_t;
            Forwarded_EXM : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Forwarded_MWB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            StackFlags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            execute_out : OUT execute_outputs_t;
            ctrl_out : OUT execute_ctrl_outputs_t
        );
    END COMPONENT;

    COMPONENT memory_stage IS
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

    COMPONENT writeback_stage IS
        PORT (
            mem_wb_ctrl : IN pipeline_memory_writeback_ctrl_t;
            mem_wb_data : IN pipeline_memory_writeback_t;
            wb_out : OUT writeback_outputs_t
        );
    END COMPONENT;

    -- ========== PIPELINE REGISTER COMPONENTS ==========

    COMPONENT if_id_register IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            flush : IN STD_LOGIC;
            flush_instruction : IN STD_LOGIC;
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
            is_interrupt_out : OUT STD_LOGIC;
            is_call_out : OUT STD_LOGIC;
            is_return_out : OUT STD_LOGIC;
            is_reti_out : OUT STD_LOGIC;
            is_jmp_out : OUT STD_LOGIC;
            is_jmp_conditional_out : OUT STD_LOGIC;
            is_swap_out : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT interrupt_unit IS
        PORT (
            IsInterrupt_DE : IN STD_LOGIC;
            IsCall_DE : IN STD_LOGIC;
            IsReturn_DE : IN STD_LOGIC;
            IsReti_DE : IN STD_LOGIC;
            IsInterrupt_EX : IN STD_LOGIC;
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

    COMPONENT freeze_control IS
        PORT (
            PassPC_MEM : IN STD_LOGIC;
            Stall_Interrupt : IN STD_LOGIC;
            Stall_Branch : IN STD_LOGIC;
            PC_Freeze : OUT STD_LOGIC;
            IFDE_WriteEnable : OUT STD_LOGIC;
            InsertNOP_IFDE : OUT STD_LOGIC
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