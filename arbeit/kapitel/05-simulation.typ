// Lokale Listing-Kopie; die Gesamtprüfung gleicht sie mit dem ausführbaren Original ab.
#let listing(teil) = {
  let code = read("../listings/kapitel6.py")
  let ausschnitt = code.split("# START " + teil + "\n").at(1)
    .split("# END " + teil).at(0).trim()
  block(breakable: false)[#raw(ausschnitt, lang: "python", block: true)]
}

= Numerische Untersuchung

Die numerische Untersuchung vergleicht die Symbolerkennung für die Spreading Factors 7, 8 und 9 unter komplexem weißem gaußschem Rauschen. Zwei getrennte Monte-Carlo-Kampagnen beantworten unterschiedliche Fragen: Wie unterscheiden sich die Fehlerraten bei gleichem SNR pro Sample, und was bleibt von diesem Unterschied bei gleichem Verhältnis von Symbolenergie zu Rauschleistungsdichte übrig? Eine dritte Kampagne untersucht einen konstanten Frequenzoffset. Zusammen umfassen die drei Kampagnen 135 Punkte mit 675 000 Symbolversuchen. Die folgenden Ergebnisse gelten für das diskrete Modell; die ergänzenden Hardwareversuche werden in Kapitel 7 getrennt behandelt.

== Signalmodell und Detektor

Das in Kapitel 3 beschriebene Modell verwendet eine Bandbreite von $B = 125 "kHz"$ und die gleiche Abtastrate $f_s = B$. Ein Symbol besteht aus $M = 2^"SF"$ komplexen Samples. Der Symbolindex $m$ wird gleichverteilt aus $0, dots, M-1$ gezogen. Der Sender erzeugt

$ x_m[n] = x_0[n] exp(j 2 pi m n/M), quad abs(x_m[n])^2 = 1. $

Die Empfangsfolge lautet $y[n] = x_m[n] + w[n]$. Sender und Empfänger sind perfekt symbolsynchron; ein Frequenzoffset ist in den beiden Rauschkampagnen nicht enthalten. Zum Dechirpen wird $y[n]$ mit $x_0[n]^*$ multipliziert. Ohne Rauschen hebt sich die gemeinsame Chirpphase auf, und wegen des Einheitsbetrags bleibt der Ton $exp(j 2 pi m n/M)$. Er durchläuft im Symbolintervall genau $m$ Perioden. Seine unnormierte $M$-Punkt-FFT hat bei Bin $m$ einen Peak mit Betrag $M$. Der Detektor entscheidet anhand des größten FFT-Betrags. Diese nichtkohärente Entscheidung benötigt keine bekannte konstante Empfangsphase: Eine gemeinsame Phasendrehung ändert die Beträge nicht. Die Modellgleichung und die Betragsentscheidung entsprechen Demeslay et al., Abschnitt III, Gleichungen (1)–(4). #cite(<lit:demeslay2022>, supplement: [Abschnitt III])

Damit wird die Symbolfehlerrate untersucht, also der Anteil falsch erkannter Symbolindizes. Eine Verwechslung kann mehrere Bits betreffen; die Symbolfehlerrate ist deshalb weder unmittelbar eine Bitfehlerrate noch eine codierte Paketfehlerrate. Präambeln, Fehlerkorrektur und reale Empfängersynchronisation sind nicht Bestandteil des Modells.

== Umsetzung des Signalwegs in Python

Das folgende Listing bildet die Gleichungen unmittelbar ab. Python schreibt die imaginäre Einheit als #raw("1j"); #raw("np.conj") konjugiert die Referenzfolge. Das Alphabet ist ein zweidimensionales Array mit $M$ Symbolen und je $M$ Samples. Durch #raw("axis=-1") wird jede Symbolzeile getrennt transformiert. Die FFT bleibt unnormiert; eine Division aller Bins durch $M$ würde die Entscheidung nicht ändern. Die NumPy-Dokumentation legt Vorzeichen, Binreihenfolge und Standardnormierung ausdrücklich fest. #cite(<lit:numpy-fft>, supplement: [Implementation details; Normalization])

#listing("signal")

Auf eine Fensterfunktion und auf zusätzliche Nullsamples wird verzichtet. Der Detektor untersucht genau die $M$ orthogonalen Modellbins eines vollständigen Symbols. Eine Fensterung würde diese Untersuchung verändern; zusätzliche Nullsamples würden die Zahl der untersuchten Spektralstellen erhöhen, aber keine zusätzliche Signalinformation erzeugen. Die Symbolindizes bleiben in der ursprünglichen FFT-Reihenfolge. Ein #raw("fftshift") wäre nur mit entsprechend angepasster Indexzuordnung verwendbar.

