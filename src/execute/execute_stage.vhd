LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY execute_stage IS
    PORT (
        clk   : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        -- Control and data inputs from ID/EX Pipeline Register (as records)
        idex_ctrl_in : IN pipeline_decode_excute_ctrl_t;
        idex_data_in : IN pipeline_decode_excute_t;

        -- Forwarding signals (as record)
        forwarding      : IN forwarding_ctrl_t;

        -- Forwarded data from later pipeline stages
        Forwarded_EXM   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Forwarded_MWB   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Stack flags input
        StackFlags      : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Data outputs (as record)
        execute_out     : OUT execute_outputs_t;

        -- Control outputs (as record)
        ctrl_out        : OUT execute_ctrl_outputs_t
    );
END execute_stage;

ARCHITECTURE Behavioral OF execute_stage IS

    -- Internal signals extracted from records
    SIGNAL WB_RegWrite_in : STD_LOGIC;
    SIGNAL WB_MemToReg_in : STD_LOGIC;
    SIGNAL M_MemRead_in : STD_LOGIC;
    SIGNAL M_MemWrite_in : STD_LOGIC;
    SIGNAL M_SpToMem_in : STD_LOGIC;
    SIGNAL M_PassInterrupt_in : STD_LOGIC;
    SIGNAL EX_ALU_Op : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL EX_PassImm : STD_LOGIC;
    SIGNAL EX_CCRWrEn : STD_LOGIC;
    SIGNAL EX_IsReturn : STD_LOGIC;
    SIGNAL EX_PassCCR : STD_LOGIC;
    SIGNAL OutA : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL OutB : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL Immediate : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL PC_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL Rsrc1 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL Rsrc2 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL Rdst1_in : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- =====================================================
    -- Component Declarations
    -- =====================================================
    COMPONENT alu IS
        PORT (
            OperandA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            OperandB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            ALU_Op   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            Result   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Zero     : OUT STD_LOGIC;
            Negative : OUT STD_LOGIC;
            Carry    : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT ccr IS
        PORT (
            clk          : IN STD_LOGIC;
            reset        : IN STD_LOGIC;
            ALU_Zero     : IN STD_LOGIC;
            ALU_Negative : IN STD_LOGIC;
            ALU_Carry    : IN STD_LOGIC;
            CCRWrEn      : IN STD_LOGIC;
            PassCCR      : IN STD_LOGIC;
            StackFlags   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            CCR_Out      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

BEGIN

    -- =====================================================
    -- Extract signals from input records
    -- =====================================================
    WB_RegWrite_in <= idex_ctrl_in.writeback_ctrl.RegWrite;
    WB_MemToReg_in <= idex_ctrl_in.writeback_ctrl.MemToALU;
    M_MemRead_in <= idex_ctrl_in.memory_ctrl.MemRead;
    M_MemWrite_in <= idex_ctrl_in.memory_ctrl.MemWrite;
    M_SpToMem_in <= idex_ctrl_in.memory_ctrl.SPtoMem;
    M_PassInterrupt_in <= idex_ctrl_in.memory_ctrl.PassInterrupt(0);
    EX_ALU_Op <= idex_ctrl_in.execute_ctrl.ALU_Operation & '0';
    EX_PassImm <= idex_ctrl_in.execute_ctrl.PassImm;
    EX_CCRWrEn <= idex_ctrl_in.execute_ctrl.CCR_WriteEnable;
    EX_IsReturn <= idex_ctrl_in.decode_ctrl.IsReturn;
    EX_PassCCR <= idex_ctrl_in.execute_ctrl.PassCCR;
    OutA <= idex_data_in.operand_a;
    OutB <= idex_data_in.operand_b;
    Immediate <= idex_data_in.immediate;
    PC_in <= idex_data_in.pc;
    Rsrc1 <= idex_data_in.rsrc1;
    Rsrc2 <= idex_data_in.rsrc2;
    Rdst1_in <= idex_data_in.rd;

    -- =====================================================
    -- Operand A MUX (3:1) - Forwarding for In_A
    -- =====================================================ut A (after forwarding MUX)
    SIGNAL In_B : STD_LOGIC_VECTOR(31 DOWNTO 0);  -- ALU Input B (after forwarding and PassImm MUX)
    SIGNAL forwarded_B : STD_LOGIC_VECTOR(31 DOWNTO 0);  -- After forwarding, before PassImm MUX

    -- ALU outputs
    SIGNAL alu_result_int : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_zero       : STD_LOGIC;
    SIGNAL alu_neg        : STD_LOGIC;
    SIGNAL alu_carry      : STD_LOGIC;

    -- CCR output
    SIGNAL ccr_out_int    : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- XOR gate output (for IsReturn logic)
    SIGNAL ccr_write_enable : STD_LOGIC;

BEGIN

    -- =====================================================
    -- Operand A MUX (3:1) - Forwarding for In_A
    -- =====================================================
    -- ForwardA: 00 = OutA (no forwarding), 10 = EX/MEM, 01 = MEM/WB
    PROCESS (forwarding.forward_a, OutA, Forwarded_EXM, Forwarded_MWB)
    BEGIN
        CASE forwarding.forward_a IS
            WHEN "00"   => In_A <= OutA;            -- No forwarding
            WHEN "10"   => In_A <= Forwarded_EXM;   -- Forward from EX/MEM
            WHEN "01"   => In_A <= Forwarded_MWB;   -- Forward from MEM/WB
            WHEN OTHERS => In_A <= OutA;
        END CASE;
    END PROCESS;

    -- =====================================================
    -- Operand B MUX (3:1) - Forwarding for In_B (before PassImm)
    -- =====================================================
    -- ForwardB: 00 = OutB (no forwarding), 10 = EX/MEM, 01 = MEM/WB
    PROCESS (forwarding.forward_b, OutB, Forwarded_EXM, Forwarded_MWB)
    BEGIN
        CASE forwarding.forward_b IS
            WHEN "00"   => forwarded_B <= OutB;            -- No forwarding
            WHEN "10"   => forwarded_B <= Forwarded_EXM;   -- Forward from EX/MEM
            WHEN "01"   => forwarded_B <= Forwarded_MWB;   -- Forward from MEM/WB
            WHEN OTHERS => forwarded_B <= OutB;
        END CASE;
    END PROCESS;

    -- =====================================================
    -- PassImm MUX (2:1) - Select between forwarded_B and Immediate
    -- =====================================================
    PROCESS (EX_PassImm, forwarded_B, Immediate)
    BEGIN
        IF EX_PassImm = '1' THEN
            In_B <= Immediate;
        ELSE
            In_B <= forwarded_B;
        END IF;
    END PROCESS;

    -- =====================================================
    -- XOR Gate for CCR Write Enable
    -- =====================================================
    -- CCRWrEn is XORed with IsReturn for proper CCR control
    ccr_write_enable <= EX_CCRWrEn XOR EX_IsReturn;

    -- =====================================================
    -- ALU Instantiation
    -- =====================================================
    ALU_UNIT : alu PORT MAP(
        OperandA => In_A,
        OperandB => In_B,
        ALU_Op   => EX_ALU_Op,
        Result   => alu_result_int,
        Zero     => alu_zero,
        Negative => alu_neg,
        Carry    => alu_carry
    );

    -- =====================================================
    -- CCR Flags Register Instantiation
    -- =====================================================
    CCR_UNIT : ccr PORT MAP(
        clk          => clk,
        reset        => reset,
        ALU_Zero     => alu_zero,
        ALU_Negative => alu_neg,
        ALU_Carry    => alu_carry,
        CCRWrEn      => ccr_write_enable,
        PassCCR      => EX_PassCCR,
        StackFlags   => StackFlags,
        CCR_Out      => ccr_out_int
    );

    -- =====================================================
    -- Output Assignments
    -- =====================================================
    -- Populate execute_outputs_t record
    execute_out.alu_result <= alu_result_int;
    execute_out.primary_data <= forwarded_B;
    execute_out.secondary_data <= In_A;
    execute_out.rdst <= Rdst1_in;
    execute_out.ccr_flags <= ccr_out_int;

    -- Populate execute_ctrl_outputs_t record (pass-through control signals)
    ctrl_out.wb_regwrite <= WB_RegWrite_in;
    ctrl_out.wb_memtoreg <= WB_MemToReg_in;
    ctrl_out.m_memread <= M_MemRead_in;
    ctrl_out.m_memwrite <= M_MemWrite_in;
    ctrl_out.m_sptomem <= M_SpToMem_in;
    ctrl_out.m_passinterrupt <= M_PassInterrupt_in;

END Behavioral;