= Ergänzende NanoVNA-Messungen <kap-messung>

Die numerische Untersuchung beschreibt die Symbolerkennung in einem vereinfachten CSS-Modell. Ergänzend dazu wurden am 5. November 2026 reale Einportmessungen durchgeführt. Sie untersuchen die Reflexion an drei Abschlüssen sowie den Einfluss eines zwischen Messgerät und Abschluss eingefügten Koaxialkabels. Die Fragen lauten: Lassen sich Leerlauf, Kurzschluss und angepasste Last in den komplexen Messwerten unterscheiden? Wie verändert das Kabel die am Geräteport beobachtete Reflexion? Gemessen wird damit eine leitungsgebundene Größe; Reichweite und Paketempfang werden nicht untersucht.

== Messaufbau und Durchführung

Verwendet wurde ein NanoVNA-F V2 mit den OPEN-, SHORT- und LOAD-Standards sowie einem der beiden Kabel des Standardsets. Die USB-Abfrage identifizierte das Gerät als #raw("NanoVNA-F_V2") mit Firmware 0.6.5. Als Referenzimpedanz wurde $Z_0 = 50 thin Omega$ verwendet. Der Messbereich reichte von 2,3 bis 2,5 GHz und bestand aus 101 Punkten mit 2 MHz Abstand. Das Herstellerhandbuch beschreibt das Gerät und seine Einportkalibrierung; seine Revision 2.0 bezieht sich auf die ältere Firmware 0.3.0. Die hier verwendete Firmware wurde deshalb unmittelbar am vorhandenen Gerät ausgelesen. #cite(<lit:sysjoint-fv2>, supplement: [Abschnitte 1.3, 4.4 und 7.2])

Vor der Aufnahme war am Gerät bereits eine Open-Short-Load-Kalibrierung für 2,3 bis 2,5 GHz durchgeführt worden. Die Standards waren dabei direkt am S11-Messport angeschlossen. Diese Referenzebene und die Kalibrierung blieben während der Reihen unverändert. Die Statusabfrage lieferte jeweils #raw("load open short cal'ed"). Sie dokumentiert die aktivierte Gerätekorrektur; Messbereich und Anschlussort der vorausgegangenen Kalibrierung wurden zusätzlich aus dem Versuchsablauf bestätigt. Eine neue Kalibrierung wurde während der Aufnahmen nicht ausgeführt.

Die theoretische Grundlage einer Eintorkorrektur lässt sich durch drei komplexe Fehlergrößen beschreiben: endliche Direktivität, Quellanpassung und die Übertragung im Reflexionsmesspfad. Gronau schreibt den gemessenen Reflexionsfaktor $M$ in der Form

$ M = E_D + (E_R Gamma)/(1-E_S Gamma). $

Dabei ist $Gamma$ der gesuchte Reflexionskoeffizient des Prüflings; $E_D$, $E_S$ und $E_R$ beschreiben die drei systematischen Fehlerbeiträge. Drei bekannte Standards liefern die Beziehungen zur Bestimmung dieser Größen. @lit:gronau2001[S. 370–372, insbesondere Gl. (8.53)–(8.57)] Das Modell erklärt das Korrekturprinzip. Die Fehlerkoeffizienten der hier aktivierten Gerätekalibrierung wurden nicht separat ausgelesen oder neu bestimmt.

#figure(
  image("../abbildungen/nanovna-aufbau.svg", width: 100%),
  caption: [Schematischer Aufbau der drei Messarten. Die gestrichelte Linie markiert die unveränderte Referenzebene am Geräteport. Im unteren Aufbau wurde am gleichen Adapter zwischen OPEN und SHORT gewechselt. Eigene Skizze nach dem durchgeführten Ablauf; keine Fotografie.],
) <fig-vna-aufbau>

