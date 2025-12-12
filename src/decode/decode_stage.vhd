LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY decode_stage IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Inputs from IF/ID Register
        pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        instruction_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        take_interrupt_in : IN STD_LOGIC;

        -- Control signals from Control Unit (as record)
        ctrl_in : IN decode_ctrl_outputs_t;

        -- Stall control from Branch Decision Unit
        stall_control : IN STD_LOGIC;

        -- Input port data
        in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- Immediate value from Fetch stage (fetched cycle after opcode)
        immediate_from_fetch : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- SWAP feedback from Execute stage
        is_swap_ex : IN STD_LOGIC;

        -- Writeback signals (from WB stage as record)
        wb_in : IN writeback_outputs_t;

        -- Data outputs to ID/EX Register (as record)
        decode_out : OUT decode_outputs_t;

        -- Control signals to ID/EX Register (as record)
        ctrl_out : OUT decode_ctrl_outputs_t;

        -- Signals for Control Unit feedback (as record)
        flags_out : OUT decode_flags_t
    );
END ENTITY decode_stage;

ARCHITECTURE Behavioral OF decode_stage IS

    -- Register File Component
    COMPONENT register_file IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            Ra : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            Rb : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            ReadDataA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            ReadDataB : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Rdst : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            WriteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            WriteEnable : IN STD_LOGIC
        );
    END COMPONENT;

    -- Register file outputs
    SIGNAL rf_data_a : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL rf_data_b : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Operand B after mux
    SIGNAL operand_b : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Register destination after SWAP mux
    SIGNAL rd_selected : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Control signals after stall handling
    SIGNAL final_decode_ctrl : decode_control_t;
    SIGNAL final_execute_ctrl : execute_control_t;
    SIGNAL final_memory_ctrl : memory_control_t;
    SIGNAL final_writeback_ctrl : writeback_control_t;

    -- Instruction fields
    SIGNAL opcode : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL ra_addr : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rb_addr : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rc_addr : STD_LOGIC_VECTOR(2 DOWNTO 0);
    -- Note: Immediate comes from immediate_from_fetch port (next fetch cycle)

    -- Instruction type detection
    SIGNAL is_interrupt : STD_LOGIC;
    SIGNAL is_hardware_int : STD_LOGIC;
    SIGNAL is_call : STD_LOGIC;
    SIGNAL is_return : STD_LOGIC;
    SIGNAL is_reti : STD_LOGIC;
    SIGNAL is_jmp : STD_LOGIC;
    SIGNAL is_jmp_conditional : STD_LOGIC;
    SIGNAL conditional_type : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    -- ========== INSTRUCTION DECODING ==========

    -- Extract instruction fields
    opcode <= instruction_in(31 DOWNTO 27);
    ra_addr <= instruction_in(26 DOWNTO 24); -- Source register A
    rb_addr <= instruction_in(23 DOWNTO 21); -- Source register B
    rc_addr <= instruction_in(20 DOWNTO 18); -- Destination register
    -- Note: Immediate value comes from immediate_from_fetch (fetched in cycle after opcode)

    -- ========== INSTRUCTION TYPE DETECTION ==========

    -- Detect special instructions for control unit
    is_interrupt <= '1' WHEN opcode = OP_INT ELSE
        '0';
    is_call <= '1' WHEN opcode = OP_CALL ELSE
        '0';
    is_return <= '1' WHEN opcode = OP_RET ELSE
        '0';
    is_reti <= '1' WHEN opcode = OP_RTI ELSE
        '0';
    is_jmp <= '1' WHEN opcode = OP_JMP ELSE
        '0';

    -- Conditional jumps
    is_jmp_conditional <= '1' WHEN (opcode = OP_JZ OR opcode = OP_JN OR opcode = OP_JC) ELSE
        '0';

    -- Determine conditional type
    conditional_type <= COND_ZERO WHEN opcode = OP_JZ ELSE
        COND_NEGATIVE WHEN opcode = OP_JN ELSE
        COND_CARRY WHEN opcode = OP_JC ELSE
        "00";

    -- Hardware interrupt detection (from take_interrupt_in)
    is_hardware_int <= take_interrupt_in;

    -- ========== REGISTER FILE INSTANTIATION ==========

    reg_file_inst : register_file
    PORT MAP(
        clk => clk,
        reset => rst,
        Ra => ra_addr,
        Rb => rb_addr,
        ReadDataA => rf_data_a,
        ReadDataB => rf_data_b,
        Rdst => wb_in.rdst,
        WriteData => wb_in.data,
        WriteEnable => wb_in.reg_we
    );

    -- ========== OPERAND B MULTIPLEXER ==========
    -- Select source for Operand B based on OutBSelect from control unit

    PROCESS (ctrl_in, rf_data_b, pushed_pc_in, immediate_from_fetch, in_port)
    BEGIN
        CASE ctrl_in.decode_ctrl.OutBSelect IS
            WHEN OUTB_REGFILE =>
                operand_b <= rf_data_b;
            WHEN OUTB_PUSHED_PC =>
                operand_b <= pushed_pc_in;
            WHEN OUTB_IMMEDIATE =>
                operand_b <= immediate_from_fetch; -- Full 32-bit immediate from fetch
            WHEN OUTB_INPUT_PORT =>
                operand_b <= in_port;
            WHEN OTHERS =>
                operand_b <= rf_data_b;
        END CASE;
    END PROCESS;

    -- ========== REGISTER DESTINATION MULTIPLEXER (SWAP) ==========
    -- For SWAP instruction: 2nd cycle uses Rsrc2 as destination
    -- Normal instructions: use Rdst field

    rd_selected <= rc_addr WHEN is_swap_ex = '1' ELSE
        ra_addr;

    -- ========== STALL CONTROL LOGIC ==========
    -- When stall_control = '1', insert NOPs in all control signals

    PROCESS (stall_control, ctrl_in)
    BEGIN
        IF stall_control = '1' THEN
            -- Insert NOP by setting all control signals to default
            final_decode_ctrl <= DECODE_CTRL_DEFAULT;
            final_execute_ctrl <= EXECUTE_CTRL_DEFAULT;
            final_memory_ctrl <= MEMORY_CTRL_DEFAULT;
            final_writeback_ctrl <= WRITEBACK_CTRL_DEFAULT;
        ELSE
            -- Pass through control signals from opcode decoder
            final_decode_ctrl <= ctrl_in.decode_ctrl;
            final_execute_ctrl <= ctrl_in.execute_ctrl;
            final_memory_ctrl <= ctrl_in.memory_ctrl;
            final_writeback_ctrl <= ctrl_in.writeback_ctrl;
        END IF;
    END PROCESS;

    -- ========== OUTPUT ASSIGNMENTS ==========

    -- Populate decode_outputs_t record
    decode_out.pc <= pc_in;
    decode_out.pushed_pc <= pushed_pc_in;
    decode_out.operand_a <= rf_data_a;
    decode_out.operand_b <= operand_b;
    decode_out.immediate <= immediate_from_fetch;
    decode_out.rsrc1 <= ra_addr;
    decode_out.rsrc2 <= rb_addr;
    decode_out.rd <= rd_selected;
    decode_out.opcode <= opcode;

    -- Populate decode_ctrl_outputs_t record (after stall handling)
    ctrl_out.decode_ctrl <= final_decode_ctrl;
    ctrl_out.execute_ctrl <= final_execute_ctrl;
    ctrl_out.memory_ctrl <= final_memory_ctrl;
    ctrl_out.writeback_ctrl <= final_writeback_ctrl;

    -- Populate decode_flags_t record (control feedback signals)
    flags_out.is_jmp <= is_jmp;
    flags_out.is_call <= is_call;
    flags_out.is_jmp_conditional <= is_jmp_conditional;
    flags_out.conditional_type <= conditional_type;
    flags_out.is_interrupt <= is_interrupt OR take_interrupt_in;
    flags_out.is_hardware_int <= is_hardware_int;
    flags_out.is_return <= is_return;
    flags_out.is_reti <= is_reti;

END ARCHITECTURE Behavioral;