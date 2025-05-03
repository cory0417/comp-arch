#include "peripherals.h"

int main(void) {
  volatile char *led = (volatile char *)LED_ADDR;

  while (1) {
    *led = 0xFF;
    int count = CLK_HZ >> 5;
    for (volatile int i = 0; i < count; i++);
    *led = 0x00;
    count = CLK_HZ >> 5;
    for (volatile int i = 0; i < count; i++);
  }
  return 0;
}
