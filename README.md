# W-Seminar: Physik der Funkübertragung mit LoRa-CSS

Die Arbeit liegt als `arbeit.pdf` vor. `arbeit/` enthält den eigenständig
baubaren Typst-Quelltext einschließlich Abbildungen, Listings und Bibliografie.

```sh
python3 scripts/compile.py
```

Es gibt eine PDF-Ausgabe: `arbeit.pdf`. Der Build lädt keine Projektdaten nach.
Nach beabsichtigten Änderungen an Literatur, Listings oder Ergebnisgrafiken
werden die lokalen Kopien zuvor mit `python3 scripts/export_arbeit.py` aktualisiert.

## Begleitdateien

- `tools/`: CSS-Modell, Kampagnen, Kontrollfälle und gespeicherte Rohzählungen.
- `auswertung/`: Rust-Werkzeug für S11, Impedanz, VSWR und Datenimport.
- `css-wasm/`: eigenständiger Rust-Rechenkern für die CSS-Simulation und sein lokales WASM-npm-Paket.
- `frontend/`: Next.js-Begleitwebsite mit interaktiver Rust/WASM-Simulation; Start und Build in `frontend/README.md`.
- `scripts/`: Aufnahme, Reproduktion der Auswertung und Gesamtprüfung.
- `daten/`: serielle Originalantworten, Touchstone, Metadaten und benötigte Auswertungen.
- `nachweise/`: Aufnahmelisten, eingefrorener Markerabgleich und Prüfbericht.
- `recherche/QUELLEN-ENDPRUEFUNG.md`: kompakte Zuordnung der verwendeten Literatur.
- `literatur.bib`: Literaturpool; die tatsächlich zitierten Einträge werden gruppiert ausgegeben.

Buchfotos, die alte Rust-Fassung, Lernunterlagen, frühere Aufgabenlisten und
zusätzliche PDF-/Plotkopien gehören nicht zu dieser Projektfassung. Die Bücher
bleiben regulär zitierte externe Quellen; lokale Scans sind keine Build-Abhängigkeit.
Die Rohmesswerte und der Nachweis des Geräteabgleichs bleiben erhalten.

## Prüfen

```sh
UV_CACHE_DIR=/tmp/wseminar-uv-cache uv sync --locked --project tools
MPLCONFIGDIR=/tmp/wseminar-matplotlib tools/.venv/bin/python scripts/check_gesamt.py --output /tmp/wseminar-pruefung
```

Der Prüflauf arbeitet in einer temporären Kopie und verwendet ausschließlich
`auswertung/`. Er umfasst Python- und Rust-Tests, Format-/Lintprüfung, die
Neurechnung aller 135 CSS-Punkte, Theoriebeispiele, 1818 Hauptmesspunkte,
101 Markerpunkte, Originalantworten, Exportkopien, Quellenverweise und den
isolierten Typst-Bau. Compiler und gecachte Cargo-Abhängigkeiten werden benötigt.
Grafiken werden nach ihrem SVG-Inhalt verglichen; numerische Rust-Ausgaben
nach Werten und Statusfeldern, unabhängig von ihrer Dezimalformatierung.

Die ursprünglichen Simulationsprotokolle behalten die damaligen Quellcode-Hashes.
Entscheidend für den aktuellen Code sind die geprüften Ergebnis-Hashes und
vollständig wiederholten Fehlerzählungen. Externe Quellenlektüre, visuelle
PDF-Kontrolle, persönliche Verantwortung und schulische Vorgaben bleiben
separate Prüfungen. Hinweise zur USB-Aufnahme stehen in `tools/NANOVNA.md`.
