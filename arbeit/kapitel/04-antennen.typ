= Reflexion, Anpassung und NanoVNA-Messprinzip

== Antenne, Leitung und Abschluss

Eine Antenne verbindet eine leitungsgebundene Welle mit einem elektromagnetischen Feld im Raum. Wie viel Leistung an ihrer Speisung angenommen wird, hängt unter anderem von ihrer Eingangsimpedanz ab. Die Eingangsimpedanz beschreibt aber nicht allein, wie wirksam eine Antenne diese Leistung abstrahlt. Auch ein Widerstand kann eine Leitung gut abschließen, ohne als effiziente Sendeantenne zu dienen. @lit:staelin11 @lit:stutzman2013[S. 56–57, 60]

Im Antennenersatzmodell setzt sich der Eingangswiderstand aus Strahlungswiderstand $R_"rad"$ und Verlustwiderstand $R_"V"$ zusammen:

$ Z_A = R_"rad" + R_"V" + j X_A. $

Beide Widerstände werden auf denselben Speisestrom bezogen. Der Strahlungswiderstand beschreibt die als Welle abgegebene Wirkleistung, der Verlustwiderstand die in Wärme umgesetzte Leistung. Eine Reflexionsmessung erfasst ihre Summe im Realteil der Eingangsimpedanz und trennt diese Beiträge nicht. Deshalb lässt sich aus einem kleinen S11-Betrag allein kein hoher Strahlungswirkungsgrad bestimmen. @lit:stutzman2013[S. 57, Gl. (2-163)–(2-167); S. 60, Gl. (2-178)]

Für die Grundlagen der Reflexionsmessung ist deshalb keine Antenne erforderlich. Anstelle ihrer Eingangsimpedanz kann eine bekannte Last angeschlossen werden. Leerlauf, Kurzschluss und angepasster Widerstand bilden besonders anschauliche Grenzfälle. Das Koaxialkabel führt die Welle zwischen Messgerät und Abschluss und beeinflusst die am Geräteeingang beobachtete Reflexion. @lit:staelin7

== Komplexer Reflexionskoeffizient

Die Abschlussimpedanz wird als $Z = R + j X$ geschrieben. Der Realteil $R$ beschreibt den resistiven Anteil, der Imaginärteil $X$ die Reaktanz; $j^2 = -1$. Bei der verwendeten Zeitkonvention $exp(j omega t)$ besitzt eine Induktivität eine positive und eine Kapazität eine negative Reaktanz. Für eine reelle Bezugsimpedanz $Z_0$ gilt:

$ Gamma = (Z - Z_0)/(Z + Z_0). $

Der komplexe Reflexionskoeffizient enthält Betrag und Phase des Verhältnisses von rücklaufender zu hinlaufender Spannungswelle an derselben Referenzebene. Für die Einportmessung entspricht er $S_11$. Umgekehrt lässt sich die Impedanz bestimmen:

$ Z = Z_0 (1 + Gamma)/(1 - Gamma). $

Nahe $Gamma = 1$ wird der Nenner klein. Kleine Messabweichungen können dann sehr große Änderungen der berechneten Impedanz verursachen. Eine scheinbar präzise Impedanzanzeige bedeutet dort deshalb nicht automatisch eine entsprechend genaue Messung. @lit:staelin7[Abschn. 7.2–7.3]

Für die idealen Abschlüsse erhält man bei $Z_0 = 50 thin Omega$:

- *Open, Leerlauf:* Für $Z -> infinity$ folgt $Gamma -> +1$.
- *Short, Kurzschluss:* Für $Z = 0$ folgt $Gamma = -1$.
- *Load, angepasster Abschluss:* Für $Z = Z_0$ folgt $Gamma = 0$.

Open und Short reflektieren im idealen Modell die gesamte einfallende Leistung. Sie unterscheiden sich in der Phase der reflektierten Spannungswelle um 180 Grad. Die ideale angepasste Last reflektiert keine Leistung. Reale Standards besitzen parasitäre Eigenschaften; ihre Abweichungen können insbesondere bei höheren Frequenzen sichtbar werden. Gronau beschreibt den offenen Abschluss mit kapazitiven und den Kurzschluss mit induktiven Anteilen; auch eine reale Last besitzt keinen exakt verschwindenden Reflexionsfaktor. Für die Kalibrierung sind deshalb die charakterisierten Eigenschaften der Standards maßgeblich. @lit:gronau2001[S. 372–373]

== Logarithmischer Betrag und Stehwellenverhältnis

Bei reeller Bezugsimpedanz ist der reflektierte Leistungsanteil $abs(Gamma)^2$. Der NanoVNA stellt den Reflexionskoeffizienten unter anderem logarithmisch dar:

$ S_(11,"dB") = 20 log_10(abs(Gamma)). $

Bei vollständiger Reflexion ergibt sich 0 dB. Ein Wert von -10 dB bedeutet $abs(Gamma) approx 0.316$ und somit 10 Prozent reflektierte Leistung. Bei -20 dB wird ein Prozent reflektiert. Für ideale Anpassung ist der logarithmische Ausdruck bei $Gamma = 0$ nicht endlich; sein Grenzwert ist negativ unendlich. Eine reale Anzeige bleibt durch Restfehler und Rauschen begrenzt.

Die positiv definierte Rückflussdämpfung lautet dagegen $L_"R" = -20 log_10(abs(Gamma))$. Eine Rückflussdämpfung von 20 dB und ein logarithmischer S11-Wert von -20 dB beschreiben daher denselben Reflexionsbetrag. Eine Verwechslung der Vorzeichen führt zu falschen Aussagen darüber, welcher Abschluss besser angepasst ist.

