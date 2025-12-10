LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY execute_stage IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        -- From ID/EX Pipeline Register
        RegA_Data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        RegB_Data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Immediate : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Ra_Addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        Rb_Addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- From Stack Pointer (Member 4)
        SP : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Forwarding inputs from pipeline registers
        Forwarded_MEM : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        Forwarded_WB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Control signals from Control Unit (Member 2)
        ALU_Op : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        spToALU : IN STD_LOGIC;
        ImmToALU : IN STD_LOGIC;
        CCRWrEn : IN STD_LOGIC;
        PassCCR : IN STD_LOGIC;
        ForwardA : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        ForwardB : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Register file write signals (from WB stage)
        WB_Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        WB_WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        WB_RegWrite : IN STD_LOGIC;

        -- Stack flags input (for RTI)
        StackFlags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Outputs to EX/MEM Pipeline Register
        ALU_Result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        RegB_Out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        CCR_Out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END execute_stage;

ARCHITECTURE Behavioral OF execute_stage IS

    -- Component declarations
    COMPONENT alu IS
        PORT (
            OperandA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            OperandB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            ALU_Op : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            Result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Zero : OUT STD_LOGIC;
            Negative : OUT STD_LOGIC;
            Carry : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT register_file IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            Ra : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rb : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ReadDataA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            ReadDataB : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            RegWrite : IN STD_LOGIC
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
            StackFlags : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            CCR_Out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    -- Internal signals
    SIGNAL rf_readA, rf_readB : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL operandA, operandB : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_result_int : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL alu_zero, alu_neg, alu_carry : STD_LOGIC;
    SIGNAL operandA_mux_out : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Instantiate Register File
    RF : register_file PORT MAP(
        clk => clk,
        reset => reset,
        Ra => Ra_Addr,
        Rb => Rb_Addr,
        ReadDataA => rf_readA,
        ReadDataB => rf_readB,
        Rdst => WB_Rdst,
        WriteData => WB_WriteData,
        RegWrite => WB_RegWrite
    );

    -- OperandA Multiplexer (4:1)
    -- ForwardA encoding: 00 = RegA, 01 = SP, 10 = Forwarded_MEM, 11 = Forwarded_WB
    PROCESS (ForwardA, rf_readA, SP, Forwarded_MEM, Forwarded_WB, spToALU, RegA_Data)
    BEGIN
        IF spToALU = '1' THEN
            operandA_mux_out <= SP;
        ELSE
            CASE ForwardA IS
                WHEN "00" => operandA_mux_out <= RegA_Data; -- No forwarding
                WHEN "01" => operandA_mux_out <= SP;
                WHEN "10" => operandA_mux_out <= Forwarded_MEM;
                WHEN "11" => operandA_mux_out <= Forwarded_WB;
                WHEN OTHERS => operandA_mux_out <= RegA_Data;
            END CASE;
        END IF;
    END PROCESS;

    operandA <= operandA_mux_out;

    -- OperandB Multiplexer (4:1)
    -- ForwardB encoding: 00 = RegB, 01 = Immediate, 10 = Forwarded_MEM, 11 = Forwarded_WB
    PROCESS (ForwardB, rf_readB, Immediate, Forwarded_MEM, Forwarded_WB, ImmToALU, RegB_Data)
    BEGIN
        IF ImmToALU = '1' THEN
            operandB <= Immediate;
        ELSE
            CASE ForwardB IS
                WHEN "00" => operandB <= RegB_Data;
                WHEN "01" => operandB <= Immediate;
                WHEN "10" => operandB <= Forwarded_MEM;
                WHEN "11" => operandB <= Forwarded_WB;
                WHEN OTHERS => operandB <= RegB_Data;
            END CASE;
        END IF;
    END PROCESS;

    -- Instantiate ALU
    ALU_UNIT : alu PORT MAP(
        OperandA => operandA,
        OperandB => operandB,
        ALU_Op => ALU_Op,
        Result => alu_result_int,
        Zero => alu_zero,
        Negative => alu_neg,
        Carry => alu_carry
    );

    -- Instantiate CCR
    CCR_UNIT : ccr PORT MAP(
        clk => clk,
        reset => reset,
        ALU_Zero => alu_zero,
        ALU_Negative => alu_neg,
        ALU_Carry => alu_carry,
        CCRWrEn => CCRWrEn,
        PassCCR => PassCCR,
        StackFlags => StackFlags,
        CCR_Out => CCR_Out
    );

    -- Outputs
    ALU_Result <= alu_result_int;
    RegB_Out <= rf_readB; -- Pass RegB data to memory stage

END Behavioral;