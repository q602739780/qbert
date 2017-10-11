    AREA handler, CODE, READWRITE
    EXPORT FIQ_Handler
    EXPORT Qbert_status
    EXPORT Enemy_A_status
    EXPORT Enemy_C_status
    EXPORT Enemy_S_status
    EXPORT Qbert_direction
    EXPORT Snake_direction
    EXPORT Score
    EXPORT Time
    EXPORT Level
    EXPORT Life
    EXPORT Pause
    EXPORT Game_Over
    
	IMPORT Display_board
	IMPORT get_random
	IMPORT board_array
    IMPORT read_character
    IMPORT read_string
    IMPORT output_character
    IMPORT output_string
    IMPORT display_digit
    IMPORT LEDs
    IMPORT RGB_LED
    ;IMPORT Random_Generator
    
Qbert_status        DCD 0x00004201  ; Alive [Bit 31 == 0], position : XY
Enemy_A_status      DCD 0x00003603  ; Alive [Bit 31 == 0], position : XY
Enemy_C_status      DCD 0x00004706  ; Alive [Bit 31 == 0], position : XY
Enemy_S_status      DCD 0xF0000000  ; Alive [Bit 31 == 0], position : XY
Qbert_direction     DCD 0x00000000  ; 0 = stop, 1 = up, 2 = right, 3 = left, 4 = down
Snake_direction
Score               DCD 0x00000000  ; Initial score = 0
Time                DCD 0x00000078  ; Time : 120
Level               DCD 0x00000000  ; Level = 0
Life                DCD 0x00000004  ; Life = 4
Pause               DCD 0x00000000  ; 0 = Playing 1 = Unpaused
Game_Over           DCD 0x00000000  ; 0 = Playing 1 = Game_Over
Counter				DCD 0x00000000	; Counter for enemy spawn
FIQ_Handler
    STMFD sp!, {r0-r7, lr}          ; Handler_Stack_Push_1
    
    ; UART0 Interrupt
    
    LDR r0, =0xE000C008             ; Check if UART0 interrupt
    LDR r1, [r0]
    TST r1, #1
    BEQ UART0_Handler               ; Taken if bit 0 == 0
    
    ; Timer0 Interrupt (for movement)
    
    LDR r0, =0xE0004000             ; Check if Timer0 Interrupt
    LDR r1, [r0]
    TST r1, #2
    BNE Timer0_Handler              ; If bit0 == 1 Timer0 taken
    
    ; Timer1 Interrupt (for time)
    
    LDR r0, =0xE0008000             ; Check if Timer1 Interrupt
    LDR r1, [r0]                    
    TST r1, #1
    BNE Timer1_Handler              ;If bit2 === 1 Timer1 taken
    
    ; EINT1 Interrupt
    
    LDR r0, =0xE01FC140             ; Check if EINT1 Interrupt
    LDR r1, [r0]                
    TST r1, #2
    BNE EINT1_Handler               ; Branch is taken if bit1 == 1
    
FIQ_Exit
    LDMFD sp!, {r0-r7, lr}          ; Handler_Stack_Pop_1
    SUBS pc, lr, #4                  ; Return to original program
    
UART0_Handler
    STMFD sp!, {r0-r6, lr}          ; Handler_Stack_Push_2
    
    BL read_character
    
    ; Pause/Game_over condition
    
    LDR r4, =Pause                  ; Exit if Paused or game_over
    LDR r1, [r4]
    CMP r1, #1
    LDRNE r4, =Game_Over
    LDRNE r1, [r4]
    CMPNE r1, #1
    BEQ UART0_Exit
    
    
    LDR r4, =Qbert_direction        ; Load Qbert_direction
    LDR r1, [r4]
    CMP r1, #0
    BNE UART0_Exit                  ; Exit if no movement
    
    CMP r0, #0x77                   ; Key_W - Up
    BEQ Key_W
    
    CMP r0, #0x64                   ; Key_D - right
    BEQ Key_D
    
    CMP r0, #0x73                   ; Key_S - Down
    BEQ Key_S
    
    CMP r0, #0x61                   ; Key_A - Left
    BEQ Key_A
    
    B UART0_Exit
    
Key_W
    MOV r1, #1                      ; Set direction to up
    STR r1, [r4]                    ; Store in Qbert_direction
    B UART0_Exit
    
Key_D
    MOV r1, #2                      ; Set direction to right
    STR r1, [r4]                    ; Store in Qbert_direction
    B UART0_Exit
    
Key_S
    MOV r1, #3                      ; Set direction to down
    STR r1, [r4]                    ; Store in QBert_direction
    B UART0_Exit
    
Key_A
    MOV r1, #4                      ; Set direction to left
    STR r1, [r4]                    ; Store in QBert_direction
    B UART0_Exit
    
UART0_Exit
    LDMFD sp!, {r0-r6, lr}          ; Handler_Stack_Pop_2
    B FIQ_Exit
    
