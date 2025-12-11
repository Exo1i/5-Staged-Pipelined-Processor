LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;

ENTITY decode_stage IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Inputs from IF/ID Register
        pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        instruction_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        take_interrupt_in : IN STD_LOGIC;
        override_op_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- Control signals from Control Unit
        decode_ctrl : IN decode_control_t;
        execute_ctrl : IN execute_control_t;
        memory_ctrl : IN memory_control_t;
        writeback_ctrl : IN writeback_control_t;

        -- Stall control from Branch Decision Unit
        stall_control : IN STD_LOGIC;

        -- Input port data
        in_port : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

        -- SWAP feedback from Execute stage
        is_swap_ex : IN STD_LOGIC;

        -- Writeback signals (from WB stage)
        wb_rd : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        wb_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wb_enable : IN STD_LOGIC;

        -- Outputs to ID/EX Register
        pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_a_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_b_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc1_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rsrc2_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- Control signals to ID/EX Register
        decode_ctrl_out : OUT decode_control_t;
        execute_ctrl_out : OUT execute_control_t;
        memory_ctrl_out : OUT memory_control_t;
        writeback_ctrl_out : OUT writeback_control_t;
        
        -- Signals for Control Unit feedback
        opcode_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        is_interrupt_out : OUT STD_LOGIC;
        is_hardware_int_out : OUT STD_LOGIC;
        is_call_out : OUT STD_LOGIC;
        is_return_out : OUT STD_LOGIC;
        is_reti_out : OUT STD_LOGIC;
        is_jmp_out : OUT STD_LOGIC;
        is_jmp_conditional_out : OUT STD_LOGIC;
        conditional_type_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
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
    SIGNAL rd_addr : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL immediate : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL immediate_extended : STD_LOGIC_VECTOR(31 DOWNTO 0);

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
    ra_addr <= instruction_in(26 DOWNTO 24);  -- Source register A
    rb_addr <= instruction_in(23 DOWNTO 21);  -- Source register B
    rd_addr <= instruction_in(20 DOWNTO 18);  -- Destination register
    immediate <= instruction_in(15 DOWNTO 0); -- Immediate value

    -- Sign-extend immediate to 32 bits
    immediate_extended <= (31 DOWNTO 16 => immediate(15)) & immediate;

    -- ========== INSTRUCTION TYPE DETECTION ==========
    
    -- Detect special instructions for control unit
    is_interrupt <= '1' WHEN opcode = OP_INT ELSE '0';
    is_call <= '1' WHEN opcode = OP_CALL ELSE '0';
    is_return <= '1' WHEN opcode = OP_RET ELSE '0';
    is_reti <= '1' WHEN opcode = OP_RTI ELSE '0';
    is_jmp <= '1' WHEN opcode = OP_JMP ELSE '0';
    
    -- Conditional jumps
    is_jmp_conditional <= '1' WHEN (opcode = OP_JZ OR opcode = OP_JN OR opcode = OP_JC) ELSE '0';
    
    -- Determine conditional type
    conditional_type <= COND_ZERO WHEN opcode = OP_JZ ELSE
                        COND_NEGATIVE WHEN opcode = OP_JN ELSE
                        COND_CARRY WHEN opcode = OP_JC ELSE
                        "00";
    
    -- Hardware interrupt detection (from take_interrupt_in)
    is_hardware_int <= take_interrupt_in;
    
    -- ========== REGISTER FILE INSTANTIATION ==========
    
    reg_file_inst : register_file
        PORT MAP (
            clk => clk,
            reset => rst,
            Ra => ra_addr,
            Rb => rb_addr,
            ReadDataA => rf_data_a,
            ReadDataB => rf_data_b,
            Rdst => wb_rd,
            WriteData => wb_data,
            WriteEnable => wb_enable
        );

    -- ========== OPERAND B MULTIPLEXER ==========
    -- Select source for Operand B based on OutBSelect from control unit
    
    PROCESS (decode_ctrl, rf_data_b, pushed_pc_in, immediate_extended, in_port)
    BEGIN
        CASE decode_ctrl.OutBSelect IS
            WHEN OUTB_REGFILE =>
                operand_b <= rf_data_b;
            WHEN OUTB_PUSHED_PC =>
                operand_b <= pushed_pc_in;
            WHEN OUTB_IMMEDIATE =>
                operand_b <= immediate_extended;
            WHEN OUTB_INPUT_PORT =>
                operand_b <= in_port;
            WHEN OTHERS =>
                operand_b <= rf_data_b;
        END CASE;
    END PROCESS;

    -- ========== REGISTER DESTINATION MULTIPLEXER (SWAP) ==========
    -- For SWAP instruction: 2nd cycle uses Rsrc2 as destination
    -- Normal instructions: use Rdst field
    
    rd_selected <= rb_addr WHEN is_swap_ex = '1' ELSE rd_addr;

    -- ========== STALL CONTROL LOGIC ==========
    -- When stall_control = '1', insert NOPs in all control signals
    
    PROCESS (stall_control, decode_ctrl, execute_ctrl, memory_ctrl, writeback_ctrl)
    BEGIN
        IF stall_control = '1' THEN
            -- Insert NOP by setting all control signals to default
            final_decode_ctrl <= DECODE_CTRL_DEFAULT;
            final_execute_ctrl <= EXECUTE_CTRL_DEFAULT;
            final_memory_ctrl <= MEMORY_CTRL_DEFAULT;
            final_writeback_ctrl <= WRITEBACK_CTRL_DEFAULT;
        ELSE
            -- Pass through control signals from opcode decoder
            final_decode_ctrl <= decode_ctrl;
            final_execute_ctrl <= execute_ctrl;
            final_memory_ctrl <= memory_ctrl;
            final_writeback_ctrl <= writeback_ctrl;
        END IF;
    END PROCESS;

    -- ========== OUTPUT ASSIGNMENTS ==========
    
    -- Pass-through signals
    pc_out <= pc_in;
    pushed_pc_out <= pushed_pc_in;
    immediate_out <= immediate_extended;

    -- Register addresses
    rsrc1_out <= ra_addr;
    rsrc2_out <= rb_addr;
    rd_out <= rd_selected;  -- After SWAP mux

    -- Operand outputs
    operand_a_out <= rf_data_a;         -- Always from register file
    -- Control feedback signals (to Control Unit at top level)
    opcode_out <= opcode;
    is_jmp_out <= is_jmp;
    is_call_out <= is_call;
    is_jmp_conditional_out <= is_jmp_conditional;
    conditional_type_out <= conditional_type;
    is_interrupt_out <= is_interrupt OR take_interrupt_in;  -- Software or hardware interrupt
    is_hardware_int_out <= is_hardware_int;
    is_return_out <= is_return;
    is_reti_out <= is_reti;
    -- Interrupt Unit signals
    is_interrupt_out <= is_interrupt OR take_interrupt_in;  -- Software or hardware interrupt
    is_hardware_int_out <= is_hardware_int;
    is_return_out <= is_return;
    is_reti_out <= is_reti;

    -- Freeze Control signal
    freeze_out <= '0';  -- No freeze request from decode (can be extended for load-use hazards)

END ARCHITECTURE Behavioral;