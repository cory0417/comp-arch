import enum

import cocotb
from cocotb.triggers import Timer
from cocotb.runner import get_runner
from test_alu import ALUOp


class InstructionType(enum.IntEnum):
    U_TYPE = 0
    J_TYPE = 1
    R_TYPE = 2
    I_TYPE = 3
    S_TYPE = 4
    B_TYPE = 5


class PCSrc(enum.IntEnum):
    OP_JALR = 0
    OP_JAL = 1
    OP_BRANCH = 2
    OP_DEFAULT = 3  # PC + 4


class RegWriteDataSrc(enum.IntEnum):
    ALU = 0
    IMM = 1
    PC_IMM = 2
    PC_4 = 3
    MEM_READ = 4
    NONE = 5  # No writeback


class ALUOperandSrc(enum.IntEnum):
    RS1_RS2 = 0  # Includes default cases where ALU isn't used as well
    RS1_IMM = 1


@cocotb.test()
async def test_instruction_type_parse(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.instruction_type.value == InstructionType.I_TYPE


@cocotb.test()
async def test_pc_src(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.pc_src.value == PCSrc.OP_DEFAULT


@cocotb.test()
async def test_reg_write_data_src(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.result_src.value == RegWriteDataSrc.ALU


@cocotb.test()
async def test_reg_write_data_src(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.result_src.value == RegWriteDataSrc.ALU


@cocotb.test()
async def test_alu_control(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.result_src.value == ALUOp.ADD


@cocotb.test()
async def test_alu_operand_src(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.alu_src.value == ALUOperandSrc.RS1_IMM


@cocotb.test()
async def test_alu_operand_src(dut):
    instr = 0b00000000001000000000000010010011  # addi x1, x0, 2
    # Extract fields from instruction
    opcode = instr & 0b1111111  # instr[0:7]
    funct3 = (instr >> 12) & 0b111  # instr[12:15]
    funct7_5 = instr >> 30 & 0b1  # instr[30]; unused in addi

    dut.op.value = opcode
    dut.funct3.value = funct3
    dut.funct7_5.value = funct7_5

    await Timer(1, units="ns")
    assert dut.alu_src.value == ALUOperandSrc.RS1_IMM


def test_control():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=["../rtl/types.sv", "../rtl/control.sv"],
        hdl_toplevel="control",
        build_dir="sim_build/control/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
    )
    runner.test(
        hdl_toplevel="control",
        test_module="test_control",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
