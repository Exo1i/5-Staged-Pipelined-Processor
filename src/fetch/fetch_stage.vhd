LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY fetch_stage IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        stall : IN STD_LOGIC;

        -- Inputs from Control/Branch Unit
        BranchSelect : IN STD_LOGIC;
        BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Branch Targets Bundle
        branch_targets : IN branch_targets_t;

        -- Memory Interface
        mem_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Instruction or Reset Vector

        -- Pipeline Output Bundle (to IF/ID register)
        fetch_out : OUT fetch_outputs_t;

        PushPCSelect : IN STD_LOGIC -- 0=PC, 1=PC+1
    );
END ENTITY fetch_stage;

ARCHITECTURE Behavioral OF fetch_stage IS

    COMPONENT pc IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            BranchSelect : IN STD_LOGIC;
            BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            enable : IN STD_LOGIC;
            target_decode : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_execute : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_memory : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            target_reset : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_nxt: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pc_plus_one : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL pc_enable : STD_LOGIC;
    SIGNAL current_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_nxt : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_plus_one : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Enable PC update when not stalled
    pc_enable <= NOT stall;

    -- Populate output record
    fetch_out.pc <= current_pc;
    fetch_out.instruction <= mem_data;
    fetch_out.pushed_pc <= pc_nxt WHEN PushPCSelect = '0' ELSE
    pc_plus_one;

    -- Instantiate PC
    pc_inst : pc
    PORT MAP(
        clk => clk,
        rst => rst,
        BranchSelect => BranchSelect,
        BranchTargetSelect => BranchTargetSelect,
        enable => pc_enable,
        target_decode => branch_targets.target_decode,
        target_execute => branch_targets.target_execute,
        target_memory => branch_targets.target_memory,
        target_reset => mem_data, -- Reset vector comes from memory (M[0])
        pc_out => current_pc,
        pc_nxt => pc_nxt,
        pc_plus_one => pc_plus_one
    );

END ARCHITECTURE Behavioral;