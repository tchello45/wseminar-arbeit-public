"""Kapitel 6: Ergebnisprüfung und vollständige Neurechnung aus den Listings."""
import csv
import hashlib
import json
import math
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/src'))
from simulation.kapitel6 import alphabet, detektor, offset, simuliere_punkt, wilson
from simulation.css import erzeuge_symbol, referenzchirp

OUT = ROOT / 'tools/src/simulation/ergebnisse'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    controls = []
    for sf in (7, 8, 9):
        A = alphabet(sf)
        M = len(A)
        _, x0 = referenzchirp(sf, 125000)
        expected = np.stack([erzeuge_symbol(x0, m) for m in range(M)])
        np.testing.assert_allclose(A, expected, atol=1e-12, rtol=0)
        np.testing.assert_array_equal(detektor(A, A[0]), np.arange(M))
        np.testing.assert_allclose(A @ A.conj().T / M, np.eye(M), atol=1e-10)
        for delta in (-1, 0, 1):
            np.testing.assert_array_equal(
                detektor(offset(A, delta), A[0]), (np.arange(M) + delta) % M)
        spec = np.fft.fft(offset(A, 0.5) * A[0].conj(), axis=-1)
        m = np.arange(M)
        np.testing.assert_allclose(abs(spec[m, m]), abs(spec[m, (m+1) % M]), atol=1e-10)
        # Unabhängiger geschlossener Betrag für die geometrische Summe.
        d = 0.5 - np.arange(M)
        np.testing.assert_allclose(abs(spec[0]), M*abs(np.sinc(d)/np.sinc(d/M)), atol=1e-10)
        controls.append(dict(sf=sf, noiseless_symbols=M, integer_offsets=3*M,
                             half_bin_symbols=M, maximum_alphabet_difference=float(abs(A-expected).max())))
    records = []
    for name, campaign in [('css-awgn.csv', 1), ('css-awgn-energy.csv', 2), ('css-offset-awgn.csv', 3)]:
        rows = list(csv.DictReader((OUT / name).open()))
        assert len(rows) == {1:39, 2:30, 3:66}[campaign]
        keys = set()
        for row in rows:
            sf, N, k = int(row['sf']), int(row['trials']), int(row['errors'])
            M, snr = 2**sf, float(row['snr_per_sample_db'])
            energy, delta = float(row['es_n0_db']), float(row.get('delta', 0))
            assert N == 5000 and 0 <= k <= N
            assert math.isclose(float(row['bandwidth_hz']), 125000)
            assert math.isclose(energy, snr + 10*math.log10(M), abs_tol=1e-12)
            assert math.isclose(float(row['noise_power']), 10**(-snr/10), rel_tol=1e-12)
            assert math.isclose(float(row['ser']), k/N, abs_tol=1e-15)
            # Zweiter Rechenweg mit Standardbibliothek, unabhängig vom Listing.
            z, p = 1.959963984540054, k/N
            c = (p+z*z/(2*N))/(1+z*z/N)
            h = z*math.sqrt(p*(1-p)/N+z*z/(4*N*N))/(1+z*z/N)
            assert math.isclose(float(row['wilson95_lower']), max(0,c-h), abs_tol=1e-14)
            assert math.isclose(float(row['wilson95_upper']), min(1,c+h), abs_tol=1e-14)
            key = (sf, energy, delta)
            assert key not in keys
            keys.add(key)
            if campaign == 1:
                stream = [20261103, 1, sf, list(range(-24,1,2)).index(int(snr))]
            elif campaign == 2:
                stream = [20261103, 2, sf, list(range(0,19,2)).index(int(energy))]
            else:
                deltas = [-1,-.75,-.5,-.49,-.25,0,.25,.49,.5,.75,1]
                stream = [20261104, 3, sf, [10,16].index(energy), deltas.index(delta)]
                assert math.isclose(float(row['frequency_offset_hz']), delta*125000/M, abs_tol=1e-12)
            actual, rate, bounds = simuliere_punkt(sf, snr, stream, delta, N)
            assert actual == k, (name, key, k, actual)
            records.append(dict(file=name, sf=sf, energy_db=energy, delta=delta, errors=k, replay_errors=actual))
        print(f'{name}: {len(rows)} Punkte vollständig nachgerechnet', flush=True)
    manifests = []
    for filename in ('lauf.json', 'css-offset-lauf.json'):
        manifest = json.loads((OUT/filename).read_text())
        hashes = manifest['csv_sha256']
        if isinstance(hashes, str):
            hashes = {'css-offset-awgn.csv': hashes}
        for name, expected in hashes.items():
            assert sha(OUT/name) == expected
        manifests.append(dict(file=filename, csv_hashes='passed',
                              historical_source_hashes=manifest['source_sha256']))
    for N in (1, 5000):
        np.testing.assert_allclose(wilson(0,N), (0,1.959963984540054**2/(N+1.959963984540054**2)), atol=1e-15)
        np.testing.assert_allclose(wilson(N,N), (1-wilson(0,N)[1],1), atol=1e-15)
    chapter = (ROOT/'arbeit/kapitel/05-simulation.typ').read_text()
    assert '#aufgabe' not in chapter
    code = (ROOT/'tools/src/simulation/kapitel6.py').read_text()
    assert (ROOT/'arbeit/listings/kapitel6.py').read_bytes() == (ROOT/'tools/src/simulation/kapitel6.py').read_bytes()
    assert 'read("../listings/kapitel6.py")' in chapter
    for part in ('signal','statistik','punkt','beispiele'):
        assert f'#listing("{part}")' in chapter
        assert code.count('# START '+part+'\n') == code.count('# END '+part+'\n') == 1
    result = dict(created_utc=datetime.now(timezone.utc).isoformat(), python=platform.python_version(),
                  numpy=np.__version__, controls=controls, points=len(records), symbols=675000,
                  all_error_counts_replayed=True, rows=records, manifests=manifests,
                  sources={str(p.relative_to(ROOT)):sha(p) for p in [Path(__file__), ROOT/'tools/src/simulation/kapitel6.py', ROOT/'arbeit/kapitel/05-simulation.typ']},
                  hardware_validation='not performed; RS02 device comparison remains in chapter 7')
    target = ROOT/'nachweise/KAPITEL06-pruefung.json'
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    print(f'Bestanden: {len(records)} Punkte, 675000 Symbole; {target}')


if __name__ == '__main__':
    main()
