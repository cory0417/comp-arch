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


def reset_registers(u_register_file):
    """Reset all registers to 0."""
    for i in range(32):
        u_register_file.registers[i].value = 0


def reset_risc_v(u_risc_v):
    """Reset RISC-V processor."""
    u_risc_v.pc.value = 0
    u_risc_v.state.value = 2  # WAIT_MEM state
    u_risc_v.instr.value = 0
    reset_registers(u_risc_v.u_register_file)


def get_word_from_memory(u_memory, base_address, offset_bytes):
    """Get memory data at given address."""
    memory_arrays = [
        u_memory.mem0,
        u_memory.mem1,
        u_memory.mem2,
        u_memory.mem3,
    ]
    address = int((base_address + offset_bytes)) & 0xFFFFFFFF
    if address >= 2048:
        if (
            address >> 13
        ) == 0x7FFFF:  # Equivalent to checking read_address[31:13] == 19'h7FFFF
            if (
                address >> 2
            ) & 0x7FF == 0x7FF:  # Equivalent to read_address[12:2] == 11'h7FF
                return u_memory.leds.value
            elif (
                address >> 2
            ) & 0x7FF == 0x7FE:  # Equivalent to read_address[12:2] == 11'h7FE
                return u_memory.millis.value
            elif (
                address >> 2
            ) & 0x7FF == 0x7FD:  # Equivalent to read_address[12:2] == 11'h7FD
                return u_memory.micros.value
            else:
                return 0
        else:
            return 0
    else:
        return sum(
            mem_array.memory[address // 4].value << (8 * i)
            for i, mem_array in enumerate(memory_arrays)
        )
