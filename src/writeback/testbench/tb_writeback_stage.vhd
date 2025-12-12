LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.control_signals_pkg.ALL;
USE work.pipeline_data_pkg.ALL;
USE std.env.ALL;

ENTITY tb_writeback_stage IS
END tb_writeback_stage;

ARCHITECTURE testbench OF tb_writeback_stage IS
    CONSTANT DATA_WIDTH : INTEGER := 32;
    CONSTANT RDST_WIDTH : INTEGER := 3;
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL mem_wb_ctrl : pipeline_memory_writeback_ctrl_t := (writeback_ctrl => WRITEBACK_CTRL_DEFAULT);
    SIGNAL mem_wb_data : pipeline_memory_writeback_t := (memory_data => (OTHERS => '0'), alu_data => (OTHERS => '0'), rdst => (OTHERS => '0'));

    -- Output signals
    SIGNAL wb_out : writeback_outputs_t;

BEGIN

    -- DUT Instantiation
    dut : ENTITY work.writeback_stage
        PORT MAP(
            clk => clk,
            rst => rst,
            mem_wb_ctrl => mem_wb_ctrl,
            mem_wb_data => mem_wb_data,
            wb_out => wb_out
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

        -- Test 2: MemToALU = '0' (ALU data selection)
        REPORT "TEST 2: MemToALU = 0 (select ALUData)";
        mem_wb_ctrl.writeback_ctrl.MemToALU <= '0';
        mem_wb_ctrl.writeback_ctrl.RegWrite <= '1';
        mem_wb_ctrl.writeback_ctrl.OutPortWriteEn <= '0';
        mem_wb_data.alu_data <= x"12345678";
        mem_wb_data.memory_data <= x"DEADBEEF";
        mem_wb_data.rdst <= "011";
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.data = x"12345678" REPORT "Expected Data = ALUData (0x12345678)" SEVERITY error;
        ASSERT wb_out.rdst = "011" REPORT "Expected RdstOut = 011" SEVERITY error;
        ASSERT wb_out.reg_we = '1' REPORT "Expected RegWE = 1" SEVERITY error;
        ASSERT wb_out.port_enable = '0' REPORT "Expected PortEnable = 0" SEVERITY error;

        -- Test 3: MemToALU = '1' (Memory data selection)
        REPORT "TEST 3: MemToALU = 1 (select MemoryData)";
        mem_wb_ctrl.writeback_ctrl.MemToALU <= '1';
        mem_wb_data.memory_data <= x"CAFEBABE";
        mem_wb_data.alu_data <= x"11111111";
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.data = x"CAFEBABE" REPORT "Expected Data = MemoryData (0xCAFEBABE)" SEVERITY error;
        ASSERT wb_out.rdst = "011" REPORT "Expected RdstOut = 011" SEVERITY error;

        -- Test 4: Register write disable
        REPORT "TEST 4: RegWrite = 0 (register write disabled)";
        mem_wb_ctrl.writeback_ctrl.RegWrite <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.reg_we = '0' REPORT "Expected RegWE = 0" SEVERITY error;

        -- Test 5: Output port write enable
        REPORT "TEST 5: OutPortWriteEn = 1 (output port enabled)";
        mem_wb_ctrl.writeback_ctrl.OutPortWriteEn <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.port_enable = '1' REPORT "Expected PortEnable = 1" SEVERITY error;

        -- Test 6: Different register destinations
        REPORT "TEST 6: Test different register destinations";
        mem_wb_ctrl.writeback_ctrl.MemToALU <= '0';
        mem_wb_ctrl.writeback_ctrl.RegWrite <= '1';
        mem_wb_ctrl.writeback_ctrl.OutPortWriteEn <= '0';
        mem_wb_data.alu_data <= x"AABBCCDD";

        FOR i IN 0 TO 7 LOOP
            mem_wb_data.rdst <= STD_LOGIC_VECTOR(to_unsigned(i, RDST_WIDTH));
            WAIT FOR CLK_PERIOD;
            ASSERT wb_out.rdst = STD_LOGIC_VECTOR(to_unsigned(i, RDST_WIDTH)) REPORT "Expected RdstOut = " & INTEGER'image(i) SEVERITY error;
        END LOOP;

        -- Test 7: Data mux with varying inputs
        REPORT "TEST 7: Data mux with varying inputs";
        FOR i IN 0 TO 3 LOOP
            IF i MOD 2 = 0 THEN
                mem_wb_ctrl.writeback_ctrl.MemToALU <= '0';
                mem_wb_data.memory_data <= x"00000000";
                mem_wb_data.alu_data <= STD_LOGIC_VECTOR(to_unsigned(i * 256, DATA_WIDTH));
                WAIT FOR CLK_PERIOD;
                ASSERT wb_out.data = STD_LOGIC_VECTOR(to_unsigned(i * 256, DATA_WIDTH)) REPORT "Expected ALUData" SEVERITY error;
            ELSE
                mem_wb_ctrl.writeback_ctrl.MemToALU <= '1';
                mem_wb_data.memory_data <= STD_LOGIC_VECTOR(to_unsigned(i * 256, DATA_WIDTH));
                WAIT FOR CLK_PERIOD;
                ASSERT wb_out.data = STD_LOGIC_VECTOR(to_unsigned(i * 256, DATA_WIDTH)) REPORT "Expected MemoryData" SEVERITY error;
            END IF;
        END LOOP;

        -- Test 8: Control signal forwarding
        REPORT "TEST 8: Control signal forwarding";
        mem_wb_ctrl.writeback_ctrl.RegWrite <= '1';
        mem_wb_ctrl.writeback_ctrl.OutPortWriteEn <= '1';
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.reg_we = '1' REPORT "RegWrite forward failed" SEVERITY error;
        ASSERT wb_out.port_enable = '1' REPORT "OutPortWriteEn forward failed" SEVERITY error;

        mem_wb_ctrl.writeback_ctrl.RegWrite <= '0';
        mem_wb_ctrl.writeback_ctrl.OutPortWriteEn <= '0';
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.reg_we = '0' REPORT "RegWrite forward failed" SEVERITY error;
        ASSERT wb_out.port_enable = '0' REPORT "OutPortWriteEn forward failed" SEVERITY error;

        -- Test 9: All signals together
        REPORT "TEST 9: All signals integrated";
        mem_wb_ctrl.writeback_ctrl.MemToALU <= '1';
        mem_wb_ctrl.writeback_ctrl.RegWrite <= '1';
        mem_wb_ctrl.writeback_ctrl.OutPortWriteEn <= '1';
        mem_wb_data.memory_data <= x"FEDCBA98";
        mem_wb_data.alu_data <= x"01234567";
        mem_wb_data.rdst <= "110";
        WAIT FOR CLK_PERIOD;
        ASSERT wb_out.data = x"FEDCBA98" REPORT "Expected MemoryData" SEVERITY error;
        ASSERT wb_out.rdst = "110" REPORT "Expected RdstOut = 110" SEVERITY error;
        ASSERT wb_out.reg_we = '1' REPORT "Expected RegWE = 1" SEVERITY error;
        ASSERT wb_out.port_enable = '1' REPORT "Expected PortEnable = 1" SEVERITY error;

        REPORT "All tests completed!";

        finish;
    END PROCESS;

END ARCHITECTURE testbench;