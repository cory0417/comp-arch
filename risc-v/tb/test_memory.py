import pathlib

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.runner import get_runner
from utils import init_clock

parent_dir = pathlib.Path(__file__).parent


@cocotb.test()
async def test_memory_read_instruction(dut):
    with open(f"{parent_dir}/rv32i_test.txt") as f:
        first_word = int(f.read(8), 16)
    init_clock(dut)
    dut.read_address.value = 0
    dut.funct3.value = 0b010  # For reading word at a time

    dut.write_mem.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")  # wait for 1 ns for propagation
    assert dut.read_data.value == first_word


@cocotb.test()
async def test_memory_read_data_hw_unsigned(dut):
    with open(f"{parent_dir}/rv32i_test.txt") as f:
        second_word = int(f.readlines()[1], 16)
    half_word_upper = (second_word >> 16) & 0x0000FFFF
    half_word_lower = second_word & 0x0000FFFF
    init_clock(dut)
    dut.read_address.value = 4  # Read the second word
    dut.funct3.value = 0b101  # For reading half-word at a time

    dut.write_mem.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")  # wait for 1 ns for propagation
    assert dut.read_data.value == half_word_lower

    dut.read_address.value = 4 + 2
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == half_word_upper


@cocotb.test()
async def test_memory_read_data_hw_signed(dut):
    with open(f"{parent_dir}/rv32i_test.txt") as f:
        third_word = int(f.readlines()[2], 16)

    third_word_upper_sign = third_word & 0x80000000
    third_word_upper = (
        (third_word >> 16) | 0xFFFF0000
        if third_word_upper_sign
        else third_word >> 16
    )
    third_word_lower_sign = third_word & 0x00008000
    third_word_lower = (
        third_word | 0xFFFF0000
        if third_word_lower_sign
        else third_word & 0x0000FFFF
    )

    init_clock(dut)
    dut.read_address.value = 8
    dut.funct3.value = 0b001  # For reading half-word at a time

    dut.write_mem.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")  # wait for 1 ns for propagation
    assert dut.read_data.value == third_word_lower

    dut.read_address.value = 8 + 2
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")  # wait for 1 ns for propagation
    assert dut.read_data.value == third_word_upper


@cocotb.test()
async def test_memory_read_data_byte_unsigned(dut):
    with open(f"{parent_dir}/rv32i_test.txt") as f:
        fourth_word = int(f.readlines()[3], 16)
    byte_0 = fourth_word & 0x000000FF
    byte_1 = (fourth_word >> 8) & 0x000000FF
    byte_2 = (fourth_word >> 16) & 0x000000FF
    byte_3 = (fourth_word >> 24) & 0x000000FF
    init_clock(dut)
    dut.read_address.value = 12
    dut.funct3.value = 0b100  # For reading unsigned byte at a time

    dut.write_mem.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")  # wait for 1 ns for propagation
    assert dut.read_data.value == byte_0
    dut.read_address.value = 12 + 1
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == byte_1
    dut.read_address.value = 12 + 2
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == byte_2
    dut.read_address.value = 12 + 3
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == byte_3


@cocotb.test()
async def test_memory_read_data_byte_signed(dut):
    with open(f"{parent_dir}/rv32i_test.txt") as f:
        fourth_word = int(f.readlines()[3], 16)
    byte_0_sign = fourth_word & 0x00000080
    byte_1_sign = fourth_word & 0x00008000
    byte_2_sign = fourth_word & 0x00800000
    byte_3_sign = fourth_word & 0x80000000
    byte_0 = (
        fourth_word & 0x000000FF | 0xFFFFFF00
        if byte_0_sign
        else fourth_word & 0x000000FF
    )
    byte_1 = (
        (fourth_word >> 8) & 0x000000FF | 0xFFFFFF00
        if byte_1_sign
        else (fourth_word >> 8) & 0x000000FF
    )
    byte_2 = (
        (fourth_word >> 16) & 0x000000FF | 0xFFFFFF00
        if byte_2_sign
        else (fourth_word >> 16) & 0x000000FF
    )
    byte_3 = (
        (fourth_word >> 24) & 0x000000FF | 0xFFFFFF00
        if byte_3_sign
        else (fourth_word >> 24) & 0x000000FF
    )

    init_clock(dut)
    dut.read_address.value = 12
    dut.funct3.value = 0b000  # For reading signed byte at a time

    dut.write_mem.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")  # wait for 1 ns for propagation
    assert dut.read_data.value == byte_0
    dut.read_address.value = 12 + 1
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == byte_1
    dut.read_address.value = 12 + 2
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == byte_2
    dut.read_address.value = 12 + 3
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.read_data.value == byte_3


@cocotb.test()
async def test_memory_write_word(dut):
    init_clock(dut)
    dut.funct3.value = 0b010
    dut.write_mem.value = 1
    dut.read_address.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0x12345789

    await RisingEdge(dut.clk)
    dut.write_mem.value = 0
    await RisingEdge(dut.clk)

    await Timer(1, units="ns")

    assert dut.read_data.value == 0x12345789


async def test_memory_write_hw(dut):
    init_clock(dut)
    dut.funct3.value = 0b001
    dut.write_mem.value = 1
    dut.read_address.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0x1234

    await RisingEdge(dut.clk)
    dut.write_mem.value = 0
    dut.funct3.value = 0b101
    await RisingEdge(dut.clk)

    await Timer(1, units="ns")

    assert dut.read_data.value == 0x1234


async def test_memory_write_byte(dut):
    init_clock(dut)
    dut.funct3.value = 0b000
    dut.write_mem.value = 1
    dut.read_address.value = 0
    dut.write_address.value = 0
    dut.write_data.value = 0x12

    await RisingEdge(dut.clk)
    dut.write_mem.value = 0
    dut.funct3.value = 0b100
    await RisingEdge(dut.clk)

    await Timer(1, units="ns")

    assert dut.read_data.value == 0x12


def test_memory():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=["../rtl/memory.sv"],
        hdl_toplevel="memory",
        build_dir="sim_build/memory/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
        build_args=[
            f'-Pmemory.INIT_FILE="{parent_dir}/rv32i_test"'
        ],  # Doing the regular parameters dict doesn't seem to work for initial block
    )
    runner.test(
        hdl_toplevel="memory",
        test_module="test_memory",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
