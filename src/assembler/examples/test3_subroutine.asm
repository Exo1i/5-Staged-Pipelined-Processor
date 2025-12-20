; Test 3: Subroutine Call
; Tests: CALL, RET, stack operations

; Reset vector
.ORG 0x0000
.DW MAIN                ; Reset vector

.ORG 0x0010
MAIN:
    LDM R1, 7
    LDM R2, 3
    CALL ADD_FUNC
    OUT R3
    HLT

.ORG 0x0050
ADD_FUNC:
    ADD R3, R1, R2
    JMP 0x00016
    RET