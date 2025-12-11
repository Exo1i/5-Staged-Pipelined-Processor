LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY execute_stage IS
    PORT (
        clk   : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        -- =====================================================
        -- Inputs from ID/EX Pipeline Register
        -- =====================================================
        -- WB (Write Back) Control Signals
        WB_RegWrite_in  : IN STD_LOGIC;
        WB_MemToReg_in  : IN STD_LOGIC;

        -- M (Memory) Control Signals
        M_MemRead_in    : IN STD_LOGIC;
        M_MemWrite_in   : IN STD_LOGIC;
        M_SpToMem_in    : IN STD_LOGIC;
        M_PassInterrupt_in : IN STD_LOGIC;

        -- EX (Execute) Control Signals
        EX_ALU_Op       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        EX_PassImm      : IN STD_LOGIC;  -- Select immediate for ALU input B
        EX_CCRWrEn      : IN STD_LOGIC;  -- CCR write enable
        EX_IsReturn     : IN STD_LOGIC;  -- Is return instruction (for CCR restore)
        EX_PassCCR      : IN STD_LOGIC;  -- Pass CCR from stack

        -- D (Data) - Register values
        OutA            : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- Register A data
        OutB            : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- Register B data
        Immediate       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- Immediate value

        -- PC
        PC_in           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Register addresses
        Rsrc1           : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rsrc2           : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rdst1_in        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- =====================================================
        -- Forwarding Signals (from external Forwarding Unit)
        -- =====================================================
        ForwardA        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        ForwardB        : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Forwarded data from later pipeline stages
        Forwarded_EXM   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- From EX/MEM stage
        Forwarded_MWB   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);  -- From MEM/WB stage

        -- Stack flags input (for RTI - restore CCR from stack)
        StackFlags      : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- =====================================================
        -- Outputs to EX/MEM Pipeline Register
        -- =====================================================
        -- WB Control Signals (pass through)
        WB_RegWrite_out : OUT STD_LOGIC;
        WB_MemToReg_out : OUT STD_LOGIC;

        -- M Control Signals (pass through)
        M_MemRead_out   : OUT STD_LOGIC;
        M_MemWrite_out  : OUT STD_LOGIC;
        M_SpToMem_out   : OUT STD_LOGIC;
        M_PassInterrupt_out : OUT STD_LOGIC;

        -- ALU Result / Memory Address
        ALU_Result_out  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Primary Data (for memory write - typically second operand)
        Primary_Data    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Secondary Data (additional data path)
        Secondary_Data  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Destination register address
        Rdst1_out       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- CCR Flags output
        CCR_Flags       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END execute_stage;

ARCHITECTURE Behavioral OF execute_stage IS

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

    -- =====================================================
    -- Internal Signals
    -- =====================================================
    -- MUX outputs for ALU inputs
    SIGNAL In_A : STD_LOGIC_VECTOR(31 DOWNTO 0);  -- ALU Input A (after forwarding MUX)
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
    PROCESS (ForwardA, OutA, Forwarded_EXM, Forwarded_MWB)
    BEGIN
        CASE ForwardA IS
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
    PROCESS (ForwardB, OutB, Forwarded_EXM, Forwarded_MWB)
    BEGIN
        CASE ForwardB IS
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
    -- Pass through WB control signals
    WB_RegWrite_out <= WB_RegWrite_in;
    WB_MemToReg_out <= WB_MemToReg_in;

    -- Pass through M control signals
    M_MemRead_out   <= M_MemRead_in;
    M_MemWrite_out  <= M_MemWrite_in;
    M_SpToMem_out   <= M_SpToMem_in;
    M_PassInterrupt_out <= M_PassInterrupt_in;

    -- ALU Result output
    ALU_Result_out  <= alu_result_int;

    -- Primary Data - forwarded operand B (for memory writes like STORE)
    Primary_Data    <= forwarded_B;

    -- Secondary Data - OutA after forwarding (additional data path)
    Secondary_Data  <= In_A;

    -- Destination register address
    Rdst1_out       <= Rdst1_in;

    -- CCR Flags output
    CCR_Flags       <= ccr_out_int;

END Behavioral;