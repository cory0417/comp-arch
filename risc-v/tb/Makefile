TOPLEVEL_LANG = verilog
SIM = verilator

# Set the timescale
export COCOTB_HDL_TIMEPRECISION = 10ns
export COCOTB_HDL_TIMEUNIT = 10ns
export COCOTB_HDL_TIMESCALE = 10ns/10ns

# Set the test module
MODULE = test_top_uart

# Set the top level module
TOPLEVEL = top

# Set build directory
SIM_BUILD = sim_build/top_uart

# Set the Verilog source files
VERILOG_SOURCES = \
    $(shell pwd)/../rtl/types.sv \
    $(shell pwd)/../rtl/control.sv \
    $(shell pwd)/../rtl/pc_selector.sv \
    $(shell pwd)/../rtl/alu.sv \
    $(shell pwd)/../rtl/register_file.sv \
    $(shell pwd)/../rtl/imm_extender.sv \
    $(shell pwd)/../rtl/risc_v.sv \
    $(shell pwd)/../rtl/memory.sv \
    $(shell pwd)/../rtl/uart_clk.sv \
    $(shell pwd)/../rtl/uart_rx.sv \
    $(shell pwd)/../rtl/uart.sv \
    $(shell pwd)/../rtl/uart_fifo.sv \
    $(shell pwd)/../rtl/top.sv

# Set Verilator specific flags
EXTRA_ARGS += --trace --trace-structs
EXTRA_ARGS += --timescale 10ns/10ns
EXTRA_ARGS += '-GINIT_FILE="$(shell pwd)/../prog/rv32i_test"'
EXTRA_ARGS += --threads 4

# Set C++ compiler flags
export CXXFLAGS += -std=c++14

# Include cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim 