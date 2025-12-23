; Test 2: Loop with Conditional Branch
; Tests: JZ, JMP, SUB, INC

; Reset vector at address 0 - points to MAIN
.ORG 0x0000
.DW MAIN        ; Reset vector - PC loads this address on startup

.ORG 0x0010
MAIN:
    LDM R0, 0       ; counter
    LDM R1, 5       ; limit
    
LOOP:
    OUT R0
    INC R0
    SUB R2, R1, R0
    JZ END
    JMP LOOP
    
END:
    HLT