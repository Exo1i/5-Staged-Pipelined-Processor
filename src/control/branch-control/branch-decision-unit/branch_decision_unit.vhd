library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.pkg_opcodes.ALL;

entity branch_decision_unit is
    Port (
        -- Inputs from various sources
        IsSoftwareInterrupt     : in  std_logic;                      -- Software interrupt
        IsHardwareInterrupt     : in  std_logic;                      -- Hardware interrupt
        IsRTI                   : in  std_logic;                      -- Return from interrupt 
        UnconditionalBranch     : in  std_logic;                      -- Unconditional branch (JMP/CALL)
        ConditionalBranch       : in  std_logic;                      -- Conditional branch in execute
        PredictedTaken          : in  std_logic;                      -- Prediction from predictor
        ActualTaken             : in  std_logic;                      -- Actual outcome from execute
        Reset                   : in  std_logic;                      -- Reset signal
        
        -- Outputs
        BranchSelect            : out std_logic;                      -- 0=PC+1, 1=branch target
        BranchTargetSelect      : out std_logic_vector(1 downto 0);  -- Target mux select
        FlushDE                 : out std_logic;                      -- Flush decode stage
        FlushIF                 : out std_logic;                      -- Flush fetch stage
        FlushEX                 : out std_logic;                      -- Flush execute stage
        Stall_Branch            : out std_logic                       -- Stall signal for freeze control
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
    process(Reset, IsHardwareInterrupt, IsSoftwareInterrupt, IsRTI, UnconditionalBranch, 
            ConditionalBranch, ActualTaken)
    begin
        -- Default values
        take_branch <= '0';
        BranchTargetSelect <= TARGET_DECODE;
        FlushDE <= '0';
        FlushIF <= '0';
        FlushEX <= '0';
        Stall_Branch <= '0';
        
        -- Priority-based decision
        if Reset = '1' then
            -- During reset: output neutral signals
            -- PC module handles reset internally (resets to 0)
            -- Don't try to branch to target_reset which may be undefined
            take_branch <= '0';
            BranchTargetSelect <= TARGET_DECODE;
            FlushDE <= '1';  -- Still flush pipeline
            FlushIF <= '1';
            
        elsif IsHardwareInterrupt = '1' then
            -- Hardware interrupt
            take_branch <= '1';
            BranchTargetSelect <= TARGET_MEMORY;  -- Interrupt vector from memory
            FlushDE <= '0';
            FlushIF <= '1';
            
        elsif IsSoftwareInterrupt = '1' then
            -- Software interrupt
            take_branch <= '1';
            BranchTargetSelect <= TARGET_MEMORY;  -- Interrupt vector from memory
            FlushDE <= '0';
            FlushIF <= '1';

        elsif IsRTI = '1' then
            -- Return from interrupt
            take_branch <= '1';
            BranchTargetSelect <= TARGET_MEMORY;  -- Return address from memory
            FlushDE <= '1';
            FlushIF <= '1';
            FlushEX <= '1';
            
        elsif UnconditionalBranch = '1' then
            -- Unconditional branch (JMP, CALL)
            take_branch <= '1';
            BranchTargetSelect <= TARGET_DECODE;  -- Use immediate from decode
            FlushDE <= '1';
            FlushIF <= '1';
            
        -- Static prediction: branch is taken when ActualTaken is true
        -- (we always predicted not-taken, so flush and redirect if actually taken)
        elsif ConditionalBranch = '1' and ActualTaken = '1' then
            take_branch <= '1';
            BranchTargetSelect <= TARGET_EXECUTE;  -- Use target from execute
            FlushDE <= '1';  -- Flush decode stage (wrong path)
            FlushIF <= '1';  -- Flush fetch stage (wrong path)
            
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
