library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;
use work.control_signals_pkg.all;

entity control_unit is
    Port (
        -- Clock and Reset
        clk                     : in  std_logic;
        rst                     : in  std_logic;
        
        -- ========== DECODE STAGE INPUTS ==========
        opcode_DE               : in  std_logic_vector(4 downto 0);   -- Opcode from instruction
        PC_DE                   : in  std_logic_vector(31 downto 0);  -- PC in decode stage
        
        -- Decode stage signals (from decode_ctrl)
        IsInterrupt_DE          : in  std_logic;                      -- Software/Hardware interrupt
        IsHardwareInt_DE        : in  std_logic;                      -- Hardware interrupt flag
        IsCall_DE               : in  std_logic;                      -- CALL instruction
        IsReturn_DE             : in  std_logic;                      -- RET instruction
        IsReti_DE               : in  std_logic;                      -- RTI instruction
        IsJMP_DE                : in  std_logic;                      -- Unconditional jump
        IsJMPConditional_DE     : in  std_logic;                      -- Conditional jump
        ConditionalType_DE      : in  std_logic_vector(1 downto 0);   -- Condition type
        
        -- ========== EXECUTE STAGE INPUTS ==========
        PC_EX                   : in  std_logic_vector(31 downto 0);  -- PC in execute stage
        CCR_Flags_EX            : in  std_logic_vector(2 downto 0);   -- CCR flags (Z, N, C)
        IsSwap_EX               : in  std_logic;                      -- SWAP in execute (feedback)
        ActualBranchTaken_EX    : in  std_logic;                      -- Actual branch outcome
        ConditionalBranch_EX    : in  std_logic;                      -- Conditional branch in execute
        
        -- Pipeline register signals in execute stage
        IsInterrupt_EX          : in  std_logic;                      -- Interrupt in execute
        IsHardwareInt_EX        : in  std_logic;                      -- Hardware interrupt in execute
        IsReti_EX               : in  std_logic;                      -- RTI in execute
        
        -- ========== MEMORY STAGE INPUTS ==========
        MemRead_MEM             : in  std_logic;                      -- Memory read request
        MemWrite_MEM            : in  std_logic;                      -- Memory write request
        IsHardwareInt_MEM       : in  std_logic;                      -- Hardware interrupt in memory
        
        -- ========== EXTERNAL INPUTS ==========
        HardwareInterrupt       : in  std_logic;                      -- External hardware interrupt
        
        -- ========== OUTPUTS TO PIPELINE ==========
        -- Control signals to pipeline stages
        decode_ctrl_out         : out decode_control_t;               -- Decode stage controls
        execute_ctrl_out        : out execute_control_t;              -- Execute stage controls
        memory_ctrl_out         : out memory_control_t;               -- Memory stage controls
        writeback_ctrl_out      : out writeback_control_t;            -- Writeback stage controls
        
        -- Pipeline control signals
        PC_WriteEnable          : out std_logic;                      -- Enable PC update
        IFDE_WriteEnable        : out std_logic;                      -- Enable IF/DE register
        InsertNOP_IFDE          : out std_logic;                      -- Insert NOP in IF/DE
        FlushDE                 : out std_logic;                      -- Flush DE stage
        FlushIF                 : out std_logic;                      -- Flush IF stage
        
        -- Memory access control
        PassPC_ToMem            : out std_logic;                      -- Allow fetch to access memory
        MemRead_Out             : out std_logic;                      -- Actual memory read
        MemWrite_Out            : out std_logic;                      -- Actual memory write
        
        -- Branch control outputs
        BranchSelect            : out std_logic;                      -- Branch or PC+1
        BranchTargetSelect      : out std_logic_vector(1 downto 0);  -- Branch target source
        
        -- Interrupt handling
        PassPC_NotPCPlus1       : out std_logic;                      -- Pass current PC (for HW int)
        TakeInterrupt_ToIFDE    : out std_logic                       -- Signal IF/DE to take interrupt
    );
end control_unit;

architecture Behavioral of control_unit is
    
    -- Component declarations
    component opcode_decoder is
        Port (
            opcode              : in  std_logic_vector(4 downto 0);
            override_operation  : in  std_logic;
            override_type       : in  std_logic_vector(1 downto 0);
            isSwap_from_execute : in  std_logic;
            take_interrupt      : in  std_logic;
            is_hardware_int_mem : in  std_logic;
            decode_ctrl         : out decode_control_t;
            execute_ctrl        : out execute_control_t;
            memory_ctrl         : out memory_control_t;
            writeback_ctrl      : out writeback_control_t
        );
    end component;
    
    component memory_hazard_unit is
        Port (
            MemRead_MEM         : in  std_logic;
            MemWrite_MEM        : in  std_logic;
            PassPC              : out std_logic;
            MemRead_Out         : out std_logic;
            MemWrite_Out        : out std_logic
        );
    end component;
    
    component interrupt_unit is
        Port (
            IsInterrupt_DE      : in  std_logic;
            IsHardwareInt_DE    : in  std_logic;
            IsCall_DE           : in  std_logic;
            IsReturn_DE         : in  std_logic;
            IsReti_DE           : in  std_logic;
            IsInterrupt_EX      : in  std_logic;
            IsHardwareInt_EX    : in  std_logic;
            IsReti_EX           : in  std_logic;
            IsHardwareInt_MEM   : in  std_logic;
            HardwareInterrupt   : in  std_logic;
            Stall               : out std_logic;
            PassPC_NotPCPlus1   : out std_logic;
            TakeInterrupt       : out std_logic;
            IsHardwareIntMEM_Out: out std_logic;
            OverrideOperation   : out std_logic;
            OverrideType        : out std_logic_vector(1 downto 0)
        );
    end component;
    
    component freeze_control is
        Port (
            PassPC_MEM          : in  std_logic;
            Stall_Interrupt     : in  std_logic;
            Stall_Branch        : in  std_logic;
            PC_WriteEnable      : out std_logic;
            IFDE_WriteEnable    : out std_logic;
            InsertNOP_IFDE      : out std_logic
        );
    end component;
    
    component branch_predictor is
        Port (
            clk                     : in  std_logic;
            rst                     : in  std_logic;
            IsJMP                   : in  std_logic;
            IsCall                  : in  std_logic;
            IsJMPConditional        : in  std_logic;
            ConditionalType         : in  std_logic_vector(1 downto 0);
            PC_DE                   : in  std_logic_vector(31 downto 0);
            CCR_Flags               : in  std_logic_vector(2 downto 0);
            ActualTaken             : in  std_logic;
            UpdatePredictor         : in  std_logic;
            PC_EX                   : in  std_logic_vector(31 downto 0);
            PredictedTaken          : out std_logic;
            TreatConditionalAsUnconditional : out std_logic
        );
    end component;
    
    component branch_decision_unit is
        Port (
            IsSoftwareInterrupt     : in  std_logic;
            IsHardwareInterrupt     : in  std_logic;
            UnconditionalBranch     : in  std_logic;
            ConditionalBranch       : in  std_logic;
            PredictedTaken          : in  std_logic;
            ActualTaken             : in  std_logic;
            Reset                   : in  std_logic;
            BranchSelect            : out std_logic;
            BranchTargetSelect      : out std_logic_vector(1 downto 0);
            FlushDE                 : out std_logic;
            FlushIF                 : out std_logic;
            Stall_Branch            : out std_logic
        );
    end component;
    
    -- Internal signals connecting sub-modules
    
    -- From Opcode Decoder
    signal decoder_decode_ctrl      : decode_control_t;
    signal decoder_execute_ctrl     : execute_control_t;
    signal decoder_memory_ctrl      : memory_control_t;
    signal decoder_writeback_ctrl   : writeback_control_t;
    
    -- From Memory Hazard Unit
    signal passpc_mem               : std_logic;
    
    -- From Interrupt Unit
    signal stall_interrupt          : std_logic;
    signal take_interrupt           : std_logic;
    signal is_hardware_int_mem_out  : std_logic;
    signal override_operation       : std_logic;
    signal override_type            : std_logic_vector(1 downto 0);
    
    -- From Branch Predictor
    signal predicted_taken          : std_logic;
    signal treat_cond_as_uncond     : std_logic;
    signal update_predictor         : std_logic;
    
    -- From Branch Decision Unit
    signal stall_branch             : std_logic;
    signal unconditional_branch     : std_logic;
    
    -- Intermediate signals
    signal software_interrupt       : std_logic;
    signal hardware_interrupt_active: std_logic;
    
