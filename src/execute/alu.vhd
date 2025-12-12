LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use work.pkg_opcodes.all;

ENTITY alu IS
  PORT (
    OperandA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    OperandB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    ALU_Op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    Result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Zero : OUT STD_LOGIC;
    Negative : OUT STD_LOGIC;
    Carry : OUT STD_LOGIC
  );
END alu;

ARCHITECTURE Behavioral OF alu IS
  -- ALU Operation Codes

  SIGNAL result_temp : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL carry_temp : STD_LOGIC;

BEGIN
  PROCESS (OperandA, OperandB, ALU_Op)
    VARIABLE temp_33bit : unsigned(32 DOWNTO 0);
  BEGIN
    carry_temp <= '0'; -- Default carry

    CASE ALU_Op IS
      WHEN ALU_ADD =>
        -- 33-bit addition for carry detection
        temp_33bit := unsigned('0' & OperandA) + unsigned('0' & OperandB);
        result_temp <= STD_LOGIC_VECTOR(temp_33bit(31 DOWNTO 0));
        carry_temp <= temp_33bit(32);

      WHEN ALU_SUB =>
        -- 33-bit subtraction for borrow detection
        temp_33bit := unsigned('0' & OperandA) - unsigned('0' & OperandB);
        result_temp <= STD_LOGIC_VECTOR(temp_33bit(31 DOWNTO 0));
        carry_temp <= temp_33bit(32); -- Borrow flag

      WHEN ALU_AND =>
        result_temp <= OperandA AND OperandB;

      WHEN ALU_NOT =>
        result_temp <= NOT OperandA;

      WHEN ALU_INC =>
        -- Increment OperandA
        temp_33bit := unsigned('0' & OperandA) + 1;
        result_temp <= STD_LOGIC_VECTOR(temp_33bit(31 DOWNTO 0));
        carry_temp <= temp_33bit(32);

      WHEN ALU_PASS_A =>
        -- Pass-through OperandA
        result_temp <= OperandA;

      WHEN ALU_PASS_B =>
        -- Pass-through OperandB
        result_temp <= OperandB;

      WHEN OTHERS =>
        result_temp <= (OTHERS => '0');
    END CASE;
  END PROCESS;

  -- Output assignments
  Result <= result_temp;

  -- Flag generation
  Zero <= '1' WHEN result_temp = X"00000000" ELSE
          '0';
  Negative <= result_temp(31); -- MSB indicates negative
  Carry <= carry_temp;

END Behavioral;