Zunächst wurden OPEN, SHORT und LOAD direkt am Geräteport gemessen. Jeder Standard wurde für drei Aufnahmen vollständig abgeschraubt und neu angeschlossen. Danach folgten drei Kabelzustände: Kabel mit frei offenem Ende ohne Adapter, Kabel mit Adapter und SHORT sowie Kabel mit demselben Adapter und OPEN. Für die Kabelwiederholungen wurde jeweils nur die Verbindung am Geräteport gelöst und mit demselben Kabelende erneut hergestellt. Der entfernte Aufbau blieb innerhalb einer Reihe unverändert. Das Kabel wurde möglichst ähnlich abgelegt; die Hände wurden vor dem Auslösen entfernt.

Der Adapter war erforderlich, weil der Abschluss mechanisch nicht direkt zum freien Kabelende passte. Er gehört deshalb ebenso wie das Kabel zum Prüfling hinter der Referenzebene. Insgesamt entstanden sechs Konfigurationen mit jeweils drei Anschlusswiederholungen, also 18 Aufnahmen und 1818 komplexe Frequenzpunkte. Das zweite Kabel des Sets wurde nicht untersucht. Eine Kalibrierung am entfernten Kabelende und eine LOAD-Messung hinter dem Kabel wurden nicht durchgeführt.

Die Anschlusswechsel führte ich von Hand aus. Die USB-Steuerung und die Auswertung erfolgten mit den im Projekt dokumentierten Python- und Rust-Werkzeugen, die mit KI-Unterstützung erstellt wurden. Die konkrete Kabeltypbezeichnung, die mechanische Länge des Kabels, die elektrische Charakterisierung des Adapters und der genaue Zeitpunkt der ursprünglichen Kalibrierung wurden nicht erfasst. Eine Aufbau-Fotografie liegt nicht vor. Diese Lücken begrenzen die spätere Reproduktion; sie werden nicht durch angenommene Zubehördaten ersetzt.

== Datenaufnahme und Auswertungsverfahren

Das Python-Werkzeug übertrug die Sweepgrenzen und Punktzahl über USB an das Gerät und las anschließend Frequenzen und Real-/Imaginärteile von S11 aus. Das Handbuch dokumentiert dafür die Befehle #raw("scan"), #raw("frequencies") und #raw("data 0"). #cite(<lit:sysjoint-fv2>, supplement: [Abschnitte 7.2.6-7.2.8]) Für jede Aufnahme wurden die seriellen Originalantworten, eine Touchstone-Datei mit der Kopfzeile #raw("# HZ S RI R 50"), eine abgeleitete CSV-Datei und Metadaten gespeichert. Eine SHA-256-Prüfsumme verknüpft die Touchstone-Datei mit dem Protokoll. Alle 18 Aufnahmen besitzen dasselbe geprüfte Frequenzraster. Die Daten werden weder geglättet noch nachträglich auf den passiven Bereich begrenzt.

Aus $Gamma = a + j b$ ergeben sich der Betrag $abs(Gamma) = sqrt(a^2+b^2)$, die Phase und der logarithmische Wert $S_(11,"dB") = 20 log_10(abs(Gamma))$. Dieser Wert trägt bei einem passiven Abschluss üblicherweise ein negatives Vorzeichen; die positiv definierte Rückflussdämpfung hat das entgegengesetzte Vorzeichen. Betrag, Phase, Impedanz und VSWR sind verschiedene Darstellungen derselben komplexen Reflexionsmessung, keine voneinander unabhängigen Messungen. @lit:keysight-reflection

Für jede Konfiguration wird bei jeder Frequenz der arithmetische Mittelwert der drei Beträge berechnet. Die angegebenen Minima und Maxima sind die beobachteten Werte der drei Anschlüsse. Sie sind weder Konfidenzintervalle noch eine vollständige Messunsicherheit. Insbesondere sind die 101 Frequenzpunkte keine 101 unabhängigen Anschlusswiederholungen.

