; Test 6: Interrupt Handling
; Tests: INT, RTI, interrupt vectors

.ORG 0x0000
RESET_VEC:
    JMP MAIN            ; Reset vector

.ORG 0x0002
INT_VEC_0:
    JMP ISR0            ; INT 0 vector (M[2])

.ORG 0x0004
INT_VEC_1:
    JMP ISR1            ; INT 1 vector (M[3])

.ORG 0x0010
MAIN:
    LDM R0, 10
    OUT R0
    INT 0               ; Trigger interrupt 0
    OUT R0              ; Should output modified value
    HLT

.ORG 0x0050
ISR0:
    PUSH R1
    INC R0              ; Modify R0
    POP R1
    RTI

.ORG 0x0070
ISR1:
    PUSH R1
    NOT R0
    POP R1
    RTI