LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.control_signals_pkg.ALL;

ENTITY id_ex_register IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        flush : IN STD_LOGIC;

        -- Data inputs from Decode Stage
        pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_a_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_b_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc1_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        rsrc2_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Control signals from Decode Stage
        decode_ctrl_in : IN decode_control_t;
        execute_ctrl_in : IN execute_control_t;
        memory_ctrl_in : IN memory_control_t;
        writeback_ctrl_in : IN writeback_control_t;

        -- Instruction type signals (for control unit feedback)
        is_swap_in : IN STD_LOGIC;
        is_interrupt_in : IN STD_LOGIC;
        is_hardware_int_in : IN STD_LOGIC;
        is_reti_in : IN STD_LOGIC;
        is_return_in : IN STD_LOGIC;
        is_call_in : IN STD_LOGIC;
        conditional_branch_in : IN STD_LOGIC;

        -- Data outputs to Execute Stage
        pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_a_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_b_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc1_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rsrc2_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Control signals to Execute Stage
        decode_ctrl_out : OUT decode_control_t;
        execute_ctrl_out : OUT execute_control_t;
        memory_ctrl_out : OUT memory_control_t;
        writeback_ctrl_out : OUT writeback_control_t;

        -- Signals for Control Unit Feedback (from Execute Stage)
        is_swap_out : OUT STD_LOGIC;
        is_interrupt_out : OUT STD_LOGIC;
        is_hardware_int_out : OUT STD_LOGIC;
        is_reti_out : OUT STD_LOGIC;
        is_return_out : OUT STD_LOGIC;
        is_call_out : OUT STD_LOGIC;
        conditional_branch_out : OUT STD_LOGIC
    );
END ENTITY id_ex_register;

ARCHITECTURE rtl OF id_ex_register IS
    
    -- Data registers
    SIGNAL pc_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pushed_pc_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL operand_a_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL operand_b_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL immediate_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rsrc1_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rsrc2_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rd_reg : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Control registers
    SIGNAL decode_ctrl_reg : decode_control_t;
    SIGNAL execute_ctrl_reg : execute_control_t;
    SIGNAL memory_ctrl_reg : memory_control_t;
    SIGNAL writeback_ctrl_reg : writeback_control_t;

    -- Instruction type registers
    SIGNAL is_swap_reg : STD_LOGIC;
    SIGNAL is_interrupt_reg : STD_LOGIC;
    SIGNAL is_hardware_int_reg : STD_LOGIC;
    SIGNAL is_reti_reg : STD_LOGIC;
    SIGNAL is_return_reg : STD_LOGIC;
    SIGNAL is_call_reg : STD_LOGIC;
    SIGNAL conditional_branch_reg : STD_LOGIC;

    -- Default/NOP control signals
    CONSTANT NOP_DECODE_CTRL : decode_control_t := (
        OutBSelect => (OTHERS => '0'),
        IsInterrupt => '0',
        IsHardwareInterrupt => '0',
        IsReturn => '0',
        IsCall => '0',
        IsReti => '0',
        IsJMP => '0',
        IsJMPConditional => '0',
        ConditionalType => (OTHERS => '0'),
        IsSwap => '0'
    );

    CONSTANT NOP_EXECUTE_CTRL : execute_control_t := (
        CCR_WriteEnable => '0',
        PassCCR => '0',
        PassImm => '0',
        ALU_Operation => (OTHERS => '0')
    );

    CONSTANT NOP_MEMORY_CTRL : memory_control_t := (
        SP_Enable => '0',
        SP_Function => '0',
        SPtoMem => '0',
        PassInterrupt => (OTHERS => '0'),
        MemRead => '0',
        MemWrite => '0',
        FlagFromMem => '0',
        IsSwap => '0'
    );

    CONSTANT NOP_WRITEBACK_CTRL : writeback_control_t := (
        MemToALU => '0',
        RegWrite => '0',
        OutPortWriteEn => '0'
    );

BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Reset all registers
            pc_reg <= (OTHERS => '0');
            pushed_pc_reg <= (OTHERS => '0');
            operand_a_reg <= (OTHERS => '0');
            operand_b_reg <= (OTHERS => '0');
            immediate_reg <= (OTHERS => '0');
            rsrc1_reg <= (OTHERS => '0');
            rsrc2_reg <= (OTHERS => '0');
            rd_reg <= (OTHERS => '0');
            decode_ctrl_reg <= NOP_DECODE_CTRL;
            execute_ctrl_reg <= NOP_EXECUTE_CTRL;
            memory_ctrl_reg <= NOP_MEMORY_CTRL;
            writeback_ctrl_reg <= NOP_WRITEBACK_CTRL;
            is_swap_reg <= '0';
            is_interrupt_reg <= '0';
            is_hardware_int_reg <= '0';
            is_reti_reg <= '0';
            is_return_reg <= '0';
            is_call_reg <= '0';
            conditional_branch_reg <= '0';

        ELSIF rising_edge(clk) THEN
            IF flush = '1' THEN
                -- Insert NOP (bubble)
                pc_reg <= (OTHERS => '0');
                pushed_pc_reg <= (OTHERS => '0');
                operand_a_reg <= (OTHERS => '0');
                operand_b_reg <= (OTHERS => '0');
                immediate_reg <= (OTHERS => '0');
                rsrc1_reg <= (OTHERS => '0');
                rsrc2_reg <= (OTHERS => '0');
                rd_reg <= (OTHERS => '0');
                decode_ctrl_reg <= NOP_DECODE_CTRL;
                execute_ctrl_reg <= NOP_EXECUTE_CTRL;
                memory_ctrl_reg <= NOP_MEMORY_CTRL;
                writeback_ctrl_reg <= NOP_WRITEBACK_CTRL;
                is_swap_reg <= '0';
                is_interrupt_reg <= '0';
                is_hardware_int_reg <= '0';
                is_reti_reg <= '0';
                is_return_reg <= '0';
                is_call_reg <= '0';
                conditional_branch_reg <= '0';

            ELSIF enable = '1' THEN
                -- Update with new values
                pc_reg <= pc_in;
                pushed_pc_reg <= pushed_pc_in;
                operand_a_reg <= operand_a_in;
                operand_b_reg <= operand_b_in;
                immediate_reg <= immediate_in;
                rsrc1_reg <= rsrc1_in;
                rsrc2_reg <= rsrc2_in;
                rd_reg <= rd_in;
                decode_ctrl_reg <= decode_ctrl_in;
                execute_ctrl_reg <= execute_ctrl_in;
                memory_ctrl_reg <= memory_ctrl_in;
                writeback_ctrl_reg <= writeback_ctrl_in;
                is_swap_reg <= is_swap_in;
                is_interrupt_reg <= is_interrupt_in;
                is_hardware_int_reg <= is_hardware_int_in;
                is_reti_reg <= is_reti_in;
                is_return_reg <= is_return_in;
                is_call_reg <= is_call_in;
                conditional_branch_reg <= conditional_branch_in;
            END IF;
            -- If enable = '0', hold current values (stall)
        END IF;
    END PROCESS;

    -- Output assignments
    pc_out <= pc_reg;
    pushed_pc_out <= pushed_pc_reg;
    operand_a_out <= operand_a_reg;
    operand_b_out <= operand_b_reg;
    immediate_out <= immediate_reg;
    rsrc1_out <= rsrc1_reg;
    rsrc2_out <= rsrc2_reg;
    rd_out <= rd_reg;
    decode_ctrl_out <= decode_ctrl_reg;
    execute_ctrl_out <= execute_ctrl_reg;
    memory_ctrl_out <= memory_ctrl_reg;
    writeback_ctrl_out <= writeback_ctrl_reg;
    is_swap_out <= is_swap_reg;
    is_interrupt_out <= is_interrupt_reg;
    is_hardware_int_out <= is_hardware_int_reg;
    is_reti_out <= is_reti_reg;
    is_return_out <= is_return_reg;
    is_call_out <= is_call_reg;
    conditional_branch_out <= conditional_branch_reg;

END ARCHITECTURE rtl;
