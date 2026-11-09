"""KI-gestützte Kontrollrechnung zu Kapitel 2, keine Hardwareauswertung.

Aufruf: python3 scripts/check_grundlagen.py
Die Prüfung belegt Rechenkonsistenz, keine persönliche Nachrechnung durch Tilman.
"""
import cmath
import json
import math

c = 299_792_458.0
frequency = 2.4e9
distance = 100.0
wavelength = c / frequency
power_tx_w = 10e-3
gain_tx = gain_rx = 10 ** (2 / 10)
additional_transmission = 10 ** (-2 / 10)

# Direkte Multiplikation in SI-Einheiten.
power_rx_w = (power_tx_w * gain_tx * gain_rx
              * (wavelength / (4 * math.pi * distance)) ** 2
              * additional_transmission)
# Separater Rechenweg über die praktische Freiraumform mit MHz und km.
constant_mhz_km = 20 * math.log10(4 * math.pi * 1e9 / c)
loss_db = (constant_mhz_km + 20 * math.log10(frequency / 1e6)
           + 20 * math.log10(distance / 1e3))
level_rx_dbm = 10 * math.log10(power_tx_w / 1e-3) + 2 + 2 - loss_db - 2
assert math.isclose(10 * math.log10(power_rx_w / 1e-3), level_rx_dbm,
                    abs_tol=1e-10)
assert math.isclose(loss_db, 80.05, abs_tol=0.005)
assert math.isclose(power_rx_w * 1e12, 157, abs_tol=0.5)

# Weitere im Kapitel verwendete Umrechnungen und Grenzfälle.
dbm_cases = {0: 1e-3, -30: 1e-6, -60: 1e-9}
for dbm, expected_w in dbm_cases.items():
    assert math.isclose(1e-3 * 10 ** (dbm / 10), expected_w, rel_tol=1e-12)
assert math.isclose(10 ** ((-70 - (-80)) / 10), 10)
assert math.isclose(10 * math.log10(2), 3.01, abs_tol=0.005)
for angle, expected in [(0, 1), (45, 0.5), (90, 0)]:
    assert math.isclose(math.cos(math.radians(angle)) ** 2, expected,
                        abs_tol=1e-14)
# Komplexe Summe gegen die reelle Interferenzformel, auch ungleiche Beiträge.
for a1, a2 in [(1, 1), (0.5, 2)]:
    for phase in [0, math.pi / 3, math.pi / 2, math.pi]:
        summed_power = abs(a1 + a2 * cmath.exp(1j * phase)) ** 2
        expanded = a1*a1 + a2*a2 + 2*a1*a2*math.cos(phase)
        assert math.isclose(summed_power, expanded, abs_tol=1e-14)
assert math.isclose(abs(1 + cmath.exp(1j * math.pi)) ** 2, 0, abs_tol=1e-14)
# Spitzen- und Effektivwertform des Poynting-Mittels (E0 = 1 V/m).
eta0 = 376.730313
assert math.isclose(1 / (2 * eta0), (1 / math.sqrt(2))**2 / eta0,
                    rel_tol=1e-12)
assert math.isclose(20 * math.log10(2400 / 868), 8.83, abs_tol=0.005)
assert math.isclose(level_rx_dbm - 20 * math.log10(2), -74.07, abs_tol=0.005)

result = {
    'lambda_2400_MHz_m': wavelength,
    'lambda_868_MHz_m': c / 868e6,
    'freiraumdaempfung_100_m_db': loss_db,
    'empfangspegel_100_m_dbm': level_rx_dbm,
    'empfangsleistung_100_m_W': power_rx_w,
    'empfangspegel_200_m_dbm': level_rx_dbm - 20 * math.log10(2),
    'distanzverdopplung_db': 20 * math.log10(2),
    'frequenzvergleich_db': 20 * math.log10(2400 / 868),
    'polarisation_45_grad': math.cos(math.radians(45)) ** 2,
    'konsistenz_lineare_und_logarithmische_rechnung': True,
    'dbm_kontrollfaelle_W': dbm_cases,
    'interferenz_acht_faelle_geprueft': True,
    'polarisation_0_45_90_grad_geprueft': True,
    'poynting_spitzen_und_effektivwert_konsistent': True,
}
print(json.dumps(result, indent=2, ensure_ascii=False))
