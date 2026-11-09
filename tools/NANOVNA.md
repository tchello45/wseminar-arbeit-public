# NanoVNA-F V2 direkt mit Python

Das Werkzeug ersetzt für die heutigen S11-Reihen die Bedienung von Saver.
Es verwendet das Textprotokoll des **NanoVNA-F V2**, nicht das binäre
S-A-A-2/NanoVNA-V2-Protokoll. Die Firmware wird beim Anschließen abgefragt.
Protokollreferenz: installierter NanoVNA-Saver 0.7.3.post1.dev18,
`Hardware/NanoVNA_F_V2.py`, `NanoVNA.py`, `VNA.py` sowie
[Upstream](https://github.com/NanoVNA-Saver/nanovna-saver).
Die Implementierung ist eigenständig; es wird kein Saver-Modul importiert.

## Start

Alle Befehle aus dem Stamm dieses Projekts. Für USB-Zugriff wird zusätzlich
`pyserial` benötigt; es ist keine Abhängigkeit der CSS-Simulation:

```bash
uv run --locked --project tools --with pyserial python scripts/nanovna.py ports
uv run --locked --project tools --with pyserial python scripts/nanovna.py probe
```

NanoVNA einschalten und mit einem USB-Datenkabel verbinden. Saver muss die
Verbindung freigeben (am einfachsten schließen). `ports` öffnet kein Gerät.
`probe` liest ausschließlich `info`, `version`, `help` und `cal`; es startet
keinen Sweep und verändert keine gespeicherte Kalibrierung. Bei mehreren
USB-Geräten `--port /dev/ttyACM0` explizit angeben. Automatische Auswahl nur
für genau einen USB-Port mit VID:PID 0483:5740; danach Prüfung der Modellantwort.
Die Probendatei wird nicht überschrieben; für erneute Abfragen `--output`
mit einem neuen Dateinamen verwenden.

## Kalibrierung und Referenzebene

**Vor Messungen am Gerät Open/Short/Load für den Messbereich kalibrieren.**
Das Skript übernimmt S11 so, wie es das Gerät liefert. Es erzeugt keine
Softwarekalibrierung, lädt keine Saver-Kalibrierdateien und verändert keine
Korrekturkoeffizienten. Eine nur in Saver angewandte Kalibrierung wird nicht
übernommen. Die gelesene `cal`-Antwort wird dokumentiert, aber nicht als
automatischer Nachweis gültiger Kalibrierung interpretiert.

Für Donnerstag: 2,3–2,5 GHz, 101 Punkte (2 MHz Abstand), Referenzebene am
S11-/CH0-Geräteport, gegebenenfalls mit fest verbleibendem Adapter. Die
Kalibrierung muss zu diesem Bereich und derselben Referenzebene passen.
Kabel erst danach als Prüfling anschließen. CH1/S21 wird nicht benötigt.
Kalibrierung am Kabelende wäre eine eigene getrennte Reihe.

## Messen

Beispielargumente unbedingt durch die **tatsächlichen** Angaben ersetzen:

```bash
uv run --locked --project tools --with pyserial python scripts/nanovna.py series \
  --calibration-note 'OSL am Gerät, 2,3–2,5 GHz, Datum/Uhrzeit …' \
  --reference-plane 'CH0-Geräteport, Adapter …' \
  --setup 'Gerät/Firmware aus probe; Kabelbezeichnung …; Aufbau-Foto …'
```

Der Dialog verlangt `KALIBRIERT`, dann führt er durch Open, Short, Load,
Kabel+Open und Kabel+Short mit jeweils drei getrennten Anschlusswiederholungen.
Bei jedem Schritt vollständig lösen, neu anschließen, Hände weg und Enter.
Mit `q` sauber beenden; vorhandene Exporte bleiben gespeichert.
Für einzelne, im Chat begleitete Anschlüsse `measure --name Open_01` mit
denselben Metadatenargumenten verwenden. Das Werkzeug kann im Terminal von
Codex laufen; physisches Umstecken und Bestätigen erfolgen durch Tilman.

Gespeichert wird unter `daten/nanovna/<Zeitstempel>/<Messung>/`:

- `.s1p`: 50-Ω-Touchstone, Hz, Real-/Imaginärteil, ohne Glättung.
- `.csv`: komplexes S11, Betrag, S11-dB, Phase, Impedanz und VSWR.
- `serial.json`: originale Geräteantworten des Sweeps.
- `metadata.json`: Gerät/Firmware, Referenzebene, Aufbau, Kalibrierungsnotiz,
  Aufnahmezeit und SHA-256 der Touchstone-Datei.
- `abbildung.png/.svg/.pdf`: Smith, S11-dB und Phase.

Eine gemeinsame Vergleichsgrafik entsteht beim Abschluss der Reihe.
Keine Dateien werden absichtlich überschrieben. Der Scan hält das kontinuierliche
Sweep am Gerät an, damit Frequenz- und S11-Arrays zusammengehören. Nach Ende
kann das kontinuierliche Sweep am Gerät wieder aktiviert werden.

## Diagramme und Aussagegrenzen

```bash
uv run --locked --project tools --with pyserial python scripts/nanovna.py plot \
  daten/roh/01.s1p daten/roh/03.s1p --output /tmp/nanovna-vergleich
uv run --locked --project tools --with pyserial python scripts/nanovna.py demo --output /tmp/nanovna-demo
```

`plot` akzeptiert den tatsächlich verwendeten Touchstone-Ausschnitt
`# HZ S RI R 50`. S11-dB ist **20 log10 |Γ|**, kein positiv definiertes
Rückflussdämpfungsmaß. Phase unter |Γ| = 0,001 wird ausgeblendet (Darstellungsregel,
keine ermittelte Gerätegrenze). Phasensprünge bei ±180° werden nicht verbunden.
VSWR bei |Γ| ≥ 1 und singuläre Impedanz werden als leere CSV-Felder ausgegeben.
Werte |Γ| > 1 werden nicht abgeschnitten oder durch eine Passivitätsannahme ersetzt.

Die Demo ist rein synthetisch und als solche in Bild und Metadaten markiert.
Standards nach OSL sind Plausibilitätskontrollen mit denselben Standards,
kein unabhängiger Genauigkeitsnachweis. Geräte-/Markerabgleich RS02 bleibt
bis zur realen Durchführung offen. Keine aktive Funkhardware an den VNA anschließen.

## Technische Prüfung

```bash
uv run --project tools python -m unittest discover -s tools/tests -p test_nanovna.py -v
```

Fake-Serial-Tests prüfen Antwortgrenzen, Echo, Modellablehnung, Timeouts,
Frequenzraster, Fehlerantworten und Datenintegrität. Handfälle prüfen die
Umrechnung und undefinierte Größen. Das ersetzt keinen Hardwaretest.


## Hardwareprüfung am 05.11.2026

USB-Kommunikation mit NanoVNA-F V2, Firmware 0.6.5, tatsächlich ausgeführt.
18 Standard-/Kabelaufnahmen gesichert. S11-dB-Gerätemarkerabgleich bestanden;
Nachweis: `../nachweise/RS02-geraet-2026-11-05/README.md`.
Bei pausiertem Sweep kann das LCD nach einem seriellen Markerwechsel noch
den alten Marker anzeigen. Für LCD-Abgleiche Anzeige erst durch laufenden
Sweep aktualisieren und anschließend wieder anhalten. Einen neuen,
gefrorenen Messpuffer zum aktualisierten Bildschirm sichern; nicht einen
älteren Sweep mit der Anzeige vergleichen.
