from test_memory import test_memory
from test_alu import test_alu
from test_register_file import test_register_file
from test_pc_selector import test_pc_selector
from test_imm_extender import test_imm_extender


def test_all():
    test_memory()
    test_alu()
    test_register_file()
    test_pc_selector()
    test_imm_extender()
