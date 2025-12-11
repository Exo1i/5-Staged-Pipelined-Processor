library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ex_mem_register is
    Port (
        clk    : in STD_LOGIC;
        reset  : in STD_LOGIC;
        enable : in STD_LOGIC;  -- For stall handling
        flush  : in STD_LOGIC;  -- For control hazards
        
        -- WB (Write Back) Control Signals - Input
        WB_RegWrite_in   : in STD_LOGIC;
        WB_MemToReg_in   : in STD_LOGIC;
        
        -- M (Memory) Control Signals - Input
        M_MemRead_in     : in STD_LOGIC;
        M_MemWrite_in    : in STD_LOGIC;
        M_SpToMem_in     : in STD_LOGIC;
        M_PassInterrupt_in : in STD_LOGIC;
        
        -- ALU Result / Memory Address - Input
        ALU_Result_in    : in STD_LOGIC_VECTOR(31 downto 0);
        
        -- Primary Data - Input
        Primary_Data_in  : in STD_LOGIC_VECTOR(31 downto 0);
        
        -- Secondary Data - Input
        Secondary_Data_in : in STD_LOGIC_VECTOR(31 downto 0);
        
        -- Rdst1 - Input
        Rdst1_in         : in STD_LOGIC_VECTOR(2 downto 0);
        
        -- WB (Write Back) Control Signals - Output
        WB_RegWrite_out  : out STD_LOGIC;
        WB_MemToReg_out  : out STD_LOGIC;
        
        -- M (Memory) Control Signals - Output
        M_MemRead_out    : out STD_LOGIC;
        M_MemWrite_out   : out STD_LOGIC;
        M_SpToMem_out    : out STD_LOGIC;
        M_PassInterrupt_out : out STD_LOGIC;
        
        -- ALU Result / Memory Address - Output
        ALU_Result_out   : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Primary Data - Output
        Primary_Data_out : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Secondary Data - Output
        Secondary_Data_out : out STD_LOGIC_VECTOR(31 downto 0);
        
        -- Rdst1 - Output
        Rdst1_out        : out STD_LOGIC_VECTOR(2 downto 0)
    );
end ex_mem_register;

architecture Behavioral of ex_mem_register is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all outputs
            -- WB signals
            WB_RegWrite_out     <= '0';
            WB_MemToReg_out     <= '0';
            -- M signals
            M_MemRead_out       <= '0';
            M_MemWrite_out      <= '0';
            M_SpToMem_out       <= '0';
            M_PassInterrupt_out <= '0';
            -- Data signals
            ALU_Result_out      <= (others => '0');
            Primary_Data_out    <= (others => '0');
            Secondary_Data_out  <= (others => '0');
            Rdst1_out           <= (others => '0');
            
        elsif rising_edge(clk) then
            if flush = '1' then
                -- Flush: Insert bubble (NOP)
                -- WB signals
                WB_RegWrite_out     <= '0';
                WB_MemToReg_out     <= '0';
                -- M signals
                M_MemRead_out       <= '0';
                M_MemWrite_out      <= '0';
                M_SpToMem_out       <= '0';
                M_PassInterrupt_out <= '0';
                -- Data signals
                ALU_Result_out      <= (others => '0');
                Primary_Data_out    <= (others => '0');
                Secondary_Data_out  <= (others => '0');
                Rdst1_out           <= (others => '0');
                
            elsif enable = '1' then
                -- Normal operation: latch inputs
                -- WB signals
                WB_RegWrite_out     <= WB_RegWrite_in;
                WB_MemToReg_out     <= WB_MemToReg_in;
                -- M signals
                M_MemRead_out       <= M_MemRead_in;
                M_MemWrite_out      <= M_MemWrite_in;
                M_SpToMem_out       <= M_SpToMem_in;
                M_PassInterrupt_out <= M_PassInterrupt_in;
                -- Data signals
                ALU_Result_out      <= ALU_Result_in;
                Primary_Data_out    <= Primary_Data_in;
                Secondary_Data_out  <= Secondary_Data_in;
                Rdst1_out           <= Rdst1_in;
            end if;
            -- If enable = '0', hold current values (stall)
        end if;
    end process;
    
end Behavioral;