== Kontrollfälle und Rauschnormierung

Vor den Kampagnen wurden sämtliche Symbole ohne Rauschen gesendet und erkannt. Für SF 7 waren 128 von 128, für SF 8 insgesamt 256 von 256 und für SF 9 insgesamt 512 von 512 Entscheidungen korrekt. Die maximale numerische Abweichung des Sendesignalbetrags von eins betrug weniger als $5 dot 10^(-16)$. Zusätzlich wurde die diskrete Orthogonalität der vollständigen Symbolalphabete geprüft. Diese Kontrollen bestätigen Eigenschaften der Implementierung im definierten Modell; sie validieren keinen realen LoRa-Empfänger.

Bei normierter Signalleistung $P_S = 1$ wird für ein vorgegebenes Sample-SNR die gesamte Rauschleistung als

$ P_N = 10^(-"SNR"_("Sample,dB")/10) $

berechnet. Unabhängige standardnormalverteilte Zufallszahlen $a[n]$ und $b[n]$ ergeben das komplexe Rauschen

$ w[n] = sqrt(P_N/2) (a[n] + j b[n]). $

Damit sind die Mittelwerte beider Komponenten null und ihre Varianzen jeweils $P_N/2$. Die erwartete Gesamtleistung ist $E[abs(w[n])^2] = P_N$. Der Faktor $1/2$ verhindert, dass durch die beiden Komponenten versehentlich die doppelte Rauschleistung eingespeist wird. Dies ist die diskrete Umsetzung des komplexen gaußschen Rauschmodells mit gleichen Komponentenvarianzen. #cite(<lit:gallager-rauschen>, supplement: [Abschnitte 7.7–7.8.1])

Eine separate Kontrolle mit 100#h(0.15em)000 Rauschsamples bei 0 dB ergab eine mittlere Leistung von 1,006756 und Varianzen von 0,502922 im Realteil sowie 0,503832 im Imaginärteil. Die Sollwerte 1 beziehungsweise 0,5 wurden innerhalb der vorab gesetzten absoluten Toleranzen von 0,02 für die Leistung und 0,01 für die Varianzen erreicht. Auch die Komponentenmittelwerte und ihre Stichprobenkovarianz lagen innerhalb von $plus.minus 0.01$. Die Unabhängigkeit folgt aus der getrennten Erzeugung der Zufallszahlen; die Stichprobenkontrolle allein beweist sie nicht.

== Parameter und Versuchsplanung

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (center, right, right, right),
    inset: 7pt,
    table.header([SF], [$M$], [$T_s$ in ms], [$R_b$ in bit/s]),
    [7], [128], [1,024], [6835,94],
    [8], [256], [2,048], [3906,25],
    [9], [512], [4,096], [2197,27],
  ),
  kind: table,
  supplement: [Tabelle],
  caption: [Symbolparameter bei $B = f_s = 125 "kHz"$; uncodierte Modellbitrate ohne Paket- und Protokollanteile.],
) <tab-css-parameter>

In der ersten Kampagne wurde das SNR pro Sample von −24 bis 0 dB in Schritten von 2 dB variiert. Mit drei SF-Werten und jeweils 5000 Symbolen pro Punkt ergeben sich 39 Punkte und 195#h(0.15em)000 Symbolversuche. Die zweite Kampagne verwendet gemeinsame $E_s/N_0$-Werte von 0 bis 18 dB in Schritten von 2 dB. Ihre 30 Punkte mit jeweils 5000 Symbolen umfassen weitere 150#h(0.15em)000 Versuche. Die beiden Rauschkampagnen ohne Offset umfassen somit 345#h(0.15em)000 simulierte Symbole unter Rauschen.

Für die diskrete Energie $E_(s,"diskret") = sum_(n=0)^(M-1) abs(x_m[n])^2 = M$ gilt bei diesem Abtastmodell

$ (E_s/N_0)_"dB" = "SNR"_("Sample,dB") + 10 log_10(M). $

Für jeden Energiepunkt wurde daher zunächst das benötigte Sample-SNR berechnet und anschließend neues Rauschen erzeugt:

$ "SNR"_("Sample,dB") = (E_s/N_0)_"dB" - 10 log_10(M), quad
  P_N = M / 10^((E_s/N_0)_"dB"/10). $

