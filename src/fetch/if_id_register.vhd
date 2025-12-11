LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY if_id_register IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC; -- Enable/Stall control
        flush : IN STD_LOGIC; -- Flush control (for branches/interrupts) -- inserts NOP

        -- Inputs from Fetch Stage
        pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- PushedPC (PC or PC+1)
        instruction_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        take_interrupt_in : IN STD_LOGIC;
        override_op_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- Override Operation (e.g. for INT/RTI)

        -- Outputs to Decode Stage
        pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- PushedPC
        instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        take_interrupt_out : OUT STD_LOGIC;
        override_op_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY if_id_register;

ARCHITECTURE rtl OF if_id_register IS
    -- Internal registers
    SIGNAL pc_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pushed_pc_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL instruction_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL take_interrupt_reg : STD_LOGIC;
    SIGNAL override_op_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- NOP Instruction Constant (Assuming all zeros is NOP, adjust if different)
    CONSTANT NOP_INSTRUCTION : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Reset all registers
            pc_reg <= (OTHERS => '0');
            pushed_pc_reg <= (OTHERS => '0');
            instruction_reg <= NOP_INSTRUCTION;
            take_interrupt_reg <= '0';
            override_op_reg <= (OTHERS => '0');

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                -- Flush pipeline register (insert bubble/NOP)
                pc_reg <= (OTHERS => '0');
                pushed_pc_reg <= (OTHERS => '0');
                instruction_reg <= NOP_INSTRUCTION;
                take_interrupt_reg <= '0';
                override_op_reg <= (OTHERS => '0');

            ELSIF enable = '1' THEN
                -- Update registers with new values
                pc_reg <= pc_in;
                pushed_pc_reg <= pushed_pc_in;
                instruction_reg <= instruction_in;
                take_interrupt_reg <= take_interrupt_in;
                override_op_reg <= override_op_in;
            END IF;
            -- If enable = '0', hold current values (stall)
        END IF;
    END PROCESS;

    -- Output assignments
    pc_out <= pc_reg;
    pushed_pc_out <= pushed_pc_reg;
    instruction_out <= instruction_reg;
    take_interrupt_out <= take_interrupt_reg;
    override_op_out <= override_op_reg;

END ARCHITECTURE rtl;