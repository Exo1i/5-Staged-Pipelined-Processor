LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.control_signals_pkg.ALL;

PACKAGE pipeline_data_pkg IS
    
    -- Data bundle for IF/ID pipeline register
    TYPE pipeline_fetch_decode_t IS RECORD
        take_interrupt    : STD_LOGIC;
        override_operation : STD_LOGIC;
        override_op       : STD_LOGIC_VECTOR(1 DOWNTO 0);
        pc                : STD_LOGIC_VECTOR(31 DOWNTO 0);
        pushed_pc         : STD_LOGIC_VECTOR(31 DOWNTO 0);
        instruction       : STD_LOGIC_VECTOR(31 DOWNTO 0);
    END RECORD;
    
    -- Data bundle for pipeline stages (PC, operands, immediates, register addresses)
    TYPE pipeline_decode_excute_t IS RECORD
        pc            : STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_a     : STD_LOGIC_VECTOR(31 DOWNTO 0);
        operand_b     : STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate     : STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsrc1         : STD_LOGIC_VECTOR(2 DOWNTO 0);
        rsrc2         : STD_LOGIC_VECTOR(2 DOWNTO 0);
        rd            : STD_LOGIC_VECTOR(2 DOWNTO 0);
    END RECORD;
    
    -- Control bundle for all pipeline control signals
    TYPE pipeline_decode_excute_ctrl_t IS RECORD
        decode_ctrl   : decode_control_t;
        execute_ctrl  : execute_control_t;
        memory_ctrl   : memory_control_t;
        writeback_ctrl: writeback_control_t;
    END RECORD;
    
    -- Data bundle for EX/MEM pipeline register
    TYPE pipeline_execute_memory_t IS RECORD
        primary_data   : STD_LOGIC_VECTOR(31 DOWNTO 0);
        secondary_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdst1          : STD_LOGIC_VECTOR(2 DOWNTO 0);
    END RECORD;
    
    -- Control bundle for EX/MEM pipeline register
    TYPE pipeline_execute_memory_ctrl_t IS RECORD
        memory_ctrl    : memory_control_t;
        writeback_ctrl : writeback_control_t;
    END RECORD;
    
    -- Data bundle for MEM/WB pipeline register
    TYPE pipeline_memory_writeback_t IS RECORD
        memory_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
        alu_data    : STD_LOGIC_VECTOR(31 DOWNTO 0);
        rdst        : STD_LOGIC_VECTOR(2 DOWNTO 0);
    END RECORD;
    
    -- Control bundle for MEM/WB pipeline register
    TYPE pipeline_memory_writeback_ctrl_t IS RECORD
        writeback_ctrl : writeback_control_t;
    END RECORD;
    
    -- Default/NOP values
    CONSTANT PIPELINE_FETCH_DECODE_RESET : pipeline_fetch_decode_t := (
        take_interrupt => '0',
        override_operation => '0',
        override_op => (OTHERS => '0'),
        pc => (OTHERS => '0'),
        pushed_pc => (OTHERS => '0'),
        instruction => (OTHERS => '0')
    );
    
    CONSTANT PIPELINE_DECODE_EXCUTE_RESET : pipeline_decode_excute_t := (
        pc => (OTHERS => '0'),
        operand_a => (OTHERS => '0'),
        operand_b => (OTHERS => '0'),
        immediate => (OTHERS => '0'),
        rsrc1 => (OTHERS => '0'),
        rsrc2 => (OTHERS => '0'),
        rd => (OTHERS => '0')
    );
    
    CONSTANT PIPELINE_DECODE_EXCUTE_CTRL_NOP : pipeline_decode_excute_ctrl_t := (
        decode_ctrl => DECODE_CTRL_DEFAULT,
        execute_ctrl => EXECUTE_CTRL_DEFAULT,
        memory_ctrl => MEMORY_CTRL_DEFAULT,
        writeback_ctrl => WRITEBACK_CTRL_DEFAULT
    );
    
    CONSTANT PIPELINE_EXECUTE_MEMORY_RESET : pipeline_execute_memory_t := (
        primary_data => (OTHERS => '0'),
        secondary_data => (OTHERS => '0'),
        rdst1 => (OTHERS => '0')
    );
    
    CONSTANT PIPELINE_EXECUTE_MEMORY_CTRL_NOP : pipeline_execute_memory_ctrl_t := (
        memory_ctrl => MEMORY_CTRL_DEFAULT,
        writeback_ctrl => WRITEBACK_CTRL_DEFAULT
    );
    
    CONSTANT PIPELINE_MEMORY_WRITEBACK_RESET : pipeline_memory_writeback_t := (
        memory_data => (OTHERS => '0'),
        alu_data => (OTHERS => '0'),
        rdst => (OTHERS => '0')
    );
    
    CONSTANT PIPELINE_MEMORY_WRITEBACK_CTRL_NOP : pipeline_memory_writeback_ctrl_t := (
        writeback_ctrl => WRITEBACK_CTRL_DEFAULT
    );
    
END PACKAGE pipeline_data_pkg;
