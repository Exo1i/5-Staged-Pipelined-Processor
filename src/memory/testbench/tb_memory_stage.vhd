LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;

ENTITY tb_memory_stage IS
END tb_memory_stage;

ARCHITECTURE testbench OF tb_memory_stage IS
    CONSTANT DATA_WIDTH : INTEGER := 32;
    CONSTANT ADDR_WIDTH : INTEGER := 18;
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';

    -- Pipeline input bundles
    SIGNAL ex_mem_ctrl_in : pipeline_execute_memory_ctrl_t;
    SIGNAL ex_mem_data_in : pipeline_execute_memory_t;

    -- Pipeline output bundles
    SIGNAL mem_wb_data_out : pipeline_memory_writeback_t;
    SIGNAL mem_wb_ctrl_out : pipeline_memory_writeback_ctrl_t;

    -- Memory interface signals
    SIGNAL MemReadData : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL MemRead : STD_LOGIC;
    SIGNAL MemWrite : STD_LOGIC;
    SIGNAL MemAddress : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL MemWriteData : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

BEGIN

    -- DUT Instantiation
    dut : ENTITY work.memory_stage
        PORT MAP(
            clk => clk,
            rst => rst,
            ex_mem_ctrl_in => ex_mem_ctrl_in,
            ex_mem_data_in => ex_mem_data_in,
            mem_wb_data_out => mem_wb_data_out,
            mem_wb_ctrl_out => mem_wb_ctrl_out,
            MemReadData => MemReadData,
            MemRead => MemRead,
            MemWrite => MemWrite,
            MemAddress => MemAddress,
            MemWriteData => MemWriteData
        );

    -- Clock generation
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR CLK_PERIOD / 2;
        clk <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS;

    -- Test stimulus
    stimulus : PROCESS
    BEGIN
        -- Test 1: Reset
        REPORT "TEST 1: Reset sequence";
        rst <= '1';
        WAIT FOR CLK_PERIOD;
        rst <= '0';
        WAIT FOR CLK_PERIOD;

        -- Test 2: PassInterrupt = "00" (reset vector)
        REPORT "TEST 2: PassInterrupt = 00 (reset vector)";
        ex_mem_ctrl_in.memory_ctrl.SPtoMem <= '0';
        ex_mem_ctrl_in.memory_ctrl.PassInterrupt <= "00";
        ex_mem_ctrl_in.memory_ctrl.MemRead <= '1';
        ex_mem_ctrl_in.memory_ctrl.MemWrite <= '0';
        ex_mem_data_in.primary_data <= x"00001000";
        ex_mem_data_in.secondary_data <= x"DEADBEEF";
        WAIT FOR CLK_PERIOD;
        ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(0, ADDR_WIDTH)) REPORT "Expected address 0" SEVERITY error;
        ASSERT MemRead = '1' REPORT "Expected MemRead = 1" SEVERITY error;
        ASSERT MemWrite = '0' REPORT "Expected MemWrite = 0" SEVERITY error;
        ASSERT MemWriteData = x"DEADBEEF" REPORT "Expected MemWriteData = DEADBEEF" SEVERITY error;

        -- Test 3: PassInterrupt = "01" (value 1)
        REPORT "TEST 3: PassInterrupt = 01 (value 1)";
        ex_mem_ctrl_in.memory_ctrl.PassInterrupt <= "01";
        WAIT FOR CLK_PERIOD;
        ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(1, ADDR_WIDTH)) REPORT "Expected address 1" SEVERITY error;

        -- Test 4: PassInterrupt = "10" (PrimaryData + 2)
        REPORT "TEST 4: PassInterrupt = 10 (PrimaryData + 2)";
        ex_mem_ctrl_in.memory_ctrl.PassInterrupt <= "10";
        ex_mem_data_in.primary_data <= x"00000100";
        WAIT FOR CLK_PERIOD;
        ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(258, ADDR_WIDTH)) REPORT "Expected address 258 (256 + 2)" SEVERITY error;

        -- Test 5: PassInterrupt = "11" (PrimaryData)
        REPORT "TEST 5: PassInterrupt = 11 (PrimaryData)";
        ex_mem_ctrl_in.memory_ctrl.PassInterrupt <= "11";
        ex_mem_data_in.primary_data <= x"00005678";
        WAIT FOR CLK_PERIOD;
        ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(16#5678#, ADDR_WIDTH)) REPORT "Expected address 0x5678" SEVERITY error;

        -- Test 6: SPtoMem = '1' (use stack pointer)
        REPORT "TEST 6: SPtoMem = 1 (use stack pointer)";
        ex_mem_ctrl_in.memory_ctrl.SPtoMem <= '1';
        ex_mem_ctrl_in.memory_ctrl.SP_Enable <= '1';
        ex_mem_ctrl_in.memory_ctrl.SP_Function <= '0'; -- Decrement (to stay within range)
        WAIT FOR CLK_PERIOD;
        WAIT FOR CLK_PERIOD;
        WAIT FOR CLK_PERIOD;
        -- After 2 decrements from reset (which is 2^18 - 1)
        -- SP should be 2^18 - 3
        REPORT "Stack pointer decremented";

        -- Test 7: Memory write operation
        REPORT "TEST 7: Memory write operation";
        ex_mem_ctrl_in.memory_ctrl.SPtoMem <= '1';
        ex_mem_ctrl_in.memory_ctrl.MemRead <= '0';
        ex_mem_ctrl_in.memory_ctrl.MemWrite <= '1';
        ex_mem_ctrl_in.memory_ctrl.SP_Enable <= '0';
        ex_mem_data_in.secondary_data <= x"CAFEBABE";
        WAIT FOR CLK_PERIOD;
        ASSERT MemWrite = '1' REPORT "Expected MemWrite = 1" SEVERITY error;
        ASSERT MemWriteData = x"CAFEBABE" REPORT "Expected MemWriteData = CAFEBABE" SEVERITY error;

        -- Test 8: SP Increment
        REPORT "TEST 8: SP Increment";
        ex_mem_ctrl_in.memory_ctrl.SP_Enable <= '1';
        ex_mem_ctrl_in.memory_ctrl.SP_Function <= '1'; -- Increment
        ex_mem_ctrl_in.memory_ctrl.MemWrite <= '0';
        WAIT FOR CLK_PERIOD;
        WAIT FOR CLK_PERIOD;
        REPORT "Stack pointer incremented";

        -- Test 9: PassInterrupt with different values
        REPORT "TEST 9: Test all PassInterrupt values";
        ex_mem_ctrl_in.memory_ctrl.SPtoMem <= '0';
        ex_mem_ctrl_in.memory_ctrl.SP_Enable <= '0';

        FOR i IN 0 TO 3 LOOP
            ex_mem_ctrl_in.memory_ctrl.PassInterrupt <= STD_LOGIC_VECTOR(to_unsigned(i, 2));
            ex_mem_data_in.primary_data <= x"00000200";
            WAIT FOR CLK_PERIOD;
            CASE i IS
                WHEN 0 =>
                    ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(0, ADDR_WIDTH)) REPORT "PassInterrupt 00 failed" SEVERITY error;
                WHEN 1 =>
                    ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(1, ADDR_WIDTH)) REPORT "PassInterrupt 01 failed" SEVERITY error;
                WHEN 2 =>
                    ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(514, ADDR_WIDTH)) REPORT "PassInterrupt 10 failed" SEVERITY error;
                WHEN OTHERS =>
                    ASSERT MemAddress = STD_LOGIC_VECTOR(to_unsigned(16#200#, ADDR_WIDTH)) REPORT "PassInterrupt 11 failed" SEVERITY error;
            END CASE;
        END LOOP;

        -- Test 10: Control signal forwarding
        REPORT "TEST 10: Control signal forwarding";
        ex_mem_ctrl_in.memory_ctrl.MemRead <= '0';
        ex_mem_ctrl_in.memory_ctrl.MemWrite <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT MemRead = '0' REPORT "MemRead forward failed" SEVERITY error;
        ASSERT MemWrite = '0' REPORT "MemWrite forward failed" SEVERITY error;

        ex_mem_ctrl_in.memory_ctrl.MemRead <= '1';
        ex_mem_ctrl_in.memory_ctrl.MemWrite <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT MemRead = '1' REPORT "MemRead forward failed" SEVERITY error;
        ASSERT MemWrite = '1' REPORT "MemWrite forward failed" SEVERITY error;

        -- Test 11: Pipeline register pass-through (ALUData = PrimaryData)
        REPORT "TEST 11: Pipeline register - ALUData pass-through";
        ex_mem_data_in.primary_data <= x"12345678";
        WAIT FOR CLK_PERIOD;
        ASSERT mem_wb_data_out.alu_data = x"12345678" REPORT "ALUData should equal PrimaryData" SEVERITY error;

        -- Test 12: Pipeline register pass-through (RdstOut = RdstIN)
        REPORT "TEST 12: Pipeline register - RdstOut pass-through";
        ex_mem_data_in.rdst1 <= "101";
        WAIT FOR CLK_PERIOD;
        ASSERT mem_wb_data_out.rdst = "101" REPORT "RdstOut should equal RdstIN" SEVERITY error;

        -- Test 13: MemReadData to MemoryData pass-through
        REPORT "TEST 13: MemReadData to MemoryData pass-through";
        MemReadData <= x"ABCDEF00";
        WAIT FOR CLK_PERIOD;
        ASSERT mem_wb_data_out.memory_data = x"ABCDEF00" REPORT "MemoryData should equal MemReadData" SEVERITY error;

        REPORT "All tests completed!";
        WAIT;

    END PROCESS;

END ARCHITECTURE testbench;