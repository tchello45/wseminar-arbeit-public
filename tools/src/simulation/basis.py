"""CSS-AWGN-Kampagnen bei gleichem Sample-SNR und gleichem E_s/N_0."""

import argparse
import csv
import hashlib
import json
import os
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/wseminar-matplotlib")
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from simulation.css import erzeuge_symbol, referenzchirp

C = 299_792_458.0
SFS = (7, 8, 9)
BATCH_SIZE = 256


def chirps(sf: int, symbols: np.ndarray) -> np.ndarray:
    """M Samples pro Symbol bei f_s=B, Einheitsleistung, diskretes CSS."""
    _, reference = referenzchirp(sf, 1.0)
    return np.stack([erzeuge_symbol(reference, int(symbol)) for symbol in symbols])


def detect(samples: np.ndarray, sf: int) -> np.ndarray:
    reference = chirps(sf, np.array([0]))[0]
    spectrum = np.fft.fft(samples * reference.conj(), axis=-1)
    return np.argmax(np.abs(spectrum), axis=-1)


def wilson(errors: int, trials: int) -> tuple[float, float]:
    """Punktweises 95-%-Wilson-Intervall für Bernoulli-Symbolfehler."""
    if trials <= 0 or not 0 <= errors <= trials:
        raise ValueError("Erforderlich: 0 <= errors <= trials und trials > 0")
    z = 1.959963984540054
    p = errors / trials
    denominator = 1 + z**2 / trials
    center = (p + z**2 / (2 * trials)) / denominator
    half = z * np.sqrt(p * (1 - p) / trials + z**2 / (4 * trials**2)) / denominator
    return max(0.0, center - half), min(1.0, center + half)


def references(out: Path, bandwidth_hz: float) -> dict:
    theta = np.linspace(0, 2 * np.pi, 1441)
    short = np.sin(theta) ** 2
    half = np.zeros_like(theta)
    mask = np.abs(np.sin(theta)) > 1e-8
    half[mask] = (np.cos(np.pi / 2 * np.cos(theta[mask])) / np.sin(theta[mask])) ** 2
    fig, ax = plt.subplots(figsize=(6, 4), subplot_kw={"projection": "polar"})
    ax.plot(theta, short, label="Hertzscher Dipol")
    ax.plot(theta, half, label="Halbwellendipol")
    ax.set_theta_zero_location("N")
    ax.set_rlim(0, 1.08)
    ax.legend(loc="lower center", bbox_to_anchor=(0.5, -0.24), ncol=2)
    ax.set_title("Normierte Fernfeldleistung · Schnitt durch die Dipolachse", pad=22)
    fig.savefig(out / "dipol-referenzen.svg", bbox_inches="tight")
    plt.close(fig)

    sf, symbol = 7, 17
    m = 2**sf
    time_us = np.arange(m) / bandwidth_hz * 1e6
    frequency_khz = (-bandwidth_hz / 2 + bandwidth_hz * np.arange(m) / m) / 1e3
    spectrum = (
        np.abs(
            np.fft.fft(
                chirps(sf, np.array([symbol]))[0] * chirps(sf, np.array([0]))[0].conj()
            )
        )
        / m
    )
    fig, axes = plt.subplots(1, 2, figsize=(8.4, 3.0))
    axes[0].plot(time_us, frequency_khz)
    axes[0].set(
        xlabel="Zeit / µs",
        ylabel="Momentane Frequenz / kHz",
        title="Unverschobener Referenzchirp",
    )
    axes[1].stem(np.arange(m), spectrum, markerfmt=".", basefmt=" ")
    axes[1].set(
        xlabel="FFT-Bin",
        ylabel="Normierter FFT-Betrag",
        title=f"Dechirping: Symbol {symbol}",
    )
    for ax in axes:
        ax.grid(alpha=0.25)
    fig.tight_layout()
    fig.savefig(out / "css-dechirping.svg", bbox_inches="tight")
    plt.close(fig)

    angles = np.linspace(0, np.pi, 20_001)
    pattern = np.zeros_like(angles)
    valid = np.abs(np.sin(angles)) > 1e-8
    pattern[valid] = (
        np.cos(np.pi / 2 * np.cos(angles[valid])) / np.sin(angles[valid])
    ) ** 2
    directivity_short = 2 / np.trapezoid(np.sin(angles) ** 3, angles)
    directivity_half = 2 / np.trapezoid(pattern * np.sin(angles), angles)
    assert abs(directivity_short - 1.5) < 1e-6
    assert abs(directivity_half - 1.6409) < 1e-3

    with (out / "symbolparameter.csv").open(
        "w", newline="", encoding="utf-8"
    ) as stream:
        writer = csv.writer(stream)
        writer.writerow(
            [
                "sf",
                "bandwidth_hz",
                "samples_per_symbol",
                "symbol_time_s",
                "uncoded_bit_rate_bps",
            ]
        )
        for spreading_factor in SFS:
            count = 2**spreading_factor
            writer.writerow(
                [
                    spreading_factor,
                    bandwidth_hz,
                    count,
                    count / bandwidth_hz,
                    spreading_factor * bandwidth_hz / count,
                ]
            )
    return {
        "wavelength_at_2_4ghz_m": C / 2.4e9,
        "half_wavelength_at_2_4ghz_m": C / 2.4e9 / 2,
        "fspl_at_10m_2_4ghz_db": float(20 * np.log10(4 * np.pi * 10 * 2.4e9 / C)),
        "fspl_difference_2_4ghz_vs_868mhz_db": float(20 * np.log10(2.4e9 / 868e6)),
        "hertzian_directivity_linear": float(directivity_short),
        "half_wave_directivity_linear": float(directivity_half),
        "vswr_at_minus_10db": float((1 + np.sqrt(0.1)) / (1 - np.sqrt(0.1))),
    }