Timer0_Handler
      STMFD sp!, {r0-r7, lr}          ; Timer0_Handler_Push_3
    ; Movement of Enemy_A (yi)
	  
	  LDR r4, =board_array     
      LDR r5,= Enemy_A_status
      LDRB r7, [r5], #1                ; r7 = Y
      LDRB r6, [r5]                    ; r6 = X     
	  CMP r6, #0x36
	  LDREQ r8, =Counter
	  LDRBEQ r1,[r8]
	  ADDEQ r1, r1, #1				; Compare counter for spawn of enemy at 2 sec 
	  BNE move_enemy				; If not at starting spawn, move the enemy	
	  CMP r1, #2 					; If 2 seconds
	  STRBEQ r1, [r8]
	  BEQ spawn_enemy
	  BGT move_enemy
	  STRB r1, [r8]
	  B Timer0_Exit

spawn_enemy
	  MOV r2, r7   					; Initialize y
	  MOV r3, r6					; Initialize X
	  LDR r5, =board_array            ;check if there is 0x08(*) or 0x0A(nothing show but was star), if so there is a stair 
      SUB r4, r2, #0
	  MOV r1, #92
      MUL r0, r4, r1                  
	  ADD r0, r0, r3
      MOV r1, #0x04
      STRB r1, [r5, r0] 
	  B Timer0_Exit

move_enemy
	  BL get_random
	  CMP r2, #0
      BEQ A_down

A_right                              
      ADD r2, r7, #2                 ;if move to right, y+2,x+12
      ADD r3, r6, #-12
      B check_bound_O
A_down
      ADD r2, r7, #4                  ;if move down , y+4, x-1
      ADD r3, r6, #-1

check_bound_O
      LDR r5, =board_array            ;check if there is 0x08(*) or 0x0A(nothing show but was star), if so there is a stair 
      SUB r4, r2, #0
	  MOV r1, #92
      MUL r0, r4, r1                  
	  ADD r0, r0, r3
    ;  ADD r0, r0, #1
	  LDRB r1, [r5, r0]
      CMP r1, #0x03
      ;BEQ update_lives               ;check if there is Q_bert in the stairs
      
      ADD r0, r0, #8
	  LDRB r1, [r5, r0]               ; load position from baord_array
      CMP r1, #0x08
      BEQ board_update_A
      CMP r1,  #0x0A
      BEQ board_update_A
      MOV r2, #02
      MOV r3, #27
      b gone

board_update_A
      MOV r1, #0x04
      STRB r1, [r5, r0]                ;save position of enemy_O
gone
                               ;change the number of the former position to 0x00 to print space or delete enemy o when it disappear
      SUB r0, r7, #0
	  MOV r1, #92
      MUL r0, r7, r1                  
      ADD r0, r0, r6
	  MOV r1, #0x00
      STRB r1, [r5, r0]
      LSL r2, r2, #8
      ADD r2, r2, r3
      LDR r5, =Enemy_A_status           ;store current position to enemy_a_status
      STR r2, [r5]
	  B Timer0_Exit
    ; Movement of Enemy_B (mohsiur)
    ; Movement of Enemy_Snake (mohsiur)
	  BL get_random			 ;used for random move snakes vertical or horizon
	  LDR r5,= Qbert_status
	  LDRB r4, [r5], #1		 ;y	of QBERT
	  LDRB r3, [r5]			 ;x	of QBERT
	  LDR r5,= Enemy_S_status
	  LDRB r7, [r5], #1		  ; y of Snake
	  LDRB r6, [r5] 		  ; x of snake
	  CMP r2, #0
	  BEQ S_horizon
	  CMP r4, r7			   ;move snake vertical	 ,up or down 
	  BGT s_down
s_up
      SUB r2, r4, #4                  ;if move down , y-4, x+1
      ADD r3, r3, #1
      B check_bound_Q      
s_down

S_horizon					   ; move snake horizon , left or right
	  CMP r3, r6
	  BGT s_right
s_left

s_right
      
    ; Movement of QBert (yi)
      LDR r5,= Qbert_status
      LDRB r7, [r5], #1                    ;Y
      LDRB r6, [r5]                    ;x
      LDR r5, =Qbert_direction             ;find direction 
      LDR r0,[r5]                           ; change q_bert direction to stop after it moves
      MOV r1, #0
      STR r0, [r5]
      CMP r0, #1
      BEQ Q_up
      CMP r0, #2
      BEQ Q_right
      CMP r0, #3
      BEQ Q_left
      CMP r0, #4
      BEQ Q_down
Q_up
      SUB r2, r7, #4                  ;if move down , y-4, x+1
      ADD r3, r6, #1
      B check_bound_Q
Q_right
      ADD r2, r7, #2                 ;if move to right, y-2,x-12
      SUB r3, r6, #12
      B check_bound_Q
