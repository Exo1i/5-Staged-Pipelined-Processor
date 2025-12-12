LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pkg_opcodes.ALL;

ENTITY pc IS
    PORT (
        -- Clock and Reset
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Control Signals from Branch Decision Unit
        BranchSelect : IN STD_LOGIC; -- 0=PC+1, 1=branch target
        BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- Target mux select
        enable : IN STD_LOGIC; -- Enable PC update (0 for HLT or stalls)

        -- Branch Target Sources
        target_decode : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Immediate from decode stage
        target_execute : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Immediate from execute stage
        target_memory : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Interrupt address from memory
        target_reset : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Reset vector from memory[0]

        -- Output
        pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- Current PC value
        pc_plus_one : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- PC + 1 for CALL/INT
    );
END ENTITY pc;

ARCHITECTURE rtl OF pc IS
    -- Internal PC register
    SIGNAL pc_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Next PC value
    SIGNAL pc_next : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Branch target based on BranchTargetSelect
    SIGNAL selected_branch_target : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
    -- Multiplexer for branch target selection
    PROCESS (BranchTargetSelect, target_decode, target_execute, target_memory, target_reset)
    BEGIN
        CASE BranchTargetSelect IS
            WHEN "00" => -- TARGET_DECODE
                selected_branch_target <= target_decode;
            WHEN "01" => -- TARGET_EXECUTE
                selected_branch_target <= target_execute;
            WHEN "10" => -- TARGET_MEMORY
                selected_branch_target <= target_memory;
            WHEN "11" => -- TARGET_RESET
                selected_branch_target <= target_reset;
            WHEN OTHERS =>
                selected_branch_target <= (OTHERS => '0');
        END CASE;
    END PROCESS;

    -- Combinational logic for next PC value
    PROCESS (pc_reg, BranchSelect, selected_branch_target, enable)
    BEGIN
        IF enable = '1' THEN
            IF BranchSelect = '1' THEN
                -- Take branch target
                pc_next <= selected_branch_target;
            ELSE
                -- Normal increment (PC + 1)
                pc_next <= STD_LOGIC_VECTOR(UNSIGNED(pc_reg) + 1);
            END IF;
        ELSE
            -- Hold current value when disabled (HLT or stall)
            pc_next <= pc_reg;
        END IF;
    END PROCESS;

    -- Sequential logic for PC register
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- On reset, PC will be loaded from memory[0] in the next cycle
            -- Initialize to 0 temporarily
            pc_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            pc_reg <= pc_next;
        END IF;
    END PROCESS;

    -- Output assignments
    pc_out <= pc_reg;
    pc_plus_one <= STD_LOGIC_VECTOR(UNSIGNED(pc_reg) + 1);

END ARCHITECTURE rtl;