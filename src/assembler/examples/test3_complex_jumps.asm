; Test 3: Complex Branch Test - All Conditional Types
; Tests: JMP, JZ, JN, JC, nested loops, forward/backward jumps
; Expected: Tests all branch types and complex control flow

; Reset vector at address 0 - points to MAIN
.ORG 0x0000
.DW MAIN        ; Reset vector

.ORG 0x0010
MAIN:
    ; Initialize registers
    LDM R0, 0       ; R0 = 0 (counter)
    LDM R1, 3       ; R1 = 3 (outer loop limit)
    LDM R2, 0       ; R2 = 0 (inner counter)
    LDM R3, 2       ; R3 = 2 (inner loop limit)
    
    ; ===== OUTER LOOP =====
OUTER_LOOP:
    OUT R0              ; Output outer counter
    LDM R2, 0           ; Reset inner counter
    
    ; ===== INNER LOOP =====
INNER_LOOP:
    INC R2              ; Increment inner counter
    SUB R4, R3, R2      ; R4 = limit - counter
    JZ INNER_DONE       ; If zero, inner loop done
    JMP INNER_LOOP      ; Continue inner loop

INNER_DONE:
    INC R0              ; Increment outer counter
    SUB R4, R1, R0      ; R4 = outer_limit - outer_counter
    JZ OUTER_DONE       ; If zero, all done
    JMP OUTER_LOOP      ; Continue outer loop

OUTER_DONE:
    ; ===== Test JZ - Jump Zero =====
    LDM R5, 5
    LDM R6, 5
    SUB R7, R5, R6      ; R7 = 5 - 5 = 0 (zero)
    JZ JZ_PASS          ; Should jump (zero flag set)
    JMP FAIL            ; Should not reach here

JZ_PASS:
    LDM R0, 0x01        ; JZ test passed marker
    OUT R0

    ; ===== Test JZ NOT jumping when non-zero =====
    LDM R5, 5
    LDM R6, 3
    SUB R7, R5, R6      ; R7 = 5 - 3 = 2 (not zero)
    JZ FAIL             ; Should NOT jump
    
    ; ===== Test JN - Jump Negative =====
    LDM R5, 1
    LDM R6, 5
    SUB R7, R5, R6      ; R7 = 1 - 5 = -4 (negative)
    JN JN_PASS          ; Should jump (negative flag set)
    JMP FAIL            ; Should not reach here

JN_PASS:
    LDM R0, 0x02        ; JN test passed marker
    OUT R0

    ; ===== Test JN NOT jumping when positive =====
    LDM R5, 5
    LDM R6, 3
    SUB R7, R5, R6      ; R7 = 5 - 3 = 2 (positive)
    JN FAIL             ; Should NOT jump

    ; ===== Test JC - Jump Carry (unsigned overflow) =====
    ; To generate carry: subtract larger from smaller unsigned
    ; When A < B (unsigned), subtraction causes borrow (carry)
    LDM R5, 2
    LDM R6, 5
    SUB R7, R5, R6      ; 2 - 5 causes borrow/carry
    JC JC_PASS          ; Should jump (carry flag set)
    JMP FAIL            ; Should not reach here

JC_PASS:
    LDM R0, 0x03        ; JC test passed marker  
    OUT R0

    ; ===== Test JC NOT jumping when no carry =====
    LDM R5, 10
    LDM R6, 3
    SUB R7, R5, R6      ; 10 - 3 = 7 (no borrow, no carry)
    JC FAIL             ; Should NOT jump

    ; ===== Forward jump test =====
    JMP SKIP_SECTION
    OUT R0              ; Should be skipped
    OUT R1              ; Should be skipped
    OUT R2              ; Should be skipped

SKIP_SECTION:
    LDM R0, 0xFF        ; Success marker - all tests passed
    OUT R0              ; Output 0xFF to indicate success
    JMP DONE

FAIL:
    LDM R0, 0xEE        ; Failure marker
    OUT R0              ; Output 0xEE to indicate failure

DONE:
    HLT