Für die zweite Kampagne wurden eigene Zufallsversuche ausgeführt. Bei $E_s/N_0 = 10 "dB"$ sind beispielsweise Rauschleistungen von 12,8, 25,6 und 51,2 für SF 7, 8 und 9 erforderlich. Mit der komplexen Basisbandkonvention $P_N = N_0 B$ und $E_s = P_S M/B$ folgt $E_s/N_0 = M P_S/P_N$. Damit ist die verwendete Umrechnung festgelegt; $N_0$ wird hier nicht nochmals auf zwei Komponenten aufgeteilt. Die Energie eines physikalischen Signals gleicher Leistung ist proportional zu $T_s = M/B$; der zweite Vergleich hält das Verhältnis $E_s/N_0$ durch die angepasste Rauschleistung konstant.

Der feste Hauptseed ist 20261103. Der PCG64-Generator erhält für jeden Punkt einen getrennten Zufallsstrom aus Hauptseed, Kampagnenkennung, SF und Rasterindex. #raw("SeedSequence") mischt diese ganzzahligen Kennungen; getrennte Ströme sind eine Eigenschaft der gewählten Pseudozufallskonstruktion und kein experimenteller Unabhängigkeitsnachweis. #cite(<lit:numpy-streams>, supplement: [SeedSequence spawning]) Die Kontrolle des Rauschens nutzt einen eigenen Strom. Verarbeitet werden Batches von höchstens 256 Symbolen. Pro Batch werden zunächst Symbolindizes und danach Real- und Imaginärrauschen gezogen. Damit sind die Ziehfolge und die Bedingungen zur Wiederholung festgelegt.

== Fehlerrate und statistische Unsicherheit

Aus der Fehlerzahl $k$ und der Versuchszahl $N = 5000$ wird die beobachtete Symbolfehlerrate $hat(p) = k/N$ berechnet. Für jeden Punkt wird zusätzlich ein zweiseitiges 95-%-Wilson-Intervall verwendet. Mit $z = 1.959964$ sind dessen Mittelpunkt $c$ und halbe Breite $h$

$ c = (hat(p) + z^2/(2N))/(1+z^2/N), quad
  h = z/(1+z^2/N) sqrt((hat(p)(1-hat(p)))/N + z^2/(4N^2)). $

Die Grenzen sind $c-h$ und $c+h$. Diese Intervalle berücksichtigen die endliche Zahl zufälliger Versuche. Sie gelten punktweise und bilden kein simultanes 95-%-Band über alle 69 Punkte. Modellfehler werden dadurch nicht erfasst. Die Formel entspricht der Wilson-Methode im NIST-Handbuch, Abschnitt 7.2.4.1. Ein 95-%-Konfidenzverfahren beschreibt die Überdeckung bei wiederholten Stichproben; es ordnet dem unbekannten Parameter nach der Rechnung keine Wahrscheinlichkeit von 95 % zu. #cite(<lit:nist-wilson>, supplement: [Abschnitt 7.2.4.1])

Bei null Fehlern lautet das Intervall $[0; 0.000767702]$, die obere Grenze entspricht etwa 0,07677 %. Null beobachtete Fehler weisen somit keine Fehlerwahrscheinlichkeit von null nach. Auf der logarithmischen y-Achse ist null nicht darstellbar. Solche Fälle erscheinen deshalb als offene Abwärtsdreiecke an der oberen Wilson-Grenze; sie werden nicht durch einen willkürlichen positiven SER-Wert ersetzt.

== Monte-Carlo-Schleife und ausführbare Beispiele

Die Funktionen für Rauschen und Intervallrechnung sind bewusst getrennt. #raw("rauschen") erhält denselben Generator wie die Symbolziehung; seine beiden Aufrufe erzeugen zuerst den vollständigen Realteil und danach den Imaginärteil eines Batches. #raw("wilson") verarbeitet die ganzzahlige Fehlerzählung, nicht gerundete Prozentwerte.

#listing("statistik")

Die folgende Schleife simuliert einen Punkt des Rasters. Der letzte Batch kann kleiner als 256 sein, sodass genau $N$ Entscheidungen gezählt werden. Für einen Energievergleich wird vor dem Aufruf #raw("snr_db = es_n0_db - 10*np.log10(2**sf)") berechnet. Bei Frequenzoffset wird der Phasenfaktor vor dem Rauschen auf das Nutzsignal angewendet. Als Fehler zählt stets die Abweichung vom ursprünglich gesendeten Index.

#listing("punkt")

Die Listings werden aus der lokalen Datei #raw("arbeit/listings/kapitel6.py") eingebunden. Sie ist eine unveränderte Kopie der eigenständig ausführbaren, auf die Rechenschritte verkürzten Fassung #raw("tools/src/simulation/kapitel6.py"). Die Kampagnenprogramme #raw("basis.py") und #raw("offset_campaign.py") ergänzen Raster, CSV-Export, Grafiken und Laufprotokolle. Der folgende Einstieg zeigt drei gezielt ausgewählte Punkte mit den ursprünglichen Zufallsstromkennungen; alle Imports und Funktionen der vorherigen Listings gehören dazu.

