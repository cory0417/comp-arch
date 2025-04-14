.section .text
.global _start

.extern _stack  // Symbol provided by linker

_start:
    la sp, _stack     // Set stack pointer to top of usable RAM
    call main
1:  j 1b              // Infinite loop after main returns