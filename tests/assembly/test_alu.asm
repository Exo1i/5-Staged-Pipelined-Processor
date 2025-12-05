.ORG 0x0000
    NOP             ; Reset Vector filler
    NOP

.ORG 0x0020         ; Start address
    LDM R1, 10      ; R1 = 10
    LDM R2, 20      ; R2 = 20
    NOP
    NOP
    NOP
    
    MOV R3, R1      ; R3 = 10
    NOP
    NOP
    NOP
    
    ADD R4, R1, R2  ; R4 = 10 + 20 = 30
    NOP
    NOP
    NOP
    
    SUB R5, R2, R1  ; R5 = 20 - 10 = 10
    NOP
    NOP
    NOP
    
    INC R1          ; R1 = 11
    NOP
    NOP
    NOP
    
    HLT