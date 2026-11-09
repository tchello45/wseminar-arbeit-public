"""Ausführbare Listings aus Kapitel 6; nur NumPy erforderlich.

Aufruf: tools/.venv/bin/python tools/src/simulation/kapitel6.py
Kampagnen und unveränderte Ergebnisdateien: basis.py / offset_campaign.py.
"""

# START signal
import numpy as np


def alphabet(sf):
    M = 2**sf
    n = np.arange(M)  # Endpunkt M gehört nicht zum Symbol.
    x0 = np.exp(2j * np.pi * (n**2 / (2 * M) - n / 2))
    return np.stack([
        x0 * np.exp(2j * np.pi * m * n / M)
        for m in range(M)
    ])


def detektor(empfangen, x0):
    # Jede Zeile ist ein Symbol, letzte Achse: M Samples.
    dechirpt = empfangen * np.conj(x0)
    spektrum = np.fft.fft(dechirpt, axis=-1)
    return np.argmax(np.abs(spektrum), axis=-1)


def offset(signal, delta):
    M = signal.shape[-1]
    n = np.arange(M)
    return signal * np.exp(2j * np.pi * delta * n / M)
# END signal


# START statistik
def rauschen(rng, form, snr_db):
    P_N = 10.0 ** (-snr_db / 10)
    a = rng.standard_normal(form)
    b = rng.standard_normal(form)
    return np.sqrt(P_N / 2) * (a + 1j * b)


def wilson(k, N):
    if N <= 0 or not 0 <= k <= N:
        raise ValueError("Erforderlich: 0 <= k <= N, N > 0")
    z = 1.959963984540054
    p = k / N
    d = 1 + z**2 / N
    c = (p + z**2 / (2 * N)) / d
    h = z / d * np.sqrt(p * (1 - p) / N + z**2 / (4 * N**2))
    unten = 0.0 if k == 0 else max(0.0, float(c - h))
    oben = 1.0 if k == N else min(1.0, float(c + h))
    return unten, oben
# END statistik


# START punkt
def simuliere_punkt(sf, snr_db, stream, delta=0.0, N=5000):
    if N <= 0:
        raise ValueError("N muss positiv sein")
    A = alphabet(sf)
    M = len(A)
    rng = np.random.Generator(
        np.random.PCG64(np.random.SeedSequence(stream))
    )
    k = 0
    for start in range(0, N, 256):
        anzahl = min(256, N - start)
        m = rng.integers(0, M, size=anzahl)
        gesendet = offset(A[m], delta)
        empfangen = gesendet + rauschen(rng, gesendet.shape, snr_db)
        erkannt = detektor(empfangen, A[0])
        # Auch mit Offset bleibt m der richtige gesendete Index.
        k += int(np.count_nonzero(erkannt != m))
    return k, k / N, wilson(k, N)
# END punkt


# START beispiele
def main():
    A = alphabet(7)
    np.testing.assert_array_equal(detektor(A, A[0]), np.arange(128))
    peak = np.abs(np.fft.fft(A[17] * A[0].conj()))
    print("Symbol 17: Bin", np.argmax(peak), "Peak", peak.max())
    # Sample-SNR -12 dB ist Rasterindex 6 der Kampagne 1.
    print("Sample-SNR:", simuliere_punkt(
        7, -12.0, [20261103, 1, 7, 6]))
    # 10 dB E_s/N_0 ist Rasterindex 5 der Kampagne 2.
    snr = 10.0 - 10 * np.log10(128)
    print("Energie:", simuliere_punkt(
        7, snr, [20261103, 2, 7, 5]))
    # Energieindex 1: 16 dB; Offsetindex 8: delta = +0.5.
    snr = 16.0 - 10 * np.log10(128)
    print("Halber Bin:", simuliere_punkt(
        7, snr, [20261104, 3, 7, 1, 8], delta=0.5))
    print("Nullfehlerintervall:", wilson(0, 5000))


if __name__ == "__main__":
    main()
# END beispiele
