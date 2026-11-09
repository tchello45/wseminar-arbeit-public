#!/usr/bin/env python3
"""Aktualisiere lokale Kopien für den eigenständig baubaren Ordner arbeit/.

Nur nach beabsichtigten Änderungen an Ergebnissen/Code/Literatur ausführen.
Der Typst-Bau verwendet ausschließlich vorhandene Dateien innerhalb arbeit/.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    'listings/css-wasm.rs': 'css-wasm/src/lib.rs',
    'listings/kapitel6.py': 'tools/src/simulation/kapitel6.py',
    'tabellen/nanovna-zentrum.typ': 'daten/auswertung/kapitel7/tabelle.typ',
    'literatur.bib': 'literatur.bib',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    root = parser.parse_args().root.resolve()
    for relative in SOURCES.values():
        if not (root/relative).is_file():
            raise FileNotFoundError(root/relative)
    subprocess.run([sys.executable, str(ROOT/'scripts/export_abbildungen.py'),
                    '--root', str(root)], check=True)
    records = {}
    for name, relative in SOURCES.items():
        target, source = root/'arbeit'/name, root/relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or target.read_bytes() != source.read_bytes():
            shutil.copyfile(source, target)
        records[name] = {'source': relative, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
    (root/'arbeit/export-quellen.json').write_text(json.dumps(records, indent=2, ensure_ascii=False)+'\n')
    print('Listings, Tabelle und Literatur nach arbeit/ exportiert.')


if __name__ == '__main__':
    main()
