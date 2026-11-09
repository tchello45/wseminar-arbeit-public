# Werkzeuge zur CSS-Simulation

Alle Befehle aus dem Projektstamm ausführen:

```sh
export UV_CACHE_DIR=/tmp/wseminar-uv-cache
export MPLCONFIGDIR=/tmp/wseminar-matplotlib
uv sync --locked --project tools
uv run --locked --project tools python -m unittest discover -s tools/tests -v
uv run --locked --project tools python -m simulation.kapitel6
```

## Bezug zur Arbeit

- `src/simulation/css.py`: Symbolparameter, Chirp, Sender, FFT-Detektor und
  Frequenzoffset; Grundlage der CSS-Erklärung und der drei Kampagnen.
- `src/simulation/basis.py`: Sample-SNR- und Energiekampagne sowie
  `css-dechirping.svg` für die Arbeit; zusätzlich analytische Dipolreferenzen.
- `src/simulation/offset.py`: rauschfreie Kontrollen bei δ = 0, ±1.
- `src/simulation/offset_campaign.py`: Offsetkampagne mit AWGN und
  analytische Kontrollen gebrochener Offsets.
- `src/simulation/kapitel6.py`: eigenständig ausführbare NumPy-Listings.
  Die identische Kopie `../arbeit/listings/kapitel6.py` wird von Typst gelesen;
  `START`-/`END`-Kommentare sind Abschnittsmarken und müssen erhalten bleiben.
- `tests/test_css.py`: Modellkontrollen und Wiederholung aller 135 gespeicherten
  Kampagnenpunkte mit der Listing-Fassung.

Das Modell ist uncodiertes diskretes CSS mit `f_s = B`, Einheitsleistung und
perfektem Symboltiming. Es untersucht Sample-SNR, E_s/N_0 und unkorrigierten
Frequenzoffset; keine vollständigen LoRa-/ELRS-Pakete oder Funkreichweiten.
Wilson-Intervalle gelten punktweise. Null beobachtete Fehler belegen keine
Fehlerwahrscheinlichkeit null.

## Kampagnen wiederholen

Neue Ausgaben zunächst getrennt von den ursprünglichen Nachweisen speichern:

```sh
uv run --locked --project tools css-simulation --output /tmp/wseminar-awgn
uv run --locked --project tools css-offset --output /tmp/wseminar-offset-kontrollen
uv run --locked --project tools python -m simulation.offset_campaign --output /tmp/wseminar-offset
```

Standardwerte: SF 7–9, B = 125 kHz, 5000 Symbole je Punkt, Batchgröße 256.
Die beiden AWGN-Raster haben 39 und 30 Punkte (Seed 20261103);
die Offsetkampagne hat 66 Punkte (Seed 20261104).
PCG64-Ströme werden je Punkt über `SeedSequence` getrennt. Für identische
Zählungen müssen auch Ziehungsreihenfolge, Batchgröße und NumPy-Version passen.
Die gespeicherten Läufe verwendeten Python 3.13.16, NumPy 2.5.4 und
Matplotlib 3.11.2; Abhängigkeiten stehen in `uv.lock`.

`css-chirp` erzeugt zusätzlich Referenzchirp- und FFT-Grafiken und prüft die
rauschfreie Erkennung aller Symbole. Es schreibt nach `src/simulation/ergebnisse/`.
Weitere Optionen zeigen die jeweiligen `--help`-Aufrufe.

## Ergebnisse und Übernahme in die Arbeit

`src/simulation/ergebnisse/` enthält CSV-Rohzählungen, SVG-/PNG-Grafiken,
ursprüngliche Laufprotokolle mit Prüfsummen und `AUSWERTUNG.md`.
Die Protokolle dokumentieren den damaligen Quellcode; ihre Quellcode-Hashes
ändern sich durch diese Bereinigung, die ursprünglichen Nachweise bleiben erhalten.
Code und Ergebnisse sind KI-gestützt; sie belegen keine persönliche
Implementierungs- oder Verständnisprüfung.

Typst liest Grafiken aus `../arbeit/abbildungen/`. Nach einer beabsichtigten
Neuberechnung müssen die verwendeten SVG-Dateien und ihre Herkunftseinträge
in `../arbeit/abbildungen/quellen.json` gemeinsam aktualisiert werden.

## Grenzen dieser Projektkopie

Die CSS-Werkzeuge unterstützen die numerischen Aussagen der Arbeit direkt.
Dipolreferenz und zusätzliche Chirp-/FFT-Bilder sind ergänzendes Material;
die Arbeit bindet sie derzeit nicht als eigene Abbildungen ein.

Die ergänzenden Programme unter `../scripts/`, die NanoVNA-Anleitung
`NANOVNA.md`, die Protokolltests und die historischen Nachweise wurden aus
dem ursprünglichen Projekt wieder übernommen. Das aktuelle Rust-Werkzeug
liegt ausschließlich unter `../auswertung/` und wird auch von der Gesamtprüfung
verwendet.

Für eine neue USB-Aufnahme benötigt `scripts/nanovna.py` zusätzlich `pyserial`;
es gehört nicht zu den CSS-Abhängigkeiten. Beispiel aus dem Projektstamm:

```sh
uv run --locked --project tools --with pyserial python scripts/nanovna.py ports
```

`scripts/check_gesamt.py` prüft den aktuellen Code durch vollständige Neurechnung.
Die ursprünglichen CSS-Laufprotokolle behalten ihre damaligen Quellcode-Hashes;
die gespeicherten Ergebnis-Hashes und die vollständige Wiederholung der
Fehlerzählungen werden unabhängig davon geprüft.