#listing("beispiele")

Der Aufruf #raw("tools/.venv/bin/python tools/src/simulation/kapitel6.py") aus dem Projektstamm liefert für SF 7 den Peak in Bin 17 mit Betrag 128 sowie die Fehlerzahlen 1023, 541 und 2475. Diese Zahlen gehören zu unterschiedlichen Versuchsbedingungen. Ihre Übereinstimmung mit den gespeicherten Kampagnen wird im Abschlussprüfskript kontrolliert; sie ergibt sich nicht allein daraus, dass dieselbe Modellformel verwendet wird.

== Ergebnisse bei gleichem SNR pro Sample

#figure(
  image("../abbildungen/css-awgn.svg", width: 100%),
  caption: [Simulierte Symbolfehlerrate bei gleichem SNR pro Sample für SF 7–9. Je Punkt 5000 Symbole, $B = f_s = 125 "kHz"$, perfekte Synchronisation und komplexes AWGN. Fehlerbalken: punktweise 95-%-Wilson-Intervalle. Offene Dreiecke markieren die obere Intervallgrenze bei null Fehlern.],
) <fig-css-snr>

Im Übergangsbereich liegt die Fehlerrate bei größerem SF deutlich niedriger (@fig-css-snr). Bei −12 dB Sample-SNR wurden für SF 7 insgesamt 1023 Fehler beobachtet, entsprechend einer SER von 0,2046. Für SF 8 waren es 75 Fehler, also 0,0150; für SF 9 trat in 5000 Versuchen kein Fehler auf. Die zugehörigen Wilson-Intervalle sind $[0.193647; 0.216007]$, $[0.011984; 0.018761]$ und $[0; 0.000767702]$.

Der Vorteil eines höheren SF ist hier mit längerer Sendedauer verbunden. Bei unveränderter Leistung und Bandbreite verdoppelt sich die Symbolenergie mit jedem SF-Schritt. Das Verhältnis $E_s/N_0$ wächst dadurch bei gleichem Sample-SNR um $10 log_10(2) approx 3.0103 "dB"$. Der Detektor kann über ein längeres Symbol integrieren. Gleichzeitig sinkt die uncodierte Bitrate, wie @tab-css-parameter zeigt: Die Symbolzeit verdoppelt sich, während die Bitzahl pro Symbol nur um eins zunimmt. Die beobachtete Verbesserung ist daher zusammen mit Zeit- und Energieaufwand zu bewerten.

== Ergebnisse bei gemeinsamem Energieverhältnis

#figure(
  image("../abbildungen/css-awgn-energy.svg", width: 100%),
  caption: [Separat simulierte Symbolfehlerrate auf gemeinsamem $E_s/N_0$-Raster. Für jeden SF wurde die Rauschleistung passend zu $M$ neu berechnet. Übrige Modellbedingungen und Intervallkonventionen wie in @fig-css-snr.],
) <fig-css-energy>

Auf der gemeinsamen Energieachse verschwindet der deutliche Vorteil größerer SF (@fig-css-energy). Bei $E_s/N_0 = 10 "dB"$ wurden für SF 7 insgesamt 541 Fehler gezählt, entsprechend einer SER von 0,1082. Für SF 8 ergibt sich aus 717 Fehlern eine SER von 0,1434, für SF 9 aus 953 Fehlern eine SER von 0,1906. Die punktweisen Wilson-Intervalle lauten $[0.099889; 0.117113]$, $[0.133959; 0.153389]$ und $[0.179952; 0.201723]$.

Die Kurven fallen somit nicht exakt zusammen: In diesem Bereich nimmt die Fehlerrate mit dem SF sogar zu. Bei gleichem Energieverhältnis konkurriert der Nutzbin bei größerem $M$ mit mehr möglichen Rauschbins. Die längere Symbolzeit liefert nun keinen zusätzlichen Vorteil im Verhältnis von Nutzenergie zu Rauschdichte, weil dieser Effekt durch die angepasste Rauschleistung ausgeglichen wurde. Die Kampagnen vergleichen verschiedene Bedingungen.

Die Abhängigkeit von der Alphabetgröße lässt sich im idealen Modell genauer begründen. Nach Dechirping und Division der FFT durch $sqrt(M P_N)$ hat jeder reine Rauschbin die mittlere quadratische Amplitude eins; im Nutzbin kommt die Amplitude $sqrt(gamma)$ mit $gamma = E_s/N_0$ hinzu. Weil Dechirping betragsneutral und die normierte DFT unitär ist, bleiben die gaußschen Rauschbins unabhängig. Die Leistung eines reinen Rauschbins ist dann exponentiell verteilt. Für die Nutzbinleistung $V$ besitzt jeder andere Bin die Wahrscheinlichkeit $1-exp(-V)$, kleiner als $V$ zu sein. Damit gilt bedingt auf $V$:

