; Test 2: Loop with Conditional Branch
; Tests: JZ, JMP, SUB, INC

.ORG 0x0000
    JMP MAIN

.ORG 0x0020
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