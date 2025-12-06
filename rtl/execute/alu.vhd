library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        OperandA : in  STD_LOGIC_VECTOR(31 downto 0);
        OperandB : in  STD_LOGIC_VECTOR(31 downto 0);
        ALU_Op   : in  STD_LOGIC_VECTOR(3 downto 0);
        Result   : out STD_LOGIC_VECTOR(31 downto 0);
        Zero     : out STD_LOGIC;
        Negative : out STD_LOGIC;
        Carry    : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is
    -- ALU Operation Codes
    constant ALU_ADD  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    constant ALU_SUB  : STD_LOGIC_VECTOR(3 downto 0) := "0001";
    constant ALU_AND  : STD_LOGIC_VECTOR(3 downto 0) := "0010";
    constant ALU_NOT  : STD_LOGIC_VECTOR(3 downto 0) := "0011";
    constant ALU_INC  : STD_LOGIC_VECTOR(3 downto 0) := "0100";
    constant ALU_PASS : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    
    signal result_temp : STD_LOGIC_VECTOR(31 downto 0);
    signal carry_temp  : STD_LOGIC;
    
begin
    process(OperandA, OperandB, ALU_Op)
        variable temp_33bit : unsigned(32 downto 0);
    begin
        carry_temp <= '0';  -- Default carry
        
        case ALU_Op is
            when ALU_ADD =>
                -- 33-bit addition for carry detection
                temp_33bit := unsigned('0' & OperandA) + unsigned('0' & OperandB);
                result_temp <= std_logic_vector(temp_33bit(31 downto 0));
                carry_temp <= temp_33bit(32);
                
            when ALU_SUB =>
                -- 33-bit subtraction for borrow detection
                temp_33bit := unsigned('0' & OperandA) - unsigned('0' & OperandB);
                result_temp <= std_logic_vector(temp_33bit(31 downto 0));
                carry_temp <= temp_33bit(32);  -- Borrow flag
                
            when ALU_AND =>
                result_temp <= OperandA AND OperandB;
                
            when ALU_NOT =>
                result_temp <= NOT OperandA;
                
            when ALU_INC =>
                -- Increment OperandA
                temp_33bit := unsigned('0' & OperandA) + 1;
                result_temp <= std_logic_vector(temp_33bit(31 downto 0));
                carry_temp <= temp_33bit(32);
                
            when ALU_PASS =>
                -- Pass-through OperandA
                result_temp <= OperandA;
                
            when others =>
                result_temp <= (others => '0');
        end case;
    end process;
    
    -- Output assignments
    Result <= result_temp;
    
    -- Flag generation
    Zero     <= '1' when result_temp = X"00000000" else '0';
    Negative <= result_temp(31);  -- MSB indicates negative
    Carry    <= carry_temp;
    
end Behavioral;