	AREA lab643, CODE, READWRITE
	EXPORT lab7
	EXPORT get_random
	EXPORT interrupt_init
	EXPORT Enable_Timer0
	EXPORT Enable_Timer1
	EXPORT Disable_Timer0
	EXPORT Reset_Timer0
	EXPORT Disable_Timer1
	EXPORT Enable_UART0_Interrupt
	IMPORT output_string
	IMPORT output_character
	IMPORT div_and_mod
	IMPORT copy_board
	IMPORT Display_board
	IMPORT board_array
	IMPORT board_array_initial
	IMPORT Game_Over
	IMPORT display_digit
	IMPORT LEDs
	IMPORT RGB_LED
	IMPORT read_character
	IMPORT read_string
	IMPORT Level
	IMPORT Qbert_status
	IMPORT Enemy_A_status
	IMPORT Enemy_S_status
	IMPORT Enemy_C_status
	IMPORT Qbert_direction
	IMPORT Time
	IMPORT Life
	IMPORT Score

	 
prompt = "Welcome to Game Q'bert\n\r",0
message1 = "Press G to start the program\n\r", 0
message2 = "Keystrokes\n\r w - move up \n\r s - move down \n\r a - move left \n\r d - move right \n\r Press Push Button to display random character ( *, @ , X, + ) ", 0
message_quit = "press 'y' to restart the game, or press anything else to end the game", 0
	ALIGN

lab7
	STMFD sp!, {lr}
	MOV r0, #0x0c
	BL output_character
	LDR r4, =board_array
	LDR r5, =board_array_initial
	BL copy_board
	BL Display_board
	LDR r4, =prompt
	BL output_string
restart	
	BL Enable_Timer1
	
	MOV r0, #0						; Display '0' on 7 segment before game start
	BL display_digit
	MOV r0, #3						; Turn on 3 LEDs
	BL LEDs
	MOV r0, #6						; White on RGB_LED
	BL RGB_LED
check_start	
    LDR r4, =message1
    BL output_string
	BL read_character
	CMP r4, #0x66
	LDR r4, =message2
	BL output_string
	BNE check_start
	BEQ start

start
	MOV r0, #2						; Green on RGB_LED
	BL RGB_LED
	MOV r0, #1						; Display '1' on 7 segments display
	BL display_digit
	LDR r4, =Level					; To level 1
	LDR r0, [r4]
	ADD r0, r0, #1
	STR r0, [r4]
	BL Enable_UART0_Interrupt		; Reset and enable all timers and UART interrupt
	BL Reset_Timer1
	BL Enable_Timer0
	BL Enable_Timer1
loop
    LDR r4, =Game_Over
    LDR r0, [r4]					; Keep checking the flag for game over
	CMP r0, #0
	BEQ loop

end
	BL Disable_UART0_Interrupt		; Disable all timers and UART interrupt
	MOV r0, #4						; Purple on RGB_LED
	BL RGB_LED
	LDR r4, =message_quit
	BL output_string
	BL read_string
	CMP r4, #0x59
	BEQ Reset
	
	LDMFD sp!, {lr}
	BX lr

