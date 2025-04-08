import cocotb
from cocotb.triggers import Timer
from cocotb.runner import get_runner


@cocotb.test()
async def test_i_imm(dut):
    dut.instr.value = 0b00000000001000000000000010010011  # addi x1, x0, 2
    imm_ext = 0b0000_0000_0000_0000_0000_0000_0000_0010  # {{20{instr[31]}}, instr[31:20]}
    await Timer(1, units="ns")
    assert dut.imm_ext.value == imm_ext


@cocotb.test()
async def test_s_imm(dut):
    dut.instr.value = 0b00000000000100000000010100100011  # sb x1, 10(x0)
    imm_ext = 0b0000_0000_0000_0000_0000_0000_0000_1010  # {{20{instr[31]}}, instr[31:25], instr[11:7]}
    await Timer(1, units="ns")
    assert dut.imm_ext.value == imm_ext


@cocotb.test()
async def test_b_imm(dut):
    dut.instr.value = 0b11111110000000001000011011100011  # beq x1, x0, -20
    imm_ext = 0b1111_1111_1111_1111_1111_1111_1110_1100  # {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}
    await Timer(2, units="ns")
    assert dut.imm_ext.value == imm_ext


@cocotb.test()
async def test_j_imm(dut):
    dut.instr.value = 0b11111111010111111111000001101111  # jal x0, -12
    imm_ext = 0b1111_1111_1111_1111_1111_1111_1111_0100  # {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}
    await Timer(1, units="ns")
    assert dut.imm_ext.value == imm_ext


@cocotb.test()
async def test_u_imm(dut):
    dut.instr.value = 0b00000000000000001110000010110111  # lui x1, 14
    imm_ext = 0b00000000000000001110000000000000  # {instr[31:12], {12{'0}}}
    await Timer(1, units="ns")
    assert dut.imm_ext.value == imm_ext


def test_imm_extender():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=["../rtl/types.sv", "../rtl/imm_extender.sv"],
        hdl_toplevel="imm_extender",
        build_dir="sim_build/imm_extender/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
    )
    runner.test(
        hdl_toplevel="imm_extender",
        test_module="test_imm_extender",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
