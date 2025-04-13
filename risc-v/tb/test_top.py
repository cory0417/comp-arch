import pathlib

import cocotb
from cocotb.triggers import ClockCycles, Timer
from cocotb.runner import get_runner
from utils import (
    init_clock,
    write_program_to_memory,
    load_hex_from_txt,
    reset_risc_v,
    get_word_from_memory,
)

parent_dir = pathlib.Path(__file__).parent


@cocotb.test()
async def test_r_i_u_s_instructions(dut):
    """
    Test RISC-V instructions.

    lui x1, 0xFEDCC         # pc = 0x00, x1 = 0xFEDCC000
    addi x1, x1, 0xA98      # pc = 0x04, x1 = 0xFEDCBA98
    srli x2, x1, 4          # pc = 0x08, x2 = 0x0FEDCBA9
    srai x3, x1, 4          # pc = 0x0C, x3 = 0xFFEDCBA9
    xori x4, x3, -1         # pc = 0x10, x4 = 0x00123456
    addi x5, x0, 2          # pc = 0x14, x5 = 0x00000002
    add x6, x5, x4          # pc = 0x18, x6 = 0x00123458
    sub x7, x6, x4          # pc = 0x1C, x7 = 0x00000002
    sll x8, x4, x5          # pc = 0x20, x8 = 0x0048D158
    ori x9, x8, 7           # pc = 0x24, x9 = 0x0048D15F
    auipc x10, 0x12345      # pc = 0x28, x10 = 0x12345028
    sw x1, 98(x5)           # pc = 0x2C, mem[0x00000002 + 98] = 0xFEDCBA98
    lw x11, 98(x5)          # pc = 0x30, x11 = 0xFEDCBA98
    """
    init_clock(dut)

    data = load_hex_from_txt(parent_dir / "rv32i_test.txt")
    # Writing the instructions to memory
    write_program_to_memory(dut, data)

    await ClockCycles(
        dut.clk, 23
    )  # takes (11*2+1) cycles for 11 instructions without memory load/store
    await Timer(1, units="ns")

    assert dut.u_risc_v.u_register_file.registers[0].value == 0
    assert dut.u_risc_v.u_register_file.registers[1].value == 0xFEDCBA98
    assert dut.u_risc_v.u_register_file.registers[2].value == 0x0FEDCBA9
    assert dut.u_risc_v.u_register_file.registers[3].value == 0xFFEDCBA9
    assert dut.u_risc_v.u_register_file.registers[4].value == 0x00123456
    assert dut.u_risc_v.u_register_file.registers[5].value == 0x00000002
    assert dut.u_risc_v.u_register_file.registers[6].value == 0x00123458
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x00000002
    assert dut.u_risc_v.u_register_file.registers[8].value == 0x0048D158
    assert dut.u_risc_v.u_register_file.registers[9].value == 0x0048D15F
    assert dut.u_risc_v.u_register_file.registers[10].value == 0x12345028

    # Now running the load/store instructions
    await ClockCycles(dut.clk, 3)  # store takes 3 cycles
    await Timer(1, units="ns")
    # Executed sw x1, 98(x5) => store word 0xFEDCBA98 at (98+2)th byte address in memory
    # (98 + 2) / 4 = 25 => 25th byte in block ram memory chunks
    assert dut.u_memory.mem0.memory[25].value == 0x98
    assert dut.u_memory.mem1.memory[25].value == 0xBA
    assert dut.u_memory.mem2.memory[25].value == 0xDC
    assert dut.u_memory.mem3.memory[25].value == 0xFE

    await ClockCycles(dut.clk, 3)  # load takes 3 cycles
    await Timer(1, units="ns")
    # Executed lw x11, 98(x5) => load word from (98+2)th byte address in memory to x11
    assert dut.u_risc_v.u_register_file.registers[11].value == 0xFEDCBA98


