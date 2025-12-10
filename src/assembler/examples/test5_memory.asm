; Test 5: Memory Operations
; Tests: LDD, STD with offsets

.ORG 0x0000
    JMP MAIN

.ORG 0x0010
MAIN:
    LDM R0, 0x0100      ; base address
    LDM R1, 42
    LDM R2, 84
    
    STD R1, 0(R0)       ; store at base
    STD R2, 5(R0)       ; store at base+5
    
    LDD R3, 0(R0)       ; load from base
    LDD R4, 5(R0)       ; load from base+5
    
    OUT R3
    OUT R4
    HLT