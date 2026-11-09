//! CSS symbol model with fs = B, matching the Python model in tools/src/simulation.
//! The same core runs in native Rust tests and in the browser via wasm-bindgen.

use num_complex::Complex64;
use serde::{Deserialize, Serialize};
use std::f64::consts::TAU;
use wasm_bindgen::prelude::*;

pub const BANDWIDTH: f64 = 125_000.0;

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Parameters {
    pub sf: u32,
    pub symbol: u32,
    pub noise: bool,
    pub snr: f64,
    pub offset: f64,
    pub seed: u32,
}

impl Default for Parameters {
    fn default() -> Self {
        Self {
            sf: 7,
            symbol: 17,
            noise: false,
            snr: -12.0,
            offset: 0.0,
            seed: 20261103,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct Sample {
    pub time: f64,
    pub frequency: f64,
    pub received: f64,
    pub dechirped: f64,
}

#[derive(Debug, Serialize)]
pub struct Bin {
    pub bin: usize,
    pub magnitude: f64,
}

#[derive(Debug, Serialize)]
pub struct ComplexSample {
    pub re: f64,
    pub im: f64,
}

impl From<Complex64> for ComplexSample {
    fn from(value: Complex64) -> Self {
        Self {
            re: value.re,
            im: value.im,
        }
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Simulation {
    pub samples: Vec<Sample>,
    pub spectrum: Vec<Bin>,
    pub detected: usize,
    pub received: Vec<ComplexSample>,
    pub dechirped: Vec<ComplexSample>,
    pub size: usize,
    pub duration: f64,
    pub bin_width: f64,
}

/// Unnormalised forward radix-2 FFT (same convention as numpy.fft.fft).
fn fft(values: &mut [Complex64]) {
    let size = values.len();
    debug_assert!(size.is_power_of_two());
    let mut j = 0;
    for i in 1..size {
        let mut bit = size >> 1;
        while j & bit != 0 {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if i < j {
            values.swap(i, j);
        }
    }
    let mut length = 2;
    while length <= size {
        for start in (0..size).step_by(length) {
            for k in 0..length / 2 {
                let twiddle = Complex64::from_polar(1.0, -TAU * k as f64 / length as f64);
                let odd = values[start + k + length / 2] * twiddle;
                let even = values[start + k];
                values[start + k] = even + odd;
                values[start + k + length / 2] = even - odd;
            }
        }
        length *= 2;
    }
}

// Mulberry32 and Box–Muller. Wrapping u32 arithmetic specifies the PRNG exactly.
struct Gaussian {
    state: u32,
}
impl Gaussian {
    fn uniform(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x6d2b79f5);
        let mut value = (self.state ^ (self.state >> 15)).wrapping_mul(1 | self.state);
        value ^= value.wrapping_add((value ^ (value >> 7)).wrapping_mul(61 | value));
        f64::from(value ^ (value >> 14)) / 4294967296.0
    }
    fn pair(&mut self) -> Complex64 {
        let radius = (-2.0 * (1.0 - self.uniform()).ln()).sqrt();
        Complex64::from_polar(radius, TAU * self.uniform())
    }
}

pub fn simulate(parameters: &Parameters) -> Result<Simulation, String> {
    let p = parameters;
    if !(7..=9).contains(&p.sf) {
        return Err("SF muss 7, 8 oder 9 sein.".into());
    }
    let size = 1_usize << p.sf;
    if p.symbol as usize >= size {
        return Err("Symbol außerhalb des Alphabets.".into());
    }
    if !p.snr.is_finite()
        || !(-24.0..=0.0).contains(&p.snr)
        || !p.offset.is_finite()
        || p.offset.abs() > 2.0
    {
        return Err("SNR oder Frequenzoffset außerhalb des gültigen Bereichs.".into());
    }
    let mut gaussian = Gaussian { state: p.seed };
    let sigma = if p.noise {
        (10_f64.powf(-p.snr / 10.0) / 2.0).sqrt()
    } else {
        0.0
    };
    let mut received = Vec::with_capacity(size);
    let mut dechirped = Vec::with_capacity(size);
    let mut samples = Vec::with_capacity(size);
    for index in 0..size {
        let n = index as f64;
        let reference_phase = TAU * (n * n / (2.0 * size as f64) - n / 2.0);
        let phase = reference_phase + TAU * (f64::from(p.symbol) + p.offset) * n / size as f64;
        let rx = Complex64::from_polar(1.0, phase) + sigma * gaussian.pair();
        let dechirp = rx * Complex64::from_polar(1.0, -reference_phase);
        samples.push(Sample {
            time: n / BANDWIDTH * 1000.0,
            frequency: (((index + p.symbol as usize) % size) as f64 / size as f64 - 0.5)
                * BANDWIDTH
                / 1000.0,
            received: rx.re,
            dechirped: dechirp.re,
        });
        received.push(rx.into());
        dechirped.push(dechirp);
    }
    let mut transformed = dechirped.clone();
    fft(&mut transformed);
    let spectrum: Vec<Bin> = transformed
        .iter()
        .enumerate()
        .map(|(bin, value)| Bin {
            bin,
            magnitude: value.norm(),
        })
        .collect();
    // Strictly greater: exact ties choose the first bin; rounding can break mathematical ties.
    let mut detected = 0;
    for bin in &spectrum {
        if bin.magnitude > spectrum[detected].magnitude {
            detected = bin.bin;
        }
    }
    Ok(Simulation {
        samples,
        spectrum,
        detected,
        received,
        dechirped: dechirped.into_iter().map(Into::into).collect(),
        size,
        duration: size as f64 / BANDWIDTH * 1000.0,
        bin_width: BANDWIDTH / size as f64,
    })
}

// START WASM_INTERFACE
/// JSON boundary: validates all parameters in Rust and throws a JS exception on error.
#[wasm_bindgen]
pub fn simulate_json(parameters_json: &str) -> Result<String, JsValue> {
    let parameters: Parameters = serde_json::from_str(parameters_json)
        .map_err(|error| JsValue::from_str(&format!("Ungültige Simulationsparameter: {error}")))?;
    let result = simulate(&parameters).map_err(|error| JsValue::from_str(&error))?;
    serde_json::to_string(&result).map_err(|error| JsValue::from_str(&error.to_string()))
}

// END WASM_INTERFACE

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_all_896_symbols() {
        for sf in 7..=9 {
            for symbol in 0..1 << sf {
                let result = simulate(&Parameters {
                    sf,
                    symbol,
                    ..Parameters::default()
                })
                .unwrap();
                assert_eq!(result.detected, symbol as usize);
                assert!(
                    (result.spectrum[symbol as usize].magnitude - result.size as f64).abs() < 1e-8
                );
            }
        }
    }

    #[test]
    fn integer_offsets_wrap_and_half_bin_splits_peak() {
        for sf in 7..=9 {
            let size = 1_i32 << sf;
            for symbol in [0, 17, size - 1] {
                for offset in [-2, -1, 1, 2] {
                    let result = simulate(&Parameters {
                        sf,
                        symbol: symbol as u32,
                        offset: f64::from(offset),
                        ..Parameters::default()
                    })
                    .unwrap();
                    assert_eq!(result.detected, (symbol + offset).rem_euclid(size) as usize);
                }
                let result = simulate(&Parameters {
                    sf,
                    symbol: symbol as u32,
                    offset: 0.5,
                    ..Parameters::default()
                })
                .unwrap();
                assert!(
                    (result.spectrum[symbol as usize].magnitude
                        - result.spectrum[((symbol + 1) % size) as usize].magnitude)
                        .abs()
                        < 1e-8
                );
            }
        }
    }

    #[test]
    fn rejects_invalid_parameters() {
        for p in [
            Parameters {
                sf: 6,
                ..Parameters::default()
            },
            Parameters {
                symbol: 128,
                ..Parameters::default()
            },
            Parameters {
                snr: f64::NAN,
                ..Parameters::default()
            },
            Parameters {
                offset: f64::INFINITY,
                ..Parameters::default()
            },
            Parameters {
                offset: 2.01,
                ..Parameters::default()
            },
        ] {
            assert!(simulate(&p).is_err());
        }
        assert!(
            serde_json::from_str::<Parameters>(
                r#"{"sf":7,"symbol":-1,"noise":false,"snr":-12,"offset":0,"seed":1}"#
            )
            .is_err()
        );
    }

    #[test]
    fn noise_seed_is_reproducible() {
        let p = Parameters {
            noise: true,
            ..Parameters::default()
        };
        assert_eq!(
            serde_json::to_string(&simulate(&p).unwrap()).unwrap(),
            serde_json::to_string(&simulate(&p).unwrap()).unwrap()
        );
        let next = Parameters {
            seed: p.seed + 1,
            ..p.clone()
        };
        assert_ne!(
            simulate(&p).unwrap().received[0].re,
            simulate(&next).unwrap().received[0].re
        );
    }
}