begin
    
    -- ========== SUB-MODULE INSTANTIATIONS ==========
    
    -- Opcode Decoder: Central control signal generator
    decoder_inst : opcode_decoder
        port map (
            opcode              => opcode_DE,
            override_operation  => override_operation,
            override_type       => override_type,
            isSwap_from_execute => IsSwap_EX,
            take_interrupt      => take_interrupt,
            is_hardware_int_mem => is_hardware_int_mem_out,
            decode_ctrl         => decoder_decode_ctrl,
            execute_ctrl        => decoder_execute_ctrl,
            memory_ctrl         => decoder_memory_ctrl,
            writeback_ctrl      => decoder_writeback_ctrl
        );
    
    -- Memory Hazard Unit: Handle Von Neumann architecture conflicts
    mem_hazard_inst : memory_hazard_unit
        port map (
            MemRead_MEM         => MemRead_MEM,
            MemWrite_MEM        => MemWrite_MEM,
            PassPC              => passpc_mem,
            MemRead_Out         => MemRead_Out,
            MemWrite_Out        => MemWrite_Out
        );
    
    -- Interrupt Unit: Manage interrupts and generate overrides
    interrupt_inst : interrupt_unit
        port map (
            IsInterrupt_DE      => IsInterrupt_DE,
            IsHardwareInt_DE    => IsHardwareInt_DE,
            IsCall_DE           => IsCall_DE,
            IsReturn_DE         => IsReturn_DE,
            IsReti_DE           => IsReti_DE,
            IsInterrupt_EX      => IsInterrupt_EX,
            IsHardwareInt_EX    => IsHardwareInt_EX,
            IsReti_EX           => IsReti_EX,
            IsHardwareInt_MEM   => IsHardwareInt_MEM,
            HardwareInterrupt   => HardwareInterrupt,
            Stall               => stall_interrupt,
            PassPC_NotPCPlus1   => PassPC_NotPCPlus1,
            TakeInterrupt       => take_interrupt,
            IsHardwareIntMEM_Out=> is_hardware_int_mem_out,
            OverrideOperation   => override_operation,
            OverrideType        => override_type
        );
    
    -- Freeze Control: Combine stall conditions
    freeze_inst : freeze_control
        port map (
            PassPC_MEM          => passpc_mem,
            Stall_Interrupt     => stall_interrupt,
            Stall_Branch        => stall_branch,
            PC_WriteEnable      => PC_WriteEnable,
            IFDE_WriteEnable    => IFDE_WriteEnable,
            InsertNOP_IFDE      => InsertNOP_IFDE
        );
    
    -- Branch Predictor: Predict branch outcomes
    predictor_inst : branch_predictor
        port map (
            clk                     => clk,
            rst                     => rst,
            IsJMP                   => IsJMP_DE,
            IsCall                  => IsCall_DE,
            IsJMPConditional        => IsJMPConditional_DE,
            ConditionalType         => ConditionalType_DE,
            PC_DE                   => PC_DE,
            CCR_Flags               => CCR_Flags_EX,
            ActualTaken             => ActualBranchTaken_EX,
            UpdatePredictor         => update_predictor,
            PC_EX                   => PC_EX,
            PredictedTaken          => predicted_taken,
            TreatConditionalAsUnconditional => treat_cond_as_uncond
        );
    
    -- Branch Decision Unit: Final branch decision and flush generation
    branch_decision_inst : branch_decision_unit
        port map (
            IsSoftwareInterrupt     => software_interrupt,
            IsHardwareInterrupt     => hardware_interrupt_active,
            UnconditionalBranch     => unconditional_branch,
            ConditionalBranch       => ConditionalBranch_EX,
            PredictedTaken          => predicted_taken,
            ActualTaken             => ActualBranchTaken_EX,
            Reset                   => rst,
            BranchSelect            => BranchSelect,
            BranchTargetSelect      => BranchTargetSelect,
            FlushDE                 => FlushDE,
            FlushIF                 => FlushIF,
            Stall_Branch            => stall_branch
        );
    
    -- ========== SIGNAL ROUTING AND LOGIC ==========
    
    -- Output decoded control signals
    decode_ctrl_out     <= decoder_decode_ctrl;
    execute_ctrl_out    <= decoder_execute_ctrl;
    memory_ctrl_out     <= decoder_memory_ctrl;
    writeback_ctrl_out  <= decoder_writeback_ctrl;
    
    -- Memory access control
    PassPC_ToMem        <= passpc_mem;
    
    -- Interrupt handling
    TakeInterrupt_ToIFDE <= take_interrupt;
    
    -- Branch control signals
    unconditional_branch    <= IsJMP_DE or IsCall_DE;
    software_interrupt      <= IsInterrupt_DE and not IsHardwareInt_DE;
    hardware_interrupt_active <= IsHardwareInt_DE or IsHardwareInt_EX or IsHardwareInt_MEM;
    
    -- Branch predictor update logic
    -- Update predictor when a conditional branch is resolved in execute stage
    update_predictor <= ConditionalBranch_EX;
    
end Behavioral;
