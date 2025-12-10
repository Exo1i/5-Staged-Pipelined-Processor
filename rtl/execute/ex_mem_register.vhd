library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex_mem_register is
    Port (
        clk    : in STD_LOGIC;
        reset  : in STD_LOGIC;
        enable : in STD_LOGIC;  -- For stall handling
        flush  : in STD_LOGIC;  -- For control hazards
        
        -- Inputs from Execute Stage
        ALU_Result_in : in STD_LOGIC_VECTOR(31 downto 0);
        RegB_Data_in  : in STD_LOGIC_VECTOR(31 downto 0);
        CCR_in        : in STD_LOGIC_VECTOR(2 downto 0);
        PC_in         : in STD_LOGIC_VECTOR(31 downto 0);
        
        -- Control signals from Execute Stage
        MemRead_in    : in STD_LOGIC;
        MemWrite_in   : in STD_LOGIC;
        RegWrite_in   : in STD_LOGIC;
        MemToReg_in   : in STD_LOGIC;
        SpToMem_in    : in STD_LOGIC;
        MemDataSel_in : in STD_LOGIC_VECTOR(1 downto 0);
        
        -- Destination register info
        Rdst_in       : in STD_LOGIC_VECTOR(2 downto 0);
        Rdst2_in      : in STD_LOGIC_VECTOR(2 downto 0);
        RegWrite2_in  : in STD_LOGIC;
        
        -- Outputs to Memory Stage
        ALU_Result_out : out STD_LOGIC_VECTOR(31 downto 0);
        RegB_Data_out  : out STD_LOGIC_VECTOR(31 downto 0);
        CCR_out        : out STD_LOGIC_VECTOR(2 downto 0);
        PC_out         : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Control signals to Memory Stage
        MemRead_out    : out STD_LOGIC;
        MemWrite_out   : out STD_LOGIC;
        RegWrite_out   : out STD_LOGIC;
        MemToReg_out   : out STD_LOGIC;
        SpToMem_out    : out STD_LOGIC;
        MemDataSel_out : out STD_LOGIC_VECTOR(1 downto 0);
        
        -- Destination register info
        Rdst_out       : out STD_LOGIC_VECTOR(2 downto 0);
        Rdst2_out      : out STD_LOGIC_VECTOR(2 downto 0);
        RegWrite2_out  : out STD_LOGIC
    );
end ex_mem_register;

architecture Behavioral of ex_mem_register is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all outputs
            ALU_Result_out <= (others => '0');
            RegB_Data_out  <= (others => '0');
            CCR_out        <= (others => '0');
            PC_out         <= (others => '0');
            MemRead_out    <= '0';
            MemWrite_out   <= '0';
            RegWrite_out   <= '0';
            MemToReg_out   <= '0';
            SpToMem_out    <= '0';
            MemDataSel_out <= (others => '0');
            Rdst_out       <= (others => '0');
            Rdst2_out      <= (others => '0');
            RegWrite2_out  <= '0';
            
        elsif rising_edge(clk) then
            if flush = '1' then
                -- Flush: Insert bubble (NOP)
                ALU_Result_out <= (others => '0');
                RegB_Data_out  <= (others => '0');
                CCR_out        <= (others => '0');
                PC_out         <= (others => '0');
                MemRead_out    <= '0';
                MemWrite_out   <= '0';
                RegWrite_out   <= '0';  -- Critical: disable writes
                MemToReg_out   <= '0';
                SpToMem_out    <= '0';
                MemDataSel_out <= (others => '0');
                Rdst_out       <= (others => '0');
                Rdst2_out      <= (others => '0');
                RegWrite2_out  <= '0';
                
            elsif enable = '1' then
                -- Normal operation: latch inputs
                ALU_Result_out <= ALU_Result_in;
                RegB_Data_out  <= RegB_Data_in;
                CCR_out        <= CCR_in;
                PC_out         <= PC_in;
                MemRead_out    <= MemRead_in;
                MemWrite_out   <= MemWrite_in;
                RegWrite_out   <= RegWrite_in;
                MemToReg_out   <= MemToReg_in;
                SpToMem_out    <= SpToMem_in;
                MemDataSel_out <= MemDataSel_in;
                Rdst_out       <= Rdst_in;
                Rdst2_out      <= Rdst2_in;
                RegWrite2_out  <= RegWrite2_in;
            end if;
            -- If enable = '0', hold current values (stall)
        end if;
    end process;
    
end Behavioral;