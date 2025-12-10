library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package pkg_opcodes is
    -- Instruction Opcodes (5-bit)
    constant OP_NOP    : std_logic_vector(4 downto 0) := "00000";
    constant OP_HLT    : std_logic_vector(4 downto 0) := "00001";
    constant OP_SETC   : std_logic_vector(4 downto 0) := "00010";
    constant OP_NOT    : std_logic_vector(4 downto 0) := "00011";
    constant OP_INC    : std_logic_vector(4 downto 0) := "00100";
    constant OP_OUT    : std_logic_vector(4 downto 0) := "00101";
    constant OP_IN     : std_logic_vector(4 downto 0) := "00110";
    constant OP_MOV    : std_logic_vector(4 downto 0) := "00111";
    constant OP_SWAP   : std_logic_vector(4 downto 0) := "01000";
    constant OP_ADD    : std_logic_vector(4 downto 0) := "01001";
    constant OP_SUB    : std_logic_vector(4 downto 0) := "01010";
    constant OP_AND    : std_logic_vector(4 downto 0) := "01011";
    constant OP_IADD   : std_logic_vector(4 downto 0) := "01100";
    constant OP_PUSH   : std_logic_vector(4 downto 0) := "01101";
    constant OP_POP    : std_logic_vector(4 downto 0) := "01110";
    constant OP_LDM    : std_logic_vector(4 downto 0) := "01111";
    constant OP_LDD    : std_logic_vector(4 downto 0) := "10000";
    constant OP_STD    : std_logic_vector(4 downto 0) := "10001";
    constant OP_JZ     : std_logic_vector(4 downto 0) := "10010";
    constant OP_JN     : std_logic_vector(4 downto 0) := "10011";
    constant OP_JC     : std_logic_vector(4 downto 0) := "10100";
    constant OP_JMP    : std_logic_vector(4 downto 0) := "10101";
    constant OP_CALL   : std_logic_vector(4 downto 0) := "10110";
    constant OP_RET    : std_logic_vector(4 downto 0) := "10111";
    constant OP_INT    : std_logic_vector(4 downto 0) := "11000";
    constant OP_RTI    : std_logic_vector(4 downto 0) := "11001";
    
    -- Override Operation Types (2-bit)
    constant OVERRIDE_PUSH_PC    : std_logic_vector(1 downto 0) := "00";
    constant OVERRIDE_PUSH_FLAGS : std_logic_vector(1 downto 0) := "01";
    constant OVERRIDE_POP_FLAGS  : std_logic_vector(1 downto 0) := "10";
    constant OVERRIDE_POP_PC     : std_logic_vector(1 downto 0) := "11";
    
    -- ALU Operations (3-bit)
    constant ALU_ADD   : std_logic_vector(2 downto 0) := "000";
    constant ALU_SUB   : std_logic_vector(2 downto 0) := "001";
    constant ALU_AND   : std_logic_vector(2 downto 0) := "010";
    constant ALU_NOT   : std_logic_vector(2 downto 0) := "011";
    constant ALU_INC   : std_logic_vector(2 downto 0) := "100";
    constant ALU_PASS  : std_logic_vector(2 downto 0) := "101";
    constant ALU_SWAP  : std_logic_vector(2 downto 0) := "110";
    constant ALU_SETC  : std_logic_vector(2 downto 0) := "111";
    
    -- OutBSelect Values (2-bit)
    constant OUTB_REGFILE   : std_logic_vector(1 downto 0) := "00";
    constant OUTB_PUSHED_PC : std_logic_vector(1 downto 0) := "01";
    constant OUTB_IMMEDIATE : std_logic_vector(1 downto 0) := "10";
    constant OUTB_INPUT_PORT: std_logic_vector(1 downto 0) := "11";
    
    -- Conditional Types (2-bit)
    constant COND_ZERO     : std_logic_vector(1 downto 0) := "00"; -- JZ
    constant COND_NEGATIVE : std_logic_vector(1 downto 0) := "01"; -- JN
    constant COND_CARRY    : std_logic_vector(1 downto 0) := "10"; -- JC
    constant COND_NONE     : std_logic_vector(1 downto 0) := "11"; -- Unconditional
    
    -- PassInterrupt Values (2-bit)
    constant PASS_INT_NORMAL    : std_logic_vector(1 downto 0) := "00"; -- Normal address from EX/MEM
    constant PASS_INT_RESET     : std_logic_vector(1 downto 0) := "01"; -- Reset vector (position 0)
    constant PASS_INT_SOFTWARE  : std_logic_vector(1 downto 0) := "10"; -- Software interrupt (from immediate)
    constant PASS_INT_HARDWARE  : std_logic_vector(1 downto 0) := "11"; -- Hardware interrupt (fixed position 1)
    
end package pkg_opcodes;
