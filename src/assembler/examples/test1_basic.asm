; Test 1: Basic Instructions
; Tests: NOP, HLT, SETC, arithmetic, output

.ORG 0x0000
    JMP START

.ORG 0x0010
START:
    NOP
    SETC
    LDM R0, 10
    LDM R1, 20
    ADD R2, R0, R1
    SUB R3, R0, R1
    AND R4, R0, R1
    NOT R0
    INC R0
    IN R2
    OUT R2
    HLT