import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.runner import get_runner
from utils import init_clock

from test_control import PCSrc


@cocotb.test()
async def test_addi_add(dut):
    init_clock(dut)

    instr_1 = 0b00000000001000000000000010010011  # addi x1, x0, 2
    dut.mem_rd.value = instr_1

    dut.pc.value = 0  # PC = 0

    await RisingEdge(dut.clk)
    # At FETCH_INSTR state
    await RisingEdge(dut.clk)
    # At EXECUTE state; instr is loaded

    # Set the next instruction by manually setting the read data from memory
    instr_2 = 0b00000000000100001000000100110011  # add x2, x1, x1
    dut.mem_rd.value = instr_2

    await Timer(1, units="ns")
    assert dut.instr.value == instr_1
    assert dut.pc.value == 0
    assert dut.pc_next.value == 4
    assert dut.pc_src.value == PCSrc.OP_DEFAULT  # PC + 4

    await RisingEdge(dut.clk)
    # At FETCH_INSTR state again and register file should be updated
    await Timer(1, units="ns")
    assert dut.u_register_file.registers[1].value == 2

    await RisingEdge(dut.clk)
    # At EXECUTE state; instr is loaded
    await Timer(1, units="ns")
    assert dut.instr.value == instr_2
    assert dut.pc.value == 4
    assert dut.pc_next.value == 8
    assert dut.pc_src.value == PCSrc.OP_DEFAULT

    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert dut.u_register_file.registers[2].value == 2 + 2


def test_risc_v():
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
        ],
        hdl_toplevel="risc_v",
        build_dir="sim_build/risc_v/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
    )
    runner.test(
        hdl_toplevel="risc_v",
        test_module="test_risc_v",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
