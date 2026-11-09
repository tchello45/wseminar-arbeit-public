"""Ausgewählte Frequenzoffset-Punkte bei festem E_s/N_0."""

import argparse
import csv
import hashlib
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from simulation.basis import BATCH_SIZE, chirps, complex_noise, detect, wilson
from simulation.css import frequenzoffset
from simulation.offset import kontrolliere_offsets

DELTAS = (-1.0, -0.75, -0.5, -0.49, -0.25, 0.0, 0.25, 0.49, 0.5, 0.75, 1.0)


def fractional_controls():
    """Alle Symbole abseits der Bindung; Halb-Bin-Gleichstand analytisch prüfen."""
    controls = []
    for sf in (7, 8, 9):
        m = 2**sf
        symbols = np.arange(m)
        alphabet = chirps(sf, symbols)
        for delta in DELTAS:
            shifted = frequenzoffset(alphabet, delta)
            spectrum = np.fft.fft(shifted * alphabet[0].conj(), axis=-1)

            distance = delta - np.arange(m)
            expected = m * abs(np.sinc(distance) / np.sinc(distance / m))
            np.testing.assert_allclose(
                abs(spectrum[0]), expected, atol=1e-10, rtol=1e-10
            )
            if abs(delta) == 0.5:
                neighbor = int(np.sign(delta)) % m
                np.testing.assert_allclose(
                    abs(spectrum[symbols, symbols]),
                    abs(spectrum[symbols, (symbols + neighbor) % m]),
                    atol=1e-10,
                )
                status = "equal neighboring peak magnitudes; argmax tie is not physical"
            else:
                np.testing.assert_array_equal(
                    detect(shifted, sf), (symbols + int(np.floor(delta + 0.5))) % m
                )
                status = "all symbols: nearest FFT bin confirmed"
            controls.append(
                {"sf": sf, "delta": delta, "checked_symbols": m, "status": status}
            )
    return controls


def campaign(trials, seed, bandwidth):
    rows = []
    for sf in (7, 8, 9):
        m = 2**sf
        alphabet = chirps(sf, np.arange(m))
        for energy_index, energy in enumerate((10.0, 16.0)):
            snr = energy - 10 * np.log10(m)
            for index, delta in enumerate(DELTAS):
                rng = np.random.default_rng(
                    np.random.SeedSequence([seed, 3, sf, energy_index, index])
                )
                errors = 0
                for start in range(0, trials, BATCH_SIZE):
                    size = min(BATCH_SIZE, trials - start)
                    symbols = rng.integers(0, m, size=size)
                    sent = frequenzoffset(alphabet[symbols], delta)
                    received = sent + complex_noise(rng, sent.shape, snr)
                    errors += int(np.count_nonzero(detect(received, sf) != symbols))
                low, high = wilson(errors, trials)
                rows.append(
                    {
                        "sf": sf,
                        "bandwidth_hz": bandwidth,
                        "delta": delta,
                        "frequency_offset_hz": delta * bandwidth / m,
                        "es_n0_db": energy,
                        "snr_per_sample_db": float(snr),
                        "noise_power": float(10 ** (-snr / 10)),
                        "trials": trials,
                        "errors": errors,
                        "ser": errors / trials,
                        "wilson95_lower": low,
                        "wilson95_upper": high,
                    }
                )
        print(f"Offset-Kampagne SF {sf} abgeschlossen", flush=True)
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trials", type=int, default=5000)
    parser.add_argument("--seed", type=int, default=20261104)
    parser.add_argument("--bandwidth-hz", type=float, default=125000)
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).parent / "ergebnisse"
    )
    args = parser.parse_args()
    if (
        args.trials <= 0
        or args.seed < 0
        or not np.isfinite(args.bandwidth_hz)
        or args.bandwidth_hz <= 0
    ):
        parser.error("trials und bandwidth-hz positiv/endlich; seed nichtnegativ")
    controls = kontrolliere_offsets(args.bandwidth_hz)
    fractional = fractional_controls()
    rows = campaign(args.trials, args.seed, args.bandwidth_hz)
    args.output.mkdir(parents=True, exist_ok=True)
    csv_path = args.output / "css-offset-awgn.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    fig, axes = plt.subplots(1, 2, figsize=(10, 4.5), layout="constrained", sharey=True)
    for ax, energy in zip(axes, (10.0, 16.0)):
        for sf, color in zip((7, 8, 9), ("#0072B2", "#D55E00", "#009E73")):
            subset = [r for r in rows if r["sf"] == sf and r["es_n0_db"] == energy]
            rates = np.array([r["ser"] for r in subset])
            ax.errorbar(
                [r["delta"] for r in subset],
                rates,
                yerr=np.maximum(
                    0,
                    [
                        rates - [r["wilson95_lower"] for r in subset],
                        [r["wilson95_upper"] for r in subset] - rates,
                    ],
                ),
                fmt="o-",
                markersize=3,
                capsize=2,
                color=color,
                label=f"SF {sf}",
            )
        ax.axvline(-0.5, color="gray", ls="--", lw=1)
        ax.axvline(0.5, color="gray", ls="--", lw=1)
        ax.set(
            title=f"Eₛ/N₀ = {energy:g} dB",
            xlabel="Normierter Offset δ = Δf / (B/M)",
            ylim=(-0.03, 1.03),
        )
        ax.grid(alpha=0.25)
        ax.legend()
    axes[0].set_ylabel("Symbolfehlerrate · punktweises 95-%-Wilson-Intervall")
    fig.suptitle(
        f"Uncodiertes CSS · komplexes AWGN · {args.trials} Symbole/Punkt · B = fₛ = {args.bandwidth_hz / 1000:g} kHz"
    )
    for ext in ("png", "svg"):
        fig.savefig(args.output / f"css-offset-awgn.{ext}", dpi=180)
    plt.close(fig)
    report = {
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "command": [sys.executable, *sys.argv],
        "seed": args.seed,
        "rng": "PCG64; SeedSequence([seed,3,sf,energy_index,delta_index])",
        "batch_size": BATCH_SIZE,
        "deltas": DELTAS,
        "energy_grid_db": [10, 16],
        "trials_per_point": args.trials,
        "points": len(rows),
        "total_symbols": len(rows) * args.trials,
        "model": "uncoded CSS; perfect symbol timing; no frequency-offset correction; offset applied before AWGN",
        "integer_controls": controls,
        "fractional_controls": fractional,
        "confidence": "pointwise two-sided 95% Wilson; not simultaneous; no model uncertainty",
        "versions": {
            "python": platform.python_version(),
            "numpy": np.__version__,
            "matplotlib": matplotlib.__version__,
        },
        "source_sha256": {
            n: hashlib.sha256(Path(__file__).with_name(n).read_bytes()).hexdigest()
            for n in ("offset_campaign.py", "offset.py", "css.py", "basis.py")
        },
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
    }
    (args.output / "css-offset-lauf.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
