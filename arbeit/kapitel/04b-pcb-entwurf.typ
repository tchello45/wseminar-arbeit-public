= Theoretischer Entwurf einer PCB-Antenne <pcb-entwurf>

Eine kleine Empfängerplatine soll wenig Platz beanspruchen und dennoch über das verwendete Frequenzband zuverlässig empfangen. Bei einer gedruckten Antenne hängen diese Anforderungen zusammen: Eine verkleinerte Struktur verändert nicht nur die Resonanz, sondern auch Verluste, Bandbreite und Richtwirkung. Dieses Kapitel entwickelt deshalb eine begründete Entwurfsentscheidung mit festgelegten Randbedingungen, einer geometrischen Referenz und überprüften Rechenbeispielen.

Die theoretische Entwurfsstudie verbindet Anforderungen mit einer Topologieentscheidung und einem nachvollziehbaren Auslegungsweg. Die Bezeichnung PCB-Antenne meint einen auf die Leiterplatte gedruckten Strahler.

== Anforderungen und Bezugsgrößen

ELRS schreibt allein durch den Protokollnamen keine bestimmte Antennenform vor. Für den Entwurf sind Frequenzbereich, Anschluss und Einbau entscheidend. Als reproduzierbares Beispiel enthält der SX128x-Zweig von ExpressLRS 3.5.6 insgesamt 80 Hoppingkanäle mit Kanalmitten zwischen 2400,4 und 2479,4 MHz. Die Signalbandbreite kommt jeweils um die Kanalmitte hinzu. Diese Quellcodeangaben belegen keine auf dem vorhandenen Empfänger installierte Firmware. @lit:elrs-fhss-356[SX128x-Domaintabelle]

Für die Studie wird der Bereich von 2,400 bis 2,4835 GHz gewählt. Er umfasst die genannten Mitten und bei einer hier angenommenen Kanalbandbreite von höchstens 800 kHz auch deren nominelle Bandränder: Der unterste Kanal beginnt dann bei 2400,0 MHz, der oberste endet bei 2479,8 MHz. Spektrale Ausläufer werden damit nicht vollständig begrenzt. Die Annahme ersetzt weder eine Modusprüfung noch einen Zulässigkeitsnachweis. Als Rechenfrequenz dient $f_0 = 2.44 thin "GHz"$; die relative Entwurfsbandbreite beträgt rund 3,42 % ($83.5/2440 approx 0.03422$).

#figure(
  table(
    columns: (1fr, 2.6fr),
    align: (left, left),
    table.header([Größe], [Festlegung der Entwurfsstudie]),
    [Port und Anpassung], [Reeller 50-Ω-Port am Eingang des Anpassnetzwerks; $S_(11,"dB") <= -10 thin "dB"$ im Entwurfsband.],
    [Platz und Masse], [Platine 35 × 45 mm; Massebereich 35 × 35 mm; Antennenzone 35 × 10 mm an einer kurzen Kante.],
    [Lagenaufbau], [Zwei Kupferlagen, nominal 35 µm; FR4 mit angenommenem $epsilon_r = 4.3$ und $h = 1.00 thin "mm"$ zwischen Leitung und Bezugsmasse.],
    [Freiraum], [In der Antennenzone keine Bauteile und kein weiteres Kupfer auf beiden Lagen. Speisung und Kurzschluss bilden definierte Übergänge zur Massekante.],
    [Umgebung], [Freie Platine; zusätzlich eine 1 mm starke Kunststoffplatte 2 mm über dem Strahler sowie eine leitende Platte 35 × 45 mm im Abstand 5 mm unter der Platine als getrennte Prüffälle.],
    [Richtungen], [Platinennormale als z-Achse; $30 degree <= theta <= 150 degree$, alle Azimutwinkel $phi$. Ziel: gesamter realisierter Gewinn mindestens −6 dBi in diesem Bereich.],
    [Toleranzfälle], [$epsilon_r = 4.1; 4.3; 4.5$ und $h = 0.90; 1.00; 1.10$ mm; Bauteilwerte im idealen Matching zusätzlich mit ±5 % variieren.],
  ),
  kind: table, supplement: [Tabelle],
  caption: [Lastenheft mit eigenen Studienannahmen. Die Werte beschreiben einen theoretischen Testträger, keine bestätigten Abmessungen oder Materialdaten des RadioMaster RP1 V2.],
) <tab-pcb-lastenheft>

