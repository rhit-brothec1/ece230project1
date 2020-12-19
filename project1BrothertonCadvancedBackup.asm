	; Project 1
	; Author: Cooper Brotherton
	; Date: December 9, 2020
	; Description: Simple assembley program which toggles LED1 on MSP432P401R Launchpad
	;		with pushbuttons
	; Last-revised: December 11, 2020

	.thumb
	.global main	; export main symbol so it is recognized by other source files

	.text
SWinit                      ; function to initialize S1 and S2 for input
	PUSH    {R0, R1, R2}
	MOV     R0, #0
	LDR     R1, P1SEL0_1	; set function of P1.1 to GPIO
	LDR     R2, P1SEL0_4	; set function of P1.4 to GPIO
	STRB    R0, [R1]
	STRB    R0, [R2]
	LDR     R1, P1SEL1_1
	LDR     R2, P1SEL1_4
	STRB    R0, [R1]
	STRB    R0, [R2]
	LDR     R1, P1DIR_1		; set direction of P1.1 to input
	LDR     R2, P1DIR_4		; set direction of P1.4 to input
	STRB    R0, [R1]
	STRB    R0, [R2]
	ORR     R0, R0, #0x01	; set lsb of R0
	LDR     R1, P1OUT_1		; set internal R of P1.1 for pull-up
	LDR     R2, P1OUT_4		; set internal R of P1.4 for pull-up
	STRB    R0, [R1]
	STRB    R0, [R2]
	LDR     R1, P1REN_1		; enable internal R of P1.1
	LDR     R2, P1REN_4		; enable internal R of P1.4
	STRB    R0, [R1]
	STRB    R0, [R2]
	POP     {R0, R1, R2}
	BX      LR

led2init                    ; function to initialize RGB LED for output
	PUSH    {R0, R1, R2, R3}
	MOV		R0, #0
	LDR     R1, P2SEL0_0	; set function of pin P2.0 to GPIO
	LDR     R2, P2SEL0_1	; set function of pin P2.1 to GPIO
	LDR     R3, P2SEL0_2	; set function of pin P2.1 to GPIO
	STRB    R0, [R1]
	STRB    R0, [R2]
	STRB    R0, [R3]
	LDR     R1, P2SEL1_0
	LDR     R2, P2SEL1_1
	LDR     R3, P2SEL1_2
	STRB    R0, [R1]
	STRB    R0, [R2]
	STRB    R0, [R3]
	LDR     R1, P2DIR_0		; set direction of P2.0 to output
	LDR     R2, P2DIR_1		; set direction of P2.1 to output
	LDR     R3, P2DIR_2		; set direction of P2.2 to output
	ORR     R0, R0, #0x01
	STRB    R0, [R1]
	STRB    R0, [R2]
	STRB    R0, [R3]
	POP     {R0, R1, R2, R3}
	BX      LR

main                        ; starting point of program
	NOP
	BL      SWinit          ; call init function
	BL		led2init		; call init function

	LDR		R0, P2OUT_0		; R0 will hold address for the active LED
	LDR     R1, P1IN_1      ; R1 will hold address for S1 input
	LDR		R2, P1IN_4		; R2 will hold address for S2 input
	LDR		R4, P2OUT_0		; R4 will hold address for Red LED output
	LDR		R5, P2OUT_1		; R5 will hold address for Green LED output
	LDR		R6, P2OUT_2		; R6 will hold address for Blue LED output
	MOV		R7, #0			; R7 will hold output values for the LED
	STRB	R7, [R4]		; Turn off all LEDs
	STRB	R7, [R5]
	STRB	R7, [R6]
	B		waitS1Press

debounce					; Software debouncing via delay
	MOV		R3, #0x1000		; load R3 <- 0x1000 (~4.096ms)
delay
	SUBS	R3, #01
	BNE		delay
	BX		LR

waitS1Press					; Waiting for S1 to be pressed. Default state.
	LDRB    R3, [R1]		; Check if S1 is pressed
	TST     R3, #0x01
	BNE     waitS1Press		; keep checking until pressed
	BL 		debounce

