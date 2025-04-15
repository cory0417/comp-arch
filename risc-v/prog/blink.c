#include "peripherals.h"

void delay(int clk_ticks) {
  int count = clk_ticks >> 4;
  for (volatile int i = 0; i < count; i++) {
    ;
  }
}


int main(void) {
  volatile char *led = (volatile char *)LED_ADDR;
  volatile char *rgb_r = (volatile char *)RGB_R_ADDR;
  volatile char *rgb_g = (volatile char *)RGB_G_ADDR;
  volatile char *rgb_b = (volatile char *)RGB_B_ADDR;

  *rgb_r = 0xFF;
  *rgb_g = 0xFF;
  *rgb_b = 0xFF;

  while (1) {
    *led = 0xFF; // Set LED to 0xFF
    *rgb_b = 0xFF;
    *rgb_r = 0x00;
    delay(CLK_HZ >> 1); // Delay for 0.5 seconds
    *led = 0x00; // Set LED to 0x00
    delay(CLK_HZ >> 1); // Delay for 0.5 seconds
    *led = 0xFF; // Set LED to 0xFF
    *rgb_r = 0xFF;
    *rgb_g = 0x00;
    delay(CLK_HZ >> 1); // Delay for 0.5 seconds
    *led = 0x00; // Set LED to 0x00
    *rgb_g = 0xFF;
    *rgb_b = 0x00;
    delay(CLK_HZ >> 1); // Delay for 0.5 seconds
  }
  return 0;
}