Das Stehwellenverhältnis, englisch VSWR, folgt aus den maximalen und minimalen Spannungsamplituden auf einer idealen verlustlosen Leitung:

$ "VSWR" = (1 + abs(Gamma))/(1 - abs(Gamma)). $

Die Formel gilt für $0 <= abs(Gamma) < 1$; bei gemessenen Beträgen über eins wird sie nicht als passive Größe verwendet. Anpassung entspricht VSWR = 1; bei vollständiger Reflexion wächst der Grenzwert unbegrenzt. Für S11 = -10 dB ergibt sich ungefähr 1,925. Diese Größen beschreiben die Anpassung an einer festgelegten Ebene. Sie beweisen weder Antennengewinn noch Reichweite. @lit:staelin7 @lit:ti-an058

== Das Smith-Diagramm lesen

Das Smith-Diagramm verbindet die komplexe Reflexion mit der normierten Impedanz $z = Z/Z_0 = r + j x$. Seine Grundlage ist dieselbe Transformation:

$ Gamma = (z - 1)/(z + 1), quad z = (1 + Gamma)/(1 - Gamma). $

Die horizontale Achse entspricht reellen Impedanzen. In der Mitte liegt $Gamma = 0$, also $z = 1$ und bei einem 50-Ω-System eine Impedanz von 50 Ω. Der Kurzschluss liegt links bei $Gamma = -1$, der ideale Leerlauf rechts bei $Gamma = +1$. Die obere Hälfte beschreibt positive, die untere negative Reaktanzen. Bei reeller positiver Bezugsimpedanz und passiven Abschlüssen mit nichtnegativem Realteil liegen die Punkte innerhalb oder auf dem Einheitskreis. @lit:staelin7

Die gekrümmten Gitterlinien lassen sich aus der Transformation erklären. Setzt man $Gamma = u + j v$, erhält man für einen konstanten normierten Widerstand $r$:

$ (u - r/(1+r))^2 + v^2 = (1/(1+r))^2. $

Jeder feste Widerstandswert wird damit auf einen Kreis abgebildet. Für eine konstante, von null verschiedene Reaktanz $x$ folgt entsprechend:

$ (u - 1)^2 + (v - 1/x)^2 = (1/x)^2. $

Auch diese Linien sind Kreisbögen. Das Diagramm ist daher eine rechnerisch begründete Darstellung und keine zusätzliche unabhängige Messgröße. Der Abstand eines Punktes vom Mittelpunkt ist der Reflexionsbetrag, sein Winkel die Reflexionsphase. Zwei Punkte können denselben Abstand und damit denselben S11-dB-Wert besitzen, obwohl ihre Impedanzen verschieden sind. Gerade Open und Short zeigen, weshalb eine reine Betragsdarstellung nicht ausreicht.

== Koaxialkabel und Referenzebene

Für eine gleichförmige Leitung mit Wellenwiderstand $Z_0$, Länge $l$ und Ausbreitungskonstante $gamma = alpha + j beta$ hängt die am Eingang beobachtete Reflexion mit der Reflexion am Abschluss zusammen:

$ Gamma_"ein" = Gamma_"Last" exp(-2 gamma l). $

Der Faktor zwei entsteht durch den Hin- und Rückweg. Bei einer verlustlosen Leitung bleibt der Betrag gleich, während sich die Phase um $-2 beta l$ ändert. Ein offenes oder kurzgeschlossenes Kabelende erzeugt deshalb bei einem Frequenzdurchlauf eine umlaufende Spur im Smith-Diagramm. Bei Verlusten wird der Betrag zusätzlich mit $exp(-2 alpha l)$ vermindert. Das Modell setzt eine gleichförmige Leitung mit passender Bezugsimpedanz voraus. @lit:staelin7

Ein verlustbehaftetes Kabel kann die am Eingang sichtbare Reflexion verkleinern. Daraus darf nicht geschlossen werden, dass der Abschluss selbst besser angepasst ist. Bei einer Kalibrierung am Kabelende wird die Referenzebene dorthin gelegt. Bei einer Kalibrierung am Geräteport und einem erst danach eingefügten Kabel gehört dessen Wirkung dagegen zum Prüfling. Beide Anordnungen beantworten unterschiedliche Fragen und müssen im Messprotokoll auseinandergehalten werden.

Reale Übergänge können zusätzlich vom gleichförmigen Leitungsmodell abweichen. Das von Chang herausgegebene Handbuch beschreibt abrupte Änderungen der Innen- und Außenleiterdurchmesser einer Koaxialleitung durch ein kapazitives Ersatzmodell. Diese Näherung setzt voraus, dass die Querschnittsabmessungen klein gegenüber der Wellenlänge sind. @lit:chang2003[S. 71–72, Abschn. 2.2.2] Für den hier verwendeten Adapter fehlen Geometrie- und Modelldaten; seine Wirkung wird deshalb nicht durch einen angenommenen Kapazitätswert herausgerechnet.

== Was der NanoVNA ergänzt

Ein Vektornetzwerkanalysator erfasst Betrag und Phase von Streuparametern über einen Frequenzbereich. Für die durchgeführten Versuche steht die Eingangsreflexion S11 im Mittelpunkt. Logarithmischer Betrag, Smith-Diagramm und VSWR sind verschiedene Darstellungen beziehungsweise abgeleitete Größen derselben komplexen Messung. Die Open-Short-Load-Kalibrierung verwendet bekannte Abschlüsse zur Korrektur systematischer Messfehler. @lit:sysjoint-fv2

Das gerätespezifische Handbuch beschreibt das Verfahren für den NanoVNA-F V2; die bei den Versuchen verwendete Firmware 0.6.5 wurde separat ausgelesen. Kapitel 7 zeigt die gemessenen Standards und den Kabeleinfluss.