waitS1Release				; Wait until S1 is released to do anything
	LDRB    R3, [R1]		; Check if S1 is no longer pressed
	TST     R3, #0x01
	BEQ     waitS1Release	; keep checking while pressed
	BL		debounce

resetCounter				; Toggles Red LED and sets counter to 500 ms
	EOR		R7, R7, #0x01	; toggle P2.0 value
	STRB    R7, [R0]
	MOV     R8, #0x24F7
    MOVT    R8, #0x0001     ; load R8 <- 0x000124F7 (499.995ms)
    B		LEDToggle

updateLED					; Update which LED is active. R->G->B->R
	MOV		R7, #0			; turn off LED
	STRB	R7, [R0]

	ITTE	EQ				; If green LED is active, set it to red
	CMPEQ 	R0, R6
	MOVEQ	R0, R4
	ADDNE	R0, R0, #0x4	; Else set it to next LED

	MOV		R7, #1			; turn on LED
	STRB	R7, [R0]
	BL		debounce		; debounce S2
waitS2Release
	LDRB	R3, [R2]		; Check if S2 is no longer pressed
	TST		R3, #0x01
	BEQ		waitS2Release
	BL		debounce

LEDToggle					; State for LED blinking while it waits for switch press
	LDRB    R3, [R1]		; get value of S1 input
	TST     R3, #0x01		; test if bit 0 is set (SW == 1)
	BEQ		LEDBreak		; if S1 pressed, turn off LED
	LDRB	R3, [R2]		; get value of S2 input
	TST     R3, #0x01		; test if bit 0 is set (SW == 1)
	BEQ		updateLED		; Change the active LED
	SUBS	R8, R8, #0x01
	BNE		LEDToggle
	B		resetCounter	; if counter == 0, reset counter and toggle LED

LEDBreak					; State after red LED toggle and S1 has been pressed
	MOV		R7, #0			; turn off LED
	STRB	R7, [R0]
waitS1Release2				; Wait for S1 to be released
	LDRB    R3, [R1]
	TST     R3, #0x01
	BEQ     waitS1Release2	; keep checking while pressed
	BL		debounce

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
	; S2 (P1.4)
P1SEL0_4	.word	0x42098150		; 0x42000000 + 32*0x4C0A + 4*0x4
P1SEL1_4	.word	0x42098190		; 0x42000000 + 32*0x4C0C + 4*0x4
P1DIR_4		.word	0x42098090		; 0x42000000 + 32*0x4C04 + 4*0x4
P1OUT_4		.word	0x42098050		; 0x42000000 + 32*0x4C02 + 4*0x4
P1IN_4		.word	0x42098010		; 0x42000000 + 32*0x4C00 + 4*0x4
P1REN_4		.word	0x420980D0		; 0x42000000 + 32*0x4C06 + 4*0x4
	; Red LED2 (P2.0)
P2SEL0_0	.word	0x42098160		; 0x42000000 + 32*0x4C0B + 4*0x0
P2SEL1_0	.word	0x420981A0		; 0x42000000 + 32*0x4C0D + 4*0x0
P2DIR_0		.word	0x420980A0		; 0x42000000 + 32*0x4C05 + 4*0x0
P2OUT_0		.word	0x42098060		; 0x42000000 + 32*0x4C03 + 4*0x0
	; Green LED2 (P2.1)
P2SEL0_1	.word	0x42098164		; 0x42000000 + 32*0x4C0B + 4*0x1
P2SEL1_1	.word	0x420981A4		; 0x42000000 + 32*0x4C0D + 4*0x1
P2DIR_1		.word	0x420980A4		; 0x42000000 + 32*0x4C05 + 4*0x1
P2OUT_1		.word	0x42098064		; 0x42000000 + 32*0x4C03 + 4*0x1

	; Blue LED2 (P2.2)
P2SEL0_2	.word	0x42098168		; 0x42000000 + 32*0x4C0B + 4*0x2
P2SEL1_2	.word	0x420981A8		; 0x42000000 + 32*0x4C0D + 4*0x2
P2DIR_2		.word	0x420980A8		; 0x42000000 + 32*0x4C05 + 4*0x2
P2OUT_2		.word	0x42098068		; 0x42000000 + 32*0x4C03 + 4*0x2

    .end
