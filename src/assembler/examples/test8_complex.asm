; ============================================================
; Example Assembly Program for RISC Processor
; Demonstrates .ORG directive and various instructions
; ============================================================

; Reset vector - PC starts from address stored at location 0
.ORG 0x0000
.DW MAIN                ; Reset vector

; Interrupt vector - PC loads from this location on interrupt
.ORG 0x0002
.DW ISR                 ; Interrupt vector

; ============================================================
; Main Program - Starts at address 0x0100
; ============================================================
.ORG 0x0100
MAIN:
    ; Initialize registers
    LDM R0, 0       ; R0 = 0 (counter)
    LDM R1, 10      ; R1 = 10 (limit)
    LDM R2, 1       ; R2 = 1 (increment)
    SETC            ; Set carry flag
    
LOOP:
    ; Output current counter value
    OUT R0          ; Output R0 to port
    
    ; Increment counter
    ADD R0, R0, R2  ; R0 = R0 + R2
    
    ; Check if counter reached limit
    SUB R3, R1, R0  ; R3 = R1 - R0
    JZ END          ; If zero, exit loop
    
    ; Continue loop
    JMP LOOP

END:
    ; Final operations
    LDM R4, 0xFF    ; Load final value
    OUT R4          ; Output it
    HLT             ; Halt processor

; ============================================================
; Subroutine Example - Starts at address 0x0200
; ============================================================
.ORG 0x0200
MULTIPLY:
    ; Multiply R1 by R2, store in R3
    ; Simple multiplication by repeated addition
    PUSH R0         ; Save R0
    LDM R0, 0       ; R0 = 0 (accumulator)
    LDM R3, 0       ; R3 = 0 (result)
    
MULT_LOOP:
    ADD R3, R3, R1  ; R3 = R3 + R1
    INC R0          ; R0++
    SUB R4, R2, R0  ; R4 = R2 - R0
    JZ MULT_DONE    ; If R0 == R2, done
    JMP MULT_LOOP
    
MULT_DONE:
    POP R0          ; Restore R0
    RET             ; Return

; ============================================================
; Interrupt Service Routine - Starts at address 0x0300
; ============================================================
.ORG 0x0300
ISR:
    ; Save context
    PUSH R0
    PUSH R1
    
    ; Handle interrupt
    IN R0           ; Read from input port
    NOT R0          ; Invert bits
    OUT R0          ; Output inverted value
    
    ; Restore context
    POP R1
    POP R0
    
    RTI             ; Return from interrupt

; ============================================================
; Data Section - Starts at address 0x0400
; ============================================================
.ORG 0x0400
DATA_ARRAY:
    ; Store some data values using LDM and STD
    LDM R5, 100
    STD R5, 0(R7)   ; Store at base address
    
    LDM R5, 200
    STD R5, 1(R7)   ; Store at base + 1
    
    LDM R5, 300
    STD R5, 2(R7)   ; Store at base + 2

; ============================================================
; Memory Operations Example - Starts at address 0x0500
; ============================================================
.ORG 0x0500
MEMORY_TEST:
    ; Test LDD and STD instructions
    LDM R6, 0x400   ; Base address
    
    LDD R0, 0(R6)   ; Load from base
    LDD R1, 1(R6)   ; Load from base + 1
    LDD R2, 2(R6)   ; Load from base + 2
    
    ; Add values
    ADD R3, R0, R1  ; R3 = R0 + R1
    ADD R3, R3, R2  ; R3 = R3 + R2
    
    ; Store result
    STD R3, 3(R6)   ; Store at base + 3
    
    RET

; ============================================================
; Stack Operations Example
; ============================================================
.ORG 0x0600
STACK_TEST:
    ; Push multiple values
    LDM R0, 10
    LDM R1, 20
    LDM R2, 30
    
    PUSH R0
    PUSH R1
    PUSH R2
    
    ; Pop in reverse order
    POP R5
    POP R4
    POP R3
    
    ; R3=10, R4=20, R5=30
    RET

; ============================================================
; Conditional Branch Example
; ============================================================
.ORG 0x0700
BRANCH_TEST:
    LDM R0, 5
    LDM R1, 5
    
    ; Test equality
    SUB R2, R0, R1  ; R2 = R0 - R1
    JZ EQUAL        ; Branch if equal
    JMP NOT_EQUAL
    
EQUAL:
    LDM R3, 1       ; Set flag = 1
    JMP BRANCH_END
    
NOT_EQUAL:
    LDM R3, 0       ; Set flag = 0
    
BRANCH_END:
    RET

; ============================================================
; Advanced Example: Fibonacci Sequence
; ============================================================
.ORG 0x0800
FIBONACCI:
    ; Calculate first N fibonacci numbers
    ; R0 = N (count)
    ; R1 = current fibonacci number
    ; R2 = previous fibonacci number
    
    LDM R0, 10      ; Calculate 10 fibonacci numbers
    LDM R1, 1       ; fib(1) = 1
    LDM R2, 0       ; fib(0) = 0
    LDM R3, 1       ; counter
    
FIB_LOOP:
    OUT R1          ; Output current fibonacci
    
    ; Calculate next fibonacci
    ADD R4, R1, R2  ; R4 = R1 + R2 (next fib)
    MOV R2, R1      ; Move current to previous
    MOV R1, R4      ; Move next to current
    
    ; Increment counter and check
    INC R3
    SUB R5, R0, R3  ; R5 = N - counter
    JZ FIB_END
    JMP FIB_LOOP
    
FIB_END:
    RET

; ============================================================
; End of Program
; ============================================================