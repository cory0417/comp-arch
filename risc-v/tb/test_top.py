import pathlib

import cocotb
from cocotb.triggers import ClockCycles, Timer
from cocotb.runner import get_runner
from utils import init_clock, write_to_memory

parent_dir = pathlib.Path(__file__).parent


@cocotb.test()
async def test_instruction_results(dut):
    init_clock(dut)

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
        build_args=[
            f'-Ptop.INIT_FILE="{parent_dir}/rv32i_test"'
        ],  # Doing the regular parameters dict doesn't seem to work for initial block
    )
    runner.test(
        hdl_toplevel="top",
        test_module="test_top",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
