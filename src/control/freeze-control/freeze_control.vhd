LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY freeze_control IS
    PORT (
        -- Inputs: Stall conditions from various sources
        PassPC_MEM : IN STD_LOGIC; -- From Memory Hazard Unit ('0' = stall due to memory conflict)
        Stall_Interrupt : IN STD_LOGIC; -- From Interrupt Unit ('1' = stall for interrupt processing)
        Stall_Branch : IN STD_LOGIC; -- From Branch Control ('1' = stall for branch misprediction) - Optional
        is_swap : IN STD_LOGIC; -- From Decode Stage ('1' = SWAP operation in progress)
        is_hlt : IN STD_LOGIC; -- From Decode Stage ('1' = HLT instruction)
        requireImmediate : IN STD_LOGIC; -- From Decode Stage ('1' = immediate instruction required)
        -- Outputs: Control signals for pipeline freeze
        PC_Freeze : OUT STD_LOGIC; -- Enable PC register update ('0' = allow update, '1' = freeze)
        IFDE_WriteEnable : OUT STD_LOGIC; -- Enable IF/DE pipeline register update
        InsertNOP_IFDE : OUT STD_LOGIC; -- Insert NOP/bubble into IF/DE stage ('1' = insert NOP)
        InsertNOP_DEEX : OUT STD_LOGIC  -- Insert NOP/bubble into DE/EX stage ('1' = insert NOP)
    );
END freeze_control;

ARCHITECTURE Behavioral OF freeze_control IS
    SIGNAL stall_condition : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN

    -- Concatenate all stall conditions into a vector for case statement
    stall_condition <= Stall_Branch & Stall_Interrupt & (NOT PassPC_MEM) & is_swap;

    PROCESS(stall_condition, requireImmediate, is_hlt)
    BEGIN
            InsertNOP_DEEX <= '0'; -- Default no NOP in DE/EX
            InsertNOP_IFDE <= '0'; -- Default no NOP in IF/DE
            PC_Freeze <= '0';        -- Default no freeze
            IFDE_WriteEnable <= '1'; -- Default enable IF/DE write

            -- HLT logic: if is_hlt is '1', freeze everything and insert NOPs
            IF is_hlt = '1' THEN
                PC_Freeze <= '1';
                IFDE_WriteEnable <= '0';
                InsertNOP_IFDE <= '0';
                InsertNOP_DEEX <= '1';
            ELSE
                CASE stall_condition IS
                    -- SWAP operation: Freeze PC and IF/DE register, but don't insert NOP
                    WHEN "0001" =>
                        PC_Freeze <= '1';        -- Freeze PC
                        IFDE_WriteEnable <= '0'; -- Disable IF/DE register write
                        InsertNOP_IFDE <= '0';   -- Don't insert NOP (preserve instruction)

                    -- Memory hazard (PassPC_MEM = '0'): Full stall with NOP
                    WHEN "0010" | "0011" =>
                        PC_Freeze <= '1';
                        IFDE_WriteEnable <= '0';
                        InsertNOP_IFDE <= '0' when requireImmediate = '1' else '1';
                        InsertNOP_DEEX <= '1' when requireImmediate = '1' else '0';

                    -- Interrupt stall: Full stall with NOP
                    WHEN "0100" | "0101" | "0110" | "0111" =>
                        PC_Freeze <= '1';
                        IFDE_WriteEnable <= '0';
                        InsertNOP_IFDE <= '1';

                    -- Branch misprediction: Full stall with NOP
                    WHEN "1000" | "1001" | "1010" | "1011" | "1100" | "1101" | "1110" | "1111" =>
                        PC_Freeze <= '1';
                        IFDE_WriteEnable <= '0';
                        InsertNOP_IFDE <= '1';

                    -- Normal operation: No stall
                    WHEN OTHERS =>
                        PC_Freeze <= '0';
                        IFDE_WriteEnable <= '1';
                        InsertNOP_IFDE <= '0';
                END CASE;
            END IF;
    END PROCESS;

END Behavioral;