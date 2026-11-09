= Quellcode und ergänzende Nachweise <anhang-nachweise>

Die zur Arbeit gehörenden Programme und Rohdaten liegen im begleitenden Projektverzeichnis. Sie ergänzen die Darstellung im Haupttext und ermöglichen die Wiederholung der Software- und Rechenprüfungen. Für den Typst-Bau genügt der Ordner `arbeit/`; er enthält lokale Kopien sämtlicher eingebundener Abbildungen, Listings, Tabellen und der Bibliografie.

== Programme und Simulationsergebnisse

- `tools/src/simulation/`: Python-Code zum vereinfachten CSS-Modell, zu Kontrollfällen sowie zu Rausch- und Frequenzoffsetkampagnen.
- `tools/src/simulation/ergebnisse/`: Parameter, numerische Ergebnisse und ursprüngliche Diagrammausgaben der durchgeführten Simulationen.
- `arbeit/abbildungen/`: alle im Haupttext eingebundenen Abbildungen; Herkunft der exportierten Ergebnisgrafiken in `quellen.json`.
- `arbeit/listings/kapitel6.py`, `arbeit/listings/css-wasm.rs`, `arbeit/tabellen/nanovna-zentrum.typ` und `arbeit/literatur.bib`: lokale Kopien der eingebundenen Inhalte.
- `css-wasm/`: eigenständige Rust-Crate des CSS-Rechenkerns mit nativen Tests; `css-wasm/pkg/` enthält nach dem Build das lokale WASM-npm-Paket.
- `auswertung/`: Rust-Werkzeug zur Berechnung von Reflexionsgrößen sowie zum Import von Einport-Touchstone- und CSV-Dateien; Aufrufe und Prüfkommandos in `auswertung/README.md`.

== Begleitwebsite <begleitwebsite>

Der Ordner `frontend/` enthält die ergänzende deutschsprachige Website auf Grundlage von Next.js, TypeScript und shadcn-Komponenten mit einem Rust/WebAssembly-Rechenkern. Sie umfasst die interaktive CSS-Simulation, vordefinierte Versuche, die gespeicherten statistischen Ergebnisse, NanoVNA-Abbildungen und einen Zugang zur schriftlichen Arbeit als PDF. Die Umsetzung erfolgte mit Unterstützung von OpenAI Codex; Art und Umfang der Unterstützung sind in der Selbstständigkeitserklärung offengelegt.

Quellcode und Startanleitung liegen unter `frontend/README.md`. Vorausgesetzt werden Node.js mit pnpm, Rust mit dem Ziel `wasm32-unknown-unknown` und `wasm-pack`. Der lokale Entwicklungsbetrieb wird aus `frontend/` mit `pnpm dev` gestartet. `pnpm build` erzeugt die statische Website unter `frontend/out/`. Vor Start und Build übersetzt `frontend/scripts/build-wasm.mjs` die Rust-Crate und stellt das WASM-Modul bereit. `pnpm wasm:pack` erzeugt ein lokal installierbares npm-Archiv unter `css-wasm/dist/`. Anschließend übernimmt das Exportskript `frontend/scripts/export-data.mjs` die benötigten CSV-Ergebnisse, ausgewählten Abbildungen und die aktuelle `arbeit.pdf` aus dem Projekt. Herkunft und Prüfsummen der exportierten Dateien werden mitgeführt. Die Begleitwebsite ist unter #link("https://lora-css.app")[lora-css.app] öffentlich zugänglich.

== Messdaten

- `daten/roh/`: Originalexporte des früheren Messpiloten.
- `daten/nanovna/`: 18 Standards-/Kabelaufnahmen vom 5. November 2026 mit seriellen Originalantworten, Touchstone, CSV und Metadaten.
- `daten/auswertung/kapitel7/`: reproduzierbare Kapitelgrafiken, Ergebnistabelle und Rust-Importe.
- `daten/auswertung/`: daraus berechnete Messgrößen im CSV-Format.