def complex_noise(
    rng: np.random.Generator, shape: tuple[int, ...], snr_db: float
) -> np.ndarray:
    """Komplexes AWGN: E|w|² = 10**(-SNR/10), Var(Re)=Var(Im)=P_N/2."""
    if not np.isfinite(snr_db):
        raise ValueError("SNR muss endlich sein")
    power = 10.0 ** (-snr_db / 10)
    return np.sqrt(power / 2) * (
        rng.standard_normal(shape) + 1j * rng.standard_normal(shape)
    )


def model_checks(seed: int = 20261103) -> dict:
    controls = []
    for sf in SFS:
        symbols = np.arange(2**sf)
        samples = chirps(sf, symbols)
        correct = int(np.count_nonzero(detect(samples, sf) == symbols))
        deviation = float(np.max(np.abs(np.abs(samples) - 1)))
        if correct != len(symbols) or deviation > 1e-12:
            raise RuntimeError(f"Rauschfreie Kontrolle für SF {sf} fehlgeschlagen")
        gram = samples @ samples.conj().T / 2**sf
        if not np.allclose(gram, np.eye(2**sf), atol=1e-10, rtol=0):
            raise RuntimeError(f"Orthogonalitätskontrolle für SF {sf} fehlgeschlagen")
        controls.append(
            {
                "sf": sf,
                "symbols": len(symbols),
                "correct": correct,
                "max_unit_amplitude_deviation": deviation,
            }
        )

    noise = complex_noise(
        np.random.default_rng(np.random.SeedSequence([seed, 0])), (100_000,), 0.0
    )
    measured = {
        "samples": len(noise),
        "snr_db": 0,
        "power": float(np.mean(abs(noise) ** 2)),
        "real_variance": float(np.var(noise.real)),
        "imag_variance": float(np.var(noise.imag)),
        "real_mean": float(np.mean(noise.real)),
        "imag_mean": float(np.mean(noise.imag)),
        "covariance": float(
            np.mean((noise.real - noise.real.mean()) * (noise.imag - noise.imag.mean()))
        ),
    }
    if (
        abs(measured["power"] - 1) > 0.02
        or abs(measured["real_variance"] - 0.5) > 0.01
        or abs(measured["imag_variance"] - 0.5) > 0.01
        or abs(measured["real_mean"]) > 0.01
        or abs(measured["imag_mean"]) > 0.01
        or abs(measured["covariance"]) > 0.01
    ):
        raise RuntimeError(f"Rauschkontrolle fehlgeschlagen: {measured}")
    return {
        "noiseless": controls,
        "discrete_orthogonality_checked": True,
        "noise": measured,
        "noise_tolerances": {
            "power_absolute": 0.02,
            "variance_absolute": 0.01,
            "mean_absolute": 0.01,
            "covariance_absolute": 0.01,
        },
    }


