# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/permutation.v
TOPLEVEL = permutation
MODULE = test_permutation

include $(shell cocotb-config --makefiles)/Makefile.sim
