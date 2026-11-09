#!/usr/bin/env python3
"""Exportiere die verwendeten Ergebnisgrafiken in den lokalen Abbildungsordner.

Nach einer Neuberechnung ausdrücklich ausführen. Der Typst-/PDF-Bau liest nur
arbeit/abbildungen und benötigt für Bilder keinen Zugriff auf die Ergebnisordner.
Vorhandene lokale Abbildungen werden durch die zugeordneten Originale ersetzt.
Die beiden PCB-Skizzen erzeugt check_pcb_entwurf.py bereits direkt am Zielort.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    'css-dechirping.svg': 'tools/src/simulation/ergebnisse/css-dechirping.svg',
    'css-awgn.svg': 'tools/src/simulation/ergebnisse/css-awgn.svg',
    'css-awgn-energy.svg': 'tools/src/simulation/ergebnisse/css-awgn-energy.svg',
    'css-offset-awgn.svg': 'tools/src/simulation/ergebnisse/css-offset-awgn.svg',
    'nanovna-aufbau.svg': 'daten/auswertung/kapitel7/aufbau.svg',
    'nanovna-standards.svg': 'daten/auswertung/kapitel7/standards.svg',
    'nanovna-kabel.svg': 'daten/auswertung/kapitel7/kabel.svg',
    'nanovna-geraeteabgleich.png': 'nachweise/RS02-geraet-2026-11-05/screen-frozen.png',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    destination = root/'arbeit/abbildungen'
    # Check every source before overwriting any destination.
    for relative in SOURCES.values():
        if not (root/relative).is_file():
            raise FileNotFoundError(root/relative)
    destination.mkdir(parents=True, exist_ok=True)
    records = {}
    for name, relative in SOURCES.items():
        source, target = root/relative, destination/name
        if not target.exists() or source.read_bytes() != target.read_bytes():
            shutil.copyfile(source, target)
        records[name] = {'source': relative, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
    (destination/'quellen.json').write_text(json.dumps(records, indent=2, ensure_ascii=False)+'\n')
    print(f'{len(records)} Ergebnisabbildungen nach {destination} exportiert.')


if __name__ == '__main__':
    main()