Zur Darstellung der Kabelphase wird der Winkel entlang der Frequenz stetig fortgesetzt: Sprünge an der Darstellungsgrenze von ±180° werden durch Addition oder Subtraktion von 360° aufgehoben. Innerhalb einer Konfiguration werden die drei Kurven auf denselben Winkelzweig gebracht. Das verändert die komplexen Messwerte nicht. Für die direkten SHORT-Werte wird entsprechend der Winkel in der Umgebung von 180° betrachtet. Die LOAD-Phase wird nicht zur Interpretation herangezogen, weil der Reflexionsvektor nahe dem Ursprung liegt und kleine komplexe Restfehler seinen Winkel stark verändern können.

== Ergebnisse der direkten Standards

@fig-vna-standards zeigt die neun direkten Aufnahmen. OPEN liegt im Smith-Diagramm nahe dem rechten Rand, SHORT nahe dem linken Rand und LOAD nahe dem Mittelpunkt. Damit stimmen die gemessenen Lagen qualitativ mit den idealen Grenzfällen $Gamma = +1$, $Gamma = -1$ und $Gamma = 0$ überein. Der Unterschied zwischen OPEN und SHORT betrifft vor allem die Phase; ihre Beträge liegen beide nahe eins. Diese Grenzfälle werden auch in der Herstellerdokumentation zu Reflexionsmessungen erläutert. @lit:keysight-reflection

#figure(
  image("../abbildungen/nanovna-standards.svg", width: 100%),
  caption: [Direkte Standards, jeweils drei Anschlusswiederholungen. Durchgezogen, gestrichelt und gepunktet kennzeichnen die Anschlüsse 1, 2 und 3. In (b) ist die Abweichung vom idealen Phasenwinkel dargestellt: OPEN relativ zu 0°, SHORT relativ zu 180°. Die logarithmischen Beträge stehen für OPEN/SHORT und LOAD auf getrennten Skalen. Eigene Messdaten vom 5. November 2026.],
) <fig-vna-standards>

Bei 2,4 GHz beträgt der mittlere Reflexionsbetrag für OPEN 0,9955 und für SHORT 0,9895. Die mittleren Phasenwinkel liegen bei −0,33° beziehungsweise 179,72°. Die beobachteten Betragsbereiche sind in @tab-vna-zentrum angegeben. LOAD zeigt dagegen Beträge zwischen 0,0036 und 0,0111. Für die drei einzelnen LOAD-Aufnahmen entsprechen die ungerundeten Beträge den S11-Werten −42,53 dB, −39,07 dB und −48,98 dB. Diese logarithmischen Unterschiede sind keine entsprechend großen absoluten Unterschiede des Reflexionskoeffizienten: Die komplexen Werte bleiben in der Nähe des Ursprungs.

#include "../tabellen/nanovna-zentrum.typ"

Über das gesamte Band treten bei OPEN einzelne Beträge bis etwa 1,023 und bei SHORT bis etwa 1,005 auf. Diese gemessenen Überschreitungen werden erhalten. Sie sind kein Hinweis auf eine aktive Verstärkung durch die passiven Standards, sondern zeigen, dass die korrigierten Messwerte Restabweichungen enthalten. Gerade bei nahezu vollständiger Reflexion kann schon eine kleine komplexe Abweichung den Messpunkt über den Einheitskreis verschieben. Ein daraus rechnerisch negatives VSWR wird nicht als gültige passive Größe ausgegeben.

Die Anschlussstreuung lässt sich bei 2,4 GHz zusätzlich als Differenz zwischen größtem und kleinstem Betrag ausdrücken. Für OPEN beträgt diese Spannweite 0,00316, für SHORT 0,00571 und für LOAD 0,00757. Beim LOAD ist die absolute Spannweite damit größer als bei OPEN und SHORT, obwohl alle drei LOAD-Werte deutlich näher am Ursprung liegen. Eine relative Streuung bezogen auf den kleinen LOAD-Mittelwert würde diesen Unterschied stark vergrößern und wäre deshalb allein kein geeigneter Vergleich der Messqualität. Die Phasenspannweiten von OPEN und SHORT betragen 0,644° und 0,328°; für LOAD wird aus dem bereits genannten Grund keine entsprechende Phasenbewertung vorgenommen.