$ P("richtig" mid V) = (1-exp(-V))^(M-1). $

Bei festem $gamma$ ist die Verteilung von $V$ unabhängig von $M$, aber die Zahl der konkurrierenden Bins wächst. Deshalb steigt die theoretische Fehlerwahrscheinlichkeit in diesem Modell mit $M$. Dies ist eine eigene Folgerung aus dem orthogonalen Signal- und Gaußmodell, keine zusätzliche Monte-Carlo-Messung. Ein Vergleich bei gleicher Bitenergie wäre anders normiert: Uncodiert gilt $E_s = "SF" E_b$, also $(E_s/N_0)_"dB" = (E_b/N_0)_"dB" + 10 log_10("SF")$.

Bei 16 und 18 dB $E_s/N_0$ wurden für alle drei SF keine Fehler beobachtet. In diesem Bereich begrenzt die Versuchszahl die Aussagekraft: Aus den Nullfehlerfällen lässt sich weder eine exakte Fehlerrate von null noch eine belastbare Rangfolge der SF ableiten.

== Reproduzierbarkeit und Aussagegrenzen

Die Implementierung liegt unter #raw("tools/src/simulation/"). Die Dateien #raw("css-awgn.csv") und #raw("css-awgn-energy.csv") enthalten für jeden Punkt SF, Bandbreite, Sample-SNR, Energieverhältnis, Rauschleistung, Versuchszahl, Fehlerzahl, SER und Wilson-Grenzen. #raw("lauf.json") speichert den tatsächlichen Aufruf, Seed und Zufallsstromdefinition, Parameter sowie Softwareversionen und Quellcode-/CSV-Prüfsummen. Verwendet wurden Python 3.13.16, NumPy 2.5.4 und Matplotlib 3.11.2. Die Abschlussprüfung berechnet alle 135 Punkte mit der Listing-Fassung erneut und vergleicht ihre Fehlerzahlen mit den gespeicherten Werten. Zusätzlich werden die CSV-Prüfsummen gegen die ursprünglichen Laufprotokolle geprüft. Reproduzierbarkeit setzt neben dem Seed denselben Generator, dieselbe Aufrufreihenfolge, Arraygrößen und eine passende Softwareumgebung voraus; NumPy verspricht keine beliebige plattform- und versionsübergreifende Identität. #cite(<lit:numpy-kompatibilitaet>, supplement: [Compatibility policy]) Die Prüfaufrufe sind in #raw("tools/README.md") dokumentiert.

Die Ergebnisse gelten für synchrones, uncodiertes CSS mit komplexem AWGN. Sie liefern keine Aussage über reale Funkreichweite, Antennenwirkungsgrad oder vollständige LoRa-/ExpressLRS-Pakete. Insbesondere wurden Timingfehler, Mehrwege, Störungen durch andere Nutzer und reale Empfängereigenschaften nicht simuliert. Die folgende Erweiterung untersucht zusätzlich einen Frequenzoffset, bezogen auf den FFT-Binabstand $B/M$.

== Einfluss eines Frequenzoffsets

Ein konstanter Frequenzoffset $Delta f$ wird durch $delta = Delta f/(B/M)$ normiert. Vor der Addition des Rauschens wird das Sendesignal mit $exp(j 2 pi delta n/M)$ multipliziert. Nach dem Dechirpen bleibt daher ein Ton mit $m+delta$ Perioden im Symbolintervall. Die Entscheidung erfolgt weiterhin mit demselben FFT-Detektor; eine Schätzung oder Korrektur des Offsets findet nicht statt.

Für ganzzahliges $delta$ liegt der Peak bei $(m+delta) mod M$. Alle Symbole für SF 7–9 wurden bei $delta = 0, +1, -1$ geprüft: 2688 von 2688 Fällen erfüllen diese Vorhersage, die Peakhöhe weicht dabei um höchstens $10^(-10)$ von $M$ ab. Der Nullfall verändert die Signalsamples exakt nicht. Die Übereinstimmung mit dem vorhergesagten verschobenen Bin bedeutet bei $delta = plus.minus 1$ jedoch eine falsche Symbolentscheidung gegenüber dem gesendeten Index.

Bei gebrochenem Offset verteilt sich die Energie auf mehrere FFT-Bins. Für den Abstand $a = m+delta-k$ zum Bin $k$ ergibt die endliche geometrische Summe den FFT-Betrag