@cocotb.test()
async def test_rgb_cycling(dut):
    """
    Test RGB cycling program.

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
    """
    init_clock(dut)
    reset_risc_v(dut.u_risc_v)
    # Writing the instructions to memory
    data = load_hex_from_txt(parent_dir / "rgb_cycle.txt")
    write_program_to_memory(dut, data)
    await ClockCycles(dut.clk, 2)  # Reprogramming complete

    await ClockCycles(dut.clk, 2)
    # lui x1, 0xFF000
    assert dut.u_risc_v.u_register_file.registers[1].value == 0xFF000000
    await ClockCycles(dut.clk, 2)
    # srai x2, x1, 8
    assert dut.u_risc_v.u_register_file.registers[2].value == 0xFFFF0000
    await ClockCycles(dut.clk, 2)
    # srli x3, x1, 16
    assert dut.u_risc_v.u_register_file.registers[3].value == 0x0000FF00
    await ClockCycles(dut.clk, 2)
    # add x3, x1, x3
    assert dut.u_risc_v.u_register_file.registers[3].value == 0xFF00FF00
    await ClockCycles(dut.clk, 2)
    # srli x4, x1, 24
    assert dut.u_risc_v.u_register_file.registers[4].value == 0x000000FF
    await ClockCycles(dut.clk, 2)
    # add x4, x1, x4
    assert dut.u_risc_v.u_register_file.registers[4].value == 0xFF0000FF
    await ClockCycles(dut.clk, 3)
    # sw x2, -4(x0)
    data = get_word_from_memory(dut.u_memory, 0, -4)
    assert data == 0xFFFF0000
    await ClockCycles(dut.clk, 2)
    # srli x6, x2, 28
    assert dut.u_risc_v.u_register_file.registers[6].value == 0x0000000F
    await ClockCycles(dut.clk, 2)
    # addi x7, x7, 1
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x00000001
    pc_at_branch_instr = dut.u_risc_v.pc.value
    await ClockCycles(dut.clk, 2)
    # blt x7, x6, -4
    assert dut.u_risc_v.pc.value == pc_at_branch_instr - 4
    await ClockCycles(
        dut.clk, (2 + 2) * 14
    )  # after 14 more addi, x7 = 0x0000000F, so branch is avoided

    await ClockCycles(dut.clk, 2)
    # addi x7, x0, 0
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x00000000
    await ClockCycles(dut.clk, 3)
    # sw x3, -4(x0)
    data = get_word_from_memory(dut.u_memory, 0, -4)
    assert data == 0xFF00FF00
    await ClockCycles(dut.clk, (2 + 2) * 15)  # loop again for blue led 15 times

    await ClockCycles(dut.clk, 2)
    # addi x7, x0, 0
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x00000000
    await ClockCycles(dut.clk, 3)
    # sw x4, -4(x0)
    data = get_word_from_memory(dut.u_memory, 0, -4)
    assert data == 0xFF0000FF
    await ClockCycles(dut.clk, (2 + 2) * 15)  # loop again for red led 15 times

    await ClockCycles(dut.clk, 2)
    # addi x7, x0, 0
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x00000000

    pc_before_jump = dut.u_risc_v.pc.value
    await ClockCycles(dut.clk, 2)
    await Timer(1, units="ns")
    # jal x0, -52
    # jump back to red led sw instruction
    assert dut.u_risc_v.pc.value == pc_before_jump - 52


@cocotb.test()
async def test_unconditional_jumps(dut):
    """
    Test unconditional jumps -- jal and jalr

    ori x1, x0, 10      # pc = 0x00, x1 = 0x0000000A
    jal x2, 0xC         # pc = 0x04, x2 = 0x00000008
    addi x3, x1, 5      # pc = 0x08, x3 = 0x0000000F
    jal x0, 0x8         # pc = 0x0C, x0 = 0x00000000
    jalr x0, 0(x2)      # pc = 0x10, x0 = 0x00000000
    sub x4, x3, x1      # pc = 0x14, x4 = 0x00000005

    Order of execution:
    1. ori x1, x0, 10
    2. jal x2, 0xC
    3. jalr x0, 0(x2)
    4. addi x3, x1, 5
    5. jal x0, 0x8
    6. sub x4, x3, x1
    """
    init_clock(dut)
    reset_risc_v(dut.u_risc_v)
    # Writing the instructions to memory
    data = [
        0x00A06093,  # ori x1 x0 10
        0x00C0016F,  # jal x2 12
        0x00508193,  # addi x3 x1 5
        0x0080006F,  # jal x0 8
        0x00010267,  # jalr x4 x2 0
        0x40118233,  # sub x4 x3 x1
    ]
    write_program_to_memory(dut, data)
    await ClockCycles(dut.clk, 2)  # Reprogramming complete

    await ClockCycles(dut.clk, 12)
    assert dut.u_risc_v.u_register_file.registers[4].value == 0x00000005
    assert dut.u_risc_v.u_register_file.registers[3].value == 0x0000000F
    assert dut.u_risc_v.u_register_file.registers[2].value == 0x00000008
    assert dut.u_risc_v.u_register_file.registers[1].value == 0x0000000A


