library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.ALL;

entity branch_decision_unit is
    Port (
        -- Inputs from various sources
        IsSoftwareInterrupt     : in  std_logic;                      -- Software interrupt
        IsHardwareInterrupt     : in  std_logic;                      -- Hardware interrupt
        IsRTI                   : in  std_logic;                      -- Return from interrupt 
        IsReturn                : in  std_logic;                      -- RET instruction (PC from stack)
        IsCall                  : in  std_logic;                      -- CALL instruction (jump to immediate)
        UnconditionalBranch     : in  std_logic;                      -- Unconditional branch (JMP)
        ConditionalBranch       : in  std_logic;                      -- Conditional branch in execute
        PredictedTaken          : in  std_logic;                      -- Prediction from predictor
        ActualTaken             : in  std_logic;                      -- Actual outcome from execute
        Reset                   : in  std_logic;                      -- Reset signal
        
        -- Outputs
        BranchSelect            : out std_logic;                      -- 0=PC+1, 1=branch target
        BranchTargetSelect      : out std_logic_vector(1 downto 0)  -- Target mux select
    );
end branch_decision_unit;

architecture Behavioral of branch_decision_unit is
    
    -- Dynamic prediction signals (commented out for static prediction)
    -- signal misprediction : std_logic;
    signal take_branch   : std_logic;
    
begin
    
    -- Dynamic prediction: Detect branch misprediction
    -- misprediction <= ConditionalBranch and (PredictedTaken xor ActualTaken);
    
    -- Determine if we should take a branch
    -- Static prediction: Always predict not-taken, resolve in execute stage
    process(Reset, IsHardwareInterrupt, IsSoftwareInterrupt, IsRTI, IsReturn, IsCall, UnconditionalBranch, 
            ConditionalBranch, ActualTaken)
    begin
        -- Default values
        take_branch <= '0';
        BranchTargetSelect <= TARGET_DECODE;
        
        -- Priority-based decision
        if Reset = '1' then
            -- During reset: output neutral signals
            -- PC module handles reset internally (resets to 0)
            -- Don't try to branch to target_reset which may be undefined
            take_branch <= '0';
            BranchTargetSelect <= TARGET_DECODE;
            
        elsif IsHardwareInterrupt = '1' or IsSoftwareInterrupt = '1' or IsRTI = '1' or IsReturn = '1' then
            -- Interrupt/RTI/RET: PC comes from memory (interrupt vector or popped return address)
            take_branch <= '1';
            BranchTargetSelect <= TARGET_MEMORY;
            
        elsif IsCall = '1' or UnconditionalBranch = '1' then
            -- CALL or JMP: jump to immediate from decode stage
            take_branch <= '1';
            BranchTargetSelect <= TARGET_DECODE;  -- Use immediate from decode
            
        -- Static prediction: branch is taken when ActualTaken is true
        -- (we always predicted not-taken, so flush and redirect if actually taken)
        elsif ConditionalBranch = '1' and ActualTaken = '1' then
            take_branch <= '1';
            BranchTargetSelect <= TARGET_EXECUTE;  -- Use target from execute
            
        -- Dynamic prediction logic (commented out):
        -- elsif misprediction = '1' then
        --     -- Branch misprediction detected
        --     take_branch <= ActualTaken;  -- Take branch based on actual outcome
        --     BranchTargetSelect <= TARGET_EXECUTE;  -- Use immediate from execute
        --     FlushDE <= '1';  -- Flush decode stage
        --     FlushIF <= '1';  -- Flush fetch stage
        --     
        -- elsif ConditionalBranch = '1' and ActualTaken = '1' then
        --     -- Conditional branch correctly predicted as taken
        --     take_branch <= '1';
        --     BranchTargetSelect <= TARGET_EXECUTE;  -- Use immediate from execute
        --     -- No flush needed if prediction was correct
            
        end if;
    end process;
    
    -- Output branch select
    BranchSelect <= take_branch;

end Behavioral;
