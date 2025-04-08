import cocotb
from cocotb.triggers import Timer
from cocotb.runner import get_runner


@cocotb.test()
async def test_pc_jalr(dut):
    dut.pc_src.value = 0  # OP_JALR; imm + rs1
    dut.rs1.value = 10
    dut.imm.value = 5
    dut.alu_result.value = 1
    dut.pc.value = 0x2000
    await Timer(1, units="ns")
    assert dut.pc_next.value == 5 + 10


@cocotb.test()
async def test_pc_jal(dut):
    dut.pc_src.value = 1  # OP_JAL; imm + PC
    dut.rs1.value = 10
    dut.imm.value = 5
    dut.alu_result.value = 1
    dut.pc.value = 0x2000
    await Timer(1, units="ns")
    assert dut.pc_next.value == 0x2000 + 5


@cocotb.test()
async def test_pc_branch_true(dut):
    dut.pc_src.value = 2  # OP_BRANCH; imm + PC OR PC + 4
    dut.rs1.value = 10
    dut.imm.value = 5
    dut.alu_result.value = 1
    dut.pc.value = 0x2000
    await Timer(1, units="ns")
    assert dut.pc_next.value == 0x2000 + 5


@cocotb.test()
async def test_pc_branch_false(dut):
    dut.pc_src.value = 2  # OP_BRANCH; imm + PC OR PC + 4
    dut.rs1.value = 10
    dut.imm.value = 5
    dut.alu_result.value = 0
    dut.pc.value = 0x2000
    await Timer(1, units="ns")
    assert dut.pc_next.value == 0x2000 + 4


@cocotb.test()
async def test_pc_plus_4(dut):
    dut.pc_src.value = 3  # default; PC + 4
    dut.rs1.value = 10
    dut.imm.value = 5
    dut.alu_result.value = 1
    dut.pc.value = 0x2000
    await Timer(1, units="ns")
    assert dut.pc_next.value == 0x2000 + 4


def test_pc_selector():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=["../rtl/pc_selector.sv"],
        hdl_toplevel="pc_selector",
        build_dir="sim_build/pc_selector/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
    )
    runner.test(
        hdl_toplevel="pc_selector",
        test_module="test_pc_selector",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
