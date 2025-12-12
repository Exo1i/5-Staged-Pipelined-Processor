LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;

ENTITY tb_control_unit IS
END tb_control_unit;

ARCHITECTURE Behavioral OF tb_control_unit IS

    -- Component declaration
    COMPONENT control_unit IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            opcode_DE : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            PC_DE : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            IsInterrupt_DE : IN STD_LOGIC;
            IsHardwareInt_DE : IN STD_LOGIC;
            IsCall_DE : IN STD_LOGIC;
            IsReturn_DE : IN STD_LOGIC;
            IsReti_DE : IN STD_LOGIC;
            IsJMP_DE : IN STD_LOGIC;
            IsJMPConditional_DE : IN STD_LOGIC;
            ConditionalType_DE : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            PC_EX : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            CCR_Flags_EX : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            IsSwap_EX : IN STD_LOGIC;
            ActualBranchTaken_EX : IN STD_LOGIC;
            ConditionalBranch_EX : IN STD_LOGIC;
            IsInterrupt_EX : IN STD_LOGIC;
            IsHardwareInt_EX : IN STD_LOGIC;
            IsReti_EX : IN STD_LOGIC;
            MemRead_MEM : IN STD_LOGIC;
            MemWrite_MEM : IN STD_LOGIC;
            IsHardwareInt_MEM : IN STD_LOGIC;
            HardwareInterrupt : IN STD_LOGIC;
            decode_ctrl_out : OUT decode_control_t;
            execute_ctrl_out : OUT execute_control_t;
            memory_ctrl_out : OUT memory_control_t;
            writeback_ctrl_out : OUT writeback_control_t;
            PC_WriteEnable : OUT STD_LOGIC;
            IFDE_WriteEnable : OUT STD_LOGIC;
            InsertNOP_IFDE : OUT STD_LOGIC;
            FlushDE : OUT STD_LOGIC;
            FlushIF : OUT STD_LOGIC;
            PassPC_ToMem : OUT STD_LOGIC;
            MemRead_Out : OUT STD_LOGIC;
            MemWrite_Out : OUT STD_LOGIC;
            BranchSelect : OUT STD_LOGIC;
            BranchTargetSelect : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            PassPC_NotPCPlus1 : OUT STD_LOGIC;
            TakeInterrupt_ToIFDE : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Clock period
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL opcode_DE : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PC_DE : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IsInterrupt_DE : STD_LOGIC := '0';
    SIGNAL IsHardwareInt_DE : STD_LOGIC := '0';
    SIGNAL IsCall_DE : STD_LOGIC := '0';
    SIGNAL IsReturn_DE : STD_LOGIC := '0';
    SIGNAL IsReti_DE : STD_LOGIC := '0';
    SIGNAL IsJMP_DE : STD_LOGIC := '0';
    SIGNAL IsJMPConditional_DE : STD_LOGIC := '0';
    SIGNAL ConditionalType_DE : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PC_EX : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL CCR_Flags_EX : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IsSwap_EX : STD_LOGIC := '0';
    SIGNAL ActualBranchTaken_EX : STD_LOGIC := '0';
    SIGNAL ConditionalBranch_EX : STD_LOGIC := '0';
    SIGNAL IsInterrupt_EX : STD_LOGIC := '0';
    SIGNAL IsHardwareInt_EX : STD_LOGIC := '0';
    SIGNAL IsReti_EX : STD_LOGIC := '0';
    SIGNAL MemRead_MEM : STD_LOGIC := '0';
    SIGNAL MemWrite_MEM : STD_LOGIC := '0';
    SIGNAL IsHardwareInt_MEM : STD_LOGIC := '0';
    SIGNAL HardwareInterrupt : STD_LOGIC := '0';

    -- Outputs
    SIGNAL decode_ctrl_out : decode_control_t;
    SIGNAL execute_ctrl_out : execute_control_t;
    SIGNAL memory_ctrl_out : memory_control_t;
    SIGNAL writeback_ctrl_out : writeback_control_t;
    SIGNAL PC_WriteEnable : STD_LOGIC;
    SIGNAL IFDE_WriteEnable : STD_LOGIC;
    SIGNAL InsertNOP_IFDE : STD_LOGIC;
    SIGNAL FlushDE : STD_LOGIC;
    SIGNAL FlushIF : STD_LOGIC;
    SIGNAL PassPC_ToMem : STD_LOGIC;
    SIGNAL MemRead_Out : STD_LOGIC;
    SIGNAL MemWrite_Out : STD_LOGIC;
    SIGNAL BranchSelect : STD_LOGIC;
    SIGNAL BranchTargetSelect : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL PassPC_NotPCPlus1 : STD_LOGIC;
    SIGNAL TakeInterrupt_ToIFDE : STD_LOGIC;

