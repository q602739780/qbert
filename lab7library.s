    AREA library, CODE, READWRITE
	EXPORT pin_connect_block
	EXPORT pin_direction	
	EXPORT uart_init
	EXPORT read_character
	EXPORT read_string
	EXPORT output_character
	EXPORT output_string
	EXPORT div_and_mod
	EXPORT LEDs
	EXPORT RGB_LED
	EXPORT display_digit
    EXPORT button_read
    EXPORT ascii_to_number
	EXPORT Display_Score
	EXPORT Display_Time
    
    IMPORT Score
    IMPORT Time
    
U0LSR EQU 0x14     		; UART0 Line Status Register

digits_SET    
	DCD 0x00001F80  ; 0
 	DCD 0x00000300  ; 1 
	DCD 0x00002DB0  ; 2 
	DCD 0x00002780  ; 3
	DCD 0x00003300  ; 4
	DCD 0x00003680  ; 5
	DCD 0x00003E80  ; 6
	DCD 0x00000380  ; 7
	DCD 0x00003F80  ; 8
	DCD 0x00003380  ; 9
	DCD 0x00003B80  ; A
	DCD 0x00003E00  ; b
	DCD 0x00001C80  ; C
	DCD 0x00002F00  ; d
	DCD 0x00003C80  ; E
					; Place other display values here
	DCD 0x00003880  ; F

digit_LEDs
	DCD 0x0000000F  ;0
	DCD 0x00000007  ;1
	DCD 0x0000000B  ;2
	DCD 0x00000003  ;3
	DCD 0x0000000D  ;4
	DCD 0x00000005  ;5
	DCD 0x00000009  ;6
	DCD 0x00000001  ;7
	DCD 0x0000000E  ;8
	DCD 0x00000006  ;9
	DCD 0x0000000A  ;A
	DCD 0x00000002  ;B
	DCD 0x0000000C  ;C
	DCD 0x00000004	;D
	DCD 0x00000008  ;E
	DCD 0x00000000  ;F

RGB_SET
    DCD 0x00000026		; 0 [off]
	DCD 0x00000024		; 1 [red]
	DCD 0x00000006		; 2 [green]
	DCD 0x00000022		; 3 [blue]
	DCD 0x00000020		; 4 [purple]
	DCD 0x00000004		; 5 [yellow]
	DCD 0x00000000		; 6 [white]
	
    ALIGN


pin_connect_block
	STMFD sp!, {r0-r2}
	
    LDR r0, =0xF0003FF0		; Used to clear bits
	LDR r1, =0xE002C000		; Address of PINSEL0
	LDR r2, [r1]
	AND r2, r2, r0			; clear bits
	ORR r2, r2, #5
	STR r2, [r1]			; Store back to PINSEL0
	
	LDR r0, =0xFFFFF333		; Used to clear bits
	LDR r2, [r1, #0x04]		; load from Address of PINSEL1
	AND r2, r2, r0			; clear bits
	ORR r2, r2, #0
	STR r2, [r1, #0x04]		; Store back to PINSEL1
	
	LDR r0, =0xFFFFFFF7		; Used to clear bits
	LDR r2, [r1, #0x14]		; load from Address of PINSEL2
	AND r2, r2, r0			; clear bit
	ORR r2, r2, #0
	STR r2, [r1, #0x14]		; Store back to PINSEL2

    LDMFD sp!, {r0-r2}
	BX lr

pin_direction
	STMFD sp!, {r0-r3}
    
	LDR r0, =0xFFD9C073		; Used to clear bits
	LDR r1, =0x00263F8C		; Used to set bits
	LDR r2, =0xE0028008		; Address of IO0DIR
	LDR r3, [r2]
	AND r3, r3, r0			; clear bits
	ORR r3, r3, r1			; set bits
	STR r3, [r2]			; store back to IO0DIR
	
	LDR r0, =0xFF00FFFF		; Used to clear bits
	LDR r3, [r2, #0x10]		; load from Address of IO1DIR
	AND r3, r3, r0			; clear bits
	ORR r3, r3, #0x000F0000	; set bits
	STR r3, [r2, #0x10]		; store back to IO1DIR
    
	LDMFD sp!, {r0-r3}
	BX lr 
    
uart_init
    STMFD sp!, {r1-r2}
    
	LDR r2, =0xE000C000 	; Load Address into r2
	MOV r1, #131 			; Copy 131 to r1
	STRB r1, [r2, #0xC] 	; Load byte from r2 and offseting by C	
	MOV r1, #120 			; Copy 120 to r1
	STRB r1, [r2] 			; Load byte from r2 no offsets
	MOV r1, #0 				; Copy 0 to r1
	STRB r1, [r2, #4] 		; Load byte from r2 and offseting by 4
	MOV r1, #3 				; Copy 3 to r1
	STRB r1, [r2, #0xC] 	; Load byte from r2 and offseting by C	
    
    LDMFD sp!, {r1-r2}
	BX lr ;exit

read_character
    	; One return value is passed to r0 carrying 
		; the character entered by user
	STMFD sp!, {r1-r2, lr}

read_char
    LDR r1, =0xE000C014 	; load register
	LDRB r2, [r1] 			; Loading byte from r1 to r2
	AND r2, r2, #1 		
	CMP r2, #0 				; Compare the RDR flag to 0
	BEQ read_char	 		; If RDR = 0 then START again
	LDR r1, =0xE000C000		; If RDR = 1, load ing address of receive buffer
	LDRB r0, [r1] 			; loading to r0	

	LDMFD sp!, {r1-r2, lr}
	BX lr

read_string
		; One argument is needed to be passed in r4 carrying 
		; the base address where the string will be stored to
	STMFD sp!, {lr, r0-r2, r4}		; store the values of lr and r0 into stack

   	MOV r4, r0
loop
	BL read_character		; read a character, result is in r0
	CMP r0, #0x0D			; check whether the character is a ENTER key
	BEQ cont				; if yes, go to "cont"
	STRB r0, [r4], #1		; else, store it to memory
	B loop
cont
	MOV r0, #0x00			; change ENTER to NULL
	STRB r0, [r4], #1		; stroe NULL to memory
	
    LDMFD sp!, {lr, r0-r2, r4}
	BX lr


output_character
    	; One argument needed to be passed in r0 carrying 
		; the character that will be displayed in UART
	STMFD sp!, {r1-r2, lr}
	
output_char	

    LDR r1, =0xE000C000		; Load base address
	LDRB r2, [r1, #U0LSR]	; load UOLSR
	AND r2, r2, #0x20	    ; empty all bits except THRE (bit #6 of U0LSR)
	CMP r2, #0				; check if THRE is 1 (1 isempty, 0 is transmitting)
	BEQ output_char			; If 1 then loop
	STRB r0, [r1]			; else, output the value in r0 and display to PuTTY

	LDMFD sp!, {r1-r2, lr}
	BX lr					; exit subroutine


output_string
		; One argument is needed to be passed in r4 carrying 
		; the base address where the string will be loaded from
	STMFD sp!,{lr, r0-r2, r4}		; Store register lr on stack
	;MOV r4, r0
	LDRB r0, [r4] 			; loading byte from r4 to r0
loop_s
	CMP r0, #0 				; check if byte is null
	BEQ then
	BL output_character 	; if not equal go to sub routine output_character
	LDRB r0, [r4, #1] !		; check next char
	B loop_s 				; if not equal loop through again until null
then
	LDMFD sp!, {lr, r0-r2, r4}
	BX lr 		  	 		; exit subroutine	


div_and_mod
    STMFD sp!, {r2-r6, r14}
    ; Your code for the signed division/mod routine goes here.
    ; The dividend is passed in r0 and the divisor in r1.
    ; The quotient is returned in r0 and the remainder in r1.
    mov r2, #15             ; initial counter=15.
    mov r3, #0              ; initial quotient=0.
    mov r4, #0              ;
    mov r5, #0              ;
    cmp r0, #0              ; check if dividend is positive.
    bgt ckdivisor
    mvn r0, r0              ; replace dividend with 2's if r0<0
    add r0, r0, #1          ;
    mov r4, #1              ; mark if dividend is negative

ckdivisor
    mov r6, r0              ; initial reminder=dividend;
    cmp r1, #0              ; check if divisor is negative
    bgt shift
    mvn r1, r1              ; replace divisor with 2's if it's <0
    add r1, r1, #1          ;
    mov r5, #1              ; mark if divisor is negative

shift
    mov r1, r1, lsl #15     ; left shift divisor 15 digit

sub
    sub r6, r6, r1          ; remainder= remainder - divisor
    cmp r6, #0              ; check if remainder is negative
    blt re                  ;
    mov r3, r3, lsl #1      ; quotient shift left 1 place and get 1
    add r3, r3, #1          ; if reminder is positive

count
    mov r1, r1, lsr #1      ;
    sub r2, r2, #1          ;
    cmp r2, #0              ;
    bge sub
    cmp r4, r5              ;
    beq result
    mvn r3,r3               ;
    add r3, r3, #1          ;

result
    mov r0, r3              ;
    mov r1, r6              ;
    B exit
    
re
    add r6, r6, r1;
    mov r3, r3, lsl #1      ;
    b count
    
exit
    LDMFD sp!, {r2-r6, r14}
    BX lr                   ; Return to the C program

LEDs
    	; One argument is needed to be passed in r0 carrying 
		; the number (0-15) which will be displayed on LEDs
	STMFD sp!, {r0, r2-r5}
    
	LDR r2, =digit_LEDs		; Load byte of address in r2 with offset (r0*4) into r2
    LDRB r2, [r2, r0, LSL #2]		
	LDR r3, =0xE0028014		    ; Load address of GPIO Port1_set
	LDR r4, =0xE002801C		    ; Load address of GPIO Port1_clear
	LDRB r5, [r3, #2]		    ; Load third byte from Port1_set
	AND r5, r5, #0xF0		    ; Change bits 16 to 19 to the one in lookup table
	ORR r5, r5, r2
	STRB r5, [r3, #2]		    ; Store it back to Port1_set
	
	LDRB r5, [r4, #2]		    ; Load third byte from Port1_clear
	MVN r2, r2				    ; Get the 1's complement of r2 (lower 4 bits only)
	AND r2, r2, #0x0F
	AND r5, r5, #0xF0		    ; Change bits 16 to 19 to correct value
	ORR r5, r5, r2
	STRB r5, [r4, #2]		    ; Store it back to Port1_clear
	
    LDMFD sp!, {r0, r2-r5}
	BX lr
	
	
RGB_LED
		; One argument is needed to be passed in r0 carrying 
		; the number (0-6) which is representing the color to show on RGB_LED
	STMFD sp!, {r0, r2-r5}			
	
    LDR r2, =RGB_SET	    ; Load byte of address in r2 with offset (r0*4) into r2
	LDRB r2, [r2, r0, LSL #2]
	LDR r3, =0xE0028004		; Load address of GPIO Port0_set
	LDR r4, =0xE002800C		; Load address of GPIO Port0_clear
	LDRB r5, [r3, #2]		; Load third byte from Port0_set
	AND r5, r5, #0xD9		; Change bits 17, 18, 21 to the one in lookup table
	ORR r5, r5, r2
	STRB r5, [r3, #2]		; Store it back to Port0_set
	
	LDRB r5, [r4, #2]		; Load third byte from Port0_clear
	MVN r2, r2				; Get the 1's complement of r2 (bits 17, 18, 21 only)
	AND r2, r2, #0x26
	AND r5, r5, #0xD9		; Change bits 17, 18, 21 to correct value
	ORR r5, r2, r5
	STRB r5, [r4, #2]		; Store it back to Port0_clear
	
    LDMFD sp!, {r0, r2-r5}
	BX lr
    
display_digit
              		; One argument is needed to be passed in r0 carrying 
		            ; the number (0-15) which will be displayed on 7-segments display
	STMFD sp!,{r0, r2-r6}
	
	LDR r5, =0xC07F				   ;used to clean the pin that unecessary for display
	LDR r1,=0xE0028000			   ;base address
	LDR r2, =digits_SET			   ;look up table
	 MOV r0, r0, LSL #2			   
	LDRH r2, [r2,r0]			   ;load half-word from address r2 to register r2
	LDR r3, =0xE0028004			   ;initialize r3 to set
	LDR r4, =0xE002800C			   ; set r4 to clear
	LDRH r6, [r3]				   ;set the target to light up 
	AND r6, r6, r5
	ORR r6, r6, r2
	STRH r6, [r3]					;light up  target
	MVN r2, r2						;the pin we dont wanna light up 
	AND r2, r2, #0x3F80			   ;find the pin which is not target and turn them off
	LDRH r6, [r4]
	AND r6, r6, r5
	ORR r6, r6, r2
	STRH r6, [r4]				   ;turn off the pin we dont use

	LDMFD sp!,{r0, r2-r6}
	BX lr;

button_read
        		; One return value is passed to r0 carrying 
		        ; the number (0-15) which read from buttons
    STMFD sp!, {r2-r6}

	LDR r2,= 0xE0028010	          ;initialize r2 to port1_pin_value
	LDRH r2, [r2, #2]		      ;load half word from address r2 to register r2 by offset 2
	MOV r3, #0					  ;counter
	MOV r6, #0					  ;store decimal number
button_loop
    ADD r4, r3, #4				  ;the digit we need to find everytime
	MOV r5, r2, LSR r4			  ;increase the digit that we are finding, for example, 1000's first, then 100's
	AND r5, r5, #1				  ;keep the bit we need to use if it is 1
	MVN r5, r5					  ;used to set the push button as 1 instead of 0
	AND r5, r5, #1
    MOV r6, r6, LSL #1
	ADD r6, r6, r5
	CMP r3, #2					  ;check if it runs for 4 times for 4 button
	BGT b_quit				      ;increasement of counter
	ADD r3, r3, #1
	B button_loop
b_quit
    MOV r0, r6					  ; return value

	LDMFD sp!, {r2-r6}
	BX lr

ascii_to_number
    STMFD sp!, {r1-r6}
	    ; value passed in r0
	    ; returned to r0
    MOV r4, #0              ; store user data as number
    MOV r5, #10             ; for multiplication
    MOV r7, #0              ; flag for negative
check_num
	LDRB r1, [r0]			; load value of number from address of number
	CMP r1, #0x0			; check if null
	BNE contne				; if not null check if character is number
	B done

contne
    CMP r1, #0x2D           ; check if '-'
    ADDEQ r7, r7, #1        ; change flag = 1
	AND r2, r1, #0xF0		; check if character is number
	CMP r2, #0x30 	        
	BEQ convert_ascii	  	; if yes go to convert_ascii
	ADD r1, r1, #9
	CMP r1, #0x49           ; check if it is A-F
	BGT convert_letter
	ADD r0, r0, #1			; else increment the address and load next character
	B check_num

convert_ascii
	AND r1, r1, #0x0F		; convert character from ascii to real number
	MOV r6, r4          	; combine the new number to all previous number in r4 by r4 := r4 * 10 + r1
	MUL r4, r6, r5			
	ADD r4, r4, r1
	ADD r0, r0, #1
	B check_num
convert_letter               ;convert it if it A-F
    CMP r1, #0X56
	BLT convert_ascii
	ADD r0, r0, #1
	B check_num
	
done
    MOV r0, r4
	LDMFD sp!, {r1-r6}
	BX lr
	
Display_Score
    ; No argument needed
    STMFD sp!, {lr}
    
    LDR r4, =Score
    LDR r0, [r4]
    
    MOV r1, #1000           ; Calculate Score/1000
    BL div_and_mod
    ORR r0, r0, #0x30       ; Convert the quotient to a string
    STMFD sp!, {r1}
    BL output_character
    LDMFD sp!, {r1}
    
    MOV r0, r1              ; Calculate (Score%1000)/100
    
    MOV r1, #100
    BL div_and_mod
    ORR r0, r0, #0x30       ; Convert quotient to string
    STMFD sp!, {r1}
    BL output_character
    LDMFD sp!, {r1}
    
    MOV r0, r1              ; Calculate (Calculate (Score%1000)/100)/10
    
    MOV r1, #10
    BL div_and_mod          ; Convert quotient to string
    ORR r0, r0, #0x30
    STMFD sp!, {r1}
    BL output_character
    LDMFD sp!, {r1}
    
    ORR r0, r1, #0x30       ; Convert the remainder into string
    BL output_character
    
    LDMFD sp!, {lr}
    BX lr

Display_Time
    ; No argument needed
    STMFD sp!, {lr}
    
    LDR r4, =Time
    LDR r0, [r4]
    MOV r1, #100            ; Calculate Time/100
    BL div_and_mod
    ORR r0, r0, #0x30       ; Convert Quotient to string
    STMFD sp!, {r1}
    BL output_character
    LDMFD sp!, {r1}
    
    MOV r0, r1              ; Calculate (Time%100)/10
    
    MOV r1, #10
    BL div_and_mod
    ORR r0, r0, #0x30       ; Convert Quotient to string
    STMFD sp!, {r1}
    BL output_character
    LDMFD sp!, {r1}
    
    ORR r0, r1, #0x30       ; Convert remainder into string
    BL output_character
    
    LDMFD sp!, {lr}
    BX lr
    
	END