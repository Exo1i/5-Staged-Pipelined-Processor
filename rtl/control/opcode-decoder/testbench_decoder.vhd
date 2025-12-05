library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;
use work.control_signals_pkg.all;

entity testbench_decoder is
end testbench_decoder;

architecture Behavioral of testbench_decoder is
    
    -- Component Declaration
    component opcode_decoder
        Port (
            opcode              : in  std_logic_vector(4 downto 0);
            override_operation  : in  std_logic;
            override_type       : in  std_logic_vector(1 downto 0);
            isSwap_from_execute : in  std_logic;
            decode_ctrl         : out decode_control_t;
            execute_ctrl        : out execute_control_t;
            memory_ctrl         : out memory_control_t;
            writeback_ctrl      : out writeback_control_t
        );
    end component;
    
    -- Signals
    signal opcode              : std_logic_vector(4 downto 0) := (others => '0');
    signal override_operation  : std_logic := '0';
    signal override_type       : std_logic_vector(1 downto 0) := (others => '0');
    signal isSwap_from_execute : std_logic := '0';
    signal decode_ctrl         : decode_control_t;
    signal execute_ctrl        : execute_control_t;
    signal memory_ctrl         : memory_control_t;
    signal writeback_ctrl      : writeback_control_t;
    
    -- Test procedure
    procedure test_instruction(
        constant test_opcode : in std_logic_vector(4 downto 0);
        constant instruction_name : in string
    ) is
    begin
        opcode <= test_opcode;
        wait for 10 ns;
        report "Testing " & instruction_name severity note;
    end procedure;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    uut: opcode_decoder
        port map (
            opcode              => opcode,
            override_operation  => override_operation,
            override_type       => override_type,
            isSwap_from_execute => isSwap_from_execute,
            decode_ctrl         => decode_ctrl,
            execute_ctrl        => execute_ctrl,
            memory_ctrl         => memory_ctrl,
            writeback_ctrl      => writeback_ctrl
        );
    
    -- Stimulus Process
    stim_proc: process
    begin
        -- Wait for global reset
        wait for 5 ns;
        
        report "====================================";
        report "Starting Opcode Decoder Tests";
        report "====================================";
        
        -- Test all normal instructions
        test_instruction(OP_NOP, "NOP");
        assert decode_ctrl.IsJMP = '0' and decode_ctrl.IsCall = '0' 
            report "NOP failed" severity error;
        
        test_instruction(OP_HLT, "HLT");
        
        test_instruction(OP_SETC, "SETC");
        assert execute_ctrl.CCR_WriteEnable = '1' 
            report "SETC: CCR_WriteEnable not set" severity error;
        
        test_instruction(OP_NOT, "NOT");
        assert execute_ctrl.ALU_Operation = ALU_NOT and 
               execute_ctrl.CCR_WriteEnable = '1' and
               writeback_ctrl.RegWrite = '1'
            report "NOT failed" severity error;
        
        test_instruction(OP_INC, "INC");
        assert execute_ctrl.ALU_Operation = ALU_INC and
               execute_ctrl.CCR_WriteEnable = '1' and
               writeback_ctrl.RegWrite = '1'
            report "INC failed" severity error;
        
        test_instruction(OP_OUT, "OUT");
        assert writeback_ctrl.OutPortWriteEn = '1'
            report "OUT: OutPortWriteEn not set" severity error;
        
        test_instruction(OP_IN, "IN");
        assert decode_ctrl.OutBSelect = OUTB_INPUT_PORT and
               writeback_ctrl.RegWrite = '1'
            report "IN failed" severity error;
        
        test_instruction(OP_MOV, "MOV");
        assert execute_ctrl.ALU_Operation = ALU_PASS and
               writeback_ctrl.RegWrite = '1'
            report "MOV failed" severity error;
        
        test_instruction(OP_SWAP, "SWAP - First Cycle");
        assert decode_ctrl.IsSwap = '1' and
               execute_ctrl.ALU_Operation = ALU_PASS and
               writeback_ctrl.RegWrite = '1' and
               writeback_ctrl.MemToALU = '0'
            report "SWAP first cycle failed" severity error;
        
        -- Test SWAP second cycle (override via isSwap_from_execute)
        opcode <= OP_NOP;  -- Different opcode to show override
        isSwap_from_execute <= '1';
        wait for 10 ns;
        report "Testing SWAP - Second Cycle Override";
        assert execute_ctrl.ALU_Operation = ALU_PASS and
               writeback_ctrl.RegWrite = '1'
            report "SWAP second cycle override failed" severity error;
        isSwap_from_execute <= '0';
        
        test_instruction(OP_ADD, "ADD");
        assert execute_ctrl.ALU_Operation = ALU_ADD and
               execute_ctrl.CCR_WriteEnable = '1' and
               writeback_ctrl.RegWrite = '1'
            report "ADD failed" severity error;
        
        test_instruction(OP_SUB, "SUB");
        assert execute_ctrl.ALU_Operation = ALU_SUB and
               execute_ctrl.CCR_WriteEnable = '1' and
               writeback_ctrl.RegWrite = '1'
            report "SUB failed" severity error;
        
        test_instruction(OP_AND, "AND");
        assert execute_ctrl.ALU_Operation = ALU_AND and
               execute_ctrl.CCR_WriteEnable = '1' and
               writeback_ctrl.RegWrite = '1'
            report "AND failed" severity error;
        
        test_instruction(OP_IADD, "IADD");
        assert decode_ctrl.OutBSelect = OUTB_IMMEDIATE and
               execute_ctrl.ALU_Operation = ALU_ADD and
               execute_ctrl.PassImm = '1' and
               execute_ctrl.CCR_WriteEnable = '1' and
               writeback_ctrl.RegWrite = '1'
            report "IADD failed" severity error;
        
        test_instruction(OP_PUSH, "PUSH");
        assert memory_ctrl.SP_Enable = '1' and
               memory_ctrl.SP_Function = '0' and
               memory_ctrl.SPtoMem = '1' and
               memory_ctrl.MemWrite = '1'
            report "PUSH failed" severity error;
        
        test_instruction(OP_POP, "POP");
        assert memory_ctrl.SP_Enable = '1' and
               memory_ctrl.SP_Function = '1' and
               memory_ctrl.SPtoMem = '1' and
               memory_ctrl.MemRead = '1' and
               writeback_ctrl.RegWrite = '1' and
               writeback_ctrl.MemToALU = '1'
            report "POP failed" severity error;
        
        test_instruction(OP_LDM, "LDM");
        assert decode_ctrl.OutBSelect = OUTB_IMMEDIATE and
               execute_ctrl.PassImm = '1' and
               writeback_ctrl.RegWrite = '1' and
               writeback_ctrl.MemToALU = '0'
            report "LDM failed" severity error;
        
        test_instruction(OP_LDD, "LDD");
        assert execute_ctrl.PassImm = '1' and
               memory_ctrl.MemRead = '1' and
               writeback_ctrl.RegWrite = '1' and
               writeback_ctrl.MemToALU = '1'
            report "LDD failed" severity error;
        
        test_instruction(OP_STD, "STD");
        assert execute_ctrl.PassImm = '1' and
               memory_ctrl.MemWrite = '1'
            report "STD failed" severity error;
        
        test_instruction(OP_JZ, "JZ");
        assert decode_ctrl.IsJMPConditional = '1' and
               decode_ctrl.ConditionalType = COND_ZERO and
               execute_ctrl.PassImm = '1'
            report "JZ failed" severity error;
        
        test_instruction(OP_JN, "JN");
        assert decode_ctrl.IsJMPConditional = '1' and
               decode_ctrl.ConditionalType = COND_NEGATIVE and
               execute_ctrl.PassImm = '1'
            report "JN failed" severity error;
        
        test_instruction(OP_JC, "JC");
        assert decode_ctrl.IsJMPConditional = '1' and
               decode_ctrl.ConditionalType = COND_CARRY and
               execute_ctrl.PassImm = '1'
            report "JC failed" severity error;
        
        test_instruction(OP_JMP, "JMP");
        assert decode_ctrl.IsJMP = '1' and
               execute_ctrl.PassImm = '1'
            report "JMP failed" severity error;
        
        test_instruction(OP_CALL, "CALL");
        assert decode_ctrl.IsCall = '1' and
               decode_ctrl.IsJMP = '1' and
               execute_ctrl.PassImm = '1'
            report "CALL failed" severity error;
        
        test_instruction(OP_RET, "RET");
        assert decode_ctrl.IsReturn = '1'
            report "RET failed" severity error;
        
        test_instruction(OP_INT, "INT");
        assert decode_ctrl.IsInterrupt = '1' and
               execute_ctrl.PassImm = '1' and
               memory_ctrl.PassInterrupt = '1'
            report "INT failed" severity error;
        
        test_instruction(OP_RTI, "RTI");
        assert decode_ctrl.IsReti = '1'
            report "RTI failed" severity error;
        
        report "====================================";
        report "Testing Override Operations";
        report "====================================";
        
        -- Test Override PUSH_PC
        override_operation <= '1';
        override_type <= OVERRIDE_PUSH_PC;
        opcode <= OP_NOP;  -- Opcode should be ignored
        wait for 10 ns;
        report "Testing OVERRIDE_PUSH_PC";
        assert memory_ctrl.SP_Enable = '1' and
               memory_ctrl.SP_Function = '0' and
               memory_ctrl.SPtoMem = '1' and
               memory_ctrl.MemWrite = '1' and
               decode_ctrl.OutBSelect = OUTB_PUSHED_PC
            report "OVERRIDE_PUSH_PC failed" severity error;
        
        -- Test Override PUSH_FLAGS
        override_type <= OVERRIDE_PUSH_FLAGS;
        wait for 10 ns;
        report "Testing OVERRIDE_PUSH_FLAGS";
        assert memory_ctrl.SP_Enable = '1' and
               memory_ctrl.SP_Function = '0' and
               memory_ctrl.SPtoMem = '1' and
               memory_ctrl.MemWrite = '1' and
               execute_ctrl.PassCCR = '1'
            report "OVERRIDE_PUSH_FLAGS failed" severity error;
        
        -- Test Override POP_PC
        override_type <= OVERRIDE_POP_PC;
        wait for 10 ns;
        report "Testing OVERRIDE_POP_PC";
        assert memory_ctrl.SP_Enable = '1' and
               memory_ctrl.SP_Function = '1' and
               memory_ctrl.SPtoMem = '1' and
               memory_ctrl.MemRead = '1' and
               writeback_ctrl.MemToALU = '1'
            report "OVERRIDE_POP_PC failed" severity error;
        
        -- Test Override POP_FLAGS
        override_type <= OVERRIDE_POP_FLAGS;
        wait for 10 ns;
        report "Testing OVERRIDE_POP_FLAGS";
        assert memory_ctrl.SP_Enable = '1' and
               memory_ctrl.SP_Function = '1' and
               memory_ctrl.SPtoMem = '1' and
               memory_ctrl.MemRead = '1' and
               memory_ctrl.FlagFromMem = '1'
            report "OVERRIDE_POP_FLAGS failed" severity error;
        
        override_operation <= '0';
        
        report "====================================";
        report "All Tests Completed Successfully!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;
