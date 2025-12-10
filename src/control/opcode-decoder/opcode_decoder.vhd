library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;
use work.control_signals_pkg.all;

entity opcode_decoder is
    Port (
        -- Inputs
        opcode              : in  std_logic_vector(4 downto 0);   -- 5-bit opcode
        override_operation  : in  std_logic;                       -- Override normal decoding
        override_type       : in  std_logic_vector(1 downto 0);   -- Type of override operation
        isSwap_from_execute : in  std_logic;                       -- Feedback from execute stage for SWAP second cycle
        take_interrupt      : in  std_logic;                       -- From interrupt unit (treat as interrupt)
        is_hardware_int_mem : in  std_logic;                       -- Hardware interrupt flag in memory stage
        
        -- Output Control Signals (grouped by stage)
        decode_ctrl         : out decode_control_t;
        execute_ctrl        : out execute_control_t;
        memory_ctrl         : out memory_control_t;
        writeback_ctrl      : out writeback_control_t
    );
end opcode_decoder;

architecture Behavioral of opcode_decoder is
begin

    process(opcode, override_operation, override_type, isSwap_from_execute, take_interrupt, is_hardware_int_mem)
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
        
        -- Handle Override Operations First
        if override_operation = '1' then
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
                    memory_sig.FlagFromMem:= '1';
                    
                when OVERRIDE_POP_PC =>
                    -- POP PC: PC = MEM[SP], SP++
                    memory_sig.SP_Enable  := '1';
                    memory_sig.SP_Function:= '1';  -- Increment
                    memory_sig.SPtoMem    := '1';
                    memory_sig.MemRead    := '1';
                    writeback_sig.MemToALU:= '1';
                    -- Branch logic handled by branch control
                    
                when others =>
                    null;
            end case;
            
        else
            -- Normal Opcode Decoding
            case opcode is
                
                when OP_NOP =>
                    -- No operation - all signals remain at default
                    null;
                    
                when OP_HLT =>
                    -- Halt - implementation specific
                    -- Could set a halt flag or freeze pipeline
                    null;
                    
                when OP_SETC =>
                    -- Set Carry Flag
                    execute_sig.CCR_WriteEnable := '1';
                    execute_sig.ALU_Operation   := ALU_SETC;
                    
                when OP_NOT =>
                    -- NOT Rdst: Rdst = ~Rdst
                    execute_sig.ALU_Operation   := ALU_NOT;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';  -- Use ALU result
                    
                when OP_INC =>
                    -- INC Rdst: Rdst = Rdst + 1
                    execute_sig.ALU_Operation   := ALU_INC;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_OUT =>
                    -- OUT Rdst: Output Port = Rdst
                    writeback_sig.OutPortWriteEn:= '1';
                    
                when OP_IN =>
                    -- IN Rdst: Rdst = Input Port
                    decode_sig.OutBSelect       := OUTB_INPUT_PORT;
                    execute_sig.ALU_Operation   := ALU_PASS;
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_MOV =>
                    -- MOV Rsrc1, Rdst: Rdst = Rsrc1
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_PASS;
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_SWAP =>
                    -- SWAP Rsrc1, Rdst: Treated as first MOV (Rsrc1 -> Rdst)
                    -- Second cycle will be overridden by isSwap_from_execute
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    decode_sig.IsSwap           := '1';  -- Mark as SWAP for pipeline
                    execute_sig.ALU_Operation   := ALU_PASS;  -- First move operation
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_ADD =>
                    -- ADD Rdst, Rsrc1, Rsrc2
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_ADD;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_SUB =>
                    -- SUB Rdst, Rsrc1, Rsrc2
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_SUB;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_AND =>
                    -- AND Rdst, Rsrc1, Rsrc2
                    decode_sig.OutBSelect       := OUTB_REGFILE;
                    execute_sig.ALU_Operation   := ALU_AND;
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_IADD =>
                    -- IADD Rdst, Rsrc1, Imm: Rdst = Rsrc1 + Imm
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.ALU_Operation   := ALU_ADD;
                    execute_sig.PassImm         := '1';
                    execute_sig.CCR_WriteEnable := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
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
                    writeback_sig.MemToALU      := '1';  -- Use memory data
                    
                when OP_LDM =>
                    -- LDM Rdst, Imm: Rdst = Imm
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.ALU_Operation   := ALU_PASS;
                    execute_sig.PassImm         := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '0';
                    
                when OP_LDD =>
                    -- LDD Rdst, offset(Rsrc): Rdst = MEM[Rsrc + offset]
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    execute_sig.ALU_Operation   := ALU_ADD;  -- Calculate address
                    memory_sig.MemRead          := '1';
                    writeback_sig.RegWrite      := '1';
                    writeback_sig.MemToALU      := '1';  -- Use memory data
                    
                when OP_STD =>
                    -- STD Rsrc1, offset(Rsrc2): MEM[Rsrc2 + offset] = Rsrc1
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    execute_sig.ALU_Operation   := ALU_ADD;  -- Calculate address
                    memory_sig.MemWrite         := '1';
                    
                when OP_JZ =>
                    -- JZ Imm: Jump if Zero
                    decode_sig.IsJMPConditional := '1';
                    decode_sig.ConditionalType  := COND_ZERO;
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    
                when OP_JN =>
                    -- JN Imm: Jump if Negative
                    decode_sig.IsJMPConditional := '1';
                    decode_sig.ConditionalType  := COND_NEGATIVE;
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    
                when OP_JC =>
                    -- JC Imm: Jump if Carry
                    decode_sig.IsJMPConditional := '1';
                    decode_sig.ConditionalType  := COND_CARRY;
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    
                when OP_JMP =>
                    -- JMP Imm: Unconditional Jump
                    decode_sig.IsJMP            := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    
                when OP_CALL =>
                    -- CALL Imm: Push PC, Jump to Imm
                    decode_sig.IsCall           := '1';
                    decode_sig.IsJMP            := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    -- PUSH_PC will be handled by InterruptUnit via override
                    
                when OP_RET =>
                    -- RET: Pop PC
                    decode_sig.IsReturn         := '1';
                    -- POP_PC will be handled by InterruptUnit via override
                    
                when OP_INT =>
                    -- INT index: Software Interrupt
                    decode_sig.IsInterrupt      := '1';
                    decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                    execute_sig.PassImm         := '1';
                    memory_sig.PassInterrupt    := PASS_INT_SOFTWARE;  -- Software interrupt address from immediate
                    -- Push PC and FLAGS handled by InterruptUnit
                    
                when OP_RTI =>
                    -- RTI: Return from Interrupt (Pop FLAGS, Pop PC)
                    decode_sig.IsReti           := '1';
                    -- POP_FLAGS and POP_PC handled by InterruptUnit via override
                    
                when others =>
                    -- Invalid opcode - treat as NOP
                    null;
                    null;
            end case;
            
            -- Handle take_interrupt signal (from interrupt unit for hardware interrupt)
            if take_interrupt = '1' then
                -- Treat as software interrupt (INT instruction)
                decode_sig.IsInterrupt      := '1';
                decode_sig.IsHardwareInterrupt := '1';  -- Mark as hardware for pipeline tracking
                decode_sig.OutBSelect       := OUTB_IMMEDIATE;
                execute_sig.PassImm         := '1';
                -- PassInterrupt will be set in memory stage based on is_hardware_int_mem
            end if;
            
            -- Handle SWAP second cycle override
            if isSwap_from_execute = '1' then
                -- Second cycle of SWAP: Complete the exchange with another MOV
                decode_sig.OutBSelect       := OUTB_REGFILE;
                execute_sig.ALU_Operation   := ALU_PASS;
                writeback_sig.RegWrite      := '1';
                writeback_sig.MemToALU      := '0';
                -- Note: Register addresses need to be swapped by datapath logic
            end if;
        end if;
        
        -- Pass IsSwap through to memory stage for forwarding unit
        memory_sig.IsSwap := decode_sig.IsSwap;
        
        -- Handle PassInterrupt based on hardware interrupt in memory stage
        if is_hardware_int_mem = '1' then
            -- Hardware interrupt in memory stage: use hardware interrupt vector
            memory_sig.PassInterrupt := PASS_INT_HARDWARE;
        end if;
        -- Note: Software interrupt sets PASS_INT_SOFTWARE during normal decode
        
        -- Assign outputs
        decode_ctrl    <= decode_sig;
        execute_ctrl   <= execute_sig;
        memory_ctrl    <= memory_sig;
        writeback_ctrl <= writeback_sig;
        
    end process;

end Behavioral;
