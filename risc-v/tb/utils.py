import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


async def reset_dut(dut):
    """Trigger active-low reset signal on DUT."""
    dut.reset_n.value = 0
    dut.wen.value = 0
    await RisingEdge(dut.clk)  # ensure reset aligns with clock edge
    dut.reset_n.value = 1


def init_clock(dut):
    """Initialize clock signal for DUT."""
    clock = Clock(dut.clk, 10, units="ns")
    _ = cocotb.start_soon(clock.start())
