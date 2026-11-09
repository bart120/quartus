# scripts/quartus_build.tcl – exécuté par : quartus_sh -t scripts/quartus_build.tcl
# Crée le projet à partir des sources versionnées, puis compile (synthèse, fitter,
# assembleur, analyse de timing). Les fichiers .qpf/.qsf générés ne sont pas versionnés.
load_package flow

if {[info exists ::env(NB_THREADS)]} { set nb $::env(NB_THREADS) } else { set nb 2 }

project_new uart_fifo -overwrite
set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY top
set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
set_global_assignment -name VHDL_FILE rtl/fifo_sync.vhd
set_global_assignment -name VERILOG_FILE rtl/uart_tx.v
set_global_assignment -name VHDL_FILE rtl/top.vhd
set_global_assignment -name SDC_FILE constraints/de10lite.sdc
set_global_assignment -name NUM_PARALLEL_PROCESSORS $nb
set_parameter -name CLK_HZ 50000000
source constraints/de10lite_pins.tcl
execute_flow -compile
project_close