interrupt_init       

		; Push button setup		 
	LDR r0, =0xE002C000
	LDR r1, [r0]
	ORR r1, r1, #0x20000000
	BIC r1, r1, #0x10000000
	STR r1, [r0]  				; PINSEL0 bits 29:28 = 10
	
		; Classify sources as IRQ or FIQ

	LDR r2, =0x8040
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x0C]
	ORR r1, r1, r2
	ORR r1, r1, #0x8000			; External Interrupt 1
	ORR r1, r1, #0x70			; UART0[bit6], Timer1[bit5], Timer0[bit4]			
	STR r1, [r0, #0x0C]

		; Enable Interrupts

	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x10]
	ORR r1, r1, r2 
	ORR r1, r1, #0x8000			; External Interrupt 1
	ORR r1, r1, #0x70			; UART0[bit6], Timer1[bit5], Timer0[bit4]
	STR r1, [r0, #0x10]
		; External Interrupt 1 setup for edge sensitive

	LDR r0, =0xE01FC148
	LDR r1, [r0]
	ORR r1, r1, #2 				 ; EINT1 = Edge Sensitive
	STR r1, [r0]
	
		; Enable Timer0 to interrupt
	LDR r0, =0xE0004014			; Match_Control_Register for Timer0
	LDR r1, [r0]
	ORR r1, r1, #0x18			; Generate Interrupt of MR0 by bit0 to 1
	AND r1, r1, #0xDF			; Disable reset and stop function of MR0 by bit[2:1] to 00
	STR r1, [r0]
	
		; Enable Timer1 to interrupt
	LDR r0, =0xE0008014			; Match_Control_Register for Timer1
	LDR r1, [r0]
	ORR r1, r1, #0x03			; Generate Interrupt and reset function of MR0 by bit[1:0] to 11
	BIC r1, r1, #0x04			; Disable stop function of MR0 by bit2 to 0
	STR r1, [r0]
	
		; Set Timer0 Time-out period
	LDR r0, =0xE000401C			; Initially set Time-out Period of MR0 to 0.25 second - fast
	LDR r1, =0x1194000
	STR r1, [r0]
	
		; Set Timer1 Time-out period
	LDR r0, =0xE0008018
	LDR r1, =0x1194000			; Permanently set Time-out Period of MR0 to 1.00 second
	STR r1, [r0]	

		; Enable FIQ's, Disable IRQ's

	MRS r0, CPSR
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0
	BX lr             	 		

Enable_Timer0

	LDR r0, =0xE0004004			; Enable Timer0 by setting bit0 of Timer Control Register
	LDR r1, [r0]
	ORR r1, r1, #0x01			
	STR r1, [r0]
	BX lr

Disable_Timer0

	LDR r0, =0xE0004004			; Disable Timer0 by clearing bit0 of Timer Control Register
	LDR r1, [r0]
	BIC r1, r1, #0x01			
	STR r1, [r0]
	BX lr

Reset_Timer0

	LDR r0, =0xE0004004			; Reset and disable Timer0 by changing bit[1:0] of TCR to 10, and then 00
	LDR r1, [r0]
	ORR r1, r1, #0x02
	BIC r1, r1, #0x01
	STR r1, [r0]
	BIC r1, r1, #0x02	
	STR r1, [r0]
	BX lr

Reset_Timer0_Period

	LDR r0, =0xE0004018			; Initially set Time-out Period of MR0 to 0.5 second - normal
	LDR r1, =0x1194000
	STR r1, [r0]

	BX lr

Enable_Timer1

	LDR r0, =0xE0008004			; Enable Timer1 by setting bit0 of Timer Control Register
	LDR r1, [r0]
	ORR r1, r1, #0x01			
	STR r1, [r0]
	BX lr

Disable_Timer1

	LDR r0, =0xE0008004			; Disable Timer1 by clearing bit0 of Timer Control Register
	LDR r1, [r0]
	BIC r1, r1, #0x01			
	STR r1, [r0]
	BX lr

Reset_Timer1

	LDR r0, =0xE0008004			; Reset and disable Timer0 by changing bit[1:0] of TCR to 10, and then 00
	LDR r1, [r0]
	ORR r1, r1, #0x02
	BIC r1, r1, #0x01
	STR r1, [r0]
	BIC r1, r1, #0x02	
	STR r1, [r0]

	BX lr

Enable_UART0_Interrupt

	LDR r0, =0xE000C004			; Set up UART0 to Interrupt When Data is Received
	LDR r1, [r0]
	ORR r1, r1, #0x01
	STR r1, [r0]
	BX lr

Disable_UART0_Interrupt

	LDR r0, =0xE000C004			; No UART0 Interrupt Even When Data is Received
	LDR r1, [r0]
	BIC r1, r1, #0x01
	STR r1, [r0]
	BX lr

get_random

	STMFD sp!, {r0-r1, lr}
	LDR r1, =0xE0004008		       
	LDRB r0, [r1]
	MOV r1, #2
	BL div_and_mod
	ADD r2, r1, #0
	LDMFD sp!, {r0-r1, lr}
	BX lr
done	
	LDMFD sp!, {lr}
	BX lr

Reset								; Resets data and timers to the initial values and Restart the game
	LDR r5, =board_array			; Reset the Board_array
	LDR r4, =board_array_initial
	BL copy_board	
	
	LDR r4, =Qbert_status		; Reset the Bomberman_status to 0x4201 
	MOV r5, #0x4200
	ADD r5, r5, #0x01
	STR r5, [r4]
	BL get_random
	LDR r4, =Enemy_A_status			; Reset Enemy_A_status
	CMP r1, #0
	MOVEQ r0, #0x4700
	ADDEQ r0, r0, #0x05
	MOVNE R0, #0x3600
	ADDNE r0, r0, #0x06
	STR r0, [r4]
	BL get_random
	LDR r4, =Enemy_C_status			; Reset Enemy_C_status
	CMP r1, #0
	MOVEQ r0, #0x4700
	ADDEQ r0, r0, #0x05
	MOVNE R0, #0x3600
	ADDNE r0, r0, #0x06
	STR r0, [r4]
	LDR r4, =Enemy_S_status		; Reset Enemy_S_status
	MOV r0, #0
	STR r0, [r4]
	LDR r4, =Qbert_direction	; Reset qbert_direction
	MOV r0, #0
	STR r0, [r4]
	LDR r4, =Time					; Reset the Time to 120
	MOV r5, #0x78
	STR r5, [r4]
	LDR r4, =Life					; Reset the Life to 4
	MOV r5, #0x04
	STR r5, [r4]
	LDR r4, =Qbert_direction	; Reset the qbert_direction to 0 (stay)
	MOV r5, #0x00
	STR r5, [r4]
	LDR r4, =Score					; Reset the Score to 0
	STR r5, [r4]
	LDR r4, =Level					; Reset the Level to 0
	STR r5, [r4]
	LDR r4, =Game_Over				; Reset the Game_over to 0 (new game)
	STR r5, [r4]

	BL Reset_Timer0					; Reset Timer0 for new game (but not Timer1 since it will be resetted later)
	B restart

	END