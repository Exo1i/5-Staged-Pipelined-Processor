library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.all;

entity tb_interrupt_unit is
end tb_interrupt_unit;

architecture Behavioral of tb_interrupt_unit is
    
    -- Component Declaration
    component interrupt_unit
        Port (
            IsInterrupt_DE      : in  std_logic;
            IsHardwareInt_DE    : in  std_logic;
            IsCall_DE           : in  std_logic;
            IsReturn_DE         : in  std_logic;
            IsReti_DE           : in  std_logic;
            IsInterrupt_EX      : in  std_logic;
            IsHardwareInt_EX    : in  std_logic;
            IsReti_EX           : in  std_logic;
            IsHardwareInt_MEM   : in  std_logic;
            HardwareInterrupt   : in  std_logic;
            Stall               : out std_logic;
            PassPC_NotPCPlus1   : out std_logic;
            TakeInterrupt       : out std_logic;
            IsHardwareIntMEM_Out: out std_logic;
            OverrideOperation   : out std_logic;
            OverrideType        : out std_logic_vector(1 downto 0)
        );
    end component;
    
    -- Clock (for sequential testing, not used in combinational unit)
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- Signals
    signal IsInterrupt_DE     : std_logic := '0';
    signal IsHardwareInt_DE   : std_logic := '0';
    signal IsCall_DE          : std_logic := '0';
    signal IsReturn_DE        : std_logic := '0';
    signal IsReti_DE          : std_logic := '0';
    signal IsInterrupt_EX     : std_logic := '0';
    signal IsHardwareInt_EX   : std_logic := '0';
    signal IsReti_EX          : std_logic := '0';
    signal IsHardwareInt_MEM  : std_logic := '0';
    signal HardwareInterrupt  : std_logic := '0';
    signal Stall              : std_logic;
    signal PassPC_NotPCPlus1  : std_logic;
    signal TakeInterrupt      : std_logic;
    signal IsHardwareIntMEM_Out: std_logic;
    signal OverrideOperation  : std_logic;
    signal OverrideType       : std_logic_vector(1 downto 0);
    
