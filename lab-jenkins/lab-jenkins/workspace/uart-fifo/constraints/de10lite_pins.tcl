# Affectation des broches de la DE10-Lite (sourcé par quartus_build.tcl).
# Sans carte, ces broches servent seulement à obtenir une compilation réaliste.
# À vérifier dans le manuel de la DE10-Lite avant tout essai sur matériel.
set_location_assignment PIN_P11 -to clk          ;# MAX10_CLK1_50
set_location_assignment PIN_B8  -to rst_n        ;# KEY0
set_location_assignment PIN_A8  -to led[0]       ;# LEDR0
set_location_assignment PIN_A9  -to led[1]       ;# LEDR1
set_location_assignment PIN_AB6 -to uart_txd     ;# connecteur Arduino (à vérifier)

foreach p {clk rst_n led[0] led[1] uart_txd} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $p
}
