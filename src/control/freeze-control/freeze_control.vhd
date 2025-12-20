LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.ALL;

ENTITY freeze_control IS
    PORT (
        -- Inputs: Stall conditions from various sources
        PassPC_MEM : IN STD_LOGIC; -- From Memory Hazard Unit ('0' = stall due to memory conflict)
        Stall_Interrupt : IN STD_LOGIC; -- From Interrupt Unit ('1' = stall for interrupt processing)
        BranchSelect : IN STD_LOGIC; -- From Branch Decision Unit ('1' = branch taken)
        BranchTargetSelect : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- From Branch Decision Unit (target mux select)
        is_swap : IN STD_LOGIC; -- From Decode Stage ('1' = SWAP operation in progress)
        is_hlt : IN STD_LOGIC; -- From Decode Stage ('1' = HLT instruction)
        requireImmediate : IN STD_LOGIC; -- From Decode Stage ('1' = immediate instruction required)
        memory_hazard_int : IN STD_LOGIC; -- From Interrupt Unit ('1' = memory hazard due to interrupt)
        
        -- Flush signals from Branch Decision Unit (for dynamic prediction)
        FlushIF : IN STD_LOGIC; -- Flush IF stage ('1' = flush)
        FlushDE : IN STD_LOGIC; -- Flush DE stage ('1' = flush)
        
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
    PROCESS(PassPC_MEM, Stall_Interrupt, is_swap, is_hlt, BranchSelect, BranchTargetSelect, FlushIF, FlushDE)
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
                

                -- Branching flush logic using explicit flush signals
                -- FlushIF and FlushDE come from branch decision unit for precise control
                IF BranchSelect = '1' OR FlushIF = '1' OR FlushDE = '1' THEN
                    IFDE_WriteEnable <= '1';
                    
                    -- Flush IF/DE stage if FlushIF is asserted
                    IF FlushIF = '1' THEN
                        InsertNOP_IFDE <= '1';
                    END IF;
                    
                    -- Flush DE/EX stage if FlushDE is asserted
                    IF FlushDE = '1' THEN
                        InsertNOP_DEEX <= '1';
                    END IF;
                    
                    -- Fallback for legacy behavior (BranchSelect without explicit flush)
                    IF BranchSelect = '1' AND FlushIF = '0' AND FlushDE = '0' THEN
                        InsertNOP_IFDE <= '1';
                        IF BranchTargetSelect = TARGET_EXECUTE THEN
                            InsertNOP_DEEX <= '1';
                        END IF;
                    END IF;

                END IF;

                IF PassPC_MEM = '0' THEN
                    PC_Freeze <= '1';
                    InsertNOP_IFDE <= '1';
                END IF;     

            END IF;
    END PROCESS;

END Behavioral;