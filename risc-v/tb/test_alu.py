import enum

import cocotb
from cocotb.triggers import Timer
from cocotb.runner import get_runner


class ALU_OP(enum.IntEnum):
    ADD = 0
    SUB = 1
    SLL = 2
    SLT = 3
    SLTU = 4
    XOR = 5
    SRL = 6
    SRA = 7
    OR = 8
    AND = 9
    BEQ = 10
    BNE = 11
    BLT = 12
    BGE = 13
    BLTU = 14
    BGEU = 15


@cocotb.test()
async def test_add(dut):
    dut.alu_in1.value = 5
    dut.alu_in2.value = 3
    dut.alu_control.value = ALU_OP.ADD
    await Timer(1, units="ns")
    assert dut.alu_result.value == 8


@cocotb.test()
async def test_sub(dut):
    dut.alu_in1.value = 5
    dut.alu_in2.value = 3
    dut.alu_control.value = ALU_OP.SUB
    await Timer(1, units="ns")
    assert dut.alu_result.value == 2


@cocotb.test()
async def test_and(dut):
    dut.alu_in1.value = 5
    dut.alu_in2.value = 3
    dut.alu_control.value = ALU_OP.AND
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_or(dut):
    dut.alu_in1.value = 5
    dut.alu_in2.value = 3
    dut.alu_control.value = ALU_OP.OR
    await Timer(1, units="ns")
    assert dut.alu_result.value == 7


@cocotb.test()
async def test_xor(dut):
    dut.alu_in1.value = 5
    dut.alu_in2.value = 3
    dut.alu_control.value = ALU_OP.XOR
    await Timer(1, units="ns")
    assert dut.alu_result.value == 6


@cocotb.test()
async def test_sll(dut):
    dut.alu_in1.value = 0b0001
    dut.alu_in2.value = 2
    dut.alu_control.value = ALU_OP.SLL
    await Timer(1, units="ns")
    assert dut.alu_result.value == 0b0100


@cocotb.test()
async def test_srl(dut):
    dut.alu_in1.value = 0xFFFF_FFF8  # 32-bit representation of -8, but should be treated as unsigned
    dut.alu_in2.value = 3
    dut.alu_control.value = ALU_OP.SRL
    await Timer(1, units="ns")
    assert dut.alu_result.value == (0xFFFF_FFF8 >> 3)  # == 536870911


@cocotb.test()
async def test_sra(dut):
    dut.alu_in1.value = -8 & 0xFFFFFFFF  # simulate 32-bit signed
    dut.alu_in2.value = 2
    dut.alu_control.value = ALU_OP.SRA
    await Timer(1, units="ns")
    assert dut.alu_result.value == (-8 >> 2) & 0xFFFFFFFF


@cocotb.test()
async def test_slt(dut):
    dut.alu_in1.value = -1 & 0xFFFFFFFF
    dut.alu_in2.value = 1
    dut.alu_control.value = ALU_OP.SLT
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_sltu(dut):
    dut.alu_in1.value = 1
    dut.alu_in2.value = 2
    dut.alu_control.value = ALU_OP.SLTU
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_beq(dut):
    dut.alu_in1.value = 123
    dut.alu_in2.value = 123
    dut.alu_control.value = ALU_OP.BEQ
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_bne(dut):
    dut.alu_in1.value = 1
    dut.alu_in2.value = 2
    dut.alu_control.value = ALU_OP.BNE
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_blt(dut):
    dut.alu_in1.value = -4 & 0xFFFFFFFF
    dut.alu_in2.value = 0
    dut.alu_control.value = ALU_OP.BLT
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_bge(dut):
    dut.alu_in1.value = 10
    dut.alu_in2.value = 10
    dut.alu_control.value = ALU_OP.BGE
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_bltu(dut):
    dut.alu_in1.value = 10
    dut.alu_in2.value = 20
    dut.alu_control.value = ALU_OP.BLTU
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


@cocotb.test()
async def test_bgeu(dut):
    dut.alu_in1.value = 20
    dut.alu_in2.value = 10
    dut.alu_control.value = ALU_OP.BGEU
    await Timer(1, units="ns")
    assert dut.alu_result.value == 1


def test_register_file():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=["../rtl/types.sv", "../rtl/alu.sv"],
        hdl_toplevel="alu",
        build_dir="sim_build/alu/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
    )
    runner.test(
        hdl_toplevel="alu",
        test_module="test_alu",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
