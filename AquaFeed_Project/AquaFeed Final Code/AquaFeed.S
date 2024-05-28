#define __SFR_OFFSET 0x00
#include <avr/io.h>
#include <avr/interrupt.h>

.extern status

.global INIT

/*
GREEN       = 2 Seconds
BLUE        = 3 Seconds
YELLOW      = 4 Seconds
DELAY BUKA  = 1 Second
*/

INIT:
  RCALL INIT_SERIAL
  
  CBI   DDRB, 0
  CBI   DDRD, 3
  CBI   DDRD, 4


//BUTTONS
BUTTON:
  SBIC  PINB, 0
  RCALL GREEN

  SBIC  PIND, 3
  RCALL BLUE

  SBIC  PIND, 4
  RCALL YELLOW

  RET

//BUTTON ACTION
GREEN:
  LDI   R30, lo8(GREEN_MESSAGE)
  LDI   R31, hi8(GREEN_MESSAGE)
GREEN_AGAIN:
  LPM   R18, Z+
  CPI   R18, 0
  BREQ  GREEN_LOOP

  RCALL LCD_BUFFER

  STS   UDR0, R18

  RJMP  GREEN_AGAIN

GREEN_MESSAGE:
  .ascii "Delay 2 seconds"
  .byte 10, 13, 0
GREEN_LOOP:
  RCALL SERVO
  RCALL GREEN_2S

  LDS   R29, status
  CPI   R29, 1
  BREQ  BUTTON

  RJMP  GREEN_LOOP

BLUE:
  LDI   R30, lo8(BLUE_MESSAGE)
  LDI   R31, hi8(BLUE_MESSAGE)
BLUE_AGAIN:
  LPM   R18, Z+
  CPI   R18, 0
  BREQ  BLUE_LOOP

  RCALL LCD_BUFFER

  STS   UDR0, R18

  RJMP  BLUE_AGAIN

BLUE_MESSAGE:
  .ascii "Delay 3 seconds"
  .byte 10, 13, 0
BLUE_LOOP:
  RCALL SERVO
  RCALL BLUE_3S

  LDS   R29, status
  CPI   R29, 1
  BREQ  BUTTON

  RJMP  BLUE_LOOP

YELLOW:
  LDI   R30, lo8(YELLOW_MESSAGE)
  LDI   R31, hi8(YELLOW_MESSAGE)
YELLOW_AGAIN:
  LPM   R18, Z+
  CPI   R18, 0
  BREQ  YELLOW_LOOP

  RCALL LCD_BUFFER

  STS   UDR0, R18

  RJMP  YELLOW_AGAIN

YELLOW_MESSAGE:
  .ascii "Delay 4 seconds"
  .byte 10, 13, 0
YELLOW_LOOP:
  RCALL SERVO
  RCALL YELLOW_4S

  LDS   R29, status
  CPI   R29, 1
  BREQ  YELLOWFIN

  RJMP  YELLOW_LOOP
YELLOWFIN:
  RJMP  BUTTON

//SERIAL MONITOR
INIT_SERIAL:
  CLR   R24
  STS   UCSR0A, R24                 ;clear UCSR0A register
  STS   UBRR0H, R24                 ;clear UBRR0H register
  LDI   R24, 103                    ;& store in UBRR0L 103 value
  STS   UBRR0L, R24                 ;to set baud rate 9600
  LDI   R24, 1<<RXEN0 | 1<<TXEN0    ;enable RXB & TXB
  STS   UCSR0B, R24
  LDI   R24, 1<<UCSZ00 | 1<<UCSZ01  ;asynch, no parity, 1 stop, 8 bits
  STS   UCSR0C, R24

  RET

LCD_BUFFER:
  LDS   R17, UCSR0A
  SBRS  R17, UDRE0                  ;test data buffer if data can be sent
  RJMP  LCD_BUFFER

  RET

//BUTTON DELAYS
GREEN_2S:
  .EQU  value, 34286                ;2 Seconds
  
  LDI   R20, hi8(value)
  STS   TCNT1H, R20
  LDI   R20, lo8(value)
  STS   TCNT1L,  R20

  RCALL TIMER_INIT

  RET
  
BLUE_3S:
  .EQU  value, 18661                ;3 Seconds
  
  LDI   R20, hi8(value)
  STS   TCNT1H, R20
  LDI   R20, lo8(value)
  STS   TCNT1L,  R20

  RCALL TIMER_INIT

  RET

YELLOW_4S:
  .EQU  value, 3036                 ;4 Seconds
  
  LDI   R20, hi8(value)
  STS   TCNT1H, R20
  LDI   R20, lo8(value)
  STS   TCNT1L,  R20
  
  RCALL TIMER_INIT

  RET

//SERVO
SERVO:
  SBI   DDRB, 1 ;SERVO
  SBI   DDRD, 6 ;BUZZER
  SBI   DDRD, 7

SERVO_AGAIN:
  LDI   R26, 2
  LDI   ZL, lo8(POSITION)
  LDI   ZH, hi8(POSITION)        
SERVO_LOOP:
  LPM   R24, Z+
  RCALL BUZZER
  SBI   PORTD, 7
  RCALL DELAY_1S
  RCALL ROTATE_SERVO
  DEC   R26
  CBI   PORTD, 7
  BRNE  SERVO_LOOP

  RET
POSITION:
  .byte 40, 90

ROTATE_SERVO:
  LDI   R20, 3
SERVO_LOOP2:
  SBI   PORTB, 1
  RCALL SERVO_PULSE
  CBI   PORTB, 1
  RCALL DELAY_1S
  DEC   R20

  BRNE  SERVO_LOOP2

  RET

SERVO_PULSE:
  CLR   R21
  OUT   TCNT0, R21      
  MOV   R21, R24
  OUT   OCR0A, R21
  LDI   R21, 0b00001100
  OUT   TCCR0B, R21     ;timer0: CTC mode, prescaler 256

  LDI   R21, (1<<TOV0)
  OUT   TIFR0, R21

SERVO_PULSE_LOOP: 
  IN    R21, TIFR0      
  SBRS  R21, OCF0A      
  RJMP  SERVO_PULSE_LOOP              
  
  CLR   R21
  OUT   TCCR0B, R21    
  
  LDI   R21, (1<<OCF0A)
  OUT   TIFR0, R21  

  LDI   R21, 0
  OUT   TCCR0A, R21
  OUT   TCCR0B, R21   
  LDI   R17, 0 
  
  RET

//BUZZER
BUZZER:
  LDI   R20, 0b10001011           ; Timer0 in Fast PWM mode, prescaler 64
  OUT   TCCR0A, R20
  LDI   R20, 0b00000011           ; Start timer with prescaler 64
  OUT   TCCR0B, R20

  RET

//DELAYS
DELAY_1S:
  LDI   R21, 255
l4:
  LDI   R22, 255
l5: 
  LDI   R23, 15
l6: 
  DEC   R23
  BRNE  l6
  DEC   R22
  BRNE  l5
  DEC   R21
  BRNE  l4
  
  RET

TIMER_INIT:
  CLR   R20
  STS   TCCR1A, R20
  LDI   R20, 0x05
  STS   TCCR1B, R20                 ;timer 1, normal, 1024 prescaler

L1:
  IN    R20, TIFR1
  SBRS  R20, TOV1
  RJMP  L1

  LDI   R20, 1 << TOV1
  OUT   TIFR1, R20

  CLR   R20
  STS   TCCR1B, R20

  RET