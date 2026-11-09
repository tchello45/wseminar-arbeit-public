# @wseminar/css-wasm

Rust-Rechenkern der interaktiven CSS-Simulation. `wasm-pack` erzeugt ein lokal nutzbares npm-Paket mit WASM-Binärdatei, ES-Modul und TypeScript-Deklarationen. Es wird nicht öffentlich veröffentlicht.

## Bauen

Benötigt: Rust, das Target `wasm32-unknown-unknown` und `wasm-pack` 0.15.1.

```sh
rustup target add wasm32-unknown-unknown
cargo install wasm-pack --version 0.15.1 --locked
wasm-pack build --target web --scope wseminar --out-dir pkg --release --no-opt --locked
```

Aus `frontend/` baut `pnpm wasm:pack` den Kern, ergänzt die Paket-Metadaten und erzeugt das installierbare Archiv `frontend/vendor/wseminar-css-wasm-0.1.0.tgz`. Danach `pnpm install --no-frozen-lockfile` ausführen und Archiv sowie Lockfile gemeinsam committen. Bei einer Versionsänderung den Archivnamen in `frontend/package.json` anpassen. Kein Upload zu npm.

Das Frontend installiert dieses eingecheckte Archiv per `file:`. `pnpm wasm:prepare` kopiert die Binärdatei aus dem installierten Paket nach `public/wasm/` und erzeugt daraus das statische Referenzsymbol. Entwicklung und Deployment führen nur diesen Node-Schritt aus und benötigen kein Rust oder wasm-pack.

## JavaScript-Schnittstelle

```js
import init, { simulate_json } from '@wseminar/css-wasm'
await init({ module_or_path: '/wasm/css_wasm_bg.wasm' })
const result = JSON.parse(simulate_json(JSON.stringify({
  sf: 7, symbol: 17, noise: false, snr: -12, offset: 0, seed: 20261103,
})))
```

Eingabe: SF 7–9, ganzzahliger Symbolindex 0…2^SF−1, Rauschschalter, SNR pro Sample −24…0 dB, Offset −2…2 Bins und ein u32-Seed. Rust prüft die vollständige JSON-Eingabe; ungültige Werte werden als JavaScript-Exception gemeldet. Ausgabe: Zeit- und Frequenzsamples, komplexe Empfangs- und Dechirpingfolgen, unnormierte FFT-Beträge, erkanntes Symbol, Symbolzeit und Binabstand. Felder und Einheiten sind in den öffentlichen Rust-Strukturen und `frontend/lib/css-model.ts` dokumentiert.

Das Modell verwendet fs = B = 125 kHz, komplexes AWGN mit E|w|² = 10^(−SNR/10), δ = Δf/(B/M), konjugiertes Dechirping und eine Radix-2-Vorwärts-FFT. Mulberry32/Box–Muller erzeugt reproduzierbares Rauschen; die Zufallsfolge unterscheidet sich von NumPy. Exakte mathematische Halb-Bin-Gleichstände können durch Gleitkommarundung unterschiedlich aufgelöst werden.

## Prüfen

```sh
cargo test --locked
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
```

Zusätzlich prüft `pnpm test` im Frontend das tatsächlich kompilierte WASM-Paket einschließlich des Python-Abgleichs. Native Rust-Tests allein sind kein Nachweis der Browserintegration. Es wird kein Geschwindigkeitsvorteil gegenüber JavaScript behauptet.