Im Smith-Diagramm ergänzt die Lage des Messpunkts die Betragsdarstellung: Zwei Punkte mit gleichem Abstand vom Ursprung können verschiedene Impedanzen darstellen. OPEN und SHORT sind dafür die Grenzbeispiele. Die Phase trennt die beiden nahezu vollständig reflektierenden Abschlüsse, während LOAD durch den kleinen Abstand zum Ursprung auffällt. Die drei Darstellungen beantworten somit verschiedene Fragen an denselben komplexen Datensatz. @lit:keysight-reflection

Die Standards wurden bereits zur Kalibrierung verwendet. Ihre erneute Messung kontrolliert deshalb die Plausibilität des Ablaufs und die beobachteten Anschlussunterschiede. Sie validiert weder die Standards unabhängig noch die absolute Genauigkeit des Geräts. Für eine Fehlerkorrektur werden Modelle der Standards verwendet; auch deren Abweichungen können systematische Fehler verursachen. @lit:keysight-calstandards @lit:nist-calstandards

== Ergebnisse der Kabelmessungen

Die Kabelreihen zeigen mit zunehmender Frequenz eine deutliche Drehung des Reflexionskoeffizienten in der komplexen Ebene. Bei 2,4 GHz beträgt die mittlere Phase des frei offenen Kabels 89,65°. Für Kabel mit Adapter und OPEN ergeben sich 10,32°, für denselben Aufbau mit SHORT −171,28°. Der kleinere Winkelabstand der beiden zuletzt genannten Zustände beträgt somit 178,40° und liegt nahe dem idealen Unterschied von 180°. Der Vergleich verwendet bei beiden Abschlüssen denselben Adapter. Die frei offene Kabelmessung besitzt dagegen sowohl einen anderen Abschluss als auch keinen Adapter und wird deshalb als eigene Konfiguration betrachtet.

#figure(
  image("../abbildungen/nanovna-kabel.svg", width: 100%),
  caption: [Die drei untersuchten Kabelkonfigurationen. In (a) zeigen blasse Linien alle drei Aufnahmen und kräftige Linien den komplexen Mittelwert; Punkte markieren die Startfrequenz. In (b) ist der mittlere Betrag logarithmisch dargestellt, die farbige Fläche reicht vom kleinsten bis zum größten Betrag. In (c) werden Mittelwert und beobachteter Bereich der stetig fortgesetzten Phase gezeigt. Die Flächen sind keine Unsicherheitsintervalle. Eigene Messdaten.],
) <fig-vna-kabel>

Die Beobachtung passt zur in Kapitel 4 beschriebenen Wirkung einer Leitung. Für ein gleichförmiges, bezüglich $Z_0$ angepasstes Leitungsmodell gilt

$ Gamma_"ein" = Gamma_"Last" exp(-2 (alpha + j beta) l). $

Die Phase enthält den Hin- und Rückweg. Bei näherungsweise frequenzunabhängiger Ausbreitungsgeschwindigkeit $v$ ist $beta = 2 pi f/v$, sodass

$ phi(f) = phi_"Last"(f) - 4 pi f l/v. $

Eine fallende Phase erklärt damit die Rotation der Kurven. Die Änderung des Reflexionskoeffizienten entlang einer Leitung ist bei Staelin in Abschnitt 7.3.1 hergeleitet. #cite(<lit:staelin7>, supplement: [S. 208-210, Gl. (7.3.3)]) Der gewählte Aufbau macht diesen Effekt sichtbar, weil die Referenzebene am Geräteport bleibt.

Zur ergänzenden Beschreibung wurde für jede Kabelaufnahme eine Gerade an die stetig fortgesetzte Phase über den gesamten Bereich von 2,3 bis 2,5 GHz angepasst. Aus der Steigung folgt die effektive Reflexionsverzögerung

$ tau_"eff" = -1/(2 pi) ("d" phi)/("d" f), $

