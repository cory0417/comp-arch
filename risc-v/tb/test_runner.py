from test_memory import test_memory
from test_alu import test_alu
from test_register_file import test_register_file
from test_pc_selector import test_pc_selector
from test_imm_extender import test_imm_extender
from test_control import test_control
from test_risc_v import test_risc_v
from test_top import test_top


def test_all():
    test_memory()
    test_alu()
    test_register_file()
    test_pc_selector()
    test_imm_extender()
    test_control()
    test_risc_v()
    test_top()