Die Grenze von −10 dB lässt höchstens zehn Prozent reflektierte Leistung zu. Sie beschreibt die Anpassung, nicht den Strahlungswirkungsgrad. Der Winkelbereich umfasst einen breiten Gürtel um die Platine; die Bereiche nahe der z-Achse sind ausdrücklich ausgenommen. Der gesamte Gewinn summiert beide orthogonalen Fernfeldpolarisationen. Die Kopplung an eine bestimmte Gegenantenne muss zusätzlich betrachtet werden. Die Grenzwerte in @tab-pcb-lastenheft sind vorab gewählte Vergleichskriterien; ihre Erfüllung ist noch kein Ergebnis.

== Topologieentscheidung und Aufbau

Eine Inverted-F-Antenne, kurz IFA, besitzt einen offenen Strahler, einen Kurzschlusszweig zur Masse und einen davon getrennten Speisepunkt. Durch Falten entsteht eine Mäander-IFA. Sie beansprucht weniger Fläche, doch benachbarte Leiterabschnitte koppeln miteinander. Deshalb lässt sich ihre Resonanz nicht allein aus der Summe der Leiterlängen bestimmen.

Für den Vergleich werden dieselben Kriterien verwendet: benötigte Fläche, Übertragbarkeit der Referenz, Zahl der geometrischen Freiheitsgrade und Abstimmaufwand. Die Mäander-IFA aus TI AN043 benötigt etwa 15,2 × 5,7 mm Strahlerfläche und ist damit besonders kompakt. Die nicht mäanderförmige IFA aus TI SWRU120D belegt etwa 25,7 × 7,5 mm ohne Massefläche. Beide passen grundsätzlich in die gewählte Antennenzone. Die Herstellerwerte gehören jedoch zu verschiedenen Referenzplatinen und erlauben keinen unmittelbaren Leistungsvergleich. @lit:ti-an043[Abschn. 4.3] @lit:ti-dn007[Abschn. 1]

Für die Studie wird die IFA aus SWRU120D, Abbildung 1-1 und Tabelle 1-1, als geometrische Referenz gewählt. Ihre Maße sind vollständig dokumentiert, und die dort untersuchte Platine verwendet ebenfalls 1 mm starkes FR4. Der einfachere Leiterweg erleichtert die Zuordnung einer Änderung zu Strahlerende oder Speisung. Da genügend Fläche vorgesehen ist, begründet die Flächenersparnis allein keine Mäanderung. Diese Wahl ist eine Entwurfsentscheidung, kein Nachweis eines höheren Wirkungsgrads. Die eigene Massefläche und die angenommenen Materialdaten weichen vom vollständigen Herstelleraufbau ab; dessen Messkurven werden daher nicht übernommen. @lit:ti-dn007[Abschn. 1–2]

#figure(
  image("../abbildungen/pcb-ifa-prinzip.svg", width: 100%),
  caption: [Eigene Prinzipskizze der gewählten IFA-Topologie und des Testträgers. Die Flächenaufteilung ist festgelegt; der gezeichnete Strahlerweg zeigt die elektrischen Anschlüsse und ist keine maßgetreue Kopie der TI-Geometrie. Der Schichtabstand im Schnitt ist überhöht.],
) <fig-pcb-ifa>

Die Massefläche gehört zum Antennensystem. Silicon Labs zeigt in AN1088 ausgeprägte Ströme entlang ihrer Kante und beschreibt getrennte Speise- und Kurzschlusszweige. Änderungen der Masse verändern deshalb auch die Antenne. @lit:silabs-an1088[Abschn. 2.1 und 3.1] In @fig-pcb-ifa liegt unter der Speiseleitung eine zusammenhängende Bezugsmasse; unter dem offenen Strahlerbereich bleibt sie ausgespart. Ein Kupferverbot unter dem Strahler ist somit mit einer definierten HF-Zuleitung vereinbar. Der Short wird kurz und breit an die Masse angeschlossen. Zusätzliche Kabel oder leitende Teile in diesem Bereich würden neue Randbedingungen schaffen.

== Wellenlänge als Startmaßstab

Aus der Vakuumlichtgeschwindigkeit $c = 299792458 thin "m/s"$ folgt bei 2,44 GHz:

$ lambda_0 = c/f_0 approx 122.866 thin "mm", quad
  lambda_0/4 approx 30.716 thin "mm", quad
  lambda_0/2 approx 61.433 thin "mm". $

Die Viertelwelle gibt einen anschaulichen Größenmaßstab für einen monopolverwandten Strahler mit Gegengewicht. Sie ist keine fertige IFA-Länge: Endeffekte, Speisung, Kurzschluss und Umgebung beeinflussen die elektrische Länge. Für eine gleichförmige Mikrostreifenleitung gilt näherungsweise $lambda_g = lambda_0/sqrt(epsilon_"eff")$, wobei sich die Felder auf Luft und Substrat verteilen. Diese Leitungsbeschreibung liefert keinen allgemeinen Verkürzungsfaktor für einen frei strahlenden Mäander mit endlicher Masse. @lit:steer-microstrip[Abschn. 3.5.1 und 3.5.3]

