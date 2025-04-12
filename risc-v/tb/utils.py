import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def init_clock(dut, period_ns=10):
    """Initialize clock signal for DUT."""
    clock = Clock(dut.clk, period_ns, units="ns")
    _ = cocotb.start_soon(clock.start())
