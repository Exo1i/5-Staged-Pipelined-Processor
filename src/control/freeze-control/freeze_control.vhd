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
        memory_hazard_int : IN STD_LOGIC; -- From Interrupt Unit ('1' = memory hazard due to interrupt)
        -- Outputs: Control signals for pipeline freeze
        PC_Freeze : OUT STD_LOGIC; -- Enable PC register update ('0' = allow update, '1' = freeze)
        IFDE_WriteEnable : OUT STD_LOGIC; -- Enable IF/DE pipeline register update
        InsertNOP_IFDE : OUT STD_LOGIC; -- Insert NOP/bubble into IF/DE stage ('1' = insert NOP)
        InsertNOP_DEEX : OUT STD_LOGIC  -- Insert NOP/bubble into DE/EX stage ('1' = insert NOP)
    );
END freeze_control;

ARCHITECTURE Behavioral OF freeze_control IS
BEGIN

    -- Concatenate all stall conditions into a vector for case statement
    PROCESS(PassPC_MEM, Stall_Interrupt, Stall_Branch, is_swap, is_hlt , memory_hazard_int)
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
                IF Stall_Interrupt = '1' THEN
                    IFDE_WriteEnable <= '0';
                ELSIF is_swap = '1' THEN 
                    PC_Freeze <= '1';
                    IFDE_WriteEnable <= '0';
                END IF;
                
                IF memory_hazard_int = '1' THEN
                    IF Stall_Interrupt = '1' THEN
                        IFDE_WriteEnable <= '1';
                        InsertNOP_IFDE <= '1';
                    ELSE 
                        IFDE_WriteEnable <= '1';
                        InsertNOP_IFDE <= '1';
                        InsertNOP_DEEX <= '1';
                    END IF;
                END IF;

                IF PassPC_MEM = '0' THEN
                    PC_Freeze <= '1';
                    InsertNOP_IFDE <= '1';
                END IF;     

            END IF;
    END PROCESS;

END Behavioral;