$ abs(Y[k]) = abs(sin(pi a)/sin(pi a/M)). $

Hier bezeichnet $Y[k]$ die FFT nach dem Dechirpen im rauschfreien Offsetfall. Die Gleichung folgt aus $Y[k] = sum_(n=0)^(M-1) exp(j 2 pi a n/M)$: Mit $q = exp(j 2 pi a/M)$ wird die Summe zu $(1-q^M)/(1-q)$; die Beträge der Exponentialdifferenzen ergeben die beiden Sinusfaktoren. An hebbaren Singularitäten ist der jeweilige Grenzwert einzusetzen, bei $a = 0$ insbesondere $M$. Diese Formel wurde unabhängig von der FFT über die normierte Sinusfunktion geprüft. Für alle Symbole wurden außerdem die nächstgelegenen Bins abseits des Halb-Bin-Falls kontrolliert. Bei $abs(delta) = 0.5$ sind im rauschfreien Fall die beiden benachbarten Peaks gleich hoch. Ein numerischer Gleichstand wird deshalb nicht als eindeutige physikalische Entscheidung interpretiert. Bei ausreichend hohem Energieverhältnis und symmetrischem Rauschen sind ungefähr gleich häufige Entscheidungen zwischen beiden Nachbarn zu erwarten; bei stärkerem Rauschen können weitere Bins gewinnen.

Die Offset-Kampagne verwendet $delta = -1; -0.75; -0.5; -0.49; -0.25; 0; 0.25; 0.49; 0.5; 0.75; 1$ und die beiden Energieverhältnisse $E_s/N_0 = 10$ und 16 dB. Für jeden SF und Rasterpunkt wurden 5000 neue Symbole simuliert, insgesamt 66 Punkte und 330#h(0.15em)000 Versuche. Bandbreite und Abtastrate bleiben 125 kHz. Rauschleistung und Wilson-Intervalle werden wie oben berechnet. Der Seed ist 20261104; getrennte PCG64-Ströme entstehen aus Seed, Kampagnenkennung 3, SF, Energieindex und Offsetindex. Die Batches enthalten höchstens 256 Symbole.

#figure(
  image("../abbildungen/css-offset-awgn.svg", width: 100%),
  caption: [Frequenzoffset bei festem $E_s/N_0$. Je Punkt 5000 Symbole; Fehlerbalken: punktweise zweiseitige 95-%-Wilson-Intervalle. Lineare SER-Achse einschließlich Nullfehlerfällen; gestrichelte Linien bei den Halb-Bin-Grenzen. Keine Offsetkorrektur.],
) <fig-css-offset>

Bei 10 dB und null Offset ergeben sich SER-Werte von 0,1076, 0,1514 und 0,1888 für SF 7–9. Das sind neue Zufallsversuche, weshalb die Werte leicht von der vorherigen Energiekampagne abweichen. Bei $delta = 0.25$ steigen sie auf 0,2138, 0,2700 und 0,3322. Bei 16 dB werden ohne Offset für alle drei SF null Fehler beobachtet, bei $delta = 0.49$ dagegen 2187, 2171 und 2146 Fehler. Genau bei $delta = 0.5$ lauten die Fehlerzahlen 2475, 2472 und 2471: Die SER liegt jeweils nahe 0,5. Bei $delta = 0.75$ werden bei 16 dB alle 5000 Symbole je SF falsch erkannt. Die Intervalle bei null beziehungsweise 5000 Fehlern reichen bis 0,000767702 beziehungsweise beginnen bei 0,999232298; auch diese Randfälle beweisen keine exakte Wahrscheinlichkeit null oder eins.

Die normierte Achse darf nicht mit einem festen Offset in Hertz gleichgesetzt werden: Ein halber Bin entspricht bei SF 7 rund 488,281 Hz, bei SF 8 rund 244,141 Hz und bei SF 9 rund 122,070 Hz. Bei gleichem physikalischem Frequenzfehler wächst der normierte Offset daher mit dem SF. Ein höherer SF kann unter den Bedingungen der ersten Rauschkampagne helfen und zugleich engere Frequenzabstände erfordern. Die Ergebnisse beschreiben einen unkorrigierten Einzel-Symbol-Detektor, keine reale LoRa-Synchronisation.

Code und Rohzählungen liegen unter #raw("offset_campaign.py") und #raw("css-offset-awgn.csv"). #raw("css-offset-lauf.json") enthält Parameter, Versionen, Kontrollfälle und SHA256-Prüfsummen. Ein Wiederholungslauf lieferte byteidentische CSV-Daten; Aufrufe und unabhängige Ergebnisprüfung sind in #raw("tools/README.md") dokumentiert.

