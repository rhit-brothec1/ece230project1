	; Project 1
	; Author: Cooper Brotherton
	; Date: December 9, 2020
	; Description: Assembley program that lets a pushbutton toggle the red LED2 to blinking or off
	; Last-revised: December 11, 2020

	.thumb
	.global main	; export main symbol so it is recognized by other source files

	.text
SWinit                      ; function to initialize S1 for input
	PUSH    {R0, R1}
	MOV     R0, #0
	LDR     R1, P1SEL0_1	; set function of P1.1 to GPIO
	STRB    R0, [R1]
	LDR     R1, P1SEL1_1
	STRB    R0, [R1]
	LDR     R1, P1DIR_1		; set direction of P1.1 to input
	STRB    R0, [R1]
	ORR     R0, R0, #0x01	; set lsb of R0
	LDR     R1, P1OUT_1		; set internal R of P1.1 for pull-up
	STRB    R0, [R1]
	LDR     R1, P1REN_1		; enable internal R of P1.1
	STRB    R0, [R1]
	POP     {R0, R1}
	BX      LR

led2init                    ; function to initialize Red LED2 for output
	PUSH    {R0, R1}
	MOV		R0, #0
	LDR     R1, P2SEL0_0	; set function of pin P2.0 to GPIO
	STRB    R0, [R1]
	LDR     R1, P2SEL1_0
	STRB    R0, [R1]
	LDR     R1, P2DIR_0		; set direction of P2.0 to output
	ORR     R0, R0, #0x01
	STRB    R0, [R1]
	POP     {R0, R1}
	BX      LR

main                        ; starting point of program
	NOP
	BL      SWinit          ; call init function
	BL		led2init		; call init function

	LDR     R1, P1IN_1      ; R1 will hold address for S1 input
	LDR		R4, P2OUT_0		; R4 will hold address for Red LED output
	MOV		R7, #0			; R7 will hold output values for the LED
	STRB	R7, [R4]		; Turn off LED
	B		waitS1Press		; Start program

waitS1Press					; Waiting for S1 to be pressed. Default state.
	LDRB    R3, [R1]		; Check if S1 is pressed
	TST     R3, #0x01
	BNE     waitS1Press		; keep checking until pressed
	MOV     R3, #0x01000	; load register with initial value for delay
	B		delayS1Press	; Debounce through delay
delayS1Press				; delay by decrementing register until it is 0
	SUBS    R3, #0x01
	BNE     delayS1Press
	B		waitS1Release

waitS1Release				; Wait until S1 is released to do anything
	LDRB    R3, [R1]		; Check if S1 is no longer pressed
	TST     R3, #0x01
	BEQ     waitS1Release	; keep checking while pressed
	MOV     R3, #0x01000	; load register with initial value for delay
	B		delayS1Release	; Bebounce through delay
delayS1Release				; delay by decrementing register until it is 0
	SUBS    R3, #0x01
	BNE     delayS1Release

resetRedCounter				; Toggles Red LED and sets counter to 500 ms
	EOR		R7, R7, #0x01	; toggle P2.0 value
	STRB    R7, [R4]
	MOV     R8, #0x49EE
    MOVT    R8, #0x0002     ; load R8 <- 0x0002_49EE (499.995ms)

redLEDToggle				; State for red LED blinking while it waits for S1 press
	LDRB    R3, [R1]		; get value of S1 input
	TST     R3, #0x01		; test if bit 0 is set (SW == 1)
	BEQ		redLEDBreak		; if S1 pressed, turn off LED
	SUBS	R8, R8, #0x01
	BNE		redLEDToggle
	B		resetRedCounter	; if counter == 0, reset counter and toggle LED

redLEDBreak					; State after red LED toggle and S1 has been pressed
	MOV		R7, #0			; turn off LED
	STRB	R7, [R4]
waitS1Release2				; Wait for S1 to be released
	LDRB    R3, [R1]
	TST     R3, #0x01
	BEQ     waitS1Release2	; keep checking while pressed
	MOV     R3, #0x01000	; Debounce through delay
	B		delayS1Release2
delayS1Release2				; delay by decrementing register until it is 0
	SUBS    R3, #0x01
	BNE     delayS1Release2

	B		waitS1Press		; back to initial state

	.align 4

    ; store addresses for peripheral registers and link to descriptive symbol
    ; offset addresses obtained from Table 6-21 of MSP432P401R Data Sheet
    ; S1 (P1.1)
P1SEL0_1	.word	0x42098144		; 0x42000000 + 32*0x4C0A + 4*0x1
P1SEL1_1	.word	0x42098184		; 0x42000000 + 32*0x4C0C + 4*0x1
P1DIR_1		.word	0x42098084		; 0x42000000 + 32*0x4C04 + 4*0x1
P1OUT_1		.word	0x42098044		; 0x42000000 + 32*0x4C02 + 4*0x1
P1IN_1		.word	0x42098004		; 0x42000000 + 32*0x4C00 + 4*0x1
P1REN_1		.word	0x420980C4		; 0x42000000 + 32*0x4C06 + 4*0x1

	; Red LED2 (P2.0)
P2SEL0_0	.word	0x42098160		; 0x42000000 + 32*0x4C0B + 4*0x0
P2SEL1_0	.word	0x420981A0		; 0x42000000 + 32*0x4C0D + 4*0x0
P2DIR_0		.word	0x420980A0		; 0x42000000 + 32*0x4C05 + 4*0x0
P2OUT_0		.word	0x42098060		; 0x42000000 + 32*0x4C03 + 4*0x0

    .end
