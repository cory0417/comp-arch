from pathlib import Path

import cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.runner import get_runner
from utils import init_clock


@cocotb.test()
async def test_uart_clk_generation(dut):
    init_clock(dut.clk, period_ns=41.7)  # 24 MHz clock period
    await RisingEdge(dut.clk)
    dut.reset_n.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1
    await RisingEdge(dut.clk)
    assert dut.baud_clk.value == 0

    # Wait for 7 clock cycles to pick the midpoint for data sampling
    await ClockCycles(dut.clk, 7)
    assert dut.baud_clk.value == 0

    # Wait 13 clock cycles to sample the first data bit
    await ClockCycles(dut.clk, 13)
    assert dut.baud_clk.value == 1


def test_uart_clk():
    sources_dir = Path(__file__).parent.parent / "rtl"

    runner = get_runner("icarus")
    runner.build(
        verilog_sources=[sources_dir / "uart_clk.sv"],
        hdl_toplevel="uart_clk",
        build_dir=Path(__file__).parent / "sim_build/uart_clk/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "10ps"),
        waves=True,
    )
    runner.test(
        hdl_toplevel="uart_clk",
        test_module="test_uart_clk",
        hdl_toplevel_lang="verilog",
        results_xml=None,
        waves=True,
    )
