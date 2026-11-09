use auswertung::{Complex64, auswerten, csv, touchstone};
use clap::Parser;
use std::{error::Error, fs::File, io, path::PathBuf, process::ExitCode};

#[derive(Parser)]
#[command(version, about = "S11-Auswertung mit CSV-Ausgabe")]
struct Args {
    #[arg(long, value_name = "DATEI", conflicts_with_all = ["real", "imag", "z0_ohm"])]
    import: Option<PathBuf>,
    #[arg(
        value_name = "REAL",
        allow_negative_numbers = true,
        required_unless_present = "import"
    )]
    real: Option<f64>,
    #[arg(
        value_name = "IMAG",
        allow_negative_numbers = true,
        required_unless_present = "import"
    )]
    imag: Option<f64>,
    #[arg(value_name = "Z0_OHM", allow_negative_numbers = true)]
    z0_ohm: Option<f64>,
}

fn run(args: Args) -> Result<(), Box<dyn Error>> {
    if let Some(path) = args.import {
        let punkte = if path
            .extension()
            .is_some_and(|ext| ext.eq_ignore_ascii_case("csv"))
        {
            csv::einlesen(File::open(&path)?)?
        } else {
            touchstone::einlesen(&path)?
        };
        csv::messreihe(io::stdout().lock(), &punkte)?;
    } else if let (Some(real), Some(imag)) = (args.real, args.imag) {
        let wert = auswerten(Complex64::new(real, imag), args.z0_ohm.unwrap_or(50.0))?;
        csv::einzelwert(io::stdout().lock(), wert)?;
    }
    Ok(())
}

fn main() -> ExitCode {
    match run(Args::parse()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("Fehler: {error}");
            ExitCode::FAILURE
        }
    }
}
