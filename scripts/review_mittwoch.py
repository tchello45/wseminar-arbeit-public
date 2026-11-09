"""Unabhängige Prüfungen der gespeicherten Mittwoch-Ergebnisse (Standardbibliothek)."""
import cmath
import csv
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tools/src/simulation/ergebnisse'
report = json.loads((OUT/'css-offset-lauf.json').read_text())
# The original run identifies its historical source. Current code is validated
# by replaying every campaign point, rather than rewriting the run provenance.
source_matches = {name: hashlib.sha256((OUT.parent/name).read_bytes()).hexdigest() == expected
                  for name, expected in report['source_sha256'].items()}
assert hashlib.sha256((OUT/'css-offset-awgn.csv').read_bytes()).hexdigest() == report['csv_sha256']
rows = list(csv.DictReader((OUT/'css-offset-awgn.csv').open()))
assert len(rows) == 66
keys = set()
for r in rows:
    sf, delta, energy = int(r['sf']), float(r['delta']), float(r['es_n0_db'])
    keys.add((sf, delta, energy))
    n, k = int(r['trials']), int(r['errors'])
    p = k/n
    assert 0 <= k <= n and math.isclose(p, float(r['ser']), abs_tol=1e-15)
    z = 1.959963984540054
    c = (p+z*z/(2*n))/(1+z*z/n)
    h = z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/(1+z*z/n)
    assert math.isclose(max(0,c-h), float(r['wilson95_lower']), abs_tol=1e-14)
    assert math.isclose(min(1,c+h), float(r['wilson95_upper']), abs_tol=1e-14)
    assert math.isclose(float(r['noise_power'])/(2**sf), 10**(-energy/10), rel_tol=1e-12)
    assert math.isclose(float(r['frequency_offset_hz']), delta*125000/(2**sf), abs_tol=1e-12)
assert len(keys) == 66
pilot = []
for name in ('01','02','03'):
    raw = ROOT/f'daten/roh/{name}.s1p'
    data = [line.split() for line in raw.read_text().splitlines() if line.strip() and not line.startswith(('!', '#'))]
    calculated = list(csv.DictReader((ROOT/f'daten/auswertung/{name}-s11.csv').open()))
    assert len(data) == len(calculated) == 101
    for source, result in zip(data, calculated):
        f, re, im = map(float, source)
        g = complex(re,im)
        assert f == float(result['frequency_hz'])
        # Spaltennamen und Toleranzen am tatsächlichen Export prüfen.
        z = 50*(1+g)/(1-g)
        expected = {'s11_re': g.real, 's11_im': g.imag, 'z0_ohm': 50,
                    'magnitude': abs(g), 'phase_deg': math.degrees(cmath.phase(g)),
                    's11_db': 20*math.log10(abs(g)), 'z_re_ohm': z.real,
                    'z_im_ohm': z.imag, 'vswr': (1+abs(g))/(1-abs(g))}
        for column, value in expected.items():
            assert math.isclose(value, float(result[column]), abs_tol=1e-10, rel_tol=1e-12)
        assert result['z_status'] == 'finite' and result['vswr_status'] == 'finite'
    pilot.append(dict(file=str(raw.relative_to(ROOT)), sha256=hashlib.sha256(raw.read_bytes()).hexdigest(), points=len(data), frequency_min_hz=float(data[0][0]), frequency_max_hz=float(data[-1][0])))
assert pilot[0]['sha256'] == pilot[1]['sha256']
print(json.dumps(dict(offset_points=66, symbols=sum(int(r['trials']) for r in rows), csv_hash='passed', historical_source_matches=source_matches, energy_normalization_and_wilson='passed', vna_exports=pilot, vna_repeat='03: reconnected under unchanged calibration, per user 2026-11-04; 01 and 02 identical', device_marker_comparison='separate frozen dataset checked by check_gesamt.py'), ensure_ascii=False, indent=2))
