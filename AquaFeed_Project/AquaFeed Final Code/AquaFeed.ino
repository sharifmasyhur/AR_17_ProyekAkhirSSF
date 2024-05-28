uint8_t btn_pin = 2;
volatile uint8_t status = 0;

extern "C"{
  void INIT();
}

void setup(){
  DDRD &= ~(1 << btn_pin);
  PORTD != (1 << btn_pin);

  attachInterrupt(digitalPinToInterrupt(btn_pin), button, FALLING);
}
void loop(){
  INIT();
  status = 0;
}
void button(){
  status = 1;
}