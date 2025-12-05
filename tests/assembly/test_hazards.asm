.ORG 0x0000
    NOP
    NOP

.ORG 0x0020
    LDM R1, 1
    LDM R2, 2
    NOP
    NOP
    NOP
    
    ; Data Hazard Sequence
    ADD R3, R1, R2  ; R3 writes 3 (WB stage)
    ADD R4, R3, R1  ; R4 reads R3 immediately (Decode stage) -> Needs Forwarding
    ADD R5, R4, R1  ; R5 reads R4 immediately -> Needs Forwarding
    
    HLT