; Infinite Loop Test with Hardware Interrupt
; Vector Table
.ORG 0x0000
.DW MAIN        ; Reset Vector -> MAIN
.DW ISR         ; Interrupt Vector -> ISR

.ORG 0x0010
MAIN:
    LDM R1, 0       ; R1 = Counter
    NOP
    NOP
LOOP:
    INC R1          ; R1++
    NOP
    NOP
    JMP LOOP        ; Infinite Loop

; After MAIN, at 0x0014, ISR will write its address here

.ORG 0x0020
ISR:
    LDM R2, 0x0020      ; R2 = ISR address (flag)
    STD R1, 0(R1)       ; store at base
    NOP
    NOP
    HLT
    RTI                 ; Return from interrupt