#include "peripherals.h"

int main(void) {
  volatile char *rgb_r = (volatile char *)RGB_R_ADDR;
  volatile char *rgb_g = (volatile char *)RGB_G_ADDR;
  volatile char *rgb_b = (volatile char *)RGB_B_ADDR;
  volatile int *micros = (volatile int *)MICROS_ADDR;

  *rgb_r = 0x00;
  *rgb_g = 0xFF;
  *rgb_b = 0xFF;

  while (1) {
    int micros_prev = *micros;
    for (int i = 255; i >= 0; i--) {
      *rgb_g = i;
      while (*micros - micros_prev < 651) ;
      micros_prev = *micros;
    }
    for (int i = 0; i <= 255; i++) {
      *rgb_r = i;
      while (*micros - micros_prev < 651) ;
      micros_prev = *micros;
    }
    for (int i = 255; i >= 0; i--) {
      *rgb_b = i;
      while (*micros - micros_prev < 651) ;
      micros_prev = *micros;
    }
    for (int i = 0; i <= 255; i++) {
      *rgb_g = i;
      while (*micros - micros_prev < 651) ;
      micros_prev = *micros;
    }
    for (int i = 255; i >= 0; i--) {
      *rgb_r = i;
      while (*micros - micros_prev < 651) ;
      micros_prev = *micros;
    }
    for (int i = 0; i <= 255; i++) {
      *rgb_b = i;
      while (*micros - micros_prev < 651) ;
      micros_prev = *micros;
    }
  }
}