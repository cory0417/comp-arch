lui x1, 0xFF000   # lui for led bits; x1 = 0xFF00_0000
srai x2, x1, 8    # srai for red bits; x2 = 0xFFFF_0000
srli x3, x1, 16   # srli for green bits; x3 = 0x0000_FF00
add x3, x1, x3    # add for green bits; x3 = 0xFF00_FF00
srli x4, x1, 24   # srli for blue bits; x4 = 0x0000_00FF
add x4, x1, x4    # add for blue bits; x4 = 0xFF00_00FF
sw x2, -4(x0)     # store red bits at address 0xFFFF_FFFC
srli x6, x2, 28   # srli for counter; x6 = 0x0000_000F (very small delay for simulation)
addi x7, x7, 1    # increment counter x7
blt x7, x6, -4    # branch back up to increment if less than 0x000F_FFF0
addi x7, x0, 0    # reset counter x7 to 0
sw x3, -4(x0)     # store green bits at address 0xFFFF_FFFC
addi x7, x7, 1    # increment counter x7
blt x7, x6, -4    # branch back up to increment if less than 0x0000_000F
addi x7, x0, 0    # reset counter x7 to 0
sw x4, -4(x0)     # store blue bits at address 0xFFFF_FFFC
addi x7, x7, 1    # increment counter x7
blt x7, x6, -4    # branch back up to increment if less than 0x0000_000F
addi x7, x0, 0    # reset counter x7 to 0
jal x0, -52       # jump back up to storing red bits
