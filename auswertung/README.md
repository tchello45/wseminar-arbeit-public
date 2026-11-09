# Auswertung

Calculates magnitude, phase, S11 in dB, impedance and VSWR from complex S11.

```sh
cargo run --locked -- 0.5 -0.2 50
cargo run --locked -- --import ../daten/roh/01.s1p
cargo run --locked -- --import measurements.csv > results.csv
```

CSV goes to stdout, errors to stderr. Imports are fully validated before output.

- CSV requires `frequency_hz`, `s11_re`, `s11_im`; NanoVNA names `s11_real`
  and `s11_imag` also work. `z0_ohm` defaults to 50 when the column is absent.
  Derived columns are ignored and recalculated. Frequencies must be finite,
  nonnegative and strictly increasing.
- Touchstone supports `.s1p`, explicit `# HZ/KHZ/MHZ/GHZ S RI/MA/DB R Z0`
  options, comments and one point per line. Multiport and Touchstone 2.x are
  unsupported.
- Output keeps explicit status fields for singular impedance and infinite or
  nonpassive VSWR. Zero reflection has `undefined` phase and `-inf` S11 dB.

CSV uses `serde` and `csv`; arguments use `clap`, calculation errors use
`thiserror`, and complex arithmetic uses `num-complex`.

```sh
cargo test --locked
cargo clippy --locked --all-targets -- -D warnings
cargo fmt --check
```
