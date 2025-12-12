LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.pkg_opcodes.ALL;
USE work.control_signals_pkg.ALL;

ENTITY testbench_decoder IS
END testbench_decoder;

ARCHITECTURE Behavioral OF testbench_decoder IS

    -- Component Declaration
    COMPONENT opcode_decoder
        PORT (
            opcode : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            override_operation : IN STD_LOGIC;
            override_type : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            isSwap_from_execute : IN STD_LOGIC;
            take_interrupt : IN STD_LOGIC;
            is_hardware_int_mem : IN STD_LOGIC;
            decode_ctrl : OUT decode_control_t;
            execute_ctrl : OUT execute_control_t;
            memory_ctrl : OUT memory_control_t;
            writeback_ctrl : OUT writeback_control_t
        );
    END COMPONENT;

    -- Signals
    SIGNAL opcode : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL override_operation : STD_LOGIC := '0';
    SIGNAL override_type : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL isSwap_from_execute : STD_LOGIC := '0';
    SIGNAL take_interrupt : STD_LOGIC := '0';
    SIGNAL is_hardware_int_mem : STD_LOGIC := '0';
    SIGNAL decode_ctrl : decode_control_t;
    SIGNAL execute_ctrl : execute_control_t;
    SIGNAL memory_ctrl : memory_control_t;
    SIGNAL writeback_ctrl : writeback_control_t;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut : opcode_decoder
    PORT MAP(
        opcode => opcode,
        override_operation => override_operation,
        override_type => override_type,
        isSwap_from_execute => isSwap_from_execute,
        take_interrupt => take_interrupt,
        is_hardware_int_mem => is_hardware_int_mem,
        decode_ctrl => decode_ctrl,
        execute_ctrl => execute_ctrl,
        memory_ctrl => memory_ctrl,
        writeback_ctrl => writeback_ctrl
    );

    -- Stimulus Process
    stim_proc : PROCESS
        -- Test procedure
        PROCEDURE test_instruction(
            CONSTANT test_opcode : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            CONSTANT instruction_name : IN STRING
        ) IS
        BEGIN
            opcode <= test_opcode;
            WAIT FOR 10 ns;
            REPORT "Testing " & instruction_name SEVERITY note;
        END PROCEDURE;
    BEGIN
        -- Wait for global reset
        WAIT FOR 5 ns;

        REPORT "====================================";
        REPORT "Starting Opcode Decoder Tests";
        REPORT "====================================";

        -- Test all normal instructions
        test_instruction(OP_NOP, "NOP");
        ASSERT decode_ctrl.IsJMP = '0' AND decode_ctrl.IsCall = '0'
        REPORT "NOP failed" SEVERITY error;

        test_instruction(OP_HLT, "HLT");

        test_instruction(OP_SETC, "SETC");
        ASSERT execute_ctrl.CCR_WriteEnable = '1'
        REPORT "SETC: CCR_WriteEnable not set" SEVERITY error;

        test_instruction(OP_NOT, "NOT");
        ASSERT execute_ctrl.ALU_Operation = ALU_NOT AND
        execute_ctrl.CCR_WriteEnable = '1' AND
        writeback_ctrl.RegWrite = '1'
        REPORT "NOT failed" SEVERITY error;

        test_instruction(OP_INC, "INC");
        ASSERT execute_ctrl.ALU_Operation = ALU_INC AND
        execute_ctrl.CCR_WriteEnable = '1' AND
        writeback_ctrl.RegWrite = '1'
        REPORT "INC failed" SEVERITY error;

        test_instruction(OP_OUT, "OUT");
        ASSERT writeback_ctrl.OutPortWriteEn = '1'
        REPORT "OUT: OutPortWriteEn not set" SEVERITY error;

        test_instruction(OP_IN, "IN");
        ASSERT decode_ctrl.OutBSelect = OUTB_INPUT_PORT AND
        writeback_ctrl.RegWrite = '1'
        REPORT "IN failed" SEVERITY error;

        test_instruction(OP_MOV, "MOV");
        ASSERT execute_ctrl.ALU_Operation = ALU_PASS AND
        writeback_ctrl.RegWrite = '1'
        REPORT "MOV failed" SEVERITY error;

        test_instruction(OP_SWAP, "SWAP - First Cycle");
        ASSERT decode_ctrl.IsSwap = '1' AND
        execute_ctrl.ALU_Operation = ALU_PASS AND
        writeback_ctrl.RegWrite = '1' AND
        writeback_ctrl.MemToALU = '0'
        REPORT "SWAP first cycle failed" SEVERITY error;

        -- Test SWAP second cycle (override via isSwap_from_execute)
        opcode <= OP_NOP; -- Different opcode to show override
        isSwap_from_execute <= '1';
        WAIT FOR 10 ns;
        REPORT "Testing SWAP - Second Cycle Override";
        ASSERT execute_ctrl.ALU_Operation = ALU_PASS AND
        writeback_ctrl.RegWrite = '1'
        REPORT "SWAP second cycle override failed" SEVERITY error;
        isSwap_from_execute <= '0';

        test_instruction(OP_ADD, "ADD");
        ASSERT execute_ctrl.ALU_Operation = ALU_ADD AND
        execute_ctrl.CCR_WriteEnable = '1' AND
        writeback_ctrl.RegWrite = '1'
        REPORT "ADD failed" SEVERITY error;

        test_instruction(OP_SUB, "SUB");
        ASSERT execute_ctrl.ALU_Operation = ALU_SUB AND
        execute_ctrl.CCR_WriteEnable = '1' AND
        writeback_ctrl.RegWrite = '1'
        REPORT "SUB failed" SEVERITY error;

        test_instruction(OP_AND, "AND");
        ASSERT execute_ctrl.ALU_Operation = ALU_AND AND
        execute_ctrl.CCR_WriteEnable = '1' AND
        writeback_ctrl.RegWrite = '1'
        REPORT "AND failed" SEVERITY error;

        test_instruction(OP_IADD, "IADD");
        ASSERT decode_ctrl.OutBSelect = OUTB_IMMEDIATE AND
        execute_ctrl.ALU_Operation = ALU_ADD AND
        execute_ctrl.PassImm = '1' AND
        execute_ctrl.CCR_WriteEnable = '1' AND
        writeback_ctrl.RegWrite = '1'
        REPORT "IADD failed" SEVERITY error;

        test_instruction(OP_PUSH, "PUSH");
        ASSERT memory_ctrl.SP_Enable = '1' AND
        memory_ctrl.SP_Function = '0' AND
        memory_ctrl.SPtoMem = '1' AND
        memory_ctrl.MemWrite = '1'
        REPORT "PUSH failed" SEVERITY error;

        test_instruction(OP_POP, "POP");
        ASSERT memory_ctrl.SP_Enable = '1' AND
        memory_ctrl.SP_Function = '1' AND
        memory_ctrl.SPtoMem = '1' AND
        memory_ctrl.MemRead = '1' AND
        writeback_ctrl.RegWrite = '1' AND
        writeback_ctrl.MemToALU = '1'
        REPORT "POP failed" SEVERITY error;

        test_instruction(OP_LDM, "LDM");
        ASSERT decode_ctrl.OutBSelect = OUTB_IMMEDIATE AND
        execute_ctrl.PassImm = '1' AND
        writeback_ctrl.RegWrite = '1' AND
        writeback_ctrl.MemToALU = '0'
        REPORT "LDM failed" SEVERITY error;

        test_instruction(OP_LDD, "LDD");
        ASSERT execute_ctrl.PassImm = '1' AND
        memory_ctrl.MemRead = '1' AND
        writeback_ctrl.RegWrite = '1' AND
        writeback_ctrl.MemToALU = '1'
        REPORT "LDD failed" SEVERITY error;

        test_instruction(OP_STD, "STD");
        ASSERT execute_ctrl.PassImm = '1' AND
        memory_ctrl.MemWrite = '1'
        REPORT "STD failed" SEVERITY error;

        test_instruction(OP_JZ, "JZ");
        ASSERT decode_ctrl.IsJMPConditional = '1' AND
        execute_ctrl.ConditionalType = COND_ZERO AND
        execute_ctrl.PassImm = '1'
        REPORT "JZ failed" SEVERITY error;

        test_instruction(OP_JN, "JN");
        ASSERT decode_ctrl.IsJMPConditional = '1' AND
        execute_ctrl.ConditionalType = COND_NEGATIVE AND
        execute_ctrl.PassImm = '1'
        REPORT "JN failed" SEVERITY error;

        test_instruction(OP_JC, "JC");
        ASSERT decode_ctrl.IsJMPConditional = '1' AND
        execute_ctrl.ConditionalType = COND_CARRY AND
        execute_ctrl.PassImm = '1'
        REPORT "JC failed" SEVERITY error;

        test_instruction(OP_JMP, "JMP");
        ASSERT decode_ctrl.IsJMP = '1' AND
        execute_ctrl.PassImm = '1'
        REPORT "JMP failed" SEVERITY error;

        test_instruction(OP_CALL, "CALL");
        ASSERT decode_ctrl.IsCall = '1' AND
        decode_ctrl.IsJMP = '1' AND
        execute_ctrl.PassImm = '1'
        REPORT "CALL failed" SEVERITY error;

        test_instruction(OP_RET, "RET");
        ASSERT decode_ctrl.IsReturn = '1'
        REPORT "RET failed" SEVERITY error;

        test_instruction(OP_INT, "INT");
        ASSERT decode_ctrl.IsInterrupt = '1' AND
        execute_ctrl.PassImm = '1' AND
        memory_ctrl.PassInterrupt = PASS_INT_SOFTWARE
        REPORT "INT failed" SEVERITY error;

        test_instruction(OP_RTI, "RTI");
        ASSERT decode_ctrl.IsReti = '1'
        REPORT "RTI failed" SEVERITY error;

        REPORT "====================================";
        REPORT "Testing Override Operations";
        REPORT "====================================";

        -- Test Override PUSH_PC
        override_operation <= '1';
        override_type <= OVERRIDE_PUSH_PC;
        opcode <= OP_NOP; -- Opcode should be ignored
        WAIT FOR 10 ns;
        REPORT "Testing OVERRIDE_PUSH_PC";
        ASSERT memory_ctrl.SP_Enable = '1' AND
        memory_ctrl.SP_Function = '0' AND
        memory_ctrl.SPtoMem = '1' AND
        memory_ctrl.MemWrite = '1' AND
        decode_ctrl.OutBSelect = OUTB_PUSHED_PC
        REPORT "OVERRIDE_PUSH_PC failed" SEVERITY error;

        -- Test Override PUSH_FLAGS
        override_type <= OVERRIDE_PUSH_FLAGS;
        WAIT FOR 10 ns;
        REPORT "Testing OVERRIDE_PUSH_FLAGS";
        ASSERT memory_ctrl.SP_Enable = '1' AND
        memory_ctrl.SP_Function = '0' AND
        memory_ctrl.SPtoMem = '1' AND
        memory_ctrl.MemWrite = '1' AND
        execute_ctrl.PassCCR = '1'
        REPORT "OVERRIDE_PUSH_FLAGS failed" SEVERITY error;

        -- Test Override POP_PC
        override_type <= OVERRIDE_POP_PC;
        WAIT FOR 10 ns;
        REPORT "Testing OVERRIDE_POP_PC";
        ASSERT memory_ctrl.SP_Enable = '1' AND
        memory_ctrl.SP_Function = '1' AND
        memory_ctrl.SPtoMem = '1' AND
        memory_ctrl.MemRead = '1' AND
        writeback_ctrl.MemToALU = '1'
        REPORT "OVERRIDE_POP_PC failed" SEVERITY error;

        -- Test Override POP_FLAGS
        override_type <= OVERRIDE_POP_FLAGS;
        WAIT FOR 10 ns;
        REPORT "Testing OVERRIDE_POP_FLAGS";
        ASSERT memory_ctrl.SP_Enable = '1' AND
        memory_ctrl.SP_Function = '1' AND
        memory_ctrl.SPtoMem = '1' AND
        memory_ctrl.MemRead = '1' AND
        memory_ctrl.FlagFromMem = '1'
        REPORT "OVERRIDE_POP_FLAGS failed" SEVERITY error;

        override_operation <= '0';

        REPORT "====================================";
        REPORT "All Tests Completed Successfully!";
        REPORT "====================================";

        WAIT;
    END PROCESS;

END Behavioral;