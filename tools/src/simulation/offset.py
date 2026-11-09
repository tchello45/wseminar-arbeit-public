"""Rauschfreie Frequenzoffset-Kontrollen für das diskrete CSS-Modell."""

import argparse
import hashlib
import json
import platform
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from simulation.css import (
    erkenne_symbol,
    erzeuge_symbol,
    frequenzoffset,
    referenzchirp,
    symbolparameter,
)


def kontrolliere_offsets(bandbreite_hz: float = 125_000) -> list[dict]:
    """Prüfe alle Symbole für δ=0,+1,-1 gegen (m+δ) mod M."""
    rows = []
    for sf in (7, 8, 9):
        m, _, _ = symbolparameter(sf, bandbreite_hz)
        _, chirp = referenzchirp(sf, bandbreite_hz)
        for delta in (0, 1, -1):
            correct = 0
            examples = []
            max_peak_deviation = 0.0
            for symbol in range(m):
                sent = erzeuge_symbol(chirp, symbol)
                received = frequenzoffset(sent, delta)
                decoded, spectrum = erkenne_symbol(received, chirp)
                expected = (symbol + delta) % m
                peak_deviation = float(abs(abs(spectrum[decoded]) - m))
                max_peak_deviation = max(max_peak_deviation, peak_deviation)
                if decoded != expected or peak_deviation > 1e-10:
                    raise RuntimeError(
                        f"SF={sf}, m={symbol}, delta={delta}: "
                        f"erkannt={decoded}, erwartet={expected}, "
                        f"FFT-Peakabweichung={peak_deviation}"
                    )
                if delta == 0 and not np.array_equal(received, sent):
                    raise RuntimeError("delta=0 verändert die Signalsamples")
                correct += 1
                if symbol in (0, 17, m - 1):
                    examples.append(
                        {"sent": symbol, "expected": expected, "detected": decoded}
                    )
            rows.append(
                {
                    "sf": sf,
                    "M": m,
                    "delta": delta,
                    "frequency_offset_hz": delta * bandbreite_hz / m,
                    "checked_symbols": m,
                    "correct": correct,
                    "max_fft_peak_deviation_from_M": max_peak_deviation,
                    "examples": examples,
                }
            )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bandwidth-hz", type=float, default=125_000)
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).parent / "ergebnisse"
    )
    args = parser.parse_args()
    if not np.isfinite(args.bandwidth_hz) or args.bandwidth_hz <= 0:
        parser.error("bandwidth-hz muss positiv und endlich sein")
    rows = kontrolliere_offsets(args.bandwidth_hz)
    report = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "bandwidth_hz": args.bandwidth_hz,
        "sample_rate_hz": args.bandwidth_hz,
        "model": "uncoded discrete CSS; noiseless; perfect symbol timing",
        "definition": "delta = frequency_offset_hz / (B/M)",
        "signal_multiplier": "exp(1j * 2*pi * delta*n/M); n=0,...,M-1",
        "expected_bin": "(symbol + delta) mod M for integer delta",
        "zero_offset_samples_unchanged": True,
        "fft_peak_absolute_tolerance": 1e-10,
        "source_sha256": {
            name: hashlib.sha256(
                Path(__file__).with_name(name).read_bytes()
            ).hexdigest()
            for name in ("css.py", "offset.py")
        },
        "versions": {"python": platform.python_version(), "numpy": np.__version__},
        "controls": rows,
    }
    lines = [
        f"CSS-Frequenzoffset: ohne Rauschen; B = f_s = {args.bandwidth_hz:g} Hz",
        "delta = Delta_f/(B/M); Faktor exp(j*2*pi*delta*n/M)",
        "delta=0: Signalsamples exakt unverändert",
    ]
    for row in rows:
        lines.append(
            f"SF {row['sf']}, M={row['M']}, delta={row['delta']:+d}, "
            f"Delta_f={row['frequency_offset_hz']:g} Hz: "
            f"{row['correct']}/{row['checked_symbols']} erwartungsgemäß"
        )
        for example in row["examples"]:
            lines.append(
                f"  m={example['sent']}: erwartet={example['expected']}, "
                f"erkannt={example['detected']}"
            )
    lines.append("Alle 2688 Symbol-/Offsetkontrollen bestanden.")
    text = "\n".join(lines) + "\n"
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "css-offset-kontrollen.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (args.output / "css-offset-kontrollen.txt").write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
