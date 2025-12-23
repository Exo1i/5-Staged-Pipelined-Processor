; Test 4: Stack Operations
; Tests: PUSH, POP

; Reset vector
.ORG 0x0000
.DW MAIN                ; Reset vector

.ORG 0x0010
MAIN:
    LDM R0, 100
    LDM R1, 200
    LDM R2, 300
    
    PUSH R0
    PUSH R1
    PUSH R2
    
    POP R5
    POP R4
    POP R3
    
    OUT R3
    OUT R4
    OUT R5
    HLT