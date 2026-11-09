"""Symbolparameter, Chirp und rauschfreie Symbolerkennung für CSS mit f_s = B."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def symbolparameter(sf: int, bandbreite_hz: float) -> tuple[int, float, float]:
    """Liefere Alphabetgröße M, Symbolzeit in s und uncodierte Bitrate in bit/s."""
    if not isinstance(sf, int) or sf < 1:
        raise ValueError("SF muss eine positive ganze Zahl sein.")
    if not np.isfinite(bandbreite_hz) or bandbreite_hz <= 0:
        raise ValueError("Die Bandbreite muss endlich und positiv sein.")
    m = 2**sf
    symbolzeit_s = m / bandbreite_hz
    bitrate = sf / symbolzeit_s
    return m, symbolzeit_s, bitrate


def referenzchirp(sf: int, bandbreite_hz: float) -> tuple[np.ndarray, np.ndarray]:
    """Erzeuge t in s und x_0[n] für genau ein Symbol, ohne Endpunktsample."""
    m, _, _ = symbolparameter(sf, bandbreite_hz)
    n = np.arange(m)
    zeit_s = n / bandbreite_hz

    chirp = np.exp(1j * 2 * np.pi * (n**2 / (2 * m) - n / 2))
    return zeit_s, chirp


def erzeuge_symbol(chirp: np.ndarray, symbol: int) -> np.ndarray:
    """Verschiebe den Referenzchirp um den Symbolindex m im Alphabet 0 bis M-1."""
    m = len(chirp)
    if not isinstance(symbol, int) or not 0 <= symbol < m:
        raise ValueError("Der Symbolindex muss eine ganze Zahl von 0 bis M-1 sein.")
    n = np.arange(m)
    return chirp * np.exp(1j * 2 * np.pi * symbol * n / m)


def erkenne_symbol(signal: np.ndarray, chirp: np.ndarray) -> tuple[int, np.ndarray]:
    """Dechirpe und liefere den stärksten FFT-Bin samt unnormierter FFT."""
    dechirpt = signal * np.conj(chirp)
    spektrum = np.fft.fft(dechirpt)
    erkannt = int(np.argmax(np.abs(spektrum)))
    return erkannt, spektrum


def frequenzoffset(signal: np.ndarray, delta: float = 0.0) -> np.ndarray:
    """Wende δ = Δf/(B/M) auf die Sampleachse (letzte Achse) an."""
    signal = np.asarray(signal)
    if signal.ndim == 0 or signal.shape[-1] == 0:
        raise ValueError("Das Signal muss mindestens ein Sample pro Symbol enthalten.")
    if not np.isfinite(delta):
        raise ValueError("Der normierte Frequenzoffset delta muss endlich sein.")
    m = signal.shape[-1]
    return signal * np.exp(1j * 2 * np.pi * delta * np.arange(m) / m)


def zeichne_fft(spektrum, symbol, sf, bandbreite_hz, zielordner):
    fig, achse = plt.subplots(figsize=(10, 4.8), layout="constrained")
    bins = np.arange(len(spektrum))
    achse.stem(bins, np.abs(spektrum), markerfmt=".", basefmt=" ")
    achse.set(
        xlabel="FFT-Bin",
        ylabel="Betrag",
        title=(
            f"Ideales CSS nach Dechirping – Symbol m = {symbol}, SF = {sf}\n"
            f"B = fₛ = {bandbreite_hz / 1000:g} kHz, M = {len(spektrum)}, ohne Rauschen"
        ),
        xlim=(-1, len(spektrum)),
        ylim=(0, len(spektrum) * 1.1),
    )
    achse.grid(alpha=0.25)
    zielordner = Path(zielordner)
    zielordner.mkdir(parents=True, exist_ok=True)
    for endung in ("png", "svg"):
        ziel = zielordner / f"css-symbol-fft.{endung}"
        fig.savefig(ziel, dpi=180)
        print(f"Grafik: {ziel}")
    plt.close(fig)


def zeichne_chirp(zeit_s, chirp, sf, bandbreite_hz, zielordner):
    _, symbolzeit_s, _ = symbolparameter(sf, bandbreite_hz)
    fig, achse = plt.subplots(figsize=(10, 4.8), layout="constrained")
    achse.plot(zeit_s * 1000, chirp.real, label="Realteil", linewidth=1)
    achse.plot(zeit_s * 1000, chirp.imag, label="Imaginärteil", linewidth=1)
    achse.set(
        xlabel="Zeit t (ms)",
        ylabel="Normierte Amplitude",
        title=(
            f"Idealer CSS-Referenzchirp – SF = {sf}, B = fₛ = {bandbreite_hz / 1000:g} kHz\n"
            f"M = {len(chirp)}, Tₛ = {symbolzeit_s * 1000:.3f} ms"
        ),
        xlim=(0, symbolzeit_s * 1000),
        ylim=(-1.15, 1.15),
    )
    achse.grid(alpha=0.25)
    achse.legend(loc="upper right")
    zielordner = Path(zielordner)
    zielordner.mkdir(parents=True, exist_ok=True)
    for endung in ("png", "svg"):
        ziel = zielordner / f"css-referenzchirp.{endung}"
        fig.savefig(ziel, dpi=180)
        print(f"Grafik: {ziel}")
    plt.close(fig)


def main() -> None:
    bandbreite_hz = 125_000
    print(f"Modellbandbreite B = {bandbreite_hz} Hz; Abtastrate f_s = B")
    print("SF    M    T_s (ms)    R_b (bit/s)")
    for sf in (7, 8, 9):
        m, symbolzeit_s, bitrate = symbolparameter(sf, bandbreite_hz)
        print(f"{sf:2d}  {m:3d}    {symbolzeit_s * 1000:8.3f}    {bitrate:10.2f}")

    sf = 7
    zeit_s, chirp = referenzchirp(sf, bandbreite_hz)
    fehler = np.max(np.abs(np.abs(chirp) - 1))
    if not np.allclose(np.abs(chirp), 1, rtol=0, atol=1e-12):
        raise RuntimeError("Der Betrag des Referenzchirps weicht von 1 ab.")
    print(f"Betragsprüfung bestanden: max. Abweichung von 1 = {fehler:.3e}")
    zeichne_chirp(
        zeit_s, chirp, sf, bandbreite_hz, Path(__file__).resolve().parent / "ergebnisse"
    )

    symbol = 17
    signal = erzeuge_symbol(chirp, symbol)
    erkannt, spektrum = erkenne_symbol(signal, chirp)
    peak = np.abs(spektrum[erkannt])
    print(f"Gesendet: {symbol}; erkannt: {erkannt}; FFT-Peak: {peak:.6f}")
    if erkannt != symbol or not np.isclose(peak, len(chirp), rtol=0, atol=1e-10):
        raise RuntimeError("Symbol 17 oder die erwartete FFT-Peakhöhe stimmt nicht.")
    zeichne_fft(
        spektrum,
        symbol,
        sf,
        bandbreite_hz,
        Path(__file__).resolve().parent / "ergebnisse",
    )

    for sf in (7, 8, 9):
        _, chirp = referenzchirp(sf, bandbreite_hz)
        korrekt = 0
        for symbol in range(len(chirp)):
            erkannt, _ = erkenne_symbol(erzeuge_symbol(chirp, symbol), chirp)
            korrekt += erkannt == symbol
        print(f"SF {sf}, ohne Rauschen: {korrekt}/{len(chirp)} korrekt")
        if korrekt != len(chirp):
            raise RuntimeError(f"Symbolkontrolle für SF {sf} fehlgeschlagen")


if __name__ == "__main__":
    main()
