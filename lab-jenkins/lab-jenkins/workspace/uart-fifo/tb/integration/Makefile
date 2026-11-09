# Test du top-level complet (FIFO VHDL + UART Verilog) avec cocotb et Icarus Verilog.
# Le VHDL est d'abord traduit en Verilog par GHDL (cible « integration » du Makefile racine).
# La même cible sert à l'acceptance, en remplaçant les sources par la netlist Yosys.
SIM             ?= icarus
TOPLEVEL_LANG    = verilog
VERILOG_SOURCES ?= $(PWD)/../../build/top_synth.v $(wildcard $(PWD)/../../rtl/*.v)
TOPLEVEL         = top
MODULE           = test_top

include $(shell cocotb-config --makefiles)/Makefile.sim
