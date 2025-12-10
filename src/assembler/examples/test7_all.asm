; Test 7: All Instructions
; Comprehensive test of entire ISA

.ORG 0x0000
    JMP MAIN

.ORG 0x0010
MAIN:
    ; One operand
    NOP
    SETC
    LDM R0, 0xFF
    NOT R0
    INC R0
    OUT R0
    IN R1
    
    ; Two operand
    LDM R2, 10
    MOV R2, R3
    LDM R4, 20
    SWAP R3, R4
    
    ; Three operand
    ADD R5, R3, R4
    SUB R6, R5, R3
    LDM R7, 0x0F
    AND R0, R5, R7
    
    ; Immediate arithmetic
    IADD R1, R0, 15
    
    ; Branch tests
    LDM R0, 5
    LDM R1, 5
    SUB R2, R0, R1
    JZ ZERO_TEST
    JMP SKIP1
    
ZERO_TEST:
    LDM R0, 3
    LDM R1, 5
    SUB R2, R0, R1
    JN NEG_TEST
    JMP SKIP2
    
NEG_TEST:
    SETC
    JC CARRY_TEST
    
CARRY_TEST:
    HLT
    
SKIP1:
    HLT
    
SKIP2:
    HLT