BEGIN

    -- Instantiate control unit
    uut : control_unit
    PORT MAP(
        clk => clk,
        rst => rst,
        opcode_DE => opcode_DE,
        PC_DE => PC_DE,
        IsInterrupt_DE => IsInterrupt_DE,
        IsHardwareInt_DE => IsHardwareInt_DE,
        IsCall_DE => IsCall_DE,
        IsReturn_DE => IsReturn_DE,
        IsReti_DE => IsReti_DE,
        IsJMP_DE => IsJMP_DE,
        IsJMPConditional_DE => IsJMPConditional_DE,
        ConditionalType_DE => ConditionalType_DE,
        PC_EX => PC_EX,
        CCR_Flags_EX => CCR_Flags_EX,
        IsSwap_EX => IsSwap_EX,
        ActualBranchTaken_EX => ActualBranchTaken_EX,
        ConditionalBranch_EX => ConditionalBranch_EX,
        IsInterrupt_EX => IsInterrupt_EX,
        IsHardwareInt_EX => IsHardwareInt_EX,
        IsReti_EX => IsReti_EX,
        MemRead_MEM => MemRead_MEM,
        MemWrite_MEM => MemWrite_MEM,
        IsHardwareInt_MEM => IsHardwareInt_MEM,
        HardwareInterrupt => HardwareInterrupt,
        decode_ctrl_out => decode_ctrl_out,
        execute_ctrl_out => execute_ctrl_out,
        memory_ctrl_out => memory_ctrl_out,
        writeback_ctrl_out => writeback_ctrl_out,
        PC_WriteEnable => PC_WriteEnable,
        IFDE_WriteEnable => IFDE_WriteEnable,
        InsertNOP_IFDE => InsertNOP_IFDE,
        FlushDE => FlushDE,
        FlushIF => FlushIF,
        PassPC_ToMem => PassPC_ToMem,
        MemRead_Out => MemRead_Out,
        MemWrite_Out => MemWrite_Out,
        BranchSelect => BranchSelect,
        BranchTargetSelect => BranchTargetSelect,
        PassPC_NotPCPlus1 => PassPC_NotPCPlus1,
        TakeInterrupt_ToIFDE => TakeInterrupt_ToIFDE
    );

    -- Clock generation
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR CLK_PERIOD/2;
        clk <= '1';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    -- Stimulus process
    stim_process : PROCESS
    BEGIN
        -- Reset
        rst <= '1';
        WAIT FOR CLK_PERIOD * 2;
        rst <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 1: Normal ADD instruction ===";
        opcode_DE <= OP_ADD;
        WAIT FOR CLK_PERIOD;
        ASSERT execute_ctrl_out.ALU_Operation = ALU_ADD
        REPORT "ADD should select ALU_ADD" SEVERITY error;
        ASSERT writeback_ctrl_out.RegWrite = '1'
        REPORT "ADD should enable RegWrite" SEVERITY error;
        ASSERT PC_WriteEnable = '0'
        REPORT "Normal operation should allow PC update" SEVERITY error;

        REPORT "=== Test 2: Memory conflict - LDD in memory stage ===";
        opcode_DE <= OP_NOP;
        MemRead_MEM <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT PassPC_ToMem = '0'
        REPORT "Memory conflict should block fetch" SEVERITY error;
        ASSERT PC_WriteEnable = '1'
        REPORT "Memory conflict should freeze PC" SEVERITY error;
        ASSERT InsertNOP_IFDE = '1'
        REPORT "Memory conflict should insert NOP" SEVERITY error;
        MemRead_MEM <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 3: Unconditional branch (JMP) ===";
        opcode_DE <= OP_JMP;
        IsJMP_DE <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT BranchSelect = '1'
        REPORT "JMP should select branch" SEVERITY error;
        ASSERT FlushDE = '1' AND FlushIF = '1'
        REPORT "JMP should flush IF and DE" SEVERITY error;
        ASSERT BranchTargetSelect = "00"
        REPORT "JMP should use decode stage target" SEVERITY error;
        IsJMP_DE <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 4: Software interrupt (INT) ===";
        opcode_DE <= OP_INT;
        IsInterrupt_DE <= '1';
        IsHardwareInt_DE <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT memory_ctrl_out.PassInterrupt = PASS_INT_SOFTWARE
        REPORT "INT should set PassInterrupt to SOFTWARE" SEVERITY error;
        ASSERT PC_WriteEnable = '1'
        REPORT "INT should stall PC" SEVERITY error;
        WAIT FOR CLK_PERIOD;
        -- Simulate interrupt in execute stage
        IsInterrupt_DE <= '0';
        IsInterrupt_EX <= '1';
        WAIT FOR CLK_PERIOD;
        IsInterrupt_EX <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 5: Hardware interrupt ===";
        HardwareInterrupt <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT TakeInterrupt_ToIFDE = '1'
        REPORT "Hardware interrupt should set TakeInterrupt" SEVERITY error;
        ASSERT PassPC_NotPCPlus1 = '1'
        REPORT "Hardware interrupt should save current PC" SEVERITY error;
        HardwareInterrupt <= '0';
        WAIT FOR CLK_PERIOD;
        -- Simulate hardware interrupt propagating through pipeline
        IsHardwareInt_DE <= '1';
        WAIT FOR CLK_PERIOD;
        IsHardwareInt_DE <= '0';
        IsHardwareInt_EX <= '1';
        WAIT FOR CLK_PERIOD;
        IsHardwareInt_EX <= '0';
        IsHardwareInt_MEM <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT memory_ctrl_out.PassInterrupt = PASS_INT_HARDWARE
        REPORT "Hardware interrupt should set PassInterrupt to HARDWARE" SEVERITY error;
        IsHardwareInt_MEM <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 6: SWAP instruction (two-cycle) ===";
        opcode_DE <= OP_SWAP;
        WAIT FOR CLK_PERIOD;
        ASSERT decode_ctrl_out.IsSwap = '1'
        REPORT "SWAP should set IsSwap" SEVERITY error;
        -- Simulate SWAP in execute stage
        IsSwap_EX <= '1';
        WAIT FOR CLK_PERIOD;
        -- Second cycle should be MOV (uses OUTB_REGFILE, but data comes from swapped register)
        ASSERT decode_ctrl_out.OutBSelect = OUTB_REGFILE
        REPORT "SWAP second cycle should use register file" SEVERITY error;
        IsSwap_EX <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 7: Conditional branch prediction ===";
        opcode_DE <= OP_JZ;
        IsJMPConditional_DE <= '1';
        ConditionalType_DE <= COND_ZERO;
        PC_DE <= x"00000100";
        WAIT FOR CLK_PERIOD;
        -- Initial prediction should be weakly not taken
        -- Simulate branch taken in execute
        ConditionalBranch_EX <= '1';
        ActualBranchTaken_EX <= '1';
        CCR_Flags_EX <= "100"; -- Z flag set
        PC_EX <= x"00000100";
        WAIT FOR CLK_PERIOD * 2;
        -- Branch predictor should update
        ConditionalBranch_EX <= '0';
        IsJMPConditional_DE <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 8: Branch misprediction ===";
        opcode_DE <= OP_JN;
        IsJMPConditional_DE <= '1';
        ConditionalType_DE <= COND_NEGATIVE;
        WAIT FOR CLK_PERIOD;
        -- Predictor predicts not taken, but actual is taken
        ConditionalBranch_EX <= '1';
        ActualBranchTaken_EX <= '1';
        CCR_Flags_EX <= "010"; -- N flag set
        WAIT FOR CLK_PERIOD;
        ASSERT FlushDE = '1' AND FlushIF = '1'
        REPORT "Misprediction should flush pipeline" SEVERITY error;
        ConditionalBranch_EX <= '0';
        IsJMPConditional_DE <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 9: CALL instruction ===";
        opcode_DE <= OP_CALL;
        IsCall_DE <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT memory_ctrl_out.SP_Enable = '1'
        REPORT "CALL should enable SP" SEVERITY error;
        ASSERT memory_ctrl_out.SP_Function = '0'
        REPORT "CALL should decrement SP" SEVERITY error;
        ASSERT memory_ctrl_out.MemWrite = '1'
        REPORT "CALL should write to memory" SEVERITY error;
        IsCall_DE <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 10: RTI instruction (two pops) ===";
        opcode_DE <= OP_RTI;
        IsReti_DE <= '1';
        WAIT FOR CLK_PERIOD;
        -- First pop: FLAGS
        ASSERT memory_ctrl_out.SP_Enable = '1'
        REPORT "RTI first cycle should enable SP" SEVERITY error;
        ASSERT memory_ctrl_out.MemRead = '1'
        REPORT "RTI first cycle should read memory" SEVERITY error;
        IsReti_DE <= '0';
        IsReti_EX <= '1';
        WAIT FOR CLK_PERIOD;
        -- Second pop: PC
        IsReti_EX <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== Test 11: Priority - Reset overrides everything ===";
        rst <= '1';
        HardwareInterrupt <= '1';
        IsInterrupt_DE <= '1';
        IsJMP_DE <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT BranchTargetSelect = "11"
        REPORT "Reset should have highest priority" SEVERITY error;
        rst <= '0';
        HardwareInterrupt <= '0';
        IsInterrupt_DE <= '0';
        IsJMP_DE <= '0';
        WAIT FOR CLK_PERIOD;

        REPORT "=== All tests completed successfully! ===";
        WAIT;
    END PROCESS;

END Behavioral;