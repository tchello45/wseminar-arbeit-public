//! S11 als komplexes Amplitudenverhältnis; Winkel in Grad, Impedanzen in Ohm.

pub use num_complex::Complex64;
pub mod touchstone;
use thiserror::Error;

pub mod csv;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Impedanz {
    Endlich(Complex64),
    /// Γ = 1: kein eindeutiger endlicher komplexer Wert.
    Singulaer,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Vswr {
    Endlich(f64),
    Unendlich,
    /// |Γ| > 1: die passive VSWR-Formel liefert keinen gültigen Wert.
    AusserhalbPassivenBereichs,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Auswertung {
    pub gamma: Complex64,
    pub z0_ohm: f64,
    pub betrag: f64,
    /// Bei Γ = 0 undefiniert.
    pub phase_grad: Option<f64>,
    /// Bei Γ = 0 negativ unendlich; kein positiver Return-Loss-Wert.
    pub s11_db: f64,
    pub impedanz: Impedanz,
    pub vswr: Vswr,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Error)]
pub enum Rechenfehler {
    #[error("Real- und Imaginärteil von Γ müssen endlich sein")]
    GammaNichtEndlich,
    #[error("Z0 muss reell, endlich und positiv sein")]
    ReferenzimpedanzUngueltig,
    #[error("Ergebnis überschreitet den f64-Zahlenbereich")]
    ZahlenbereichUeberschritten,
}

/// Berechnet Reflexionsgrößen; Singularitäten gelten nur bei exakter Gleichheit.
pub fn auswerten(gamma: Complex64, z0_ohm: f64) -> Result<Auswertung, Rechenfehler> {
    if !gamma.re.is_finite() || !gamma.im.is_finite() {
        return Err(Rechenfehler::GammaNichtEndlich);
    }
    if !z0_ohm.is_finite() || z0_ohm <= 0.0 {
        return Err(Rechenfehler::ReferenzimpedanzUngueltig);
    }
    let betrag = gamma.re.hypot(gamma.im);
    if !betrag.is_finite() {
        return Err(Rechenfehler::ZahlenbereichUeberschritten);
    }
    let phase_grad = (betrag != 0.0).then(|| gamma.arg().to_degrees());
    let s11_db = 20.0 * betrag.log10();
    let vswr = if betrag < 1.0 {
        Vswr::Endlich((1.0 + betrag) / (1.0 - betrag))
    } else if betrag == 1.0 {
        Vswr::Unendlich
    } else {
        Vswr::AusserhalbPassivenBereichs
    };
    let impedanz = if gamma == Complex64::new(1.0, 0.0) {
        Impedanz::Singulaer
    } else {
        let z = ((1.0 + gamma) / (1.0 - gamma)) * z0_ohm;
        if !z.re.is_finite() || !z.im.is_finite() {
            return Err(Rechenfehler::ZahlenbereichUeberschritten);
        }
        Impedanz::Endlich(z)
    };
    Ok(Auswertung {
        gamma,
        z0_ohm,
        betrag,
        phase_grad,
        s11_db,
        impedanz,
        vswr,
    })
}
