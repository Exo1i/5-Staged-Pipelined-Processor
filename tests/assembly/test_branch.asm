.ORG 0x0000
    JMP START       ; 1. Test Unconditional JMP over empty space

.ORG 0x0020
START:
    LDM R1, 5
    LDM R2, 5
    NOP
    NOP
    NOP
    
    SUB R3, R1, R2  ; R3 = 0, Z flag set
    NOP
    NOP
    NOP
    
    JZ IS_ZERO      ; 2. Test JZ (Should jump)
    
    LDM R7, 0xBAD   ; Should not execute
    HLT

IS_ZERO:
    LDM R4, 1       ; Marker
    CALL MY_SUB     ; 3. Test CALL
    
    LDM R6, 0xFF    ; Marker for return
    HLT

MY_SUB:
    LDM R5, 7       ; Inside Subroutine
    RET             ; 4. Test RET