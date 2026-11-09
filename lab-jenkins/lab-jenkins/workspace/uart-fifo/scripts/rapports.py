#!/usr/bin/env python3
"""Extraction des rapports pour Jenkins.

  python3 scripts/rapports.py quartus            timing et ressources Quartus -> CSV (plugin Plot),
                                                  code de sortie 1 si le timing n'est pas tenu
  python3 scripts/rapports.py warnings <outil>    journal -> JSON natif Warnings NG
                                                  (outil : verilator, vsg, quartus)
"""
import json
import re
import sys
from pathlib import Path

B = Path("build")
B.mkdir(exist_ok=True)


def ecrire(nom, entetes, valeurs):
    (B / nom).write_text(",".join(entetes) + "\n" + ",".join(map(str, valeurs)) + "\n")


# --- Performance (TP 5) ------------------------------------------------------------

def perf_quartus():
    sta = Path("output_files/uart_fifo.sta.summary").read_text()
    blocs = re.findall(r"Type\s*:\s*(.*?)\nSlack\s*:\s*(-?\d+\.\d+)", sta)
    setup = min(float(s) for t, s in blocs if "Setup" in t)      # tracé sur la courbe
    pire = min(float(s) for _, s in blocs)                        # setup, hold, recovery...
    fit = Path("output_files/uart_fifo.fit.summary").read_text()
    le = int(re.search(r"Total logic elements\s*:\s*([\d,]+)", fit).group(1).replace(",", ""))
    reg = int(re.search(r"Total registers\s*:\s*([\d,]+)", fit).group(1).replace(",", ""))
    return setup, pire, le, reg


# --- Avertissements (TP 8) -----------------------------------------------------------

MOTIFS = {
    "verilator": (r"^%Warning-(?P<cat>\w+): (?P<f>[^:]+):(?P<l>\d+):\d+: (?P<msg>.*)",
                  "build/lint-verilator.log"),
    "vsg":       (r"^(?:ERROR|WARNING): (?P<f>\S+?)\((?P<l>\d+)\)(?P<cat>\S+) -- (?P<msg>.*)",
                  "build/lint-vsg.log"),
    "quartus":   (r"^(?:Critical )?Warning \((?P<cat>\d+)\): (?P<msg>.*)$",
                  "build/quartus.log"),
}


def avertissements(outil):
    motif, journal = MOTIFS[outil]
    issues = []
    for ligne in Path(journal).read_text(errors="ignore").splitlines():
        m = re.match(motif, ligne)
        if not m:
            continue
        d = m.groupdict()
        f, l = d.get("f"), d.get("l")
        if not f:                                   # Quartus : « ... at uart_tx.v(42) ... »
            loc = re.search(r"at (\S+)\((\d+)\)", d["msg"])
            f, l = loc.groups() if loc else ("", 0)
        issues.append({"fileName": f, "lineStart": int(l or 0), "category": d["cat"],
                       "type": outil, "message": d["msg"].strip(),
                       "severity": "HIGH" if "ritical" in ligne else "NORMAL"})
    sortie = B / f"warnings_{outil}.json"
    sortie.write_text(json.dumps({"issues": issues}, indent=1, ensure_ascii=False))
    print(f"{outil} : {len(issues)} avertissement(s) -> {sortie}")


if __name__ == "__main__":
    if sys.argv[1] == "warnings":
        avertissements(sys.argv[2])
        sys.exit(0)
    setup, pire, logique, reg = perf_quartus()
    ecrire("timing_quartus.csv", ["Slack setup (ns)"], [setup])
    ecrire("ressources_quartus.csv", ["Logique", "Registres"], [logique, reg])
    print(f"quartus : slack setup = {setup} ns, pire slack = {pire} ns, "
          f"logique = {logique}, registres = {reg}")
    sys.exit(1 if pire < 0 else 0)