Das einfache Ersatzmodell $f_0 prop 1/(l sqrt(epsilon_"eff"))$ erlaubt dennoch eine Sensitivitätsabschätzung. Logarithmisches Differenzieren ergibt für kleine Änderungen:

$ (Delta f_0)/f_0 approx - (Delta l)/l - 1/2 (Delta epsilon_"eff")/epsilon_"eff". $

Eine um ein Prozent größere wirksame Länge senkt die Resonanzfrequenz darin näherungsweise um ein Prozent, also um 24,4 MHz. Dieser Wert beschreibt die Empfindlichkeit des Ersatzmodells. Er sagt nicht voraus, um wie viel eine bestimmte Änderung der PCB-Geometrie ihre Resonanz verschiebt.

== Berechnung der 50-Ω-Zuleitung

Für eine idealisierte Mikrostreifenleitung mit $u = w/h >= 1$ werden folgende quasistatische Näherungen verwendet:

$ epsilon_"eff" approx (epsilon_r+1)/2 + (epsilon_r-1)/2 (1+12/u)^(-1/2), $
$ Z_0 approx (120 pi thin Omega)/(sqrt(epsilon_"eff") (u+1.393+0.667 ln(u+1.444))). $

Hier sind $w$ die Leiterbreite und $h$ der Abstand zur Bezugsmasse. Die Gleichungen beschreiben eine dünne Leitung ohne seitliche Masse und ohne Lötstoppmaske; die endliche Kupferdicke wird vernachlässigt. Sie sind in der QPDK-Modelldokumentation angegeben. @lit:qpdk-microstrip[Funktionen microstrip_epsilon_eff und microstrip_z0]

Die Lösung von $Z_0 = 50 thin Omega$ erfolgt durch Intervallhalbierung für $1 <= u <= 10$. Bei $epsilon_r = 4.3$ ergibt sich $u approx 1.960468$ und $epsilon_"eff" approx 3.268321$. Für das gewählte $h = 1.00 thin "mm"$ folgt damit $w approx 1.9605 thin "mm"$. Rückeinsetzen liefert 50 Ω innerhalb der numerischen Toleranz von $10^(-11) thin Omega$; die Genauigkeit der Näherungsformel ist davon unabhängig.

Der Stackup bestimmt die physische Breite: Bei 0,20 mm Abstand wären es 0,3921 mm, bei 1,60 mm dagegen 3,1367 mm. Für eine unveränderte Breite von 1,9605 mm ergeben die vier Kombinationen aus $epsilon_r = 4.1$ beziehungsweise 4,5 und $h = 0.90$ beziehungsweise 1,10 mm Impedanzen zwischen 45,91 und 54,05 Ω. Diese Eckfälle verdeutlichen den Einfluss der Annahmen; sie sind kein statistisches Fertigungstoleranzband. Die Näherung vernachlässigt Kupferdicke, Lötstoppmaske und Anschlussübergänge.

== Anpassung einer hypothetischen Antennenimpedanz

Ein Anpassnetzwerk benötigt die komplexe Impedanz am festgelegten Port. Als Rechenbeispiel sei bei $f_0$ die Last $Z_A = (25+j 10) thin Omega$ gegeben. Sie ist frei gewählt und stammt weder aus einer Messung noch aus einer Feldsimulation. Ohne Netzwerk beträgt $S_(11,"dB") approx -8.97 thin "dB"$ an 50 Ω.

Eine Serieninduktivität mit $X_L = 15 thin Omega$ erhöht den Imaginärteil auf 25 Ω. Damit folgen

$ L = (15 thin Omega)/(2 pi f_0) approx 0.9784 thin "nH", quad
  Z_1 = (25+j 25) thin Omega, $
$ Y_1 = 1/Z_1 = (0.02-j 0.02) thin "S". $

Ein Kondensator parallel zum gesamten Serienzweig ergänzt die positive Suszeptanz $omega_0 C = 0.02 thin "S"$. Seine Kapazität beträgt

$ C = (0.02 thin "S")/(2 pi f_0) approx 1.3045 thin "pF". $

Damit wird $Y_"ein" = 0.02 thin "S"$ und folglich $Z_"ein" = 50 thin Omega$. Der Parallelkondensator liegt aus Eingangssicht vor der Serieninduktivität (@fig-pcb-matching). Eine andere Reihenfolge wäre eine andere Schaltung.

