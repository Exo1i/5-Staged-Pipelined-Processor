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
        BranchTargetSelect      : out std_logic_vector(1 downto 0);   -- Target mux select
        
        -- Dynamic prediction outputs
        Misprediction           : out std_logic;                      -- Misprediction detected
        UpdatePredictor         : out std_logic;                      -- Update predictor state
        FlushIF                 : out std_logic;                      -- Flush fetch stage
        FlushDE                 : out std_logic                       -- Flush decode stage
    );
end branch_decision_unit;

architecture Behavioral of branch_decision_unit is
    
    -- Dynamic prediction signals
    signal misprediction_sig : std_logic;
    signal take_branch       : std_logic;
    
begin
    
    -- Dynamic prediction: Detect branch misprediction
    -- Misprediction occurs when we have a conditional branch and prediction differs from actual
    misprediction_sig <= ConditionalBranch and (PredictedTaken xor ActualTaken);
    
    -- Output misprediction signal
    Misprediction <= misprediction_sig;
    
    -- Update predictor whenever a conditional branch is resolved in execute
    UpdatePredictor <= ConditionalBranch;
    
    -- Determine if we should take a branch (dynamic prediction)
    process(Reset, IsHardwareInterrupt, IsSoftwareInterrupt, IsRTI, IsReturn, IsCall, UnconditionalBranch, 
            ConditionalBranch, ActualTaken, PredictedTaken, misprediction_sig)
    begin
        -- Default values
        take_branch <= '0';
        BranchTargetSelect <= TARGET_DECODE;
        FlushIF <= '0';
        FlushDE <= '0';
        
        -- Priority-based decision
        if Reset = '1' then
            -- During reset: output neutral signals
            -- PC module handles reset internally (resets to 0)
            take_branch <= '0';
            BranchTargetSelect <= TARGET_DECODE;
            FlushIF <= '0';
            FlushDE <= '0';
            
        elsif IsHardwareInterrupt = '1' or IsSoftwareInterrupt = '1' or IsRTI = '1' or IsReturn = '1' then
            -- Interrupt/RTI/RET: PC comes from memory (interrupt vector or popped return address)
            take_branch <= '1';
            BranchTargetSelect <= TARGET_MEMORY;
            FlushIF <= '1';  -- Flush fetch stage
            FlushDE <= '1';  -- Flush decode stage
            
        elsif IsCall = '1' or UnconditionalBranch = '1' then
            -- CALL or JMP: jump to immediate from decode stage
            take_branch <= '1';
            BranchTargetSelect <= TARGET_DECODE;  -- Use immediate from decode
            FlushIF <= '1';  -- Flush the instruction that was fetched after the branch
            FlushDE <= '0';  -- Don't flush decode (branch instruction itself)
            
        elsif misprediction_sig = '1' then
            -- Branch misprediction detected - need to redirect and flush
            take_branch <= ActualTaken;  -- Take branch based on actual outcome
            if ActualTaken = '1' then
                BranchTargetSelect <= TARGET_EXECUTE;  -- Branch target from execute stage
            else
                BranchTargetSelect <= TARGET_DECODE;   -- PC+1 (fall through) - handled by PC
            end if;
            FlushIF <= '1';  -- Flush fetch stage
            FlushDE <= '1';  -- Flush decode stage
            
        elsif ConditionalBranch = '1' and PredictedTaken = '1' and ActualTaken = '1' then
            -- Conditional branch correctly predicted as taken - no flush needed
            -- Branch target already set in decode when prediction was made
            take_branch <= '0';  -- PC already pointing to target
            BranchTargetSelect <= TARGET_EXECUTE;
            FlushIF <= '0';
            FlushDE <= '0';
            
        end if;
    end process;
    
    -- Output branch select
    BranchSelect <= take_branch;

end Behavioral;