@cocotb.test()
async def test_conditional_jumps(dut):
    """
    Test conditional jumps -- beq, bne, blt, bge

    addi x1, x0, 0xE    # pc = 0x00, x1 = 0x0000000E
    andi x2, x1, 0x7    # pc = 0x04, x2 = 0x00000006
    beq x1, x2, 0x8     # pc = 0x08; x1 != x2, so branch not taken
    xor x3, x1, x2      # pc = 0x0C, x3 = 0x00000008
    add x4, x2, x3      # pc = 0x10, x4 = 0x0000000E
    bne x1, x4, -8      # pc = 0x14; x1 == x4, so branch not taken
    blt x2, x1, 0x8     # pc = 0x18; x2 < x1, so branch taken
    sub x2, x1, x4      # pc = 0x1C, x2 = 0x00000000
    addi x2, x2, 0x9    # pc = 0x1C, x2 = 0x0000000F; second time -- x2 = 0x00000009
    bge x2, x1, -8      # pc = 0x20; x2 >= x1, so branch taken; x2 < x1, so branch not taken second time
    addi x6, x2, 5      # pc = 0x24, x6 = 0x0000000E

    Order of execution:
    1. addi x1, x0, 0xE
    2. andi x2, x1, 0x7
    3. beq x1, x2, 0x8
    4. xor x3, x1, x2
    5. add x4, x2, x3
    6. bne x1, x4, -8
    7. blt x2, x1, 0x8
    8. addi x2, x2, 0x9
    9. bge x2, x1, -8
    10. sub x2, x1, x4
    11. addi x6, x2, 5
    12. bge x2, x1, -8
    13. addi x6, x2, 5
    """
    init_clock(dut)
    reset_risc_v(dut.u_risc_v)
    # Writing the instructions to memory
    data = [
        0x00E00093,  # addi x1 x0 14
        0x0070F113,  # andi x2 x1 7
        0x00208463,  # beq x1 x2 8
        0x0020C1B3,  # xor x3 x1 x2
        0x00310233,  # add x4 x2 x3
        0xFE409CE3,  # bne x1 x4 -8
        0x00114463,  # blt x2 x1 8
        0x40408133,  # sub x2 x1 x4
        0x00910113,  # addi x2 x2 9
        0xFE115CE3,  # bge x2 x1 -8
        0x00510313,  # addi x6 x2 5
    ]
    write_program_to_memory(dut, data)
    await ClockCycles(dut.clk, 2)

    await ClockCycles(dut.clk, 26)
    assert dut.u_risc_v.u_register_file.registers[1].value == 0x0000000E
    assert dut.u_risc_v.u_register_file.registers[2].value == 0x00000009
    assert dut.u_risc_v.u_register_file.registers[3].value == 0x00000008
    assert dut.u_risc_v.u_register_file.registers[4].value == 0x0000000E
    assert dut.u_risc_v.u_register_file.registers[6].value == 0x0000000E


