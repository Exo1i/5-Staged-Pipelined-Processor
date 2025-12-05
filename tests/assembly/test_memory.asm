.ORG 0x0000
    NOP
    NOP

.ORG 0x0020
    LDM R1, 0x55    ; Data pattern
    LDM R2, 0x0100  ; Base Address (256)
    NOP
    NOP
    NOP
    
    STD R1, 0(R2)   ; Mem[256] = 0x55
    NOP
    NOP
    NOP
    
    LDM R3, 0       ; Clear R3
    NOP
    NOP
    NOP
    
    LDD R3, 0(R2)   ; R3 = Mem[256] (Should be 0x55)
    HLT