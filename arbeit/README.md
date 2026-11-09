# Seminararbeit bauen

Dieser Ordner enthält alle Dateien, die Typst zum Bauen der Arbeit benötigt:
Kapitel, Layout, Abbildungen, Listings, Ergebnistabelle und Literaturdaten.
Er kann unabhängig vom übrigen Projekt kopiert werden.

Mit installierter Typst-CLI aus diesem Ordner:

```sh
typst compile --root . main.typ /tmp/wseminar.pdf
```

Die Schriften müssen auf dem System verfügbar sein (Layout: Libertinus Serif).

`listings/kapitel6.py`, `listings/css-wasm.rs`, `tabellen/nanovna-zentrum.typ` und `literatur.bib` sind
lokale Kopien der geprüften Projektinhalte. Beim Typst-Bau findet keine
Synchronisierung mit Dateien außerhalb dieses Ordners statt.

Die Herkunftsangaben in `export-quellen.json` und `abbildungen/quellen.json`
sind Dokumentation; ihre Quelldateien werden zum PDF-Bau nicht benötigt.
Die im Anhang erwähnten Rohdaten und Programme gehören zur wissenschaftlichen
Reproduktion der Untersuchung und sind im begleitenden Projekt enthalten.

Das Literaturverzeichnis hat dieselben drei Gruppen wie Philips Vergleichsarbeit:
Primärliteratur, Sekundärliteratur sowie Software-Dokumentation und Online-Quellen.
Die Zuordnung und Reihenfolge stehen in `literaturgruppen.json`; die IEEE-Zitate
verwenden das Präfix `lit:`. Bei einer neuen oder entfernten Quelle die
Gruppenliste entsprechend pflegen. Die Gesamtprüfung verlangt, dass jede
tatsächlich zitierte Quelle genau einer Gruppe angehört.

Alexandria 0.2.2 liegt mit Lizenz unter `vendor/` bei. `literatur.typ` nutzt dessen
Bibliografieprozessor und Renderer mit vorab festgelegter Gruppenreihenfolge;
für den Bau ist kein Paketdownload erforderlich. Die Zitiernummern laufen über
alle drei Gruppen durch.