def campaign(
    out: Path, trials: int, seed: int, bandwidth_hz: float, *, equal_energy: bool
) -> list[dict]:
    """Jeden Punkt neu simulieren; Streams unabhängig von anderen Punkten."""
    rows = []
    campaign_id = 2 if equal_energy else 1
    grid = range(0, 19, 2) if equal_energy else range(-24, 1, 2)
    name = "css-awgn-energy" if equal_energy else "css-awgn"
    for sf in SFS:
        count = 2**sf

        alphabet = chirps(sf, np.arange(count))
        for index, value in enumerate(grid):
            rng = np.random.default_rng(
                np.random.SeedSequence([seed, campaign_id, sf, index])
            )
            snr_db = float(value - 10 * np.log10(count) if equal_energy else value)
            errors = 0
            for begin in range(0, trials, BATCH_SIZE):
                size = min(BATCH_SIZE, trials - begin)
                symbols = rng.integers(0, count, size=size)
                samples = alphabet[symbols]
                noise = complex_noise(rng, samples.shape, snr_db)
                errors += int(np.count_nonzero(detect(samples + noise, sf) != symbols))
            lower, upper = wilson(errors, trials)
            rows.append(
                {
                    "sf": sf,
                    "bandwidth_hz": bandwidth_hz,
                    "snr_per_sample_db": snr_db,
                    "es_n0_db": float(
                        value if equal_energy else value + 10 * np.log10(count)
                    ),
                    "noise_power": 10.0 ** (-snr_db / 10),
                    "trials": trials,
                    "errors": errors,
                    "ser": errors / trials,
                    "wilson95_lower": lower,
                    "wilson95_upper": upper,
                }
            )
        print(f"{name}: SF {sf}, {len(grid)} Punkte abgeschlossen", flush=True)
    with (out / f"{name}.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    plot_campaign(rows, out, name, equal_energy)
    return rows


def plot_campaign(rows: list[dict], out: Path, name: str, equal_energy: bool) -> None:
    fig, ax = plt.subplots(figsize=(9, 5.5), layout="constrained")
    for sf, color in zip(SFS, ("#0072B2", "#D55E00", "#009E73")):
        selected = [row for row in rows if row["sf"] == sf]
        x = np.array(
            [
                row["es_n0_db" if equal_energy else "snr_per_sample_db"]
                for row in selected
            ]
        )
        rates = np.array([row["ser"] for row in selected])
        lower = np.array([row["wilson95_lower"] for row in selected])
        upper = np.array([row["wilson95_upper"] for row in selected])
        positive = rates > 0
        ax.plot(
            x, np.where(positive, rates, np.nan), "o-", color=color, label=f"SF {sf}"
        )
        ax.errorbar(
            x[positive],
            rates[positive],
            yerr=np.maximum(
                0,
                [rates[positive] - lower[positive], upper[positive] - rates[positive]],
            ),
            fmt="none",
            color=color,
            capsize=3,
        )
        ax.scatter(
            x[~positive],
            upper[~positive],
            marker="v",
            facecolors="none",
            edgecolors=color,
        )
    trials = rows[0]["trials"]
    zero_upper = wilson(0, trials)[1]
    ax.set(
        xlabel="Eₛ/N₀ / dB (gleiche Symbolenergie)"
        if equal_energy
        else "SNR pro Sample / dB (gleiche Signalleistung)",
        ylabel="Symbolfehlerrate mit punktweisem 95-%-Wilson-Intervall",
        yscale="log",
        ylim=(min(zero_upper / 3, 0.00003), 1.2),
        title=f"Synchrones, uncodiertes CSS · komplexes AWGN · {trials} Symbole je Punkt\n"
        f"B = fₛ = {rows[0]['bandwidth_hz'] / 1000:g} kHz · M = 2ˢᶠ Samples/Symbol",
    )
    ax.grid(alpha=0.25, which="both")
    ax.legend()
    fig.supxlabel(
        f"▽ Bei 0 Fehlern: obere Wilson-Grenze {zero_upper:.6g}; kein SER-Wert von null nachgewiesen.",
        fontsize=9,
    )
    for extension in ("svg", "png"):
        fig.savefig(out / f"{name}.{extension}", dpi=180)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trials", type=int, default=5000)
    parser.add_argument("--seed", type=int, default=20261103)
    parser.add_argument("--bandwidth-hz", type=float, default=125_000)
    parser.add_argument(
        "--output", type=Path, default=Path(__file__).parent / "ergebnisse"
    )
    args = parser.parse_args()
    if args.seed < 0:
        parser.error("seed muss nichtnegativ sein")
    if args.trials <= 0 or not np.isfinite(args.bandwidth_hz) or args.bandwidth_hz <= 0:
        parser.error("trials und bandwidth-hz müssen positiv und endlich sein")
    args.output.mkdir(parents=True, exist_ok=True)
    checks = model_checks(args.seed)
    values = references(args.output, args.bandwidth_hz)
    rows = campaign(
        args.output, args.trials, args.seed, args.bandwidth_hz, equal_energy=False
    )
    energy_rows = campaign(
        args.output, args.trials, args.seed, args.bandwidth_hz, equal_energy=True
    )
    summary = {
        "seed": args.seed,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "command": [sys.executable, *sys.argv],
        "working_directory": str(Path.cwd()),
        "source_sha256": {
            name: hashlib.sha256(
                Path(__file__).with_name(name).read_bytes()
            ).hexdigest()
            for name in ("basis.py", "css.py")
        },
        "rng": "PCG64; SeedSequence([seed, campaign_id, sf, grid_index]); control=[seed,0]",
        "csv_sha256": {
            name: hashlib.sha256((args.output / name).read_bytes()).hexdigest()
            for name in ("css-awgn.csv", "css-awgn-energy.csv", "symbolparameter.csv")
        },
        "batch_size": BATCH_SIZE,
        "spreading_factors": SFS,
        "sample_snr_grid_db": list(range(-24, 1, 2)),
        "es_n0_grid_db": list(range(0, 19, 2)),
        "energy_campaign": "independently simulated; SNR_sample=Es/N0-10*log10(M)",
        "trials_per_point": args.trials,
        "bandwidth_hz": args.bandwidth_hz,
        "sample_rate_hz": args.bandwidth_hz,
        "signal_power": 1,
        "model": "synchronous uncoded discrete CSS; f_s=B; complex AWGN; noncoherent FFT detector",
        "confidence_interval": "pointwise 95% Wilson binomial interval, not a simultaneous band",
        "checks": checks,
        "reference_values": values,
        "simulation_points": len(rows) + len(energy_rows),
        "total_awgn_symbols": (len(rows) + len(energy_rows)) * args.trials,
        "versions": {
            "python": platform.python_version(),
            "numpy": np.__version__,
            "matplotlib": matplotlib.__version__,
        },
        "excluded": [
            "coding",
            "packet framing",
            "timing and frequency offsets",
            "multipath",
            "interference",
            "real receiver calibration",
            "PCB antenna EM model",
        ],
    }
    (args.output / "lauf.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