@cocotb.test()
async def test_load_store(dut):
    """
    Test load/store instructions.

    lui x1, 0x1F2E3   # pc = 0x00, x1 = 0x1F2E_3000
    addi x1, x1, 0xD4C  # pc = 0x04, x1 = 0x1F2E_2D4C
    sw x1, 100(x0)  # pc = 0x04, mem[0x00000064] = 0x1F2E_2D4C
    lw x3, 100(x0) # pc = 0x08, x2 = 0x1F2E_2D4C
    sh x1, 104(x0) # pc = 0x0C, mem[0x00000068] = 0x0000_2D4C
    lh x4, 104(x0) # pc = 0x10, x4 = 0x0000_2D4C
    sb x1, 108(x0) # pc = 0x14, mem[0x0000006C] = 0x0000_004C
    lb x5, 108(x0) # pc = 0x18, x5 = 0x0000_004C
    lb x6, 105(x0) # pc = 0x1C, x6 = 0x0000_002D
    addi x7, x0, 0x08F  # pc = 0x20, x7 = 0x0000_008F
    sb x1, 109(x0) # pc = 0x24, mem[0x0000006C] = 0x0000_8F4C
    lhu x8, 108(x0) # pc = 0x28, x8 = 0x0000_8F4C
    lh x9, 108(x0) # pc = 0x2C, x9 = 0xFFFF_8F4C
    lbu x10, 109(x0) # pc = 0x30, x10 = 0x0000_008F
    lb x11, 109(x0) # pc = 0x34, x11 = 0xFFFF_FF8F
    """
    init_clock(dut)
    reset_risc_v(dut.u_risc_v)
    data = [
        0x1F2E30B7,  # lui x1 0x1f2e3
        0xD4C08093,  # addi x1 x1 -692
        0x06102223,  # sw x1 100 x0
        0x06402183,  # lw x3 100 x0
        0x06101423,  # sh x1 104 x0
        0x06801203,  # lh x4 104 x0
        0x06100623,  # sb x1 108 x0
        0x06C00283,  # lb x5 108 x0
        0x06900303,  # lb x6 105 x0
        0x08F00393,  # addi x7 x0 143
        0x067006A3,  # sb x7 109 x0
        0x06C05403,  # lhu x8 108 x0
        0x06C01483,  # lh x9 108 x0
        0x06D04503,  # lbu x10 109 x0
        0x06D00583,  # lb x11 109 x0
    ]
    write_program_to_memory(dut, data)
    await ClockCycles(dut.clk, 2)

    await ClockCycles(dut.clk, 2)
    assert dut.u_risc_v.u_register_file.registers[1].value == 0x1F2E_3000
    await ClockCycles(dut.clk, 2)
    assert dut.u_risc_v.u_register_file.registers[1].value == 0x1F2E_2D4C

    await ClockCycles(dut.clk, 3)
    assert get_word_from_memory(dut.u_memory, 0, 100) == 0x1F2E_2D4C
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[3].value == 0x1F2E_2D4C

    await ClockCycles(dut.clk, 3)
    assert get_word_from_memory(dut.u_memory, 0, 104) & 0xFFFF == 0x0000_2D4C
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[4].value == 0x0000_2D4C

    await ClockCycles(dut.clk, 3)
    assert get_word_from_memory(dut.u_memory, 0, 108) & 0xFF == 0x0000_004C
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[5].value == 0x0000_004C

    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[6].value == 0x0000_002D

    await ClockCycles(dut.clk, 2)
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x0000_008F

    await ClockCycles(dut.clk, 3)
    assert get_word_from_memory(dut.u_memory, 0, 108) >> 8 & 0xFF == 0x0000_008F
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[8].value == 0x0000_8F4C
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[9].value == 0xFFFF_8F4C
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[10].value == 0x0000_008F
    await ClockCycles(dut.clk, 3)
    assert dut.u_risc_v.u_register_file.registers[11].value == 0xFFFF_FF8F


@cocotb.test()
async def test_integer_register_immediate(dut):
    """
    Test integer register-immediate instructions (I-type).

    addi x1, x0, 0x80F    # pc = 0x00, x1 = 0xFFFF_F80F = -2033
    slti x2, x1, -2032    # pc = 0x04, x2 = 0x00000001; x1 < -2032
    sltiu x3, x1, 10   # pc = 0x08, x3 = 0x00000000; x1 > 10 (unsigned)
    sltiu x4, x0, 1      # pc = 0x0C, x4 = 0x00000001; x0 < 0x0000_0001 (unsigned) -- only possible when rs1 is 0
    andi x5, x1, 0x0FF    # pc = 0x10, x5 = 0x0000_000F
    ori x6, x5, 0xFCF    # pc = 0x14, x6 = 0xFFFF_FFCF
    xori x7, x6, 0xFF0    # pc = 0x18, x7 = 0x0000_003F
    xori x8, x6, -1      # pc = 0x1C, x8 = 0x0000_0030
    slli x9, x7, 24       # pc = 0x1C, x9 = 0x3F00_0000
    srli x10, x9, 2       # pc = 0x20, x10 = 0x0FC0_0000
    srai x11, x10, 2      # pc = 0x24, x11 = 0x003F_0000
    """
    init_clock(dut)
    reset_risc_v(dut.u_risc_v)
    data = [
        0x80F00093,  # addi x1 x0 -2033
        0x8100A113,  # slti x2 x1 -2032
        0x00A0B193,  # sltiu x3 x1 10
        0x00103213,  # sltiu x4 x0 1
        0x0FF0F293,  # andi x5 x1 255
        0xFCF2E313,  # ori x6 x5 -49
        0xFF034393,  # xori x7 x6 -16
        0xFFF34413,  # xori x8 x6 -1
        0x01839493,  # slli x9 x7 24
        0x0024D513,  # srli x10 x9 2
        0x40255593,  # srai x11 x10 2
    ]
    write_program_to_memory(dut, data)
    await ClockCycles(dut.clk, 2)

    await ClockCycles(dut.clk, 22)  # 11 instructions, 2 cycles each
    assert dut.u_risc_v.u_register_file.registers[1].value == 0xFFFFF80F
    assert dut.u_risc_v.u_register_file.registers[2].value == 0x00000001
    assert dut.u_risc_v.u_register_file.registers[3].value == 0x00000000
    assert dut.u_risc_v.u_register_file.registers[4].value == 0x00000001
    assert dut.u_risc_v.u_register_file.registers[5].value == 0x0000000F
    assert dut.u_risc_v.u_register_file.registers[6].value == 0xFFFFFFCF
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x0000003F
    assert dut.u_risc_v.u_register_file.registers[8].value == 0x00000030
    assert dut.u_risc_v.u_register_file.registers[9].value == 0x3F000000
    assert dut.u_risc_v.u_register_file.registers[10].value == 0x0FC00000
    assert dut.u_risc_v.u_register_file.registers[11].value == 0x03F00000


