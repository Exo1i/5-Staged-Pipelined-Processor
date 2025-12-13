LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use work.pkg_opcodes.all;

ENTITY alu IS
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
END alu;

ARCHITECTURE Behavioral OF alu IS

SIGNAL temp_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL temp_carry : STD_LOGIC;
SIGNAL add_result : STD_LOGIC_VECTOR(32 DOWNTO 0);
SIGNAL sub_result : STD_LOGIC_VECTOR(32 DOWNTO 0);
SIGNAL inc_result : STD_LOGIC_VECTOR(32 DOWNTO 0);

BEGIN

  -- Extended arithmetic operations for carry detection (using Carry_In)
  add_result <= STD_LOGIC_VECTOR(UNSIGNED('0' & OperandA) + UNSIGNED('0' & OperandB) + ("" & Carry_In));
  sub_result <= STD_LOGIC_VECTOR(UNSIGNED('0' & OperandA) - UNSIGNED('0' & OperandB) - ("" & Carry_In));
  inc_result <= STD_LOGIC_VECTOR(UNSIGNED('0' & OperandA) + 1);

  -- ALU operation process
  PROCESS(ALU_Op, OperandA, OperandB, Carry_In, add_result, sub_result, inc_result)
  BEGIN
    -- Default values
    temp_result <= (OTHERS => '0');
    temp_carry <= '0';

    CASE ALU_Op IS
      WHEN ALU_ADD =>
        temp_result <= add_result(31 DOWNTO 0);
        temp_carry <= add_result(32);

      WHEN ALU_SUB =>
        temp_result <= sub_result(31 DOWNTO 0);
        temp_carry <= sub_result(32); -- Borrow flag

      WHEN ALU_AND =>
        temp_result <= OperandA AND OperandB;
        temp_carry <= '0';

      WHEN ALU_NOT =>
        temp_result <= NOT OperandA;
        temp_carry <= '0';

      WHEN ALU_INC =>
        temp_result <= inc_result(31 DOWNTO 0);
        temp_carry <= inc_result(32);

      WHEN ALU_PASS_A =>
        temp_result <= OperandA;
        temp_carry <= '0';

      WHEN ALU_PASS_B =>
        temp_result <= OperandB;
        temp_carry <= '0';

      WHEN ALU_SETC =>
        temp_result <= (OTHERS => '0');
        temp_carry <= '1';

      WHEN OTHERS =>
        temp_result <= (OTHERS => '0');
        temp_carry <= '0';
    END CASE;
  END PROCESS;

  -- Output assignments
  Result <= temp_result;

  -- Flag generation
  Zero <= '1' WHEN temp_result = X"00000000" ELSE '0';
  Negative <= temp_result(31);
  Carry <= temp_carry;

END Behavioral;