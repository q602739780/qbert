extern int lab7(void);	
extern int pin_connect_block(void);
extern int pin_direction(void);
extern int interrupt_init(void);
extern int uart_init(void);
extern int Enable_Timer(void);
extern int Enable_UART0_Interrupt(void);


int main()
{ 	
   interrupt_init();
   pin_connect_block();
   pin_direction();
   uart_init();
   //Enable_Timer();
   //Enable_UART0_Interrupt();
   lab7();
}
