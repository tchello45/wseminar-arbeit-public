use auswertung::{Complex64, Impedanz, Rechenfehler, Vswr, auswerten, csv, touchstone};

#[test]
fn reflexionsgrenzen() {
    let angepasst = auswerten(Complex64::new(0.0, 0.0), 50.0).unwrap();
    assert_eq!(
        angepasst.impedanz,
        Impedanz::Endlich(Complex64::new(50.0, 0.0))
    );
    assert_eq!(angepasst.phase_grad, None);
    assert_eq!(angepasst.s11_db, f64::NEG_INFINITY);
    assert_eq!(angepasst.vswr, Vswr::Endlich(1.0));
    let offen = auswerten(Complex64::new(1.0, 0.0), 50.0).unwrap();
    assert_eq!(offen.impedanz, Impedanz::Singulaer);
    assert_eq!(offen.vswr, Vswr::Unendlich);
    let kurz = auswerten(Complex64::new(-1.0, 0.0), 50.0).unwrap();
    assert_eq!(kurz.impedanz, Impedanz::Endlich(Complex64::new(0.0, 0.0)));
    assert_eq!(
        auswerten(Complex64::new(2.0, 0.0), 50.0).unwrap().vswr,
        Vswr::AusserhalbPassivenBereichs
    );
}

#[test]
fn ungueltige_rechenwerte() {
    assert_eq!(
        auswerten(Complex64::new(f64::NAN, 0.0), 50.0),
        Err(Rechenfehler::GammaNichtEndlich)
    );
    assert_eq!(
        auswerten(Complex64::new(0.0, 0.0), 0.0),
        Err(Rechenfehler::ReferenzimpedanzUngueltig)
    );
    assert_eq!(
        auswerten(Complex64::new(f64::MAX, f64::MAX), 50.0),
        Err(Rechenfehler::ZahlenbereichUeberschritten)
    );
}

#[test]
fn touchstone_darstellungen_und_kommentare() {
    for (format, a) in [("RI", "0.5"), ("MA", "0.5"), ("DB", "-6.020599913279624")] {
        let punkte =
            touchstone::parse(&format!("! Test\n# mhz s {format} r 75\n1 {a} 0 ! Punkt\n"))
                .unwrap();
        assert_eq!(punkte[0].frequency_hz, 1e6);
        assert!((punkte[0].s11.betrag - 0.5).abs() < 1e-14);
        assert_eq!(
            punkte[0].s11.impedanz,
            Impedanz::Endlich(Complex64::new(225.0, 0.0))
        );
    }
}

#[test]
fn touchstone_lehnt_fehler_mit_zeilennummer_ab() {
    for text in [
        "1 0 0",
        "# HZ S RI R 50\n1 0 0\n1 0 0",
        "# HZ S MA R 50\n1 -1 0",
        "# HZ S DB R 50\n1 -99999 0",
        "# HZ S RI R 50\n1 NaN 0",
        "[Version] 2.0",
    ] {
        assert!(touchstone::parse(text).unwrap_err().zeile.is_some());
    }
    assert!(touchstone::parse("# HZ S RI R 50").is_err());
}

#[test]
fn csv_importiert_nanovna_mit_quoting_und_standardimpedanz() {
    let input = "s11_imag,frequency_hz,s11_real,note\r\n0,1,0.5,\"a,b\"\r\n";
    let punkte = csv::einlesen(input.as_bytes()).unwrap();
    assert_eq!(punkte[0].s11.z0_ohm, 50.0);
    assert_eq!(punkte[0].s11.gamma, Complex64::new(0.5, 0.0));
}

#[test]
fn csv_roundtrip_bewahrt_sonderfaelle() {
    let punkte = touchstone::parse("# HZ S RI R 75\n1 0 0\n2 1 0\n3 2 0").unwrap();
    let mut output = Vec::new();
    csv::messreihe(&mut output, &punkte).unwrap();
    let rows = ::csv::Reader::from_reader(output.as_slice())
        .records()
        .collect::<Result<Vec<_>, _>>()
        .unwrap();
    assert_eq!(&rows[0][5], "undefined");
    assert_eq!(&rows[0][6], "-inf");
    assert_eq!(&rows[1][7], "");
    assert_eq!(&rows[1][9], "singular");
    assert_eq!(&rows[1][10], "inf");
    assert_eq!(&rows[2][11], "outside_passive_range");
    let imported = csv::einlesen(output.as_slice()).unwrap();
    assert_eq!(imported, punkte);
}

#[test]
fn csv_lehnt_ungueltige_daten_ab() {
    for rows in ["", "1,0", "1,NaN,0", "NaN,0,0", "-1,0,0", "2,0,0\n1,0,0"] {
        let input = format!("frequency_hz,s11_re,s11_im\n{rows}");
        assert!(csv::einlesen(input.as_bytes()).is_err(), "{input}");
    }
    assert!(csv::einlesen("frequency_hz,s11_re\n1,0\n".as_bytes()).is_err());
}
