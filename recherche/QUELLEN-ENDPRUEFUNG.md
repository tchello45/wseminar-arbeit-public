# Quellenprüfung, Stand 8. November 2026

Die 40 im Haupttext zitierten Quellen bestehen aus 37 Online-Quellen und drei gedruckten Büchern. Die Online-Quellen wurden über ihre Originalanbieter aufgerufen und auf die verwendeten Aussagen bezogen geprüft. Bei Fachbüchern oder umfangreichen Papers bedeutet dies die einschlägigen Abschnitte, nicht eine vollständige Lektüre jedes Werks. Die eigene Algebra und die numerischen Aussagen werden getrennt durch die Rechenskripte geprüft.

Zwischenzeitliche Abruffehler der drei MIT-PDFs ließen sich über das offizielle Kurs-Leseverzeichnis beheben; dieselben Direktdateien waren danach zugänglich. Die Feynman-Seiten enthalten einen vorgeschalteten JavaScript-Hinweis, der eigentliche Fachtext war dennoch auslesbar. Keine zusätzliche Fachquelle war für eine ungestützte Kernaussage nötig.

## Im Text verwendete Quellen

- **`chiani2019`** — II-A/II-B und III: kontinuierliche Chirps, diskrete orthogonale Samples und Spektralgrenzen; Metadaten und DOI stimmen. [Originalquelle](https://arxiv.org/abs/1906.04256v1)
- **`maleki2023`** — II-A/II-B, Gl. (2)–(13): komplexe Basisbanddarstellung, Referenzchirp und Symbolerzeugung; arXiv v1, kein ungeprüftes Journaljahr. [Originalquelle](https://arxiv.org/abs/2310.10503v1)
- **`demeslay2022`** — III-A/B, Gl. (1)–(4): Signalfolge, AWGN, Dechirping und Betragsentscheidung; Mehrwegeabschnitte begründen die Modellabgrenzung. [Originalquelle](https://arxiv.org/abs/2201.03825v1)
- **`semtech-phy`** — Herstellerseite: CSS als Grundlage der LoRa-Modulation; LoRaWAN nicht mit der Modulation gleichsetzen. [Originalquelle](https://www.semtech.com/lora/what-is-lora)
- **`feynman18`** — II, 18–1/Tabelle 18–1: Maxwell-Gleichungen und Verschiebungsstrom; c²-Schreibweise äquivalent zu μ₀ε₀. [Originalquelle](https://www.feynmanlectures.caltech.edu/II_18.html)
- **`feynman20`** — II, 20–2/20–3: quellenfreie Wellengleichung, transversale Welle und Verhältnis E/B. [Originalquelle](https://www.feynmanlectures.caltech.edu/II_20.html)
- **`staelin7`** — 7.2 und 7.3.1, insbesondere Gl. (7.3.3)/(7.3.4), gedruckte S. 208: Reflexion und normierte Impedanz; Viertelwellentransformation. Der verlustbehaftete Exponentialfaktor im Text ist die Erweiterung des gleichförmigen Leitungsmodells. [Originalquelle](https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/MIT6_013S09_chap07.pdf)
- **`staelin10`** — 10.2 und 10.3.3–10.3.5: Fernfeld, Polarisation, effektive Fläche und Friis (10.3.37); Leistungsbezüge im eigenen Text ausdrücklich definiert. [Originalquelle](https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/MIT6_013S09_chap10.pdf)
- **`staelin11`** — Einleitung und 11.2: Antennen koppeln Leitung und Strahlung; dient der Einordnung, nicht als Messergebnis der eigenen Platine. [Originalquelle](https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/MIT6_013S09_chap11.pdf)
- **`ti-an043`** — AN043/SWRA117D, insbesondere 4.3: Mäander-IFA, 15,2 × 5,7 mm und Layoutabhängigkeit; Herstellerkurven nicht auf eigene Platine übertragen. [Originalquelle](https://www.ti.com/lit/pdf/swra117)
- **`ti-an058`** — AN058/SWRA161B, 5.2 und 6.2.5: Strahlungscharakteristik und messgestützte Anpassung; S11 allein kein Wirkungsgradnachweis. Autor Richard Wallace auf Titelseite. [Originalquelle](https://www.ti.com/lit/an/swra161b/swra161b.pdf)
- **`ti-dn007`** — SWRU120D, 1–2, Abb. 1-1/Tabelle 1-1: 25,7 × 7,5 mm ohne Massefläche und 1-mm-Referenzplatine; keine eigene Feldsimulation. [Originalquelle](https://www.ti.com/lit/pdf/swru120)
- **`elrs-signal`** — Signal Health: RSSI in dBm und erfolgreich empfangene Pakete/LQI unterscheiden; keine eigenen ELRS-Daten vorhanden. [Originalquelle](https://www.expresslrs.org/info/signal-health/)
- **`elrs-lua`** — Packet Rate: Modulationsarten und Funkmodi hängen von Hardware/Modus ab; kein Beleg der installierten Firmware. [Originalquelle](https://www.expresslrs.org/quick-start/transmitters/lua-howto/)
- **`elrs-fhss-356`** — Versionsgebundene FHSS.cpp, RADIO_SX128X-Domaintabelle: 2400400000 bis 2479400000 Hz, 80 Kanäle. Zusätzlich Raw-Datei desselben Tags gelesen. [Originalquelle](https://github.com/ExpressLRS/ExpressLRS/blob/3.5.6/src/lib/FHSS/FHSS.cpp)
- **`silabs-an1088`** — Rev. 0.1, 2.1 und 3.1: IFA-Anschlüsse, Masse, Platzierung und Abstimmung; Referenzdesign bleibt platinenspezifisch. [Originalquelle](https://www.silabs.com/documents/public/application-notes/an1088-designing-with-pcb-antenna.pdf)
- **`steer-microstrip`** — 3.5.1 und 3.5.3: Mikrostreifengeometrie und effektive Permittivität; keine allgemeine IFA-Verkürzungsregel. [Originalquelle](https://eng.libretexts.org/Bookshelves/Electrical_Engineering/Electronics/Microwave_and_RF_Design_II_-_Transmission_Lines_(Steer)/03%3A_Planar_Transmission_Lines/3.05%3A_Microstrip_Transmission_Lines)
- **`qpdk-microstrip`** — microstrip_epsilon_eff und microstrip_z0: Formeln einschließlich Zweig w/h ≥ 1 direkt abgeglichen; Kupferdicke/Masken im eigenen Beispiel vernachlässigt. [Originalquelle](https://gdsfactory.github.io/quantum-rf-pdk/models.html#microstrip-epsilon-eff)
- **`mathworks-fields`** — R2026b, Field Parameters/Gain/Realized Gain: Materialverluste und Portfehlanpassung getrennt; Formel im Kapitel stimmt. [Originalquelle](https://www.mathworks.com/help/antenna/ug/field-calculation-in-antennas.html)
- **`gustafsson2018`** — arXiv v2, Metadaten/Abstract und Optimierungskontext: Wirkungsgrad/Bandbreite als Zielkonflikt; keine eigene Schrankenberechnung behauptet. [Originalquelle](https://arxiv.org/abs/1802.01476v2)
- **`openems-patch-python`** — Python-Tutorial: Port, CreateNF2FFBox, S11 und CalcNF2FF; methodisches Beispiel einer Patchantenne, keine ausgeführte IFA-Simulation. [Originalquelle](https://github.com/thliebig/openEMS/blob/master/python/Tutorials/Simple_Patch_Antenna.py)
- **`staelin2`** — 2.3.4 und 2.7.3, gedruckte S. 35–36 und 61: Polarisation und zeitlicher Mittelwert des Poynting-Vektors; H-Einheit A/m. [Originalquelle](https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/MIT6_013S09_chap02.pdf)
- **`feynman-interferenz`** — I, 29–4: kohärente Überlagerung und phasenabhängige Intensität; eigene komplexe Umformung im Kapitel. [Originalquelle](https://www.feynmanlectures.caltech.edu/I_29.html)
- **`nist-pegel`** — 8.7: logarithmische Feld-/Leistungsgrößen und Bezugsgrößen. [Originalquelle](https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-8)
- **`ntia-handbuch`** — Gedruckte S. 2–15 und 3–1: dBm und logarithmische Leistungsbilanz; keine aktuellen Geräteparameter übernommen. [Originalquelle](https://its.ntia.gov/publications/download/tn_89-2.pdf)
- **`itu-freiraum`** — P.525-5 (11/2024), Anhang 2.3, S. 3, Gl. (4)–(6): isotrope Empfangsfläche und Freiraumdämpfung. [Originalquelle](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.525-5-202411-I!!PDF-E.pdf)
- **`wyatt-signale`** — 2.6/2.6.4: komplexe Exponentialsignale, Euler-Formel und Komponenten. [Originalquelle](https://clwyatt.github.io/notes-2714/02-ct-signals.html)
- **`orloff-komplex`** — 4.2–4.3: imaginäre Einheit, j-Konvention und komplexe Exponentialfunktion. [Originalquelle](https://ocw.mit.edu/courses/es-1803-differential-equations-spring-2024/mites_1803_s24_topic4.pdf)
- **`gallager-rauschen`** — 7.7–7.8.1, insbesondere Definition 7.8.1 und Beispiel 7.8.1: zirkuläres komplexes Gaußrauschen; Komponentenvarianz 1/2 bei Gesamtvarianz eins. [Originalquelle](https://ocw.mit.edu/courses/6-450-principles-of-digital-communications-i-fall-2006/49163236e20779bae41639ff9dec1ac4_book_7.pdf)
- **`numpy-fft`** — Implementation details/Normalization: negatives DFT-Vorzeichen, unnormierte Vorwärtstransformation und Binreihenfolge. [Originalquelle](https://numpy.org/doc/stable/reference/routines.fft.html)
- **`numpy-streams`** — SeedSequence und ganzzahlige Seedfolgen für getrennte Pseudozufallsströme; keine experimentelle Unabhängigkeit behauptet. [Originalquelle](https://numpy.org/doc/stable/reference/random/parallel.html)
- **`numpy-kompatibilitaet`** — Compatibility policy: gleicher Seed allein garantiert keine beliebige versions-/plattformübergreifende Identität. [Originalquelle](https://numpy.org/doc/stable/reference/random/compatibility.html)
- **`nist-wilson`** — 7.2.4.1: Wilson durch Inversion des Score-Tests; Grenzen und Nullfehlerfall zusätzlich unabhängig nachgerechnet. [Originalquelle](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)
- **`sysjoint-fv2`** — Rev. 2.0 für Firmware 0.3.0, 1.3/4.4/7.2: Gerät, Kalibrierung und serielle Befehle; Firmware 0.6.5 stammt aus eigenen Originalantworten. [Originalquelle](https://www.sysjoint.com/ueditor/php/upload/file/NanoVNA-F%20V2%20Portable%20Vector%20Network%20Analyzer%20User%20Guide%20V2.0.pdf)
- **`keysight-reflection`** — Reflection Coefficient, Return Loss, VSWR und Impedanz: Vorzeichen und Bedeutung der abgeleiteten Darstellungen. [Originalquelle](https://helpfiles.keysight.com/csg/m9485a/tutorials/reflection_measurements.htm)
- **`keysight-calstandards`** — Standard Definitions: bekannte Modelle einschließlich Verzögerung und Verlust; Wiederholungsmessung eigener Kalibrierstandards ist kein unabhängiger Genauigkeitsnachweis. [Originalquelle](https://helpfiles.keysight.com/csg/m9485a/s3_cals/calibration_standards.htm)
- **`keysight-portextensions`** — Why use Port Extensions: Referenzebene, Verzögerung und optionale Verlustkorrektur; nicht allgemein vollständiges Adapter-Deembedding. [Originalquelle](https://helpfiles.keysight.com/csg/pxivna/S3_Cals/Port_Extensions.htm)
- **`nist-calstandards`** — Publikationsseite/Abstract und Metadaten, 5.12.2003, Juroshek/LeGolvan: Modellfehler der Standards verursachen systematische Kalibrierfehler. Kein vollständiger Konferenzvolltext behauptet. [Originalquelle](https://www.nist.gov/publications/correcting-systematic-errors-one-port-calibration-standards)

## Bibliografiepool außerhalb des Haupttextes

Die weiteren 26 Einträge bleiben als Recherchepool erhalten und werden von Typst nicht im Literaturverzeichnis ausgegeben. Erreichbarkeit beziehungsweise Metadaten wurden ebenfalls erneut geprüft, soweit zugänglich. Dies ist keine fachliche Volltextfreigabe für eine spätere Verwendung. Insbesondere:

- `afisiadis2019`, `waret2018`: arXiv-Metadaten und Abstract zugänglich; Forschungsfragen betreffen Interferenz beziehungsweise Netzwerkdurchsatz.
- `sx1281`, `lr1121`: Semtech-Produktseiten zugänglich; Datenblattvolltexte hier nicht vollständig geprüft.
- `griffiths4`: Cambridge-Titel erreichbar; tatsächliche verwendete Buchausgabe weiterhin nicht belegt. Der Eintrag ist unzitiert.
- `pozar2011`: alte Wiley-UAT-Adresse mit 403 gesperrt; auch die reguläre Verlagsadresse war hier gesperrt. Bibliografischer Pooleintrag bleibt unzitiert; keine neue Volltextprüfung behauptet.
- `bahl2022`, `taflove2005`: Verlagstitel erreichbar; kein Zugriff auf vollständige Bücher behauptet.
- `ti-measurements`: Originaldatei überschreitet die Größenbegrenzung des Recherchewerkzeugs (ca. 15 MB); nicht als neu gelesen verbucht.
- `nanovna-manual`, `nanovna-spec`: NanoRFE-Seiten erreichbar, beziehen sich auf eine andere Modellfamilie als den tatsächlich eingesetzten SYSJOINT NanoVNA-F V2. Deshalb keine daraus übernommene Gerätegenauigkeit.
- `gum2008`: BIPM-Originalausgabe zugänglich; kein Beleg einer hier ausgeführten vollständigen Unsicherheitsbilanz.
- `yee1966`: DOI löst auf IEEE auf, Volltext durch Robot-Prüfung begrenzt; nur Metadatenprüfung.
- `schneider2010`: Autorenseite erreichbar; auf aktuelle index.html-Adresse umgestellt.
- `openems`, `openems-nf2ff`, `openems-patch`: Originaldokumentation erreichbar; weder Solverlauf noch EM-Validierung dieses Projekts.
- `elrs-power`, `elrs-hardware`, `elrs-xo`, `elrs-smd`, `elrs-diy`: Original-Projektdokumentation erreichbar; zukünftiger Versuch erfordert tatsächliche Hardware-/Firmwaredaten.
- `esp32c3`: Originaldatenblatt Version 1.7 zugänglich; kein Nachweis für einen zusätzlichen LoRa-Funkpfad.
- `etsi328`: konkrete Fassung V2.2.2 (2019-07) erreichbar; keine Aussage, dies sei der heute einzig maßgebliche Rechts-/Normenstand.
- `typst-bib`: offizielle Dokumentation erreichbar; der aktuelle Build prüft die tatsächlich verwendeten Schlüssel.
- `st-an5129`: Original-PDF beim erneuten Abruf wiederholt Timeout; keine aktuelle Volltextprüfung behauptet. Quelle ist unzitiert und trägt keine Schlussfolgerung.

## Gedruckte Bücher: Seitenprüfung am 7. November 2026

Die einschlägigen Fotos wurden für die Prüfung gelesen und danach aus dieser
Projektfassung entfernt. Sie sind keine Voraussetzung für Build oder numerische
Reproduktion. Die Originalsammlung im separaten Projekt wurde nicht verändert.

- **`gronau2001`** — Impressum: Gregor Gronau, Springer 2001, ISBN 3-540-41790-7.
  S. 370–371, Gl. (8.53)–(8.57): drei komplexe Fehlergrößen der Eintorkorrektur
  und ihre Bestimmung mit bekannten Standards. S. 372–373: nichtideale
  kapazitive OPEN-, induktive SHORT- und nicht vollständig reflexionsfreie
  LOAD-Standards. Die Aussagen im Mess- und Diskussionskapitel stimmen damit überein.
- **`stutzman2013`** — Impressum: Stutzman/Thiele, 3. Auflage, Copyright 2013,
  ISBN 978-0-470-57664-9. Geprüft: S. 23–26 Maxwell-Gleichungen und
  Leistungsbegriffe; S. 30 Wellenlänge und Phase; S. 34–35 Fernfeldterme;
  S. 42–44 Fernfeldgrenzen; S. 52–55 Richtwirkung und Gewinn; S. 56–60
  Impedanz, Strahlungs-/Verlustwiderstand und Effizienz; S. 61–65 Polarisation.
  Die zitierten Gleichungen und Begriffe sind belegt. 2013 ist durch das
  Impressum bestätigt und trotz abweichender Veröffentlichungsdaten in
  manchen Katalogen kein zu korrigierendes erfundenes Jahr.
- **`chang2003`** — Impressum: Kai Chang als Herausgeber, Wiley 2003,
  ISBN 0-471-39056-9. S. 71–72, Abschnitt 2.2.2: koaxiale Durchmessersprünge
  als kapazitive Diskontinuitäten bei kleinen Querschnitten relativ zur
  Wellenlänge. Die Arbeit verwendet dies qualitativ und leitet keinen
  unbekannten Adapterkorrekturwert daraus ab. Das ist durch den Text gedeckt.

## Ergebnis und Grenzen

Keine erfundene zitierte Quelle oder widersprechende Kernaussage festgestellt.
Alle 41 Schlüssel sind in der Bibliografie und genau einer Literaturgruppe
vorhanden. Die Bücher müssen nicht als Scans mit der Arbeit veröffentlicht
werden. Die Quellenprüfung ersetzt keine persönliche Lektüre und prüft keine
hier nicht verwendeten Abschnitte eines vollständigen Buchs.

Die Modellgrenze zur analogen Empfangsfilterung wurde in Kapitel 3 ausdrücklich
mit Chiani/Elzanaty II-B ergänzt. Die Daten- und Quellenlücken der unvollständig
kopierten Projektfassung sind behoben. Schulische Vorgaben zu Umfang und
KI-Hilfsmitteln sowie persönliche Freigabe und Unterschrift bleiben offen.


## Erneuter Inhalts- und Quellenabgleich nach der Sprachkorrektur

Am 7. November 2026 wurden die Kapitel erneut fachlich gelesen und die im
Haupttext verwendeten Online-Quellen erneut aufgerufen. Die Direktabrufe von
Staelin Kapitel 7 und 10 scheiterten im Recherchewerkzeug; die einschlägigen
Abschnitte wurden stattdessen in der vollständigen offiziellen MIT-Ausgabe
abgeglichen:
https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/mit6_013_s09_coursetextbook.pdf

Die vorhandenen Buchfotos im separaten Projekt wseminar wurden für Gronau
S. 370–373, Chang S. 71–72 sowie die einschlägigen Grundlagen-, Fernfeld-,
Gewinn-, Impedanz-, Wirkungsgrad- und Polarisationsstellen von Stutzman/Thiele
erneut eingesehen; auch die drei Impressumsfotos wurden abgeglichen.
Dies ist eine Prüfung der verwendeten Stellen, keine vollständige Buchlektüre.

Zwei kleine Korrekturen: Der Vorname von Clément Demeslay wird nun mit Akzent
geführt. Der Pareto-Beleg in Kapitel 5 benennt genauer die in Gustafsson et al.
tatsächlich untersuchten Größen Strahlungswirkungsgrad und Gütefaktor bei
vorgegebenem Entwurfsraum. Eine unmittelbare Optimierung der eigenen
Platinenfläche wurde daraus weder abgeleitet noch durchgeführt.

Zusätzlich zur Wiederholung der Kampagnen wurde die in Kapitel 6 selbst
hergeleitete bedingte Erfolgswahrscheinlichkeit unabhängig mit einer
zweidimensionalen Gauß-Hermite-Quadratur ausgewertet. Bei Es/N0 = 10 dB
ergeben sich für SF 7/8/9 theoretische SER von rund
0,1069892 / 0,1459007 / 0,1912958. Alle drei Werte liegen in den im Kapitel
angegebenen punktweisen Wilson-Intervallen der Simulation. Die Ergebnisse
bei 160 und 240 Quadraturpunkten je Dimension unterscheiden sich um weniger
als 5e-9; dies ist eine numerische Konvergenzkontrolle, kein Fehlerbeweis.

Keine weitere widersprechende Kernaussage gefunden. Die bereits dokumentierten
Grenzen der CSS-Idealisierung, der NanoVNA-Kalibrierkontrolle und des rein
theoretischen PCB-Entwurfs bleiben für die Schlussfolgerungen maßgeblich.

## Ergänzung Rust und WebAssembly, 8. November 2026

- **`rust-wasm-target`** — Offizielles rustc-Handbuch: Ziel `wasm32-unknown-unknown`, Browser-/JavaScript-Einsatz und Grenzen der Betriebssystemfunktionen. [Originalquelle](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html)
- **`wasm-bindgen-deployment`** — Offizieller wasm-bindgen-Leitfaden: `web`-Ausgabe, ES-Modul und explizite Initialisierung. Paketbau und lokale npm-Installation wurden zusätzlich am eigenen Artefakt geprüft. [Originalquelle](https://wasm-bindgen.github.io/wasm-bindgen/reference/deployment.html)
