"""Physikalische Kontrollfälle für den gemeinsamen CSS-Kern."""

import csv
import hashlib
import json
import unittest
from pathlib import Path

import numpy as np
from simulation.basis import chirps, complex_noise, detect, model_checks, wilson
from simulation.css import (
    erkenne_symbol,
    erzeuge_symbol,
    frequenzoffset,
    referenzchirp,
    symbolparameter,
)
from simulation.kapitel6 import simuliere_punkt
from simulation.offset import kontrolliere_offsets
from simulation.offset_campaign import fractional_controls


class CssChecks(unittest.TestCase):
    def test_noiseless_frequency_offset_controls(self):
        rows = kontrolliere_offsets()
        self.assertEqual(len(rows), 9)
        self.assertEqual(sum(row["correct"] for row in rows), 2688)

    def test_frequency_offset_batch_and_fractional_tone(self):
        for sf in (7, 8, 9):
            m = 2**sf
            symbols = np.arange(m)
            samples = chirps(sf, symbols)
            np.testing.assert_array_equal(frequenzoffset(samples), samples)
            for delta in (0, 1, -1):
                np.testing.assert_array_equal(
                    detect(frequenzoffset(samples, delta), sf), (symbols + delta) % m
                )
            _, reference = referenzchirp(sf, 125_000)
            symbol, delta = m - 1, 0.25
            received = frequenzoffset(samples[symbol], delta)
            np.testing.assert_allclose(
                received * reference.conj(),
                np.exp(2j * np.pi * (symbol + delta) * np.arange(m) / m),
                atol=1e-12,
            )
            np.testing.assert_allclose(abs(received), abs(samples[symbol]), atol=1e-12)

    def test_fractional_offset_dirichlet_and_half_bin(self):
        rows = fractional_controls()
        self.assertEqual(len(rows), 33)
        self.assertEqual(sum(r["checked_symbols"] for r in rows), 9856)

    def test_invalid_frequency_offset(self):
        for delta in (np.nan, np.inf, -np.inf):
            with self.assertRaises(ValueError):
                frequenzoffset(np.ones(128), delta)
        for signal in (np.array(1), np.array([])):
            with self.assertRaises(ValueError):
                frequenzoffset(signal)

    def test_all_symbols_and_noise(self):
        checks = model_checks()
        self.assertEqual(
            [row["correct"] for row in checks["noiseless"]], [128, 256, 512]
        )

    def test_dechirped_tone_and_parseval(self):
        for sf in (7, 8, 9):
            m, time, bitrate = symbolparameter(sf, 125_000)
            self.assertAlmostEqual(time, m / 125_000)
            self.assertAlmostEqual(bitrate * time, sf)
            _, reference = referenzchirp(sf, 125_000)
            for symbol in (0, 1, m // 2, m - 1):
                samples = erzeuge_symbol(reference, symbol)
                decoded, spectrum = erkenne_symbol(samples, reference)
                self.assertEqual(decoded, symbol)
                self.assertAlmostEqual(abs(spectrum[symbol]), m)
                self.assertAlmostEqual(float(np.sum(abs(spectrum) ** 2) / m), m)
                np.testing.assert_allclose(
                    samples * reference.conj(),
                    np.exp(2j * np.pi * symbol * np.arange(m) / m),
                    atol=1e-12,
                )
                np.testing.assert_allclose(chirps(sf, np.array([symbol]))[0], samples)
                self.assertEqual(detect(samples, sf), symbol)

    def test_noise_scaling_and_replay(self):
        noise = complex_noise(np.random.default_rng(123), (100_000,), 0)
        replay = complex_noise(np.random.default_rng(123), (100_000,), 0)
        scaled = complex_noise(np.random.default_rng(123), (100_000,), 10)
        np.testing.assert_array_equal(noise, replay)
        np.testing.assert_allclose(scaled, noise / np.sqrt(10), atol=1e-14)
        for sf in (7, 8, 9):
            m = 2**sf
            snr = 8 - 10 * np.log10(m)
            self.assertAlmostEqual(10 ** (-snr / 10) / m, 10 ** (-8 / 10))

    def test_stored_campaigns_replay(self):
        folder = Path(__file__).parents[1] / "src/simulation/ergebnisse"
        self.assertEqual(
            (folder.parent / "kapitel6.py").read_bytes(),
            (folder.parents[3] / "arbeit/listings/kapitel6.py").read_bytes(),
        )
        for name, campaign_id, seed, points in (
            ("css-awgn", 1, 20261103, 39),
            ("css-awgn-energy", 2, 20261103, 30),
            ("css-offset-awgn", 3, 20261104, 66),
        ):
            path = folder / f"{name}.csv"
            report_name = "css-offset-lauf.json" if campaign_id == 3 else "lauf.json"
            report = json.loads((folder / report_name).read_text())
            expected_hash = report["csv_sha256"]
            if campaign_id != 3:
                expected_hash = expected_hash[path.name]
            self.assertEqual(
                hashlib.sha256(path.read_bytes()).hexdigest(), expected_hash
            )
            with path.open(newline="") as stream:
                rows = list(csv.DictReader(stream))
            self.assertEqual(len(rows), points)
            for index, row in enumerate(rows):
                sf = int(row["sf"])
                if campaign_id == 3:
                    energy_index, delta_index = divmod(index % 22, 11)
                    stream = [seed, campaign_id, sf, energy_index, delta_index]
                else:
                    stream = [seed, campaign_id, sf, index % (points // 3)]
                with self.subTest(campaign=name, point=index):
                    errors, ser, interval = simuliere_punkt(
                        sf,
                        float(row["snr_per_sample_db"]),
                        stream,
                        delta=float(row.get("delta", 0)),
                        N=int(row["trials"]),
                    )
                    self.assertEqual(errors, int(row["errors"]))
                    self.assertEqual(ser, float(row["ser"]))
                    self.assertAlmostEqual(interval[0], float(row["wilson95_lower"]))
                    self.assertAlmostEqual(interval[1], float(row["wilson95_upper"]))

    def test_wilson_boundaries(self):
        z2 = 1.959963984540054**2
        lower, upper = wilson(0, 5000)
        self.assertAlmostEqual(lower, 0)
        self.assertAlmostEqual(upper, z2 / (5000 + z2))
        self.assertAlmostEqual(wilson(5000, 5000)[0], 1 - upper)
        self.assertAlmostEqual(wilson(2500, 5000)[0], 1 - wilson(2500, 5000)[1])
        for errors, trials in ((-1, 5), (6, 5), (0, 0)):
            with self.assertRaises(ValueError):
                wilson(errors, trials)


if __name__ == "__main__":
    unittest.main()
