# Point d'entrée unique, en local comme dans Jenkins.
BUILD := build
$(shell mkdir -p $(BUILD))

# Paramètres de simulation du top : 10 cycles par bit, message toutes les 20 000 périodes
SIM_GENERICS := -gCLK_HZ=1152000 -gBAUD=115200 -gPERIODE_ENVOI=20000
VERILOG_RTL  := $(wildcard rtl/*.v)

.PHONY: lint test-vhdl coverage test-verilog integration acceptance doc quartus clean

lint:                      # conteneur hdl-sim
	for f in rtl/*.v; do verilator --lint-only -Wall $$f; done 2> $(BUILD)/lint-verilator.log || true
	vsg -f rtl/*.vhd -of syntastic > $(BUILD)/lint-vsg.log || true

test-vhdl:                 # conteneur hdl-sim
	python3 tb/vunit/run.py -p 4 --xunit-xml $(BUILD)/vunit.xml

coverage:                  # le « - » ignore l'échec des tests : le rapport JUnit tranchera
	-python3 tb/vunit/run.py -p 4 --xunit-xml $(BUILD)/vunit.xml
	gcovr --root . coverage_data --filter rtl/ --cobertura $(BUILD)/coverage.xml --txt $(BUILD)/coverage.txt

test-verilog:              # conteneur hdl-sim
	$(MAKE) -C tb/cocotb

# Intégration : GHDL traduit le VHDL en Verilog, puis Icarus simule le top complet
$(BUILD)/top_synth.v: rtl/fifo_sync.vhd rtl/top.vhd
	ghdl --synth --std=08 --out=verilog $(SIM_GENERICS) rtl/fifo_sync.vhd rtl/top.vhd -e top > $@

integration: $(BUILD)/top_synth.v   # conteneur hdl-sim
	$(MAKE) -C tb/integration \
	  VERILOG_SOURCES="$(CURDIR)/$(BUILD)/top_synth.v $(addprefix $(CURDIR)/,$(VERILOG_RTL))" \
	  COCOTB_RESULTS_FILE=$(CURDIR)/$(BUILD)/integration.xml

# Acceptance : netlist de portes produite par Yosys, simulée avec le même test
$(BUILD)/top_netlist.v: $(BUILD)/top_synth.v $(VERILOG_RTL)
	yosys -q -l $(BUILD)/yosys.log -p "read_verilog $(BUILD)/top_synth.v $(VERILOG_RTL); \
	  synth -flatten -top top; stat; write_verilog -noattr $@"

acceptance: $(BUILD)/top_netlist.v  # conteneur hdl-sim
	$(MAKE) -C tb/integration SIM_BUILD=sim_build_netlist \
	  VERILOG_SOURCES=$(CURDIR)/$(BUILD)/top_netlist.v \
	  COCOTB_RESULTS_FILE=$(CURDIR)/$(BUILD)/acceptance.xml

doc:                       # conteneur hdl-sim
	doxygen Doxyfile > /dev/null
	yosys -q -p "read_verilog rtl/uart_tx.v; prep -top uart_tx; show -format svg -prefix $(BUILD)/doc/uart_tx"

quartus:                   # conteneur quartus
	quartus_sh -t scripts/quartus_build.tcl | tee $(BUILD)/quartus.log
	quartus_sta -t scripts/chemins_critiques.tcl

clean:
	rm -rf $(BUILD) vunit_out coverage_data tb/*/sim_build* tb/*/results.xml tb/*/__pycache__ \
	  db incremental_db output_files simulation
