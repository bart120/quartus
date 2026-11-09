// materiel-tp8/clignoteur.v – code VOLONTAIREMENT piégé pour le TP 8 (qualité du code).
// À copier dans rtl/ et à instancier dans top.vhd (voir LISEZMOI.txt).
module clignoteur (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] mode,
    output reg        led
);
    reg [23:0] compteur;
    reg        inutilise;              // signal jamais utilisé
    reg        rapide;

    // TODO : rendre la période de clignotement paramétrable
    always @(posedge clk) begin
        if (rst)
            compteur = 0;              // affectation bloquante en logique séquentielle
        else
            compteur = compteur + 1;
    end

    // FIXME : case incomplet, un latch est inféré sur « rapide »
    always @(*) begin
        case (mode)
            2'b00: rapide = 1'b0;
            2'b01: rapide = 1'b1;
        endcase
    end

    always @(posedge clk)
        led <= rapide ? compteur[20] : (compteur == 8'hFF);   // largeurs différentes
endmodule