#figure(
  image("../abbildungen/pcb-lc-anpassung.svg", width: 100%),
  caption: [Eigene Schaltungsskizze des idealen Rechenbeispiels. Der Kondensator liegt parallel zu Serieninduktivität und Last. Das rechte Rechteck bezeichnet die komplexe Last, kein einzelnes Widerstandsbauteil.],
) <fig-pcb-matching>

Die komplexe Rückrechnung verwendet

$ Z_"ein" = (1/(Z_A+j omega_0 L) + j omega_0 C)^(-1), quad
  Gamma_"ein" = (Z_"ein"-50 thin Omega)/(Z_"ein"+50 thin Omega). $

Sie ergibt ideal $Gamma_"ein" = 0$. Eine getrennte Rechnung über die Kettenmatrix des Netzwerks stimmt innerhalb einer Toleranz von $10^(-11) thin Omega$ überein. Rundet man auf 1,00 nH und 1,30 pF, folgt $Z_"ein" approx (50.666+j 0.175) thin Omega$ und $S_(11,"dB") approx -43.30 thin "dB"$. Bei unabhängigen Abweichungen von ±5 % um die ungerundeten Werte liegen die vier Eckfälle zwischen −30,86 und −30,56 dB. Ein zusätzliches Raster mit 101 × 101 Wertepaaren liefert als größten untersuchten Reflexionsbetrag rund 0,02966.

Diese Zahlen gelten ausschließlich bei 2,44 GHz und unveränderter Last. Sie beschreiben weder die Bandbreite noch reale Bauteile mit Verlusten, Eigenresonanzen und parasitären Anschlussgrößen.

== Bewertung von Anpassung und Abstrahlung

Gute Anpassung bedeutet nicht automatisch gute Abstrahlung. Mit der am Port angenommenen Leistung gilt für die Strahlungseffizienz $eta_"rad" = P_"rad"/P_"angenommen"$. Bei gleichem Strombezug entspricht dies dem Anteil des Strahlungswiderstands am gesamten Eingangswiderstand: $eta_"rad" = R_"rad"/(R_"rad"+R_"V")$. Stutzman und Thiele unterscheiden diesen Wirkungsgrad ausdrücklich von der Richtwirkung und verknüpfen beide über den Gewinn. @lit:stutzman2013[S. 54–55, Gl. (2-152)–(2-155); S. 60, Gl. (2-178)] Für einen Einport mit reeller Bezugsimpedanz folgen

$ eta_"tot" = (1-abs(S_11)^2) eta_"rad", quad G(theta,phi) = eta_"rad" D(theta,phi), $
$ G_"real" (theta,phi) = (1-abs(S_11)^2) eta_"rad" D(theta,phi). $

$D$ bezeichnet die Richtwirkung. Die Größen sind linear; ihre logarithmische Gewinnangabe lautet $10 log_10(G_"real")$ in dBi. Alle Leistungen und Verluste müssen sich auf dieselbe Systemgrenze beziehen, hier auf das Gesamtsystem hinter dem Eingangsport einschließlich eines gegebenenfalls verlustbehafteten Anpassnetzwerks. Die zusätzliche Polarisationsfehlanpassung zur Gegenantenne ist noch nicht enthalten. @lit:mathworks-fields[Field Parameters: Gain und Realized Gain]

Als Zahlenbeispiel ergeben −20 dB S11 bei $eta_"rad" = 0.30$ eine Gesamteffizienz von 0,297. Bei −10 dB und $eta_"rad" = 0.80$ sind es dagegen 0,72. Bei gleicher Richtwirkung wäre der zweite Fall günstiger. S11 allein bestimmt die unbekannten Wirkungsgrade nicht. Auch der höchste Spitzengewinn reicht für eine bewegliche Einheit nicht aus, weil andere Richtungen tiefe Einbrüche aufweisen können. @lit:ti-an058[Abschn. 5.2]

== Ergebnis der Entwurfsstudie

Das Ergebnis der Studie ist die Wahl einer dokumentierten IFA als Ausgangspunkt für einen ausdrücklich festgelegten Testträger. Eigene, reproduzierbar geprüfte Rechnungen liefern Größenmaßstäbe, eine nominelle Speiseleitungsbreite und ein ideales Anpassbeispiel einschließlich Toleranzbetrachtung. Die Referenzmaße und Herstellerbeobachtungen stammen aus der Literatur. Die Rechnungen beschreiben idealisierte Leitungs- und Schaltungsmodelle; sie bestimmen weder den realen Antennenwirkungsgrad noch eine Überlegenheit gegenüber der Mäander-IFA.
