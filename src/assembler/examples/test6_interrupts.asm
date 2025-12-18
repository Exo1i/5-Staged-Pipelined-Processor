; Test 6: Interrupt Handling
; Tests: INT 0, INT 1, INT 2, RTI, interrupt vectors

.ORG 0x0000
.DW MAIN                ; Reset vector

.ORG 0x0002
.DW ISR0                ; Interrupt vector 0

.ORG 0x0004
.DW ISR1                ; Interrupt vector 1

.ORG 0x0006
.DW ISR2                ; Interrupt vector 2

.ORG 0x0010
MAIN:
    LDM R0, 10
    OUT R0              ; Output 10
    
    INT 0               ; Trigger interrupt 0 (INC R0)
    OUT R0              ; Should output 11
    
    INT 1               ; Trigger interrupt 1 (NOT R0)
    OUT R0              ; Should output ~11 = 0xFFFFFFF4
    
    INT 2               ; Trigger interrupt 2 (ADD 5)
    OUT R0              ; Should output 0xFFFFFFF4 + 5 = 0xFFFFFFF9
    
    LDM R1, 0xFF
    OUT R1              ; Success marker
    HLT

.ORG 0x0050
ISR0:
    PUSH R1
    INC R0              ; R0 = R0 + 1
    POP R1
    RTI

.ORG 0x0070
ISR1:
    PUSH R1
    NOT R0              ; R0 = ~R0
    POP R1
    RTI

.ORG 0x0090
ISR2:
    PUSH R1
    LDM R1, 5
    ADD R0, R0, R1      ; R0 = R0 + 5
    POP R1
    RTI