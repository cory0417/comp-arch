import pathlib

from cocotb.runner import get_runner

parent_dir = pathlib.Path(__file__).parent


def test_top():
    runner = get_runner("icarus")
    runner.build(
        verilog_sources=[
            "../rtl/types.sv",
            "../rtl/control.sv",
            "../rtl/pc_selector.sv",
            "../rtl/alu.sv",
            "../rtl/register_file.sv",
            "../rtl/imm_extender.sv",
            "../rtl/risc_v.sv",
            "../rtl/memory.sv",
            "../rtl/top.sv",
        ],
        hdl_toplevel="top",
        build_dir="sim_build/top/",
        always=True,
        clean=True,
        verbose=True,
        timescale=("1ns", "1ns"),
        build_args=[
            f'-Pmemory.INIT_FILE="{parent_dir}/rv32i_test"'
        ],  # Doing the regular parameters dict doesn't seem to work for initial block
    )
    runner.test(
        hdl_toplevel="top",
        test_module="test_top",
        hdl_toplevel_lang="verilog",
        results_xml=None,
    )
