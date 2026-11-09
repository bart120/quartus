# Laboratoire – Formation Jenkins, intégration continue FPGA (Quartus)

Tout tourne dans Docker. Rien d'autre à installer sur le poste.

## Prérequis sur chaque poste

- PC x86 (pas de Mac Apple Silicon : Quartus n'existe qu'en x86), Linux ou Windows avec WSL2
- 16 Go de RAM, environ 60 Go de disque libre
- Docker avec Compose (Docker Engine sous Linux, Docker Desktop sous Windows)
- Accès internet vers Docker Hub, les dépôts Ubuntu et PyPI, et le site Intel (téléchargement de Quartus)

## Contenu

| Élément | Rôle |
| --- | --- |
| `docker-compose.yml` | Jenkins, Gitea, Mailpit, agent `hdl-sim` ; agent Quartus et Apache activés par profil |
| `images/hdl-sim/` | Agent de simulation libre : GHDL (backend GCC), Icarus, Verilator, Yosys, VUnit, cocotb, VSG, Doxygen, gcovr |
| `images/quartus/` | Agent Quartus Prime Lite (MAX 10), à construire avec les installeurs Intel |
| `images/jenkins/` | Image Jenkins personnalisée du TP 2 (plugins figés) |
| `apache/` | Reverse proxy du TP 2 |
| `workspace/uart-fifo/` | Projet fil rouge, à pousser dans Gitea |
| `corrige/Jenkinsfile` | Corrigé du TP 9 |

## Démarrage (jour 1, 9h00)

```bash
cp .env.exemple .env
docker compose up -d --build        # construit hdl-sim (10 à 15 minutes) et démarre le labo
docker compose ps
```

En parallèle, **dès 9h00** : télécharger Quartus Prime Lite et le fichier MAX 10 dans
`images/quartus/installeur/` (voir le `LISEZMOI.txt` de ce dossier).

| Service | Adresse |
| --- | --- |
| Jenkins | http://localhost:8080 |
| Gitea | http://localhost:3000 |
| Mailpit | http://localhost:8025 |
| Jenkins via Apache (TP 2) | http://localhost:8082 |

Mot de passe initial de Jenkins : `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`

## Vérifier le projet à la main

```bash
docker compose exec hdl-sim bash
cd uart-fifo
make lint coverage test-verilog integration acceptance doc
```

Résultat attendu : 3 tests VUnit, 2 tests cocotb, intégration et acceptance réussis,
100 % de lignes couvertes sur `fifo_sync.vhd`.

## Cibles du Makefile

| Cible | Agent | Ce qu'elle fait |
| --- | --- | --- |
| `lint` | hdl-sim | Verilator (`-Wall`) sur `rtl/*.v`, VSG sur `rtl/*.vhd` |
| `test-vhdl` / `coverage` | hdl-sim | Tests VUnit de la FIFO ; `coverage` ajoute le rapport Cobertura |
| `test-verilog` | hdl-sim | Tests cocotb de l'émetteur UART (Icarus) |
| `integration` | hdl-sim | GHDL traduit le VHDL en Verilog, cocotb vérifie que le top émet `HELLO\r\n` |
| `acceptance` | hdl-sim | Netlist de portes produite par Yosys, simulée avec le même test |
| `doc` | hdl-sim | Documentation Doxygen du VHDL et schéma SVG de `uart_tx` |
| `quartus` | quartus | Compilation complète MAX 10 et rapport des chemins critiques |

`scripts/rapports.py` produit les CSV de timing et de ressources (plugin Plot) et convertit
les avertissements Verilator, VSG et Quartus au format de Warnings NG.

## Agent Quartus (jour 1, après-midi)

```bash
docker build -t formation/quartus images/quartus      # 30 à 60 minutes
docker run --rm formation/quartus quartus_sh --version
# créer le nœud « quartus » dans Jenkins, copier son secret dans .env, puis :
docker compose --profile quartus up -d
```

## Écarts avec le document des TP

- **Pas de Questa** (pas de licence) : l'intégration et l'acceptance utilisent GHDL, Icarus,
  Yosys et cocotb sur l'agent `hdl-sim`. Cibles `integration` et `acceptance`.
- Le stage d'acceptance simule la netlist **post-synthèse Yosys** (portes génériques), et
  vérifie les critères de livraison à partir des rapports Quartus.
- `tb/vunit/run.py` utilise `VUnit.from_argv(compile_builtins=False)` (VUnit 4.7).
- Les broches de `constraints/de10lite_pins.tcl` ne servent qu'à compiler : à vérifier dans
  le manuel de la DE10-Lite avant tout essai sur carte.
- Le code piégé du TP 8 est dans `workspace/uart-fifo/materiel-tp8/`, avec sa notice.
