# Prüfung der aktuellen Projektfassung

Der aktuelle Prüfweg ist `scripts/check_gesamt.py`. Er verwendet ausschließlich
das Rust-Crate `auswertung/` und schreibt neue Berichte nach dem mit `--output`
angegebenen Verzeichnis. Der kompakte aktuelle Bericht liegt nach erfolgreicher
Prüfung unter `nachweise/pruefung.json`.

```sh
MPLCONFIGDIR=/tmp/wseminar-matplotlib tools/.venv/bin/python scripts/check_gesamt.py --output /tmp/wseminar-pruefung
```

Geprüft werden Softwaretests, Rust-Format und Clippy, Grundlagen- und
PCB-Rechenbeispiele, 135 CSS-Punkte mit 675000 Symbolversuchen,
1818 NanoVNA-Hauptmesspunkte und der zusätzliche eingefrorene Marker-Sweep
mit 101 Punkten. Die aktuellen Rust-Ausgaben werden sowohl mit Python als
auch mit den gespeicherten CSV-Werten verglichen. Ein numerischer Vergleich
verwendet rtol = atol = 1e-9; Statusfelder müssen unverändert sein.

Die SVG-Reproduktion, lokale Export-Herkunft, alle Literaturverweise und der
isolierte Typst-Bau werden ebenfalls geprüft.
Die ursprünglichen CSS-Laufprotokolle werden nicht auf neue Code-Hashes umgeschrieben.

Diese Prüfungen sind keine neue Hardwaremessung und bestimmen keine absolute
VNA-Genauigkeit. Die externe Quellenlektüre und die gerenderte PDF-Prüfung
werden getrennt durchgeführt. Vor Abgabe sind persönliche Inhaltsprüfung,
Schule und Kursleitung, erlaubter Umfang, Hilfsmittelregelung sowie Datum und
Unterschrift der Erklärung zu bestätigen.