begin
    
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Instantiate the Unit Under Test (UUT)
    uut: interrupt_unit
        port map (
            IsInterrupt_DE       => IsInterrupt_DE,
            IsHardwareInt_DE     => IsHardwareInt_DE,
            IsCall_DE            => IsCall_DE,
            IsReturn_DE          => IsReturn_DE,
            IsReti_DE            => IsReti_DE,
            IsInterrupt_EX       => IsInterrupt_EX,
            IsHardwareInt_EX     => IsHardwareInt_EX,
            IsReti_EX            => IsReti_EX,
            IsHardwareInt_MEM    => IsHardwareInt_MEM,
            HardwareInterrupt    => HardwareInterrupt,
            Stall                => Stall,
            PassPC_NotPCPlus1    => PassPC_NotPCPlus1,
            TakeInterrupt        => TakeInterrupt,
            IsHardwareIntMEM_Out => IsHardwareIntMEM_Out,
            OverrideOperation    => OverrideOperation,
            OverrideType         => OverrideType
        );
    
    -- Stimulus Process
    stim_proc: process
    begin
        wait for 5 ns;
        
        report "====================================";
        report "Starting Interrupt Unit Tests";
        report "====================================";
        
        -- Test Case 1: No interrupt operations - Normal state
        report "Test 1: Normal operation (no interrupts)";
        IsInterrupt_DE <= '0';
        IsCall_DE <= '0';
        IsReturn_DE <= '0';
        IsReti_DE <= '0';
        IsInterrupt_EX <= '0';
        IsReti_EX <= '0';
        HardwareInterrupt <= '0';
        wait for clk_period;
        assert Stall = '0' and OverrideOperation = '0'
            report "Test 1 FAILED: Should not stall in normal state" 
            severity error;
        report "Test 1 PASSED";
        
        -- Test Case 2: Software Interrupt - Cycle 1 (INT in decode)
        report "Test 2: Software Interrupt - First Cycle (PUSH_PC)";
        IsInterrupt_DE <= '1';
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_PUSH_PC
            report "Test 2 FAILED: Should stall and override with PUSH_PC" 
            severity error;
        report "Test 2 PASSED: Stall='1', Override=PUSH_PC";
        
        -- Test Case 3: Software Interrupt - Cycle 2 (INT in execute)
        report "Test 3: Software Interrupt - Second Cycle (PUSH_FLAGS)";
        IsInterrupt_DE <= '0';  -- Moved from decode
        IsInterrupt_EX <= '1';  -- Now in execute
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_PUSH_FLAGS
            report "Test 3 FAILED: Should stall and override with PUSH_FLAGS" 
            severity error;
        report "Test 3 PASSED: Stall='1', Override=PUSH_FLAGS";
        
        -- Clear
        IsInterrupt_EX <= '0';
        wait for clk_period;
        
        -- Test Case 4: Hardware Interrupt
        report "Test 4: Hardware Interrupt";
        HardwareInterrupt <= '1';
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_PUSH_PC and
               TakeInterrupt = '1' and
               PassPC_NotPCPlus1 = '1'
            report "Test 4 FAILED: Hardware interrupt handling incorrect" 
            severity error;
        report "Test 4 PASSED: Hardware interrupt with PassPC_NotPCPlus1";
        
        HardwareInterrupt <= '0';
        wait for clk_period;
        
        -- Test Case 5: RTI - Cycle 1 (RTI in decode)
        report "Test 5: RTI - First Cycle (POP_FLAGS)";
        IsReti_DE <= '1';
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_POP_FLAGS
            report "Test 5 FAILED: RTI should pop FLAGS first (opposite order)" 
            severity error;
        report "Test 5 PASSED: Stall='1', Override=POP_FLAGS";
        
        -- Test Case 6: RTI - Cycle 2 (RTI in execute)
        report "Test 6: RTI - Second Cycle (POP_PC)";
        IsReti_DE <= '0';
        IsReti_EX <= '1';
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_POP_PC
            report "Test 6 FAILED: RTI should pop PC second" 
            severity error;
        report "Test 6 PASSED: Stall='1', Override=POP_PC";
        
        IsReti_EX <= '0';
        wait for clk_period;
        
        -- Test Case 7: CALL instruction (single cycle)
        report "Test 7: CALL instruction";
        IsCall_DE <= '1';
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_PUSH_PC
            report "Test 7 FAILED: CALL should push PC" 
            severity error;
        report "Test 7 PASSED: Stall='1', Override=PUSH_PC";
        
        IsCall_DE <= '0';
        wait for clk_period;
        
        -- Test Case 8: RET instruction (single cycle)
        report "Test 8: RET instruction";
        IsReturn_DE <= '1';
        wait for clk_period;
        assert Stall = '1' and 
               OverrideOperation = '1' and 
               OverrideType = OVERRIDE_POP_PC
            report "Test 8 FAILED: RET should pop PC" 
            severity error;
        report "Test 8 PASSED: Stall='1', Override=POP_PC";
        
        IsReturn_DE <= '0';
        wait for clk_period;
        
        -- Test Case 9: Priority test (Hardware interrupt during software interrupt)
        report "Test 9: Priority - Hardware interrupt has highest priority";
        IsInterrupt_DE <= '1';
        IsInterrupt_EX <= '1';
        HardwareInterrupt <= '1';
        wait for clk_period;
        assert OverrideType = OVERRIDE_PUSH_PC and
               TakeInterrupt = '1' and
               PassPC_NotPCPlus1 = '1'
            report "Test 9 FAILED: Hardware interrupt should have priority" 
            severity error;
        report "Test 9 PASSED: Hardware interrupt takes priority";
        
        HardwareInterrupt <= '0';
        IsInterrupt_DE <= '0';
        IsInterrupt_EX <= '0';
        wait for clk_period;
        
        -- Test Case 10: Sequence simulation - Complete INT operation
        report "Test 10: Complete INT sequence simulation";
        
        -- Cycle 1: INT enters decode
        IsInterrupt_DE <= '1';
        wait for clk_period;
        assert OverrideType = OVERRIDE_PUSH_PC
            report "Test 10a FAILED" severity error;
        report "  Cycle 1: INT in decode, PUSH_PC";
        
        -- Cycle 2: INT moves to execute
        IsInterrupt_DE <= '0';
        IsInterrupt_EX <= '1';
        wait for clk_period;
        assert OverrideType = OVERRIDE_PUSH_FLAGS
            report "Test 10b FAILED" severity error;
        report "  Cycle 2: INT in execute, PUSH_FLAGS";
        
        -- Cycle 3: INT completes
        IsInterrupt_EX <= '0';
        wait for clk_period;
        assert Stall = '0'
            report "Test 10c FAILED" severity error;
        report "  Cycle 3: INT complete, no stall";
        report "Test 10 PASSED: Complete INT sequence";
        
        -- Test Case 11: Sequence simulation - Complete RTI operation
        report "Test 11: Complete RTI sequence simulation";
        
        -- Cycle 1: RTI enters decode
        IsReti_DE <= '1';
        wait for clk_period;
        assert OverrideType = OVERRIDE_POP_FLAGS
            report "Test 11a FAILED" severity error;
        report "  Cycle 1: RTI in decode, POP_FLAGS (reverse order)";
        
        -- Cycle 2: RTI moves to execute
        IsReti_DE <= '0';
        IsReti_EX <= '1';
        wait for clk_period;
        assert OverrideType = OVERRIDE_POP_PC
            report "Test 11b FAILED" severity error;
        report "  Cycle 2: RTI in execute, POP_PC";
        
        -- Cycle 3: RTI completes
        IsReti_EX <= '0';
        wait for clk_period;
        assert Stall = '0'
            report "Test 11c FAILED" severity error;
        report "  Cycle 3: RTI complete, no stall";
        report "Test 11 PASSED: Complete RTI sequence (reverse order verified)";
        
        wait for clk_period;
        
        report "====================================";
        report "All Interrupt Unit Tests Completed Successfully!";
        report "====================================";
        
        wait;
    end process;

end Behavioral;
