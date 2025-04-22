#include "peripherals.h"

int main(void) {
  volatile char *led = (volatile char *)LED_ADDR;
  volatile char *rgb_r = (volatile char *)RGB_R_ADDR;
  volatile char *rgb_g = (volatile char *)RGB_G_ADDR;
  volatile char *rgb_b = (volatile char *)RGB_B_ADDR;

  *rgb_r = 0xFF;
  *rgb_g = 0xFF;
  *rgb_b = 0xFF;

  while (1) {
    *led = 0xFF;
    *rgb_b = 0xFF;
    *rgb_r = 0x00;
    int count = CLK_HZ >> 5;
    for (volatile int i = 0; i < count; i++);
    *led = 0x00;
    count = CLK_HZ >> 5;
    for (volatile int i = 0; i < count; i++);
    *led = 0xFF;
    *rgb_r = 0xFF;
    *rgb_g = 0x00;
    count = CLK_HZ >> 5;
    for (volatile int i = 0; i < count; i++);
    *led = 0x00;
    *rgb_g = 0xFF;
    *rgb_b = 0x00;
    count = CLK_HZ >> 5;
    for (volatile int i = 0; i < count; i++);
  }
  return 0;
}
