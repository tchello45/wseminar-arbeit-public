use crate::{Auswertung, Complex64, Impedanz, Vswr, auswerten, touchstone::Messpunkt};
use serde::{Deserialize, Serialize};
use std::io::{Read, Write};
use thiserror::Error;

const HEADER: &[&str] = &[
    "s11_re",
    "s11_im",
    "z0_ohm",
    "magnitude",
    "phase_deg",
    "s11_db",
    "z_re_ohm",
    "z_im_ohm",
    "z_status",
    "vswr",
    "vswr_status",
];

#[derive(Debug, Error)]
pub enum CsvFehler {
    #[error(transparent)]
    Csv(#[from] ::csv::Error),
    #[error("Datensatz {datensatz}: {grund}")]
    Messwert { datensatz: usize, grund: String },
    #[error("Keine Einportdaten vorhanden")]
    Leer,
}

#[derive(Deserialize)]
struct Eingabe {
    frequency_hz: f64,
    #[serde(alias = "s11_real")]
    s11_re: f64,
    #[serde(alias = "s11_imag")]
    s11_im: f64,
    #[serde(default = "standardimpedanz")]
    z0_ohm: f64,
}

fn standardimpedanz() -> f64 {
    50.0
}

/// Liest komplexe S11-Werte; abgeleitete CSV-Spalten werden neu berechnet.
pub fn einlesen(reader: impl Read) -> Result<Vec<Messpunkt>, CsvFehler> {
    let mut reader = ::csv::ReaderBuilder::new()
        .trim(::csv::Trim::All)
        .from_reader(reader);
    let mut punkte: Vec<Messpunkt> = Vec::new();
    for (index, row) in reader.deserialize::<Eingabe>().enumerate() {
        let row = row?;
        let fehler = |grund: String| CsvFehler::Messwert {
            datensatz: index + 1,
            grund,
        };
        if !row.frequency_hz.is_finite() || row.frequency_hz < 0.0 {
            return Err(fehler(
                "Frequenz muss endlich und nicht negativ sein".into(),
            ));
        }
        if punkte
            .last()
            .is_some_and(|p| row.frequency_hz <= p.frequency_hz)
        {
            return Err(fehler("Frequenzen müssen streng aufsteigend sein".into()));
        }
        let s11 = auswerten(Complex64::new(row.s11_re, row.s11_im), row.z0_ohm)
            .map_err(|error| fehler(error.to_string()))?;
        punkte.push(Messpunkt {
            frequency_hz: row.frequency_hz,
            s11,
        });
    }
    if punkte.is_empty() {
        return Err(CsvFehler::Leer);
    }
    Ok(punkte)
}

#[derive(Serialize)]
struct Ausgabe {
    s11_re: f64,
    s11_im: f64,
    z0_ohm: f64,
    magnitude: f64,
    phase_deg: String,
    s11_db: f64,
    z_re_ohm: Option<f64>,
    z_im_ohm: Option<f64>,
    z_status: &'static str,
    vswr: Option<f64>,
    vswr_status: &'static str,
}

impl From<Auswertung> for Ausgabe {
    fn from(value: Auswertung) -> Self {
        let (z_re_ohm, z_im_ohm, z_status) = match value.impedanz {
            Impedanz::Endlich(z) => (Some(z.re), Some(z.im), "finite"),
            Impedanz::Singulaer => (None, None, "singular"),
        };
        let (vswr, vswr_status) = match value.vswr {
            Vswr::Endlich(x) => (Some(x), "finite"),
            Vswr::Unendlich => (Some(f64::INFINITY), "infinite"),
            Vswr::AusserhalbPassivenBereichs => (None, "outside_passive_range"),
        };
        Self {
            s11_re: value.gamma.re,
            s11_im: value.gamma.im,
            z0_ohm: value.z0_ohm,
            magnitude: value.betrag,
            phase_deg: value
                .phase_grad
                .map_or_else(|| "undefined".into(), |x| x.to_string()),
            s11_db: value.s11_db,
            z_re_ohm,
            z_im_ohm,
            z_status,
            vswr,
            vswr_status,
        }
    }
}

pub fn einzelwert(writer: impl Write, wert: Auswertung) -> Result<(), ::csv::Error> {
    let mut writer = ::csv::Writer::from_writer(writer);
    writer.serialize(Ausgabe::from(wert))?;
    Ok(writer.flush()?)
}

pub fn messreihe(writer: impl Write, punkte: &[Messpunkt]) -> Result<(), ::csv::Error> {
    let mut writer = ::csv::WriterBuilder::new()
        .has_headers(false)
        .from_writer(writer);
    writer.write_record(std::iter::once("frequency_hz").chain(HEADER.iter().copied()))?;
    for punkt in punkte {
        writer.serialize((punkt.frequency_hz, Ausgabe::from(punkt.s11)))?;
    }
    Ok(writer.flush()?)
}
