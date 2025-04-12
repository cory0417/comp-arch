import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from pathlib import Path


def init_clock(dut, period_ns=10):
    """Initialize clock signal for DUT."""
    clock = Clock(dut.clk, period_ns, units="ns")
    _ = cocotb.start_soon(clock.start())


def write_program_to_memory(dut, data: list[hex]):
    """Write to memory."""
    memory_arrays = [
        dut.u_memory.mem0,
        dut.u_memory.mem1,
        dut.u_memory.mem2,
        dut.u_memory.mem3,
    ]
    for i, word in enumerate(data):
        for j, mem_array in enumerate(memory_arrays):
            mem_array.memory[i].value = (word >> (8 * j)) & 0xFF

    # Pad the rest of the memory with 0s
    if len(data) < 2048:
        for i in range(len(data), 2048):
            for j, mem_array in enumerate(memory_arrays):
                mem_array.memory[i].value = 0x00


def load_hex_from_txt(path: Path) -> list[hex]:
    """Load hex file from txt file."""
    if not path.exists():
        raise FileNotFoundError(f"File {path} does not exist.")

    # Assumes that each line is a 4-byte hex number in string format
    with open(path, "r") as f:
        return [int(line.strip(), 16) for line in f]
