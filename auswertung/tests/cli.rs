use std::{path::Path, process::Command};

fn cli(args: &[&str]) -> std::process::Output {
    Command::new(env!("CARGO_BIN_EXE_auswertung"))
        .args(args)
        .output()
        .unwrap()
}

#[test]
fn argumente_und_negative_werte() {
    assert!(cli(&["--help"]).status.success());
    for args in [
        &[][..],
        &["1"][..],
        &["1", "0", "50", "extra"][..],
        &["--import", "test.s1p", "1", "0"][..],
    ] {
        let output = cli(args);
        assert!(!output.status.success());
        assert!(output.stdout.is_empty());
    }
    let output = cli(&["-0.5", "-0.2"]);
    assert!(output.status.success());
    let mut reader = csv::Reader::from_reader(output.stdout.as_slice());
    assert_eq!(reader.headers().unwrap().len(), 11);
    assert_eq!(&reader.records().next().unwrap().unwrap()[0], "-0.5");
}

#[test]
fn importfehler_schreibt_keine_teilergebnisse() {
    let path = std::env::temp_dir().join(format!("auswertung-invalid-{}.csv", std::process::id()));
    std::fs::write(&path, "frequency_hz,s11_re,s11_im\n1,0,0\n2,NaN,0\n").unwrap();
    let output = cli(&["--import", path.to_str().unwrap()]);
    std::fs::remove_file(path).unwrap();
    assert!(!output.status.success());
    assert!(output.stdout.is_empty());
    assert!(!output.stderr.is_empty());
}

#[test]
fn vorhandene_messdatei_importieren() {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("../daten/roh/01.s1p");
    let output = cli(&["--import", path.to_str().unwrap()]);
    assert!(output.status.success());
    assert_eq!(
        auswertung::csv::einlesen(output.stdout.as_slice())
            .unwrap()
            .len(),
        101
    );
}