wobei die Phase hier im Bogenmaß und die Frequenz in Hertz einzusetzen sind. Für das frei offene Kabel ergeben die drei Anpassungen 2,049 bis 2,054 ns. Für Kabel mit Adapter und OPEN sind es 2,118 bis 2,121 ns, für Kabel mit Adapter und SHORT 2,042 bis 2,046 ns. Diese Werte beschreiben die jeweilige gemessene Phasensteigung. Nur bei vernachlässigbarer Frequenzabhängigkeit der Abschlussphase und einem geeigneten Leitungsmodell entspräche $tau_"eff"$ unmittelbar der doppelten einfachen Laufzeit. Auch OPEN-/SHORT-Standards und Adapter können eine elektrische Verzögerung beitragen. @lit:keysight-portextensions

Aus den unterschiedlichen Steigungen wird daher keine präzise mechanische Kabellänge abgeleitet. Dafür fehlen unter anderem die dokumentierte Länge, die Ausbreitungsgeschwindigkeit und die getrennte Charakterisierung der Übergänge. Ebenso wird der kleinere Reflexionsbetrag hinter dem Kabel nicht allein als Kabeldämpfung ausgegeben. Bei 2,4 GHz liegen die mittleren Beträge bei 0,9848 für das freie Ende, 0,9404 für Adapter mit OPEN und 0,9055 für Adapter mit SHORT. Die Differenz zwischen den beiden letzten Werten zeigt bereits, dass ein reines Modell mit identischer Dämpfung und idealen Abschlüssen die Kombination nicht vollständig beschreibt. Die Messung erfasst Kabel, Adapter, Abschluss, Übergangsreflexionen und verbleibende Messfehler gemeinsam. Eine kleinere Eingangsreflexion bedeutet hier keine nachgewiesene Verbesserung des Abschlusses.

Bei den drei Kabelkonfigurationen betragen die Betrags-Spannweiten bei 2,4 GHz 0,00465 für das freie Ende, 0,00502 für Adapter mit OPEN und 0,00655 für Adapter mit SHORT. Die zugehörigen Phasenspannweiten liegen bei 0,570°, 0,434° und 0,816°. Der Unterschied der mittleren OPEN-/SHORT-Phasen von rund 178,40° ist damit deutlich größer als die beobachteten Anschlussunterschiede. Daraus folgt jedoch keine statistisch abgesicherte Abweichung vom idealen Wert 180°: Gemeinsame Kalibrierfehler und die unterschiedlichen elektrischen Eigenschaften der Abschlüsse werden durch diese drei Anschlusswiederholungen nicht erfasst.

=== Bedeutung der Referenzebene

Die Referenzebene legt fest, an welchem Ort das Verhältnis von rücklaufender zu hinlaufender Welle angegeben wird. Bei der hier gewählten Kalibrierung am Geräteport liegt die gesamte eingefügte Kabel-Adapter-Anordnung hinter dieser Ebene. Der VNA zeigt deshalb ihre Eingangsreflexion und nicht unmittelbar den Reflexionskoeffizienten am entfernten Abschluss. Dass ein offenes Kabel bei 2,4 GHz eine Phase nahe 90° statt nahe 0° besitzt, ist damit vereinbar: Der Abschluss ist offen, aber die Phase wird nach Hin- und Rückweg am anderen Ende der Leitung beobachtet.

Im idealen verlustlosen Modell verändert eine Verschiebung der Referenzebene entlang einer angepassten Leitung nur die Phase; der Betrag bleibt gleich. Eine Verlängerung um eine Viertelwellenlänge erzeugt beispielsweise eine zusätzliche Reflexionsphase von −180°. Ein idealer OPEN am Leitungsende würde dann am Eingang wie ein SHORT erscheinen. Erst die Angabe von Frequenz, elektrischer Länge und Referenzebene macht eine solche Impedanzbeschreibung eindeutig. Das ist eine Folgerung des Leitungsmodells, keine zusätzlich gemessene Viertelwellenleitung. #cite(<lit:staelin7>, supplement: [Abschnitt 7.3.1])

