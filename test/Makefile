SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../src/project.v
VERILOG_SOURCES += $(PWD)/../src/wake_ctrl_v2.v
TOPLEVEL = tt_um_sreemathesh_wake_ctrl
MODULE = test

include $(shell cocotb-config --makefiles)/Makefile.sim