Q_left
      SUB r2, r7, #2                 ;if move to right, y+2,x+12
      ADD r3, r6, #12
      B check_bound_Q
Q_down
      ADD r2, r7, #4                  ;if move down , y+4, x-1
      SUB r3, r6, #1
      B check_bound_Q
check_bound_Q
      LDR r5, =board_array            
      SUB r4, r2, #0
	  MOV r1, #92
      MUL r0, r4, r1                  
      ADD r0, r0, r3
      ADD r0, r0, #1
      LDRB r1, [r5, r0]               ; load new position from baord_array
      CMP r1, #0x04                   ;check if there is enemy o on the stairs
      ;BEQ  Updating_lives
      ADD r0, r0, #3                  ;check if there is 0x08(*) or 0x0A(nothing show but was star), if so there is a stair    
      LDRB r1, [r5, r0]               ; load position from baord_array
      CMP r1, #0x04
      BEQ update_score
      CMP r1, #0x0A
      BEQ board_update_Q 

update_score
      MOV r1, #0x0A
      STRB r1, [r5, r0]
      LDR r5, = Score
      LDR r1, [r5]
      CMP r1, #210
;      BEQ Updating_level
      ADD r1, r1, #10
      STR r1, [r5]

board_update_Q
      LDR r5, = board_array
      SUB r0, r0, #4
      MOV r1, #0x03
      STR r1, [r5, r0]
                        ;change the number of the former position to 0x00 to print space
      SUB r0, r6, #0
	  MOV r1, #92
      MUL r0, r6, r1                  
      ADD r0, r0, r7
	  MOV r1, #0x00 
      STRB r1, [r5, r0]
      LSL r2, r2, #8
      ADD r2, r2, r3
      LDR r5,  Qbert_status           ;store current position to enemy_a_status
      STR r2, [r5]      
    ; Updating Board if jumped on empty spot (yi/mohsiur)
    ; Updating Score (yi/mohsiur)
    ; Check if QBert hits enemies or falls down (mohsiur)
    ; Updating lives (mohsiur)
    ; Updating Level (mohsiur)
    
Timer0_Exit

    BL Display_board
    LDR r0, =0xE0004000             ; Clear Timer0 Interrupt by writing 1 to bit 0
    LDR r1, [r0]
    ORR r1, r1, #1
    STR r1, [r0]
    LDMFD sp!, {r0-r7, lr}          ; Timer0_Handler_Pop_3
    B FIQ_Exit
    
Timer1_Handler
    STMFD sp!, {r0-r7, lr}          ; Timer1_Handler_Push_4
    
    LDR r4, =Level                  ; Do nothing if Level = 0 
    LDR r0, [r4]
    CMP r0, #0
    BEQ Timer1_Exit
    
    LDR r4, =Time                   ; Decrement Time
    LDR r0, [r4]
    SUB r0, r0, #1
    STR r0, [r4]
    CMP r0, #0
    LDREQ r5, =Game_Over
    MOVEQ r1, #1                    ; If time == 0, update Game_Over to 1
    STREQ r1, [r5]
;    BLEQ Disable_Timer0
 ;   BLEQ Disable_Timer1
    BL Display_board
    
Timer1_Exit
    LDR r0, =0xE0008000             ; Clear Timer1 interrupt by writing bit0 of Interrupt Register
    LDR r1, [r0]
    ORR r1, r1, #1
    STR r1, [r0]
    LDMFD sp!, {r0-r7, lr}          ; Timer1_Handler_Pop_4
    B FIQ_Exit
    
EINT1_Handler
    STMFD sp!, {r0-r7, lr}
    
    LDR r4, =Level                  ; Do nothing if Level = 0 
    LDR r1, [r4]
    CMP r1, #0
    LDRNE r4, =Game_Over            
    LDRNE r1, [r4]
    CMPNE r1, #1
    BEQ EINT1_Exit
    
    LDR r4, =Pause
    LDR r1, [r4]
    CMP r1, #0
    
    MOVEQ r0, #3                    ; Currently playing (0) pause the game
    BLEQ RGB_LED                    ; Update RGB LED to Blue
   ; BLEQ Disable_Timer0             ; Disable Timr Interrupts
    ;BLEQ Disable_Timer1
    MOVEQ r1, #1                    ; Update Pause Status
    
    MOVNE r0, #2
    BLNE RGB_LED
  ;  BLNE Enable_Timer0
   ; BLNE Enable_Timer1
    MOVNE r1, #0
    
    STR r1, [r4]                    ; STore new Pause status
    BL Display_board
    
EINT1_Exit
    LDR r0, =0xE01FC140             ; Clear Interrupt by writing 1 to bit1
    LDR r1, [r0]
    ORR r1, r1, #2
    STR r1, [r0]
    LDMFD sp!, {r0-r7, lr}
    B FIQ_Exit

	END