Für eine getrennte Beurteilung des entfernten Abschlusses wäre eine Kalibrierung an dessen Anschlussebene oder eine geeignete Korrektur der dazwischenliegenden Anordnung erforderlich. Eine Port-Extension kann den zusätzlichen Phasenweg und gegebenenfalls modellierte Verluste berücksichtigen; sie ersetzt nicht allgemein die vollständige Charakterisierung fehlangepasster Adapter und Übergänge. @lit:keysight-portextensions Eine solche Korrektur wurde hier nicht angewendet. Die unveränderte Referenzebene ist für diesen Versuch beabsichtigt, weil gerade der Einfluss der eingefügten Leitung sichtbar werden soll.

== Geräteabgleich und Bewertung

Zur Prüfung des Datenwegs wurde zusätzlich ein Gerätemarkerabgleich am unveränderten Aufbau Kabel + Adapter + OPEN durchgeführt. Dieser zusätzliche Datensatz gehört nicht zu den drei Anschlusswiederholungen. Nach dem seriellen Setzen des Markers zeigte das pausierte LCD zunächst noch die alte Markerposition. Deshalb wurde die Anzeige durch einen kurzen laufenden Sweep aktualisiert und danach angehalten. Der anschließend ausgelesene Messpuffer war vor und nach dem Bildschirmabruf identisch.

#figure(
  image("../abbildungen/nanovna-geraeteabgleich.png", width: 92%),
  caption: [Direkt über USB gespeicherte Geräteanzeige beim Abgleich. Marker 1 liegt bei 2400,000000 MHz; relevant ist der gelbe S11-LOGMAG-Wert −0,52 dB. Die ebenfalls eingeblendete S21-Spur wurde nicht untersucht. Das Bild zeigt den zusätzlichen angehaltenen Abgleich-Sweep.],
) <fig-vna-abgleich>

Bei 2,4 GHz enthält dieser Puffer $Gamma = "0.925653" + j "0.172879"$. Daraus berechnet Python −0,5221319 dB; das Rust-Werkzeug liefert denselben Wert bis auf numerische Rundung. Die Geräteanzeige zeigt −0,52 dB bei einer Auflösung von 0,01 dB. Die Differenz von rund 0,00213 dB liegt innerhalb einer halben Anzeigeeinheit von 0,005 dB. Der S11-dB-Markerabgleich ist damit bestanden. Dies ist eine Übereinstimmung zwischen Datenübernahme, Umrechnung und gerundeter Anzeige, keine Bestimmung der Gerätegenauigkeit. Die Smith-Impedanzwerte wurden nicht quantitativ mit dem LCD abgeglichen.

Zusätzlich wurden alle 1818 Punkte der 18 Hauptaufnahmen mit dem Rust-Werkzeug importiert und gegen eine getrennte Python-Rechnung geprüft. Verglichen wurden Frequenz, komplexes S11, Betrag, Phase, S11-dB, Impedanz und, im passiven Bereich, VSWR. Endliche Werte stimmten bei relativer und absoluter Vergleichstoleranz von jeweils $10^(-9)$ überein. Die weiteren 101 Punkte des Geräteabgleichs wurden separat geprüft. Diese Kontrollen ergänzen die bereits ausgeführten synthetischen Handfälle des Rechenwerkzeugs.

Die Messreihen belegen die Unterscheidung der drei Abschlüsse sowie die Bedeutung von Phase und Referenzebene bei einem eingefügten Kabel. Drei Anschlusswiederholungen zeigen die in diesem Ablauf beobachteten Unterschiede. Eine vollständige Unsicherheitsbilanz würde zusätzlich unter anderem die Standards, Kalibrierwiederholung, Gerätefehler und zeitliche Drift erfassen. Deren Beiträge werden durch die vorliegenden Reihen nicht getrennt bestimmt.

Der experimentelle Beitrag untersucht Reflexion und Leitungseinfluss. Die Messgrößen beschreiben die komplexe Eingangsreflexion der Standards und Kabelaufbauten; sie ergänzen die Ergebnisse zur Symbolerkennung aus der eigenständigen CSS-Simulation.
