from pathlib import Path

import cocotb
from cocotb.triggers import ClockCycles, Timer, RisingEdge, FallingEdge
from cocotb.types import Logic

from utils import (
    init_clock,
    write_program_to_memory,
    load_hex_from_txt,
    reset_risc_v,
    get_word_from_memory,
    get_register_value,
)
from functools import partial

parent_dir = Path(__file__).parent


@cocotb.test()
async def test_uart_rx(dut):
    init_clock(dut.clk, period_ns=80)  # 12.5 MHz clock period
    init_clock(
        dut.clk_24mhz, period_ns=40
    )  # 25 MHz clock period    dut.uart_reset_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.uart_reset_n.value = 1
    await ClockCycles(dut.clk, 1)

    data = 0b10110101  # Example data to be received

    dut.rx.value = Logic(0)  # Start bit
    await ClockCycles(dut.uart_baud_clk, 8)  # Wait for 1 start bit time
    for i in range(8):
        dut.rx.value = Logic(bool(data & (1 << i)))  # Set the data bit
        await ClockCycles(dut.uart_baud_clk, 8)
    dut.rx.value = Logic(1)
    assert dut.uart_rx_data.value == data

    await ClockCycles(dut.uart_baud_clk, 5)  # Stop bit
    await Timer(10, units="ns")  # Wait for the stop bit to be processed
    assert dut.uart_rx_state.value == 0  # IDLE state
    await ClockCycles(dut.uart_baud_clk, 4)  # Stop bit

    # Try another data
    data = 0x0F
    dut.rx.value = Logic(0)
    await ClockCycles(dut.uart_baud_clk, 8)
    for i in range(8):
        dut.rx.value = Logic(bool(data & (1 << i)))
        await ClockCycles(dut.uart_baud_clk, 8)
    dut.rx.value = Logic(1)
    await ClockCycles(dut.uart_baud_clk, 5)
    assert dut.uart_rx_data.value == data
    await Timer(10, units="ns")
    assert dut.uart_rx_state.value == 0


# @cocotb.test()
async def test_uart_full_fifo(dut):
    init_clock(dut.clk, period_ns=80)  # 12.5 MHz clock period
    init_clock(dut.clk_24mhz, period_ns=40)  # 25 MHz clock period
    dut.uart_reset_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.uart_reset_n.value = 1
    await ClockCycles(dut.clk, 1)

    for i in range(512):
        data = (8 - i % 8) & 0xFF

        dut.rx.value = Logic(0)  # Start bit
        await ClockCycles(dut.uart_baud_clk, 8)  # Wait for 1 start bit time
        for j in range(8):
            dut.rx.value = Logic(bool(data & (1 << j)))  # Set the data bit
            await ClockCycles(dut.uart_baud_clk, 8)
        dut.rx.value = Logic(1)
        assert dut.uart_rx_data.value == data

        await ClockCycles(dut.uart_baud_clk, 5)  # Stop bit
        await Timer(10, units="ns")  # Wait for the stop bit to be processed
        assert dut.uart_rx_state.value == 0  # IDLE state
        await ClockCycles(dut.uart_baud_clk, 4)  # Stop bit

    await RisingEdge(dut.rx_fifo_full_ack)
    assert dut.uart_rx_fifo_full.value == 1
    await RisingEdge(dut.clk)
    assert dut.uart_rx_fifo_full.value == 0


@cocotb.test()
async def test_uart_reprogram(dut):
    init_clock(dut.clk, period_ns=80)  # 12.5 MHz clock period
    init_clock(dut.clk_24mhz, period_ns=40)  # 25 MHz clock period
    dut.uart_reset_n.value = 0
    await RisingEdge(dut.clk)
    dut.uart_reset_n.value = 1
    await RisingEdge(dut.clk)

    # From `test_unconditional_jumps`
    prog = [
        0x00A06093,  # ori x1 x0 10
        0x00C0016F,  # jal x2 12
        0x00508193,  # addi x3 x1 5
        0x0080006F,  # jal x0 8
        0x00010267,  # jalr x4 x2 0
        0x40118233,  # sub x4 x3 x1
    ]
    # Convert program to array of 8-bit values
    prog_bytes = []
    for word in prog:
        for i in range(4):
            prog_bytes.append((word >> (i * 8)) & 0xFF)

    # Fill program with 0s to 512 bytes
    prog_bytes += [0x00] * (512 - len(prog_bytes))
    assert len(prog_bytes) == 512

    # Load the program into memory by sending to UART
    for i, byte in enumerate(prog_bytes):
        dut.rx.value = Logic(0)  # Start bit
        await ClockCycles(dut.uart_baud_clk, 8)  # Wait for 1 start bit time
        for j in range(8):
            dut.rx.value = Logic(bool(byte & (1 << j)))  # Set the data bit
            await ClockCycles(dut.uart_baud_clk, 8)
        dut.rx.value = Logic(1)
        assert dut.uart_rx_data.value == byte

        await ClockCycles(dut.uart_baud_clk, 5)  # Stop bit
        await Timer(10, units="ns")  # Wait for the stop bit to be processed
        assert dut.uart_rx_state.value == 0  # IDLE state
        await ClockCycles(dut.uart_baud_clk, 4)  # Stop bit
        print(f"Sent {i}th byte: {byte:#04x}")

    # await RisingEdge(dut.rx_fifo_full_ack)
    # assert dut.rx_fifo_full.value == 1
    # assert dut.cpu_reset_n.value == 0
    # await RisingEdge(dut.clk)
    # await Timer(10, units="ns")
    # assert dut.rx_fifo_full.value == 0
    # assert dut.cpu_reset_n.value == 1
    await FallingEdge(dut.cpu_reset_n)

    await ClockCycles(dut.clk, 2)

    await ClockCycles(dut.clk, 12)
    assert dut.registers[4].value == 0x00000005
    assert dut.registers[3].value == 0x0000000F
    assert dut.registers[2].value == 0x00000008
    assert dut.registers[1].value == 0x0000000A
