import pathlib

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.runner import get_runner
from utils import init_clock


@cocotb.test()
async def memory_read_instruction(dut):
    parent_dir = pathlib.Path(__file__).parent
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


def test_memory():
    parent_dir = pathlib.Path(__file__).parent
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
