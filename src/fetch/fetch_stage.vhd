LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY fetch_stage IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        stall : IN STD_LOGIC;

        -- Inputs from Control/Branch Unit
        BranchSelect : IN STD_LOGIC;
        BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Branch Targets
        target_decode : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        target_execute : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        target_memory : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Memory Interface
        mem_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Instruction or Reset Vector
        pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Pipeline Output (to Decode)
        pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        instruction_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Interrupt Input
        intr_in : IN STD_LOGIC;
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
            pc_plus_one : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL pc_enable : STD_LOGIC;
    SIGNAL current_pc : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pc_plus_one : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- Enable PC update when not stalled
    pc_enable <= NOT stall;

    -- Output current PC to memory
    pc_out <= current_pc;

    -- Pass instruction from memory to decode stage
    instruction_out <= mem_data;

    -- Mux for PushedPC selection (PC vs PC+1)
    pushed_pc_out <= current_pc WHEN PushPCSelect = '0' ELSE
        pc_plus_one;

    -- Instantiate PC
    pc_inst : pc
    PORT MAP(
        clk => clk,
        rst => rst,
        BranchSelect => BranchSelect,
        BranchTargetSelect => BranchTargetSelect,
        enable => pc_enable,
        target_decode => target_decode,
        target_execute => target_execute,
        target_memory => target_memory,
        target_reset => mem_data, -- Reset vector comes from memory (M[0])
        pc_out => current_pc,
        pc_plus_one => pc_plus_one
    );

END ARCHITECTURE Behavioral;