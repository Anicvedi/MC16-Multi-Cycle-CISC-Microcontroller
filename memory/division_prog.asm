; ==============================================================================
; E3: 245 Processor System Design - IISc DESE
; Lab Exercise 1: Multi-Cycle MC16 Processor
; Test Program: Unsigned Division of two 16-bit numbers
; Memory Addresses:
;   [26] = Dividend  (e.g., 100 = 0x0064)
;   [27] = Divisor   (e.g., 7   = 0x0007)
;   [28] = Constant 0
;   [29] = Quotient  (Expected: 14 = 0x000E)
;   [30] = Remainder (Expected: 2  = 0x0002)
; ==============================================================================

ORG 0
START:
    LOAD R0, [26]       ; R0 = Dividend (working remainder)
    LOAD R1, [27]       ; R1 = Divisor
    LOAD R2, [28]       ; R2 = Initial Quotient = 0

DIV_LOOP:
    SUB  R3, R0, R1     ; R3 = R0 - R1. Updates Carry (Borrow): C=1 if R0 < R1
    JC   DIV_DONE       ; If R0 < R1, jump to DIV_DONE (loop termination)
    SUB  R0, R0, R1     ; R0 = R0 - R1 (Dividend = Dividend - Divisor)
    INCR R2             ; R2 = R2 + 1 (Quotient++)
    JMP  DIV_LOOP       ; Repeat loop

DIV_DONE:
    STORE [29], R2      ; Store Quotient at address 29
    STORE [30], R0      ; Store Remainder at address 30

HALT:
    JMP  HALT           ; Infinite loop terminating the program (jump to same address)

; ==============================================================================
; Data Section (Locations 26 to 31)
; ==============================================================================
ORG 26
DIVIDEND:
    DATA 100            ; 0x0064 (100 in decimal)
DIVISOR:
    DATA 7              ; 0x0007 (7 in decimal)
CONST_ZERO:
    DATA 0              ; 0x0000
QUOTIENT:
    DATA 0              ; Result placeholder (will become 14 / 0x000E)
REMAINDER:
    DATA 0              ; Result placeholder (will become 2 / 0x0002)