@cocotb.test()
async def test_integer_register_register(dut):
    """
    Test integer register-register instructions (R-type).

    addi x1, x0, 0x001       # pc = 0x00, x1 = 0x00000001
    add x2, x1, x1         # pc = 0x04, x2 = 0x00000002
    slt x3, x1, x2       # pc = 0x08, x3 = 0x00000001; x1 < x2
    sub x4, x1, x2       # pc = 0x0C, x4 = 0xFFFFFFFF; x1 - x2 = -1
    sltu x5, x1, x4         # pc = 0x10, x5 = 0x00000001; x1 < -1 (unsigned)
    slt x6, x1, x4       # pc = 0x14, x6 = 0x00000000; x1 > -1
    xor x7, x1, x2       # pc = 0x18, x7 = 0x00000003
    or x8, x7, x1         # pc = 0x1C, x8 = 0x00000003
    sll x9, x8, x7         # pc = 0x20, x9 = 0x00000018
    srl x10, x4, x1        # pc = 0x24, x10 = 0x7FFFFFFF
    sra x11, x4, x1        # pc = 0x28, x11 = 0xFFFFFFFF
    and x12, x10, x11       # pc = 0x2C, x12 = 0x7FFFFFFF
    """
    init_clock(dut)
    reset_risc_v(dut.u_risc_v)
    data = [
        0x00100093,  # addi x1 x0 1
        0x00108133,  # add x2 x1 x1
        0x0020A1B3,  # slt x3 x1 x2
        0x40208233,  # sub x4 x1 x2
        0x0040B2B3,  # sltu x5 x1 x4
        0x0040A333,  # slt x6 x1 x4
        0x0020C3B3,  # xor x7 x1 x2
        0x0013E433,  # or x8 x7 x1
        0x007414B3,  # sll x9 x8 x7
        0x00125533,  # srl x10 x4 x1
        0x401255B3,  # sra x11 x4 x1
        0x00B57633,  # and x12 x10 x11
    ]
    write_program_to_memory(dut, data)
    await ClockCycles(dut.clk, 2)

    await ClockCycles(dut.clk, 24)  # 12 instructions, 2 cycles each
    assert dut.u_risc_v.u_register_file.registers[1].value == 0x00000001
    assert dut.u_risc_v.u_register_file.registers[2].value == 0x00000002
    assert dut.u_risc_v.u_register_file.registers[3].value == 0x00000001
    assert dut.u_risc_v.u_register_file.registers[4].value == 0xFFFFFFFF
    assert dut.u_risc_v.u_register_file.registers[5].value == 0x00000001
    assert dut.u_risc_v.u_register_file.registers[6].value == 0x00000000
    assert dut.u_risc_v.u_register_file.registers[7].value == 0x00000003
    assert dut.u_risc_v.u_register_file.registers[8].value == 0x00000003
    assert dut.u_risc_v.u_register_file.registers[9].value == 0x00000018
    assert dut.u_risc_v.u_register_file.registers[10].value == 0x7FFFFFFF
    assert dut.u_risc_v.u_register_file.registers[11].value == 0xFFFFFFFF
    assert dut.u_risc_v.u_register_file.registers[12].value == 0x7FFFFFFF


def test_top():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=[
            "../rtl/types.sv",
            "../rtl/control.sv",
            "../rtl/pc_selector.sv",
            "../rtl/alu.sv",
            "../rtl/register_file.sv",
            "../rtl/imm_extender.sv",
            "../rtl/risc_v.sv",
            "../rtl/memory.sv",
            "../rtl/top.sv",
        ],
        hdl_toplevel="top",
        build_dir="sim_build/top/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
        # NOTE: program can be passed as a parameter here
        # build_args=[
        #     f'-Ptop.INIT_FILE="{parent_dir}/rv32i_test"'
        # ],  # Doing the regular parameters dict doesn't seem to work for initial block
    )
    runner.test(
        hdl_toplevel="top",
        test_module="test_top",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
