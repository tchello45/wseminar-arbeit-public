"""Unabhängige Kontrollrechnungen zu Kapitel 3, nur Python-Standardbibliothek.

Aufruf: python3 scripts/check_css_theorie.py
Ausgabe: JSON auf stdout. Keine Messung oder persönliche Verständnisprüfung.
"""
import cmath
import json
import math

bandwidth = 125_000.0
rows = []
wrap_cases = 0
max_wrap_error = 0.0
for sf in (7, 8, 9):
    size = 2**sf
    duration = size / bandwidth
    rows.append({
        'sf': sf, 'M': size, 'symbolzeit_s': duration,
        'bitrate_bit_s': sf / duration,
        'binabstand_Hz': 1 / duration,
        'B_durch_Rb': size / sf,
    })
    # Kontinuierliche Phase durch Integration der stückweisen Frequenz.
    # Vergleich mit der kompakten diskreten Formel für sämtliche Samples.
    for symbol in range(size):
        wrap_time = (size - symbol) / bandwidth
        for n in range(size):
            t = n / bandwidth
            cycles = (-bandwidth / 2 + symbol * bandwidth / size) * t
            cycles += bandwidth * t * t / (2 * duration)
            cycles -= bandwidth * max(0.0, t - wrap_time)
            discrete = n*n/(2*size) - n/2 + symbol*n/size
            error = abs(cmath.exp(2j*math.pi*cycles)
                        - cmath.exp(2j*math.pi*discrete))
            max_wrap_error = max(max_wrap_error, error)
            assert error < 2e-11, (sf, symbol, n, error)
            wrap_cases += 1
assert math.isclose(rows[0]['symbolzeit_s'], 0.001024)
assert math.isclose(rows[0]['bitrate_bit_s'], 6835.9375)
assert math.isclose(rows[1]['bitrate_bit_s'], 3906.25)

# Direkte DFT-Summe statt FFT: Null-, Rand-, Ganzzahl- und Halb-Bin-Fälle.
size = 128
spectra = []
for symbol, delta in [(17, 0), (127, 1), (0, -1), (17, 0.5)]:
    spectrum = [abs(sum(cmath.exp(2j*math.pi*(symbol+delta-k)*n/size)
                        for n in range(size))) for k in range(size)]
    if delta == 0.5:
        assert math.isclose(spectrum[17], spectrum[18], abs_tol=1e-10)
        assert max(spectrum) <= spectrum[17] + 1e-10
    else:
        peak = (symbol + int(delta)) % size
        assert math.isclose(spectrum[peak], size, abs_tol=1e-10)
        assert max(v for k, v in enumerate(spectrum) if k != peak) < 1e-10
    spectra.append({'m': symbol, 'delta': delta, 'maximaler_Betrag': max(spectrum)})

print(json.dumps({
    'status': 'bestanden', 'modell': 'B = f_s = 125000 Hz',
    'parameter': rows, 'wrap_samplevergleiche': wrap_cases,
    'maximaler_komplexer_wrap_fehler': max_wrap_error,
    'direkte_DFT_Kontrollen': spectra,
    'rauschleistung_bei_SNR_dB': {'0': 10**0, '-10': 10**1},
}, ensure_ascii=False, indent=2))
