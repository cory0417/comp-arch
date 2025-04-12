import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.runner import get_runner
from utils import init_clock, reset_registers


@cocotb.test()
async def register_read_tb(dut):
    init_clock(dut)
    reset_registers(dut)

    dut.a1.value = 1
    dut.a2.value = 2
    dut.registers[1].value = 0xDEADBEEF
    dut.registers[2].value = 0xCAFEBABE

    await Timer(1, units="ns")  # wait for 1 ns for propagation

    assert (
        dut.rd1.value == 0xDEADBEEF
    ), f"Expected rd1 = 0xDEADBEEF, got {dut.rd1.value}"
    assert (
        dut.rd2.value == 0xCAFEBABE
    ), f"Expected rd2 = 0xCAFEBABE, got {dut.rd2.value}"


@cocotb.test()
async def register_write_and_read_tb(dut):
    init_clock(dut)
    reset_registers(dut)

    dut.wd.value = 0xDEADBEEF
    dut.a3.value = 1
    dut.wen.value = 1

    # Read from registers 1 and 2
    dut.a1.value = 1
    dut.a2.value = 2
    await RisingEdge(dut.clk)

    # Write 0xCAFEBABE to register 2
    dut.wd.value = 0xCAFEBABE
    dut.a3.value = 2
    await RisingEdge(dut.clk)

    dut.wen.value = 0
    await Timer(1, units="ns")  # wait for 1 ns for propagation

    assert (
        dut.rd1.value == 0xDEADBEEF
    ), f"Expected rd1 = 0xDEADBEEF, got {dut.rd1.value}"
    assert (
        dut.rd2.value == 0xCAFEBABE
    ), f"Expected rd2 = 0xCAFEBABE, got {dut.rd2.value}"


@cocotb.test()
async def register_write_to_zero(dut):
    init_clock(dut)
    reset_registers(dut)

    dut.a1.value = 0
    dut.a3.value = 0
    dut.wd.value = 0xDEADBEEF
    dut.wen.value = 1

    await RisingEdge(dut.clk)  # write attempt
    dut.wen.value = 0
    await Timer(1, units="ns")  # wait for 1 ns for propagation

    assert dut.rd1.value == 0, f"Expected rd1 = 0, got {dut.rd1.value}"


def test_register_file():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=["../rtl/register_file.sv"],
        hdl_toplevel="register_file",
        build_dir="sim_build/register_file/",
        always=True,
        clean=True,
        verbose=True,
    )
    runner.test(
        hdl_toplevel="register_file",
        test_module="test_register_file",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
