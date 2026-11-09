# Horloge 50 MHz de la DE10-Lite (MAX10_CLK1_50)
create_clock -name clk -period 20.000 [get_ports clk]
derive_clock_uncertainty

# Entrées et sorties lentes, non contraintes en timing
set_false_path -from [get_ports rst_n]
set_false_path -to   [get_ports {uart_txd led[*]}]
