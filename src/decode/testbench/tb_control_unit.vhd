library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;
use work.control_signals_pkg.all;

entity tb_control_unit is
end tb_control_unit;

architecture Behavioral of tb_control_unit is
    
    -- Component declaration
    component control_unit is
        Port (
            clk                     : in  std_logic;
            rst                     : in  std_logic;
            opcode_DE               : in  std_logic_vector(4 downto 0);
            PC_DE                   : in  std_logic_vector(31 downto 0);
            IsInterrupt_DE          : in  std_logic;
            IsHardwareInt_DE        : in  std_logic;
            IsCall_DE               : in  std_logic;
            IsReturn_DE             : in  std_logic;
            IsReti_DE               : in  std_logic;
            IsJMP_DE                : in  std_logic;
            IsJMPConditional_DE     : in  std_logic;
            ConditionalType_DE      : in  std_logic_vector(1 downto 0);
            PC_EX                   : in  std_logic_vector(31 downto 0);
            CCR_Flags_EX            : in  std_logic_vector(2 downto 0);
            IsSwap_EX               : in  std_logic;
            ActualBranchTaken_EX    : in  std_logic;
            ConditionalBranch_EX    : in  std_logic;
            IsInterrupt_EX          : in  std_logic;
            IsHardwareInt_EX        : in  std_logic;
            IsReti_EX               : in  std_logic;
            MemRead_MEM             : in  std_logic;
            MemWrite_MEM            : in  std_logic;
            IsHardwareInt_MEM       : in  std_logic;
            HardwareInterrupt       : in  std_logic;
            decode_ctrl_out         : out decode_control_t;
            execute_ctrl_out        : out execute_control_t;
            memory_ctrl_out         : out memory_control_t;
            writeback_ctrl_out      : out writeback_control_t;
            PC_WriteEnable          : out std_logic;
            IFDE_WriteEnable        : out std_logic;
            InsertNOP_IFDE          : out std_logic;
            FlushDE                 : out std_logic;
            FlushIF                 : out std_logic;
            PassPC_ToMem            : out std_logic;
            MemRead_Out             : out std_logic;
            MemWrite_Out            : out std_logic;
            BranchSelect            : out std_logic;
            BranchTargetSelect      : out std_logic_vector(1 downto 0);
            PassPC_NotPCPlus1       : out std_logic;
            TakeInterrupt_ToIFDE    : out std_logic
        );
    end component;
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals
    signal clk                     : std_logic := '0';
    signal rst                     : std_logic := '0';
    signal opcode_DE               : std_logic_vector(4 downto 0) := (others => '0');
    signal PC_DE                   : std_logic_vector(31 downto 0) := (others => '0');
    signal IsInterrupt_DE          : std_logic := '0';
    signal IsHardwareInt_DE        : std_logic := '0';
    signal IsCall_DE               : std_logic := '0';
    signal IsReturn_DE             : std_logic := '0';
    signal IsReti_DE               : std_logic := '0';
    signal IsJMP_DE                : std_logic := '0';
    signal IsJMPConditional_DE     : std_logic := '0';
    signal ConditionalType_DE      : std_logic_vector(1 downto 0) := (others => '0');
    signal PC_EX                   : std_logic_vector(31 downto 0) := (others => '0');
    signal CCR_Flags_EX            : std_logic_vector(2 downto 0) := (others => '0');
    signal IsSwap_EX               : std_logic := '0';
    signal ActualBranchTaken_EX    : std_logic := '0';
    signal ConditionalBranch_EX    : std_logic := '0';
    signal IsInterrupt_EX          : std_logic := '0';
    signal IsHardwareInt_EX        : std_logic := '0';
    signal IsReti_EX               : std_logic := '0';
    signal MemRead_MEM             : std_logic := '0';
    signal MemWrite_MEM            : std_logic := '0';
    signal IsHardwareInt_MEM       : std_logic := '0';
    signal HardwareInterrupt       : std_logic := '0';
    
    -- Outputs
    signal decode_ctrl_out         : decode_control_t;
    signal execute_ctrl_out        : execute_control_t;
    signal memory_ctrl_out         : memory_control_t;
    signal writeback_ctrl_out      : writeback_control_t;
    signal PC_WriteEnable          : std_logic;
    signal IFDE_WriteEnable        : std_logic;
    signal InsertNOP_IFDE          : std_logic;
    signal FlushDE                 : std_logic;
    signal FlushIF                 : std_logic;
    signal PassPC_ToMem            : std_logic;
    signal MemRead_Out             : std_logic;
    signal MemWrite_Out            : std_logic;
    signal BranchSelect            : std_logic;
    signal BranchTargetSelect      : std_logic_vector(1 downto 0);
    signal PassPC_NotPCPlus1       : std_logic;
    signal TakeInterrupt_ToIFDE    : std_logic;
    
