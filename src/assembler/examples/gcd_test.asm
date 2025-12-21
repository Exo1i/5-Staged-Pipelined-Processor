# ============================================================================
# GCD(48, 18) = 6
# GCD(35, 14) = 7
# while b != 0: if a > b: a = a - b, else: swap(a, b)
# ============================================================================

.ORG 0

# R0 = a
# R1 = b
# R2 = temp
# R3 = constant
# R6 = current test number

LDM R0, 48
LDM R1, 18
LDM R3, 0
LDM R6, 1

OUT R0
OUT R1

GCD_Loop:
    # Check if b == 0
    SUB R2, R1, R3
    JZ GCD_Done

    # Check if a < b to swap
    SUB R2, R0, R1
    JN Swap_AB

    MOV R2, R0
    JMP GCD_Loop

Swap_AB:
    SWAP R0, R1
    JMP GCD_Loop

GCD_Done:
    OUT R0

    LDM R7, 2
    SUB R6, R6, R7
    JZ End_Tests


# Second Test
LDM R0, 35
LDM R1, 14
LDM R6, 2

OUT R0
OUT R1
JMP GCD_Loop

End_Tests:
    HLT
