# scripts/chemins_critiques.tcl – exécuté par : quartus_sta -t scripts/chemins_critiques.tcl
# Rapport des 10 pires chemins (TP 8) et du pire chemin détaillé.
project_open uart_fifo
create_timing_netlist
read_sdc
update_timing_netlist
report_timing -setup -npaths 10 -detail path_only -file build/chemins_critiques.rpt
report_timing -setup -npaths 1 -detail full_path -file build/timing_quartus.rpt
delete_timing_netlist
project_close
