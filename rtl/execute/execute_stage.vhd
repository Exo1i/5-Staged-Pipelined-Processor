library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity execute_stage is
    Port (
        clk   : in STD_LOGIC;
        reset : in STD_LOGIC;
        
        -- From ID/EX Pipeline Register
        RegA_Data      : in  STD_LOGIC_VECTOR(31 downto 0);
        RegB_Data      : in  STD_LOGIC_VECTOR(31 downto 0);
        Immediate      : in  STD_LOGIC_VECTOR(31 downto 0);
        Ra_Addr        : in  STD_LOGIC_VECTOR(2 downto 0);
        Rb_Addr        : in  STD_LOGIC_VECTOR(2 downto 0);
        
        -- From Stack Pointer (Member 4)
        SP             : in  STD_LOGIC_VECTOR(31 downto 0);
        
        -- Forwarding inputs from pipeline registers
        Forwarded_MEM  : in  STD_LOGIC_VECTOR(31 downto 0);
        Forwarded_WB   : in  STD_LOGIC_VECTOR(31 downto 0);
        
        -- Control signals from Control Unit (Member 2)
        ALU_Op         : in  STD_LOGIC_VECTOR(3 downto 0);
        spToALU        : in  STD_LOGIC;
        ImmToALU       : in  STD_LOGIC;
        CCRWrEn        : in  STD_LOGIC;
        PassCCR        : in  STD_LOGIC;
        ForwardA       : in  STD_LOGIC_VECTOR(1 downto 0);
        ForwardB       : in  STD_LOGIC_VECTOR(1 downto 0);
        
        -- Register file write signals (from WB stage)
        WB_Rdst        : in  STD_LOGIC_VECTOR(2 downto 0);
        WB_WriteData   : in  STD_LOGIC_VECTOR(31 downto 0);
        WB_RegWrite    : in  STD_LOGIC;
        
        -- SWAP instruction support
        WB_Rdst2       : in  STD_LOGIC_VECTOR(2 downto 0);
        WB_WriteData2  : in  STD_LOGIC_VECTOR(31 downto 0);
        WB_RegWrite2   : in  STD_LOGIC;
        
        -- Stack flags input (for RTI)
        StackFlags     : in  STD_LOGIC_VECTOR(2 downto 0);
        
        -- Outputs to EX/MEM Pipeline Register
        ALU_Result     : out STD_LOGIC_VECTOR(31 downto 0);
        RegB_Out       : out STD_LOGIC_VECTOR(31 downto 0);
        CCR_Out        : out STD_LOGIC_VECTOR(2 downto 0)
    );
end execute_stage;

architecture Behavioral of execute_stage is
    
    -- Component declarations
    component alu is
        Port (
            OperandA : in  STD_LOGIC_VECTOR(31 downto 0);
            OperandB : in  STD_LOGIC_VECTOR(31 downto 0);
            ALU_Op   : in  STD_LOGIC_VECTOR(3 downto 0);
            Result   : out STD_LOGIC_VECTOR(31 downto 0);
            Zero     : out STD_LOGIC;
            Negative : out STD_LOGIC;
            Carry    : out STD_LOGIC
        );
    end component;
    
    component register_file is
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            Ra         : in  STD_LOGIC_VECTOR(2 downto 0);
            Rb         : in  STD_LOGIC_VECTOR(2 downto 0);
            ReadDataA  : out STD_LOGIC_VECTOR(31 downto 0);
            ReadDataB  : out STD_LOGIC_VECTOR(31 downto 0);
            Rdst       : in  STD_LOGIC_VECTOR(2 downto 0);
            WriteData  : in  STD_LOGIC_VECTOR(31 downto 0);
            RegWrite   : in  STD_LOGIC;
            Rdst2      : in  STD_LOGIC_VECTOR(2 downto 0);
            WriteData2 : in  STD_LOGIC_VECTOR(31 downto 0);
            RegWrite2  : in  STD_LOGIC
        );
    end component;
    
    component ccr is
        Port (
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            ALU_Zero     : in  STD_LOGIC;
            ALU_Negative : in  STD_LOGIC;
            ALU_Carry    : in  STD_LOGIC;
            CCRWrEn      : in  STD_LOGIC;
            PassCCR      : in  STD_LOGIC;
            StackFlags   : in  STD_LOGIC_VECTOR(2 downto 0);
            CCR_Out      : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;
    
    -- Internal signals
    signal rf_readA, rf_readB : STD_LOGIC_VECTOR(31 downto 0);
    signal operandA, operandB : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_result_int     : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_zero, alu_neg, alu_carry : STD_LOGIC;
    signal operandA_mux_out   : STD_LOGIC_VECTOR(31 downto 0);
    
begin
    
    -- Instantiate Register File
    RF: register_file port map (
        clk        => clk,
        reset      => reset,
        Ra         => Ra_Addr,
        Rb         => Rb_Addr,
        ReadDataA  => rf_readA,
        ReadDataB  => rf_readB,
        Rdst       => WB_Rdst,
        WriteData  => WB_WriteData,
        RegWrite   => WB_RegWrite,
        Rdst2      => WB_Rdst2,
        WriteData2 => WB_WriteData2,
        RegWrite2  => WB_RegWrite2
    );
    
    -- OperandA Multiplexer (4:1)
    -- ForwardA encoding: 00 = RegA, 01 = SP, 10 = Forwarded_MEM, 11 = Forwarded_WB
    process(ForwardA, rf_readA, SP, Forwarded_MEM, Forwarded_WB, spToALU, RegA_Data)
    begin
        if spToALU = '1' then
            operandA_mux_out <= SP;
        else
            case ForwardA is
                when "00"   => operandA_mux_out <= RegA_Data;  -- No forwarding
                when "01"   => operandA_mux_out <= SP;
                when "10"   => operandA_mux_out <= Forwarded_MEM;
                when "11"   => operandA_mux_out <= Forwarded_WB;
                when others => operandA_mux_out <= RegA_Data;
            end case;
        end if;
    end process;
    
    operandA <= operandA_mux_out;
    
    -- OperandB Multiplexer (4:1)
    -- ForwardB encoding: 00 = RegB, 01 = Immediate, 10 = Forwarded_MEM, 11 = Forwarded_WB
    process(ForwardB, rf_readB, Immediate, Forwarded_MEM, Forwarded_WB, ImmToALU, RegB_Data)
    begin
        if ImmToALU = '1' then
            operandB <= Immediate;
        else
            case ForwardB is
                when "00"   => operandB <= RegB_Data;
                when "01"   => operandB <= Immediate;
                when "10"   => operandB <= Forwarded_MEM;
                when "11"   => operandB <= Forwarded_WB;
                when others => operandB <= RegB_Data;
            end case;
        end if;
    end process;
    
    -- Instantiate ALU
    ALU_UNIT: alu port map (
        OperandA => operandA,
        OperandB => operandB,
        ALU_Op   => ALU_Op,
        Result   => alu_result_int,
        Zero     => alu_zero,
        Negative => alu_neg,
        Carry    => alu_carry
    );
    
    -- Instantiate CCR
    CCR_UNIT: ccr port map (
        clk          => clk,
        reset        => reset,
        ALU_Zero     => alu_zero,
        ALU_Negative => alu_neg,
        ALU_Carry    => alu_carry,
        CCRWrEn      => CCRWrEn,
        PassCCR      => PassCCR,
        StackFlags   => StackFlags,
        CCR_Out      => CCR_Out
    );
    
    -- Outputs
    ALU_Result <= alu_result_int;
    RegB_Out   <= rf_readB;  -- Pass RegB data to memory stage
    
end Behavioral;