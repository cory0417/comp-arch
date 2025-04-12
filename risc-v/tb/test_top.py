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
