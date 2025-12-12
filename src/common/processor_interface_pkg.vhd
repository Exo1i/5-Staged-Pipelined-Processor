LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- =====================================================================
-- Package: processor_interface_pkg
-- Purpose: Interface record types for external connections
-- Benefit: Cleaner entity ports, grouped related signals
-- =====================================================================

PACKAGE processor_interface_pkg IS

    -- ========== MEMORY INTERFACE RECORD ==========
    -- Groups all memory-related signals together
    TYPE memory_interface_t IS RECORD
        -- Address for instruction fetch or data access
        addr      : STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Data from memory (instructions or loaded data)
        data_in   : STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Data to memory (store operations)
        data_out  : STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Control signals
        read      : STD_LOGIC;
        write     : STD_LOGIC;
    END RECORD;
    
    -- Default values for memory interface
    CONSTANT MEMORY_INTERFACE_IDLE : memory_interface_t := (
        addr     => (OTHERS => '0'),
        data_in  => (OTHERS => '0'),
        data_out => (OTHERS => '0'),
        read     => '0',
        write    => '0'
    );
    
    -- ========== I/O PORT INTERFACE RECORD ==========
    -- Groups input/output port signals
    TYPE io_port_t IS RECORD
        -- Input port data
        in_port         : STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Output port data
        out_port        : STD_LOGIC_VECTOR(31 DOWNTO 0);
        
        -- Output port write enable
        out_port_enable : STD_LOGIC;
    END RECORD;
    
    -- Default values for I/O ports
    CONSTANT IO_PORT_IDLE : io_port_t := (
        in_port         => (OTHERS => '0'),
        out_port        => (OTHERS => '0'),
        out_port_enable => '0'
    );

END PACKAGE processor_interface_pkg;
