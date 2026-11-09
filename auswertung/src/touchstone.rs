//! Begrenzter Touchstone-1.x-Einportimport mit expliziter Optionszeile.

use crate::{Auswertung, Complex64, auswerten};
use std::{error::Error, fmt, fs, path::Path};

#[derive(Debug, Clone, PartialEq)]
pub struct Messpunkt {
    pub frequency_hz: f64,
    pub s11: Auswertung,
}

#[derive(Debug)]
pub struct Importfehler {
    pub zeile: Option<usize>,
    pub grund: String,
}

impl Importfehler {
    fn neu(zeile: usize, grund: impl Into<String>) -> Self {
        Self {
            zeile: Some(zeile),
            grund: grund.into(),
        }
    }
}

impl fmt::Display for Importfehler {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if let Some(zeile) = self.zeile {
            write!(f, "Zeile {zeile}: ")?;
        }
        f.write_str(&self.grund)
    }
}

impl Error for Importfehler {}

#[derive(Clone, Copy)]
enum Format {
    Ri,
    Ma,
    Db,
}

struct Optionen {
    frequenzfaktor: f64,
    format: Format,
    z0: f64,
}

fn zahl(token: &str, zeile: usize) -> Result<f64, Importfehler> {
    let wert = token
        .parse::<f64>()
        .map_err(|_| Importfehler::neu(zeile, format!("Ungültige Zahl: {token}")))?;
    if !wert.is_finite() {
        return Err(Importfehler::neu(zeile, "Nur endliche Zahlen unterstützt"));
    }
    Ok(wert)
}

fn optionen(text: &str, zeile: usize) -> Result<Optionen, Importfehler> {
    let tokens: Vec<_> = text
        .split_whitespace()
        .map(str::to_ascii_uppercase)
        .collect();
    if tokens.len() != 5 || tokens[1] != "S" || tokens[3] != "R" {
        return Err(Importfehler::neu(
            zeile,
            "Erwartet: # HZ/KHZ/MHZ/GHZ S RI/MA/DB R <positives Z0>; alle Optionen explizit",
        ));
    }
    let frequenzfaktor = match tokens[0].as_str() {
        "HZ" => 1.0,
        "KHZ" => 1e3,
        "MHZ" => 1e6,
        "GHZ" => 1e9,
        _ => {
            return Err(Importfehler::neu(
                zeile,
                "Nicht unterstützte Frequenzeinheit",
            ));
        }
    };
    let format = match tokens[2].as_str() {
        "RI" => Format::Ri,
        "MA" => Format::Ma,
        "DB" => Format::Db,
        _ => {
            return Err(Importfehler::neu(
                zeile,
                "Nicht unterstützte S11-Darstellung",
            ));
        }
    };
    let z0 = zahl(&tokens[4], zeile)?;
    if z0 <= 0.0 {
        return Err(Importfehler::neu(zeile, "Z0 muss positiv sein"));
    }
    Ok(Optionen {
        frequenzfaktor,
        format,
        z0,
    })
}

impl Optionen {
    fn messpunkt(&self, text: &str, zeile: usize) -> Result<Messpunkt, Importfehler> {
        let tokens: Vec<_> = text.split_whitespace().collect();
        if tokens.len() != 3 {
            return Err(Importfehler::neu(
                zeile,
                "Genau Frequenz und zwei S11-Werte pro Zeile erwartet (ein Port)",
            ));
        }
        let frequency_hz = zahl(tokens[0], zeile)? * self.frequenzfaktor;
        if !frequency_hz.is_finite() || frequency_hz < 0.0 {
            return Err(Importfehler::neu(
                zeile,
                "Frequenz muss endlich und nicht negativ sein",
            ));
        }
        let a = zahl(tokens[1], zeile)?;
        let b = zahl(tokens[2], zeile)?;
        let gamma = match self.format {
            Format::Ri => Complex64::new(a, b),
            Format::Ma if a < 0.0 => {
                return Err(Importfehler::neu(
                    zeile,
                    "MA-Betrag darf nicht negativ sein",
                ));
            }
            Format::Ma => Complex64::from_polar(a, b.to_radians()),
            Format::Db => {
                let betrag = 10.0_f64.powf(a / 20.0);
                if !betrag.is_finite() || betrag == 0.0 {
                    return Err(Importfehler::neu(
                        zeile,
                        "DB-Umrechnung außerhalb des Zahlenbereichs",
                    ));
                }
                Complex64::from_polar(betrag, b.to_radians())
            }
        };
        let s11 = auswerten(gamma, self.z0)
            .map_err(|error| Importfehler::neu(zeile, error.to_string()))?;
        Ok(Messpunkt { frequency_hz, s11 })
    }
}

/// Prüft den gesamten Einportimport; erfordert explizite Optionen und einen Punkt pro Zeile.
pub fn parse(text: &str) -> Result<Vec<Messpunkt>, Importfehler> {
    let mut opts = None;
    let mut punkte: Vec<Messpunkt> = Vec::new();
    for (index, roh) in text.lines().enumerate() {
        let zeile = index + 1;
        let inhalt = roh.split('!').next().unwrap_or_default().trim();
        if inhalt.is_empty() {
            continue;
        }
        if inhalt.starts_with('[') {
            return Err(Importfehler::neu(
                zeile,
                "Touchstone-2.x-Schlüsselwörter nicht unterstützt",
            ));
        }
        if let Some(optionstext) = inhalt.strip_prefix('#') {
            if opts.is_some() {
                return Err(Importfehler::neu(
                    zeile,
                    "Zusätzliche Optionszeile nicht unterstützt",
                ));
            }
            opts = Some(optionen(optionstext, zeile)?);
            continue;
        }
        let opts = opts
            .as_ref()
            .ok_or_else(|| Importfehler::neu(zeile, "Optionszeile fehlt vor den Daten"))?;
        let Messpunkt { frequency_hz, s11 } = opts.messpunkt(inhalt, zeile)?;
        if punkte
            .last()
            .is_some_and(|p| frequency_hz <= p.frequency_hz)
        {
            return Err(Importfehler::neu(
                zeile,
                "Frequenzen müssen streng aufsteigend sein",
            ));
        }
        punkte.push(Messpunkt { frequency_hz, s11 });
    }
    if punkte.is_empty() {
        return Err(Importfehler {
            zeile: None,
            grund: "Keine Einportdaten vorhanden".into(),
        });
    }
    Ok(punkte)
}

pub fn einlesen(pfad: &Path) -> Result<Vec<Messpunkt>, Importfehler> {
    if !pfad
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("s1p"))
    {
        return Err(Importfehler {
            zeile: None,
            grund: "Nur .s1p-Einportdateien unterstützt".into(),
        });
    }
    let text = fs::read_to_string(pfad).map_err(|error| Importfehler {
        zeile: None,
        grund: format!("{}: {error}", pfad.display()),
    })?;
    parse(&text)
}