begin
    
    -- Instantiate control unit
    uut : control_unit
        port map (
            clk                     => clk,
            rst                     => rst,
            opcode_DE               => opcode_DE,
            PC_DE                   => PC_DE,
            IsInterrupt_DE          => IsInterrupt_DE,
            IsHardwareInt_DE        => IsHardwareInt_DE,
            IsCall_DE               => IsCall_DE,
            IsReturn_DE             => IsReturn_DE,
            IsReti_DE               => IsReti_DE,
            IsJMP_DE                => IsJMP_DE,
            IsJMPConditional_DE     => IsJMPConditional_DE,
            ConditionalType_DE      => ConditionalType_DE,
            PC_EX                   => PC_EX,
            CCR_Flags_EX            => CCR_Flags_EX,
            IsSwap_EX               => IsSwap_EX,
            ActualBranchTaken_EX    => ActualBranchTaken_EX,
            ConditionalBranch_EX    => ConditionalBranch_EX,
            IsInterrupt_EX          => IsInterrupt_EX,
            IsHardwareInt_EX        => IsHardwareInt_EX,
            IsReti_EX               => IsReti_EX,
            MemRead_MEM             => MemRead_MEM,
            MemWrite_MEM            => MemWrite_MEM,
            IsHardwareInt_MEM       => IsHardwareInt_MEM,
            HardwareInterrupt       => HardwareInterrupt,
            decode_ctrl_out         => decode_ctrl_out,
            execute_ctrl_out        => execute_ctrl_out,
            memory_ctrl_out         => memory_ctrl_out,
            writeback_ctrl_out      => writeback_ctrl_out,
            PC_WriteEnable          => PC_WriteEnable,
            IFDE_WriteEnable        => IFDE_WriteEnable,
            InsertNOP_IFDE          => InsertNOP_IFDE,
            FlushDE                 => FlushDE,
            FlushIF                 => FlushIF,
            PassPC_ToMem            => PassPC_ToMem,
            MemRead_Out             => MemRead_Out,
            MemWrite_Out            => MemWrite_Out,
            BranchSelect            => BranchSelect,
            BranchTargetSelect      => BranchTargetSelect,
            PassPC_NotPCPlus1       => PassPC_NotPCPlus1,
            TakeInterrupt_ToIFDE    => TakeInterrupt_ToIFDE
        );
    
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Stimulus process
    stim_process : process
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 1: Normal ADD instruction ===";
        opcode_DE <= OP_ADD;
        wait for CLK_PERIOD;
        assert execute_ctrl_out.ALU_Operation = ALU_ADD 
            report "ADD should select ALU_ADD" severity error;
        assert writeback_ctrl_out.RegWrite = '1' 
            report "ADD should enable RegWrite" severity error;
        assert PC_WriteEnable = '1' 
            report "Normal operation should allow PC update" severity error;
        
        report "=== Test 2: Memory conflict - LDD in memory stage ===";
        opcode_DE <= OP_NOP;
        MemRead_MEM <= '1';
        wait for CLK_PERIOD;
        assert PassPC_ToMem = '0' 
            report "Memory conflict should block fetch" severity error;
        assert PC_WriteEnable = '0' 
            report "Memory conflict should freeze PC" severity error;
        assert InsertNOP_IFDE = '1' 
            report "Memory conflict should insert NOP" severity error;
        MemRead_MEM <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 3: Unconditional branch (JMP) ===";
        opcode_DE <= OP_JMP;
        IsJMP_DE <= '1';
        wait for CLK_PERIOD;
        assert BranchSelect = '1' 
            report "JMP should select branch" severity error;
        assert FlushDE = '1' and FlushIF = '1' 
            report "JMP should flush IF and DE" severity error;
        assert BranchTargetSelect = "00" 
            report "JMP should use decode stage target" severity error;
        IsJMP_DE <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 4: Software interrupt (INT) ===";
        opcode_DE <= OP_INT;
        IsInterrupt_DE <= '1';
        IsHardwareInt_DE <= '0';
        wait for CLK_PERIOD;
        assert memory_ctrl_out.PassInterrupt = PASS_INT_SOFTWARE 
            report "INT should set PassInterrupt to SOFTWARE" severity error;
        assert PC_WriteEnable = '0' 
            report "INT should stall PC" severity error;
        wait for CLK_PERIOD;
        -- Simulate interrupt in execute stage
        IsInterrupt_DE <= '0';
        IsInterrupt_EX <= '1';
        wait for CLK_PERIOD;
        IsInterrupt_EX <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 5: Hardware interrupt ===";
        HardwareInterrupt <= '1';
        wait for CLK_PERIOD;
        assert TakeInterrupt_ToIFDE = '1' 
            report "Hardware interrupt should set TakeInterrupt" severity error;
        assert PassPC_NotPCPlus1 = '1' 
            report "Hardware interrupt should save current PC" severity error;
        HardwareInterrupt <= '0';
        wait for CLK_PERIOD;
        -- Simulate hardware interrupt propagating through pipeline
        IsHardwareInt_DE <= '1';
        wait for CLK_PERIOD;
        IsHardwareInt_DE <= '0';
        IsHardwareInt_EX <= '1';
        wait for CLK_PERIOD;
        IsHardwareInt_EX <= '0';
        IsHardwareInt_MEM <= '1';
        wait for CLK_PERIOD;
        assert memory_ctrl_out.PassInterrupt = PASS_INT_HARDWARE 
            report "Hardware interrupt should set PassInterrupt to HARDWARE" severity error;
        IsHardwareInt_MEM <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 6: SWAP instruction (two-cycle) ===";
        opcode_DE <= OP_SWAP;
        wait for CLK_PERIOD;
        assert decode_ctrl_out.IsSwap = '1' 
            report "SWAP should set IsSwap" severity error;
        -- Simulate SWAP in execute stage
        IsSwap_EX <= '1';
        wait for CLK_PERIOD;
        -- Second cycle should be MOV
        assert decode_ctrl_out.OutBSelect = OUTB_SWAPPED 
            report "SWAP second cycle should use swapped value" severity error;
        IsSwap_EX <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 7: Conditional branch prediction ===";
        opcode_DE <= OP_JZ;
        IsJMPConditional_DE <= '1';
        ConditionalType_DE <= COND_ZERO;
        PC_DE <= x"00000100";
        wait for CLK_PERIOD;
        -- Initial prediction should be weakly not taken
        -- Simulate branch taken in execute
        ConditionalBranch_EX <= '1';
        ActualBranchTaken_EX <= '1';
        CCR_Flags_EX <= "100";  -- Z flag set
        PC_EX <= x"00000100";
        wait for CLK_PERIOD * 2;
        -- Branch predictor should update
        ConditionalBranch_EX <= '0';
        IsJMPConditional_DE <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 8: Branch misprediction ===";
        opcode_DE <= OP_JN;
        IsJMPConditional_DE <= '1';
        ConditionalType_DE <= COND_NEGATIVE;
        wait for CLK_PERIOD;
        -- Predictor predicts not taken, but actual is taken
        ConditionalBranch_EX <= '1';
        ActualBranchTaken_EX <= '1';
        CCR_Flags_EX <= "010";  -- N flag set
        wait for CLK_PERIOD;
        assert FlushDE = '1' and FlushIF = '1' 
            report "Misprediction should flush pipeline" severity error;
        ConditionalBranch_EX <= '0';
        IsJMPConditional_DE <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 9: CALL instruction ===";
        opcode_DE <= OP_CALL;
        IsCall_DE <= '1';
        wait for CLK_PERIOD;
        assert memory_ctrl_out.SP_Enable = '1' 
            report "CALL should enable SP" severity error;
        assert memory_ctrl_out.SP_Function = '0' 
            report "CALL should decrement SP" severity error;
        assert memory_ctrl_out.MemWrite = '1' 
            report "CALL should write to memory" severity error;
        IsCall_DE <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 10: RTI instruction (two pops) ===";
        opcode_DE <= OP_RTI;
        IsReti_DE <= '1';
        wait for CLK_PERIOD;
        -- First pop: FLAGS
        assert memory_ctrl_out.SP_Enable = '1' 
            report "RTI first cycle should enable SP" severity error;
        assert memory_ctrl_out.MemRead = '1' 
            report "RTI first cycle should read memory" severity error;
        IsReti_DE <= '0';
        IsReti_EX <= '1';
        wait for CLK_PERIOD;
        -- Second pop: PC
        IsReti_EX <= '0';
        wait for CLK_PERIOD;
        
        report "=== Test 11: Priority - Reset overrides everything ===";
        rst <= '1';
        HardwareInterrupt <= '1';
        IsInterrupt_DE <= '1';
        IsJMP_DE <= '1';
        wait for CLK_PERIOD;
        assert BranchTargetSelect = "11" 
            report "Reset should have highest priority" severity error;
        rst <= '0';
        HardwareInterrupt <= '0';
        IsInterrupt_DE <= '0';
        IsJMP_DE <= '0';
        wait for CLK_PERIOD;
        
        report "=== All tests completed successfully! ===";
        wait;
    end process;

end Behavioral;