#pagebreak(weak: true)

== Rust-Werkzeug zur Messdatenauswertung

Das Rust-Kommandozeilenwerkzeug unter #raw("auswertung/") berechnet aus komplexem S11 den Reflexionsbetrag, die Phase, S11 in dB, Impedanz und VSWR. Unterstützt wird ein begrenzter Touchstone-1.x-Einportimport mit RI-, MA- und DB-Darstellung, Frequenzeinheit und reeller positiver Referenzimpedanz. Zusätzlich können CSV-Dateien mit komplexen S11-Spalten importiert werden, auch mit den NanoVNA-Spaltennamen. CSV-Einlesen und -Ausgabe verwenden die Bibliotheken #raw("serde") und #raw("csv"); abgeleitete Messgrößen werden neu berechnet. Aufrufe und Prüfkommandos stehen in #raw("auswertung/README.md"). Nicht unterstützte oder fehlerhafte Dateien werden vor der CSV-Ausgabe abgelehnt. Singuläre und undefinierte Werte erhalten ausdrückliche Statusfelder.

Der Rechenkern wurde an den Fällen $Gamma = 0, -1, 1, 0.5$ und $plus.minus j/2$ geprüft. Bei 50 Ω ergeben sich beispielsweise für $Gamma = 0.5$ die Impedanz 150 Ω, VSWR 3 und S11 von etwa −6,0206 dB. Für $Gamma = j/2$ folgt aus $Z = 50 (1+j/2)/(1-j/2)$ die Impedanz $30+j 40$ Ω. Äquivalente RI-, MA- und DB-Dateien liefern innerhalb der festgelegten Toleranzen dieselben Werte. Die aktuelle Fassung besteht alle zehn Rechen-, CLI- und Importtests.

Drei vorliegende VNA-Exporte wurden mit jeweils 101 Punkten importiert. Die zehn numerischen Ausgabespalten aller 303 Punkte wurden zusätzlich unabhängig mit Python und komplexer Arithmetik nachgerechnet, mit absoluter Toleranz $10^(-10)$ oder relativer Toleranz $10^(-12)$. Dieser Vergleich prüft die Datenverarbeitung, nicht die Messgenauigkeit des VNA.

Der Softwarevergleich ist damit abgeschlossen. Ein zusätzlicher Abgleich mit einem gespeicherten Gerätemarker bei gleicher Frequenz, Bezugsgröße und Referenzebene ist Teil der experimentellen Validierung in Kapitel 7. Der dort dokumentierte Abgleich wurde am 5. November 2026 durchgeführt; seine Aussagekraft ist auf Datenübernahme und gerundete Anzeige begrenzt.

== Rust-Rechenkern und WebAssembly-Begleitwebsite <rust-wasm>

Die Begleitwebsite setzt das diskrete Signalmodell als unmittelbar bedienbare Anwendung um. Der Rechenkern liegt in der eigenständigen Rust-Crate #raw("css-wasm/"); sie ist vom S11-Auswertungswerkzeug unter #raw("auswertung/") getrennt. TypeScript und Next.js übernehmen die Benutzeroberfläche und die Diagrammdarstellung. Chirperzeugung, Rauschen, Frequenzoffset, Dechirping, FFT und Symbolentscheidung werden dagegen vollständig in Rust berechnet.

=== Umsetzung der Modellgleichungen

Die Rust-Fassung verwendet dieselben Modellgleichungen und Rauschleistungsbezüge wie die Python-Simulation. Bei $B = f_s = 125 "kHz"$ sind SF 7, 8 und 9, der Symbolindex, das Sample-SNR sowie ein Frequenzoffset von −2 bis +2 Bins einstellbar. Der Referenzchirp und die Symbolverschiebung werden aus den Gleichungen in Kapitel 3 erzeugt. Nach Addition des komplexen gaußschen Rauschens und Anwendung des Frequenzoffsets folgt die Multiplikation mit dem konjugierten Referenzchirp. Eine unnormierte Radix-2-FFT liefert die Beträge; der größte Betrag bestimmt das erkannte Symbol.

Für die Rauscherzeugung werden ein deterministischer Mulberry32-Generator und die Box–Muller-Transformation verwendet. Der Seed wird mit den übrigen Parametern übergeben. Wiederholte Aufrufe mit denselben Parametern liefern innerhalb derselben Implementierung dieselben Ergebnisse; die Zufallsfolge ist jedoch nicht identisch mit der NumPy-Folge. Mathematisch gleich hohe Peaks, etwa beim Halb-Bin-Offset ohne Rauschen, können durch Gleitkommarundung unterschiedlich aufgelöst werden.

