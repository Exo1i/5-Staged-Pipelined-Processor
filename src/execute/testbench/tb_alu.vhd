library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_alu is
end tb_alu;

architecture Behavioral of tb_alu is
    
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
    
    -- Test signals
    signal OperandA : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal OperandB : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal ALU_Op   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal Result   : STD_LOGIC_VECTOR(31 downto 0);
    signal Zero     : STD_LOGIC;
    signal Negative : STD_LOGIC;
    signal Carry    : STD_LOGIC;
    
    -- ALU Operation Codes
    constant ALU_ADD  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    constant ALU_SUB  : STD_LOGIC_VECTOR(3 downto 0) := "0001";
    constant ALU_AND  : STD_LOGIC_VECTOR(3 downto 0) := "0010";
    constant ALU_NOT  : STD_LOGIC_VECTOR(3 downto 0) := "0011";
    constant ALU_INC  : STD_LOGIC_VECTOR(3 downto 0) := "0100";
    constant ALU_PASS_A : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    
begin
    
    UUT: alu port map (
        OperandA => OperandA,
        OperandB => OperandB,
        ALU_Op   => ALU_Op,
        Result   => Result,
        Zero     => Zero,
        Negative => Negative,
        Carry    => Carry
    );
    
    stimulus: process
    begin
        report "Starting ALU Testbench";
        
        -- Test 1: ADD operation (positive result)
        report "Test 1: ADD 10 + 5 = 15";
        OperandA <= std_logic_vector(to_unsigned(10, 32));
        OperandB <= std_logic_vector(to_unsigned(5, 32));
        ALU_Op   <= ALU_ADD;
        wait for 10 ns;
        assert Result = std_logic_vector(to_unsigned(15, 32)) 
            report "ADD failed: expected 15" severity error;
        assert Zero = '0' and Negative = '0' and Carry = '0' 
            report "ADD flags incorrect" severity error;
        
        -- Test 2: ADD with carry (overflow)
        report "Test 2: ADD with overflow";
        OperandA <= X"FFFFFFFF";  -- Max value
        OperandB <= X"00000001";
        ALU_Op   <= ALU_ADD;
        wait for 10 ns;
        assert Result = X"00000000" report "ADD overflow result incorrect" severity error;
        assert Zero = '1' and Carry = '1' report "ADD overflow flags incorrect" severity error;
        
        -- Test 3: SUB operation
        report "Test 3: SUB 20 - 8 = 12";
        OperandA <= std_logic_vector(to_unsigned(20, 32));
        OperandB <= std_logic_vector(to_unsigned(8, 32));
        ALU_Op   <= ALU_SUB;
        wait for 10 ns;
        assert Result = std_logic_vector(to_unsigned(12, 32)) 
            report "SUB failed" severity error;
        assert Zero = '0' and Negative = '0' 
            report "SUB flags incorrect" severity error;
        
        -- Test 4: SUB with borrow (underflow)
        report "Test 4: SUB with underflow";
        OperandA <= X"00000000";
        OperandB <= X"00000001";
        ALU_Op   <= ALU_SUB;
        wait for 10 ns;
        assert Result = X"FFFFFFFF" report "SUB underflow result incorrect" severity error;
        assert Negative = '1' and Carry = '1' report "SUB underflow flags incorrect" severity error;
        
        -- Test 5: SUB resulting in zero
        report "Test 5: SUB 42 - 42 = 0";
        OperandA <= std_logic_vector(to_unsigned(42, 32));
        OperandB <= std_logic_vector(to_unsigned(42, 32));
        ALU_Op   <= ALU_SUB;
        wait for 10 ns;
        assert Result = X"00000000" report "SUB zero result incorrect" severity error;
        assert Zero = '1' report "Zero flag not set" severity error;
        
        -- Test 6: AND operation
        report "Test 6: AND 0xFF00FF00 & 0x0FF00FF0 = 0x0F000F00";
        OperandA <= X"FF00FF00";
        OperandB <= X"0FF00FF0";
        ALU_Op   <= ALU_AND;
        wait for 10 ns;
        assert Result = X"0F000F00" report "AND failed" severity error;
        
        -- Test 7: NOT operation
        report "Test 7: NOT 0xAAAAAAAA = 0x55555555";
        OperandA <= X"AAAAAAAA";
        OperandB <= X"00000000";  -- OperandB not used
        ALU_Op   <= ALU_NOT;
        wait for 10 ns;
        assert Result = X"55555555" report "NOT failed" severity error;
        
        -- Test 8: NOT all ones
        report "Test 8: NOT 0xFFFFFFFF = 0x00000000";
        OperandA <= X"FFFFFFFF";
        ALU_Op   <= ALU_NOT;
        wait for 10 ns;
        assert Result = X"00000000" report "NOT all ones failed" severity error;
        assert Zero = '1' report "Zero flag not set on NOT" severity error;
        
        -- Test 9: INC operation
        report "Test 9: INC 99 = 100";
        OperandA <= std_logic_vector(to_unsigned(99, 32));
        OperandB <= X"00000000";  -- OperandB not used
        ALU_Op   <= ALU_INC;
        wait for 10 ns;
        assert Result = std_logic_vector(to_unsigned(100, 32)) 
            report "INC failed" severity error;
        
        -- Test 10: INC with overflow
        report "Test 10: INC 0xFFFFFFFF with overflow";
        OperandA <= X"FFFFFFFF";
        ALU_Op   <= ALU_INC;
        wait for 10 ns;
        assert Result = X"00000000" report "INC overflow result incorrect" severity error;
        assert Zero = '1' and Carry = '1' report "INC overflow flags incorrect" severity error;
        
        -- Test 11: PASS operation
        report "Test 11: PASS 0x12345678";
        OperandA <= X"12345678";
        OperandB <= X"00000000";
        ALU_Op   <= ALU_PASS_A;
        wait for 10 ns;
        assert Result = X"12345678" report "PASS failed" severity error;
        
        -- Test 12: Negative flag test
        report "Test 12: Negative flag on MSB=1";
        OperandA <= X"80000000";  -- MSB set
        ALU_Op   <= ALU_PASS_A;
        wait for 10 ns;
        assert Negative = '1' report "Negative flag not set" severity error;
        
        report "ALU Testbench Completed Successfully";
        wait;
    end process;
    
end Behavioral;