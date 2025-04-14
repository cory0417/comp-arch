/* blink.ld */

MEMORY
{
  RAM (rwx) : ORIGIN = 0x0000, LENGTH = 0x2000  /* 8KB RAM */
}

ENTRY(_start)

SECTIONS
{
  .text : {
    *(.text)
    *(.text*)
    *(.rodata)
    *(.rodata*)
  } > RAM

  .data : {
    *(.data)
    *(.data*)
  } > RAM

  .bss : {
    *(.bss)
    *(COMMON)
  } > RAM

  .stack (NOLOAD): {
    __stack_top = ORIGIN(RAM) + LENGTH(RAM);
    __stack_bottom = __stack_top - 0x400; /* 1KB stack */
  } > RAM

  PROVIDE(_stack = __stack_top);
}