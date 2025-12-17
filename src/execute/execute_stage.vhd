LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pipeline_data_pkg.ALL;
USE work.control_signals_pkg.ALL;
USE work.pkg_opcodes.ALL;
ENTITY execute_stage IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        -- Control and data inputs from ID/EX Pipeline Register (as records)
        idex_ctrl_in : IN pipeline_decode_excute_ctrl_t;
        idex_data_in : IN pipeline_decode_excute_t;

        -- Forwarding signals (as record)
        immediate : STD_LOGIC_VECTOR(31 DOWNTO 0);
        forwarding : IN forwarding_ctrl_t;

        -- Forwarded data from later pipeline stages
        Forwarded_EXM : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Forwarded_MWB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Stack flags input
        StackFlags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Data outputs (as record)
        execute_out : OUT execute_outputs_t;

        -- Control outputs (as record)
        ctrl_out : OUT execute_ctrl_outputs_t
    );
END execute_stage;

ARCHITECTURE Behavioral OF execute_stage IS

    -- =====================================================
    -- Component Declarations
    -- =====================================================
    COMPONENT alu IS
        PORT (
            Carry_In: IN STD_LOGIC;
            OperandA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            OperandB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            ALU_Op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Zero : OUT STD_LOGIC;
            Negative : OUT STD_LOGIC;
            Carry : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT ccr IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ALU_Zero : IN STD_LOGIC;
            ALU_Negative : IN STD_LOGIC;
            ALU_Carry : IN STD_LOGIC;
            CCRWrEn : IN STD_LOGIC;
            PassCCR : IN STD_LOGIC;
            SetCarry : IN STD_LOGIC;
            StackFlags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            CCR_Out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    -- MUX outputs for ALU inputs
    SIGNAL In_A : STD_LOGIC_VECTOR(31 DOWNTO 0); -- ALU Input A (after forwarding MUX)
    SIGNAL In_B : STD_LOGIC_VECTOR(31 DOWNTO 0); -- ALU Input B (after forwarding and PassImm MUX)
    SIGNAL forwarded_B : STD_LOGIC_VECTOR(31 DOWNTO 0); -- After forwarding, before PassImm MUX

    -- ALU outputs
    SIGNAL alu_result_int : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_zero : STD_LOGIC;
    SIGNAL alu_neg : STD_LOGIC;
    SIGNAL alu_carry : STD_LOGIC;

    -- CCR output
    SIGNAL ccr_out_int : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- XOR gate output (for IsReturn logic)
    SIGNAL ccr_write_enable : STD_LOGIC;
    SIGNAL set_carry_in_ccr : STD_LOGIC;
BEGIN

    -- CCR write enable logic (XOR with IsReturn)
    ccr_write_enable <= idex_ctrl_in.execute_ctrl.CCR_WriteEnable OR idex_ctrl_in.decode_ctrl.IsReturn;
    set_carry_in_ccr <= '1' when idex_ctrl_in.execute_ctrl.ALU_Operation = ALU_SETC else '0';
    
    -- =====================================================
    -- Operand A MUX (3:1) - Forwarding for In_A
    -- =====================================================
    PROCESS (forwarding.forward_a, idex_data_in.operand_a, Forwarded_EXM, Forwarded_MWB)
    BEGIN
        CASE forwarding.forward_a IS
            WHEN FORWARD_NONE => In_A <= idex_data_in.operand_a;
            WHEN FORWARD_EX_MEM => In_A <= Forwarded_EXM;
            WHEN FORWARD_MEM_WB => In_A <= Forwarded_MWB;
            WHEN OTHERS => In_A <= idex_data_in.operand_a;
        END CASE;
    END PROCESS;

    -- =====================================================
    -- PassImm MUX (2:1) - Select between forwarded_B and Immediate
    -- =====================================================
    In_B <= immediate WHEN idex_ctrl_in.execute_ctrl.PassImm = '1' ELSE
        idex_data_in.operand_b;

    -- =====================================================
    -- Operand B MUX (3:1) - Forwarding for In_B (before PassImm)
    -- =====================================================
    PROCESS (forwarding.forward_b, idex_data_in.operand_b, Forwarded_EXM, Forwarded_MWB, In_B)
    BEGIN
        CASE forwarding.forward_b IS
            WHEN FORWARD_NONE => forwarded_B <= In_B;
            WHEN FORWARD_EX_MEM => forwarded_B <= Forwarded_EXM;
            WHEN FORWARD_MEM_WB => forwarded_B <= Forwarded_MWB;
            WHEN OTHERS => forwarded_B <= idex_data_in.operand_b;
        END CASE;
    END PROCESS;

    -- =====================================================
    -- Operand Secondary MUX (3:1) - Forwarding for secondary operand (before PassImm)
    -- =====================================================
    PROCESS (forwarding.forward_secondary, idex_data_in.operand_b, Forwarded_EXM, Forwarded_MWB, In_B)
    BEGIN
        CASE forwarding.forward_secondary IS
            WHEN FORWARD_NONE => forwarded_B <= idex_data_in.operand_b;
            WHEN FORWARD_EX_MEM => forwarded_B <= Forwarded_EXM;
            WHEN FORWARD_MEM_WB => forwarded_B <= Forwarded_MWB;
            WHEN OTHERS => forwarded_B <= idex_data_in.operand_b;
        END CASE;
    END PROCESS;

    -- =====================================================
    -- ALU Instantiation
    -- =====================================================
    ALU_UNIT : alu PORT MAP(
        Carry_In => ccr_out_int(0),
        OperandA => In_A,
        OperandB => forwarded_B,
        ALU_Op => idex_ctrl_in.execute_ctrl.ALU_Operation,
        Result => alu_result_int,
        Zero => alu_zero,
        Negative => alu_neg,
        Carry => alu_carry
    );

    -- =====================================================
    -- CCR Flags Register Instantiation
    -- =====================================================
    CCR_UNIT : ccr PORT MAP(
        clk => clk,
        reset => reset,
        ALU_Zero => alu_zero,
        ALU_Negative => alu_neg,
        ALU_Carry => alu_carry,
        CCRWrEn => ccr_write_enable,
        SetCarry => set_carry_in_ccr,
        PassCCR => idex_ctrl_in.execute_ctrl.PassCCR,
        StackFlags => StackFlags,
        CCR_Out => ccr_out_int
    );

    -- =====================================================
    -- Output Assignments
    -- =====================================================
    execute_out.primary_data <= alu_result_int;
    execute_out.secondary_data <= ccr_out_int WHEN idex_ctrl_in.execute_ctrl.PassCCR = '1' ELSE
    idex_data_in.operand_b;
    execute_out.rdst <= idex_data_in.rd;
    execute_out.ccr_flags <= ccr_out_int;

    ctrl_out.wb_regwrite <= idex_ctrl_in.writeback_ctrl.RegWrite;
    ctrl_out.wb_memtoreg <= idex_ctrl_in.writeback_ctrl.PassMem;
    ctrl_out.m_memread <= idex_ctrl_in.memory_ctrl.MemRead;
    ctrl_out.m_memwrite <= idex_ctrl_in.memory_ctrl.MemWrite;
    ctrl_out.m_sptomem <= idex_ctrl_in.memory_ctrl.SPtoMem;
    ctrl_out.m_passinterrupt <= idex_ctrl_in.memory_ctrl.PassInterrupt(0);

END Behavioral;