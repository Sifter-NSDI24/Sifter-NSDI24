# Makefile

# defaults
SIM ?= ghdl
GHDL_ARGS += --std=08
SIM_ARGS += --ieee-asserts=disable
SIM_ARGS += --wave=wave.ghw

TOPLEVEL_LANG ?= vhdl
COCOTB_HDL_TIMEUNIT = 1ps
COCOTB_HDL_TIMEPRECISION = 1ps

VHDL_SOURCES += ../src/constants.vhd
VHDL_SOURCES += ../src/fin_time_arr_bhv.vhd
VHDL_SOURCES += ../src/dma_buf_bhv.vhd
VHDL_SOURCES += ../src/xpm_fifo_sync.vhd
VHDL_SOURCES += ../src/fifo_wrapper.vhd
VHDL_SOURCES += ../src/pifo.vhd
VHDL_SOURCES += ../src/pifo_wrapper.vhd
VHDL_SOURCES += ../src/sifter_level.vhd
VHDL_SOURCES += ../src/sifter_lvl_top.vhd
VHDL_SOURCES += ../src/sifter_test_wrapper.vhd

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = sifter_test_wrapper

# MODULE is the basename of the Python test file
MODULE = fixed,rand

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
