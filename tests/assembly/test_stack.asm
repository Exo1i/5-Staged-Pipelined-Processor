.ORG 0x0000
    NOP
    NOP

.ORG 0x0020
    LDM R1, 0xAA    ; Pattern A
    LDM R2, 0xBB    ; Pattern B
    NOP
    NOP
    NOP
    
    PUSH R1         ; Stack <- 0xAA
    NOP
    NOP
    NOP
    
    PUSH R2         ; Stack <- 0xBB
    NOP
    NOP
    NOP
    
    POP R3          ; R3 <- 0xBB
    NOP
    NOP
    NOP
    
    POP R4          ; R4 <- 0xAA
    HLT