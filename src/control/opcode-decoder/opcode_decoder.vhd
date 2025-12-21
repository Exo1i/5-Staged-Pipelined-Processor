library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;
use work.control_signals_pkg.all;

entity opcode_decoder is
    Port (
        -- Inputs
        opcode              : in  std_logic_vector(4 downto 0);   -- 5-bit opcode from IF/ID instruction
        override_operation  : in  std_logic;                       -- Override normal decoding
        override_type       : in  std_logic_vector(1 downto 0);   -- Type of override operation
        isSwap_from_execute : in  std_logic;                       -- Feedback from execute stage for SWAP second cycle
        take_interrupt      : in  std_logic;                       -- From interrupt unit (treat as interrupt)
        is_hardware_int_mem : in  std_logic;                       -- Hardware interrupt flag in memory stage
        requireImmediate    : in std_logic;                       -- --- will come from excute --- --

        -- Output Control Signals (grouped by stage)
        decode_ctrl         : out decode_control_t;
        execute_ctrl        : out execute_control_t;
        memory_ctrl         : out memory_control_t;
        writeback_ctrl      : out writeback_control_t;
        
        -- Instruction Type Outputs (for Interrupt Unit, Branch Predictor, etc.)
        is_jmp_out              : out std_logic;  -- JMP instruction detected
        is_jmp_conditional_out  : out std_logic  -- Conditional jump (JZ/JN/JC)
    );
end opcode_decoder;

architecture Behavioral of opcode_decoder is
begin

    process(opcode, override_operation, override_type, isSwap_from_execute, take_interrupt, is_hardware_int_mem, requireImmediate)
        variable decode_sig   : decode_control_t;
        variable execute_sig  : execute_control_t;
        variable memory_sig   : memory_control_t;
        variable writeback_sig: writeback_control_t;
    begin
        -- Initialize all signals to default values
        decode_sig   := DECODE_CTRL_DEFAULT;
        execute_sig  := EXECUTE_CTRL_DEFAULT;
        memory_sig   := MEMORY_CTRL_DEFAULT;
        writeback_sig:= WRITEBACK_CTRL_DEFAULT;
        
       -- Handle take_interrupt signal (from interrupt unit for hardware interrupt)
        if isSwap_from_execute = '1' then
            -- Second cycle of SWAP: Complete the exchange with another MOV
            decode_sig.OutBSelect       := OUTB_REGFILE;
            execute_sig.ALU_Operation   := ALU_PASS_A;
            writeback_sig.RegWrite      := '1';
            writeback_sig.PassMem      := '0';
            -- Note: Register addresses need to be swapped by datapath logic
            -- Don't set IsSwap flag - this is the second cycle
        
        -- Handle Override Operations
        elsif override_operation = '1' then
            case override_type is
                when OVERRIDE_PUSH_PC =>
                    -- PUSH PC: SP--, MEM[SP] = PC
                    memory_sig.SP_Enable  := '1';
                    memory_sig.SP_Function:= '0';  -- Decrement
                    memory_sig.SPtoMem    := '1';
                    memory_sig.MemWrite   := '1';
                    decode_sig.OutBSelect := OUTB_PUSHED_PC;
                    
                when OVERRIDE_PUSH_FLAGS =>
                    -- PUSH FLAGS: SP--, MEM[SP] = FLAGS
                    memory_sig.SP_Enable  := '1';
                    memory_sig.SP_Function:= '0';  -- Decrement
                    memory_sig.SPtoMem    := '1';
                    memory_sig.MemWrite   := '1';
                    execute_sig.PassCCR   := '1';
                    
                when OVERRIDE_POP_FLAGS =>
                    -- POP FLAGS: FLAGS = MEM[SP], SP++
                    memory_sig.SP_Enable  := '1';
                    memory_sig.SP_Function:= '1';  -- Increment
                    memory_sig.SPtoMem    := '1';
                    memory_sig.MemRead    := '1';
                    memory_sig.MemToCCR   := '1';
                    
                when OVERRIDE_NOP =>
                    -- NOP Override: Do nothing (all defaults)
                    null;
                    
                when others =>
                    null;
            end case;

        elsif take_interrupt = '1' then
            -- Treat as software interrupt (INT instruction)
            decode_sig.IsInterrupt      := '1';
            memory_sig.PassInterrupt    := PASS_INT_HARDWARE;  
            memory_sig.MemRead          := '1';
            memory_sig.IsInterrupt    := '1';
        elsif requireImmediate = '1' then
            -- Immediate instruction required but no override - treat as NOP
            null;    
        else
            -- Normal Opcode Decoding
            case opcode is
                
                when OP_NOP =>
                    -- No operation - all signals remain at default
                    null;
                    
                when OP_HLT =>
                    -- Halt - implementation specific
                    -- Could set a halt flag or freeze pipeline
                    decode_sig.IsHLT := '1';
                    
                when OP_SETC =>
                    -- Set Carry Flag
                    execute_sig.CCR_WriteEnable := '1';
                    execute_sig.ALU_Operation   := ALU_SETC;
                    
                when OP_NOT =>
                    -- NOT Rdst: Rdst = ~Rdst
                    execute_sig.ALU_Operation   := ALU_NOT;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';  -- Use ALU result
                    
                when OP_INC =>
                    -- INC Rdst: Rdst = Rdst + 1
                    execute_sig.ALU_Operation   := ALU_INC;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_OUT =>
                    -- OUT Rdst: Output Port = Rdst
                    execute_sig.ALU_Operation   := ALU_PASS_A;
                    writeback_sig.PassMem      := '0';
                    writeback_sig.OutPortWriteEn:= '1';
                    
                when OP_IN =>
                    -- IN Rdst: Rdst = Input Port
                    decode_sig.OutBSelect       := OUTB_INPUT_PORT;
                    execute_sig.ALU_Operation   := ALU_PASS_B;
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_MOV =>
                    -- MOV Rsrc1, Rdst: Rdst = Rsrc1
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_PASS_A;
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_SWAP =>
                    -- SWAP Rsrc1, Rdst: Treated as first MOV (Rsrc1 -> Rdst)
                    -- Second cycle will be overridden by isSwap_from_execute
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    decode_sig.IsSwap           := '1';  -- Mark as SWAP for pipeline
                    memory_sig.IsSwap           := '1';  -- Pass to memory stage
                    execute_sig.ALU_Operation   := ALU_PASS_B;  -- First move operation
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_ADD =>
                    -- ADD Rdst, Rsrc1, Rsrc2
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_ADD;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_SUB =>
                    -- SUB Rdst, Rsrc1, Rsrc2
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_SUB;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_AND =>
                    -- AND Rdst, Rsrc1, Rsrc2
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_AND;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_IADD =>
                    -- IADD Rdst, Rsrc1, Imm: Rdst = Rsrc1 + Imm
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    decode_sig.RequireImmediate := '1';
                    execute_sig.ALU_Operation   := ALU_ADD;
                    execute_sig.PassImm         := '1';
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_PUSH =>
                    -- PUSH Rdst: SP--, MEM[SP] = Rdst
                    memory_sig.SP_Enable        := '1';
                    memory_sig.SP_Function      := '0';  -- Decrement
                    memory_sig.SPtoMem          := '1';
                    memory_sig.MemWrite         := '1';
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    
                when OP_POP =>
                    -- POP Rdst: Rdst = MEM[SP], SP++
                    memory_sig.SP_Enable        := '1';
                    memory_sig.SP_Function      := '1';  -- Increment
                    memory_sig.SPtoMem          := '1';
                    memory_sig.MemRead          := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '1';  -- Use memory data
                    
                when OP_LDM =>
                    -- LDM Rdst, Imm: Rdst = Imm
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    decode_sig.RequireImmediate := '1';
                    execute_sig.ALU_Operation   := ALU_PASS_B;
                    execute_sig.PassImm         := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '0';
                    
                when OP_LDD =>
                    -- LDD Rdst, offset(Rsrc): Rdst = MEM[Rsrc + offset]
                    decode_sig.RequireImmediate := '1';
                    execute_sig.PassImm         := '1';
                    execute_sig.ALU_Operation   := ALU_ADD;  -- Calculate address
                    memory_sig.MemRead          := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.PassMem      := '1';  -- Use memory data
                    
                when OP_STD =>
                    -- STD Rsrc1, offset(Rsrc2): MEM[Rsrc2 + offset] = Rsrc1
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    decode_sig.RequireImmediate := '1';
                    execute_sig.PassImm         := '1';
                    execute_sig.ALU_Operation   := ALU_ADD;  -- Calculate address
                    memory_sig.MemWrite         := '1';
                    
                when OP_JZ =>
                    -- JZ Imm: Jump if Zero
                    decode_sig.IsJMPConditional := '1';
                    decode_sig.RequireImmediate := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    execute_sig.ConditionalType := COND_ZERO;
                    execute_sig.CCR_WriteEnable := '1';
                    
                when OP_JN =>
                    -- JN Imm: Jump if Negative
                    decode_sig.IsJMPConditional := '1';
                    decode_sig.RequireImmediate := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    execute_sig.ConditionalType := COND_NEGATIVE;
                    execute_sig.CCR_WriteEnable := '1';
                    
                when OP_JC =>
                    -- JC Imm: Jump if Carry
                    decode_sig.IsJMPConditional := '1';
                    decode_sig.RequireImmediate := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    execute_sig.ConditionalType := COND_CARRY;
                    execute_sig.CCR_WriteEnable := '1';
   
                when OP_JMP =>
                    -- JMP Imm: Unconditional Jump
                    decode_sig.IsJMP            := '1';
                    decode_sig.RequireImmediate := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    
                when OP_CALL =>
                    -- CALL Imm: Push PC, Jump to Imm
                    decode_sig.IsCall           := '1';
                    decode_sig.RequireImmediate := '1';
                    decode_sig.IsJMP            := '1';
                    memory_sig.SP_Enable        := '1';
                    memory_sig.SP_Function      := '0';  -- Decrement
                    memory_sig.SPtoMem          := '1';
                    memory_sig.MemWrite         := '1';
                    decode_sig.OutBSelect       := OUTB_PUSHED_PC;
                    -- PUSH_PC will be handled by InterruptUnit via override
                    
                when OP_RET =>
                    -- RET: SP++, PC <- MEM[SP]
                    decode_sig.IsReturn   := '1';
                    memory_sig.IsReturn   := '1';  -- Propagate to branch_decision_unit
                    memory_sig.SP_Enable  := '1';
                    memory_sig.SP_Function:= '1';  -- Increment
                    memory_sig.SPtoMem    := '1';
                    memory_sig.MemRead    := '1';
                    
                when OP_INT =>
                    -- INT index: Software Interrupt
                    decode_sig.IsInterrupt      := '1';
                    decode_sig.RequireImmediate := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    memory_sig.PassInterrupt    := PASS_INT_SOFTWARE;  -- Software interrupt address from immediate
                    execute_sig.ALU_Operation   := ALU_PASS_B;
                    memory_sig.MemRead          := '1';
                    memory_sig.IsInterrupt    := '1';
                    -- Push PC and FLAGS handled by InterruptUnit
                    
                when OP_RTI =>
                    -- RTI: Return from Interrupt (Pop FLAGS, Pop PC)
                    decode_sig.IsReti     := '1';
                    memory_sig.SP_Enable  := '1';
                    memory_sig.SP_Function:= '1';  -- Increment
                    memory_sig.SPtoMem    := '1';
                    memory_sig.MemRead    := '1';
                    memory_sig.IsReti      := '1';
                    -- POP_FLAGS and POP_PC handled by InterruptUnit via override
                    
                when others =>
                    -- Invalid opcode - treat as NOP
                    null;
                    null;
            end case;
            
            
        end if;
        
                
        -- Assign control outputs
        decode_ctrl    <= decode_sig;
        execute_ctrl   <= execute_sig;
        memory_ctrl    <= memory_sig;
        writeback_ctrl <= writeback_sig;
        
    end process;

    -- ========== INSTRUCTION TYPE DETECTION (Combinational) ==========
    -- These outputs go to Interrupt Unit, Branch Predictor, Freeze Control
    
    is_jmp_out <= '1' when opcode = OP_JMP else '0';
    -- Conditional jump detection
    is_jmp_conditional_out <= '1' when (opcode = OP_JZ or opcode = OP_JN or opcode = OP_JC) else '0';

end Behavioral;
