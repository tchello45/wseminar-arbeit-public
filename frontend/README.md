# LoRa-CSS – Simulation und Messung

Deutschsprachige Next.js-Begleitwebsite mit einer interaktiven Rust/WebAssembly-Simulation, gespeicherten Versuchsergebnissen und NanoVNA-Grafiken. Die Oberfläche verwendet die vorhandenen shadcn/Base-UI-Komponenten.

## Voraussetzungen und erster Start

Benötigt werden Node ≥ 22.18 und pnpm. Das vorgebaute WASM-Paket liegt unter `vendor/` im Repository; für Installation, Entwicklung und Deployment werden keine Rust-Werkzeuge benötigt.

Aus `frontend/`:

```sh
pnpm install --frozen-lockfile
pnpm dev
```

`pnpm dev` und `pnpm build` bereiten das installierte WASM-Paket vor und exportieren anschließend die Originaldaten. Benötigt werden die drei CSV-Kampagnen unter `../tools/src/simulation/ergebnisse/`, die ausgewählten SVGs unter `../arbeit/abbildungen/` und `../arbeit.pdf`. Ungültige oder fehlende Daten brechen den Export ab. `public/media/sources.json` dokumentiert Quellen und Prüfsummen. Die Originaldaten werden nicht verändert.

## Architektur und npm-Paket

- `../css-wasm/`: Rust-Crate mit Chirp, komplexem AWGN, Frequenzoffset, Dechirping, Radix-2-FFT und Symbolentscheidung. Die Crate besitzt eigene native Tests und ist vom Rust-S11-Werkzeug getrennt.
- `@wseminar/css-wasm`: durch wasm-pack erzeugtes lokales ES-Modul mit WASM-Binärdatei und TypeScript-Deklarationen. pnpm installiert das eingecheckte Archiv `vendor/wseminar-css-wasm-0.1.0.tgz` per `file:`; Turbopack verwendet den gemeinsamen Projektstamm.
- `lib/css-model.ts`: ausschließlich UI-Parameter, Standardwerte und Datentypen. `lib/css-wasm.ts` initialisiert das Modul und transportiert JSON; es enthält keinen zweiten Simulationskern.
- `components/seminar/css-lab.tsx`: lädt das Modul im Browser und zeigt bis zur Initialisierung einen Ladezustand. Bei einem Ladefehler ist ein expliziter erneuter Versuch möglich. Es gibt keinen stillen TypeScript-Ersatzrechenkern.
- Die statische Einstiegsabbildung wird beim Build mit demselben WASM-Modul erzeugt. Ergebnisdiagramme verwenden gespeicherte CSV-Kampagnen und werden nicht als neue Monte-Carlo-Kampagne berechnet.

Rust, `wasm32-unknown-unknown` und wasm-pack 0.15.1 werden nur bei Änderungen am Rust-Kern benötigt:

```sh
pnpm wasm:pack
pnpm install --no-frozen-lockfile
pnpm test
pnpm build
```

`wasm:pack` baut den Rust-Kern und erzeugt `vendor/wseminar-css-wasm-0.1.0.tgz`. Nach Änderungen das Archiv und die aktualisierte `pnpm-lock.yaml` gemeinsam committen. Bei einer Versionsänderung auch den Dateinamen der Abhängigkeit in `package.json` anpassen. Dieses Archiv kann mit npm oder pnpm lokal installiert werden. Es findet keine Veröffentlichung in einer Registry statt. Schnittstelle und eigenständige Verwendung stehen in `../css-wasm/README.md`.

## Prüfen und bauen

```sh
cargo test --manifest-path ../css-wasm/Cargo.toml --locked
cargo fmt --manifest-path ../css-wasm/Cargo.toml --check
cargo clippy --manifest-path ../css-wasm/Cargo.toml --locked --all-targets -- -D warnings
pnpm test
pnpm lint
pnpm typecheck
pnpm build
pnpm start
```

`pnpm test` führt das tatsächlich kompilierte WASM-Paket aus und benötigt für den direkten Python-Abgleich `../tools/.venv/bin/python`. Die Tests prüfen alle 896 rauschfreien Symbole, Offset- und Rauschkontrollen sowie die JSON-Schnittstelle und Originaldaten. Native Rust-Tests allein ersetzen keine WASM- oder Browserprüfung.

`pnpm build` erzeugt die statische Website in `out/`; `pnpm start` stellt sie lokal auf Port 3000 bereit (Python 3). Die Website benötigt zur Laufzeit keinen Rechenserver, keine Datenbank und keine externen Dienste. Die WASM-Datei wird unter `/wasm/css_wasm_bg.wasm` mitgeliefert. Für die Bereitstellung sollte `.wasm` mit `application/wasm` ausgeliefert werden. Ein Hosting ist nicht eingerichtet.

## Deployment

Projektstamm des Hosters: `frontend/`. Installationsbefehl: `pnpm install --frozen-lockfile`; Build-Befehl: `pnpm build`; statisches Ausgabeverzeichnis: `out/`. Node ≥ 22.18 verwenden. Der vollständige Repository-Checkout muss verfügbar sein, da der Datenexport die Forschungsdaten und die PDF aus dem übergeordneten Projekt verwendet.

## Modell und Grenzen

fs = B = 125 kHz, SF 7–9, komplexes AWGN mit E|w|² = 10^(−SNR/10), δ = Δf/(B/M), konjugiertes Dechirping und unnormierte Vorwärts-FFT. Mulberry32/Box–Muller erzeugt reproduzierbares Rauschen mit einer anderen Zufallsfolge als NumPy. Die interaktive Anwendung zeigt Einzelentscheidungen, keine vollständige LoRa-/ExpressLRS-Verbindung. Es wurde kein Geschwindigkeitsvergleich mit JavaScript durchgeführt.

Navigation über shadcn-Buttons mit `useRouter().push()`; Auswahllisten verwenden shadcn-Select. Standard ist das dunkle Theme; die Auswahl wird lokal im Browser gespeichert.