=== Übersetzung und Schnittstelle

Die Crate wird für das Rust-Ziel #raw("wasm32-unknown-unknown") zu WebAssembly übersetzt. Dieses Ziel ermöglicht die Ausführung kompilierten Rust-Codes in einer WebAssembly-Laufzeit und stellt nicht die üblichen Betriebssystemfunktionen eines nativen Programms bereit. @lit:rust-wasm-target

Das Werkzeug #raw("wasm-pack") erzeugt daraus das lokale npm-Paket #raw("@")#raw("wseminar/css-wasm"). Es enthält die WASM-Binärdatei, die mit #raw("wasm-bindgen") erzeugte JavaScript-Anbindung und TypeScript-Deklarationen. Die Ausgabe mit #raw("--target web") wird als ES-Modul eingebunden und vor dem ersten Rechenaufruf initialisiert. @lit:wasm-bindgen-deployment

Die Schnittstelle #raw("simulate_json") nimmt einen JSON-Text mit SF, Symbolindex, Rauschschalter, Sample-SNR, Offset und Seed entgegen. Rust prüft den Parametersatz und berechnet erst danach die Signalfolgen. Zurückgegeben werden ein JSON-Text mit den Samples, FFT-Beträgen, der Symbolentscheidung, Symbolzeit und Binabstand. TypeScript überführt diese Daten in die Diagrammdarstellung. Das folgende Listing zeigt die tatsächlich verwendete Schnittstelle; der numerische Rechenkern wird durch #raw("simulate") aufgerufen.

#raw(
  read("../listings/css-wasm.rs").split("// START WASM_INTERFACE\n").at(1)
    .split("// END WASM_INTERFACE").at(0).trim(),
  lang: "rust", block: true,
)

Das Modul wird einmalig im Browser geladen; Parameteränderungen benötigen keinen Rechenserver. Ein Ladefehler wird angezeigt und kann durch erneutes Laden behandelt werden. Der Website-Bau erzeugt die WASM-Datei für die statische Website. Das npm-Paket ist zusätzlich als lokales Archiv verfügbar und wird nicht öffentlich veröffentlicht.

=== Prüfung und Aussagegrenzen

Vier native Rust-Tests prüfen den Rechenkern. Ergänzend führen sieben Tests im Frontend das tatsächlich kompilierte WASM-Paket aus. Dazu gehören sämtliche 896 rauschfreien Symbolentscheidungen für SF 7 bis 9, zyklische Verschiebungen bei ganzzahligen Offsets, gleich hohe Nachbarpeaks beim Halb-Bin-Offset, ungültige Eingaben sowie Reproduzierbarkeit und Leistungsnormierung des Rauschens. Ausgewählte rauschfreie Empfangssamples stimmen mit der Python-Implementierung auf $10^(-10)$ überein; für die FFT-Beträge wird eine absolute Toleranz von $10^(-8)$ verwendet. Die Browserprüfung umfasst zudem die Bedienung sowie fehlende Moduldateien und erneutes Laden.

Die Kontrollen prüfen die Modellumsetzung und Browserintegration, nicht einen realen LoRa-Empfänger oder eine vollständige Funkverbindung. Ein Geschwindigkeitsvorteil gegenüber JavaScript wurde nicht untersucht. Rust und WebAssembly dienen hier einem getrennt prüfbaren, im Browser wiederverwendbaren Rechenkern.

Die interaktive Anwendung zeigt einzelne Symbolentscheidungen und ersetzt keine Monte-Carlo-Auswertung. Vordefinierte Versuche veranschaulichen Rauscheinfluss sowie einen halben und einen ganzen Bin Frequenzoffset. Die statistischen Ergebnisdiagramme übernehmen weiterhin die gespeicherten CSV-Daten der drei Kampagnen, die NanoVNA-Darstellungen die vorhandenen Messgrafiken. Quellcode und lokaler Betrieb sind in @begleitwebsite dokumentiert.

== Einordnung der Untersuchung

Die drei Kampagnen beantworten die untersuchten Fragen innerhalb desselben Modells: Bei festem Sample-SNR sinkt die beobachtete Fehlerrate mit wachsender Symbolzeit, bei festem $E_s/N_0$ wirkt dagegen die größere Zahl konkurrierender Bins. Ein unkorrigierter Frequenzoffset verteilt die Energie zwischen diesen Bins und kann schon ohne Rauschen eine falsche Symbolzuordnung verursachen. Symbolzeit, Energie und Frequenzraster müssen deshalb bei einem SF-Vergleich gemeinsam angegeben werden.
