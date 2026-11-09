= Physikalische Grundlagen der Funkübertragung

Eine Funkverbindung überträgt Information durch elektromagnetische Wellen. Für die Untersuchung von LoRa-CSS sind deren Ausbreitung, der Zusammenhang zwischen Feldstärke und Leistung sowie die Übertragungsverluste entscheidend. Zunächst wird die ungestörte Ausbreitung im Vakuum hergeleitet, die näherungsweise auch für Luft gilt. Überlagerung und Polarisation erklären anschließend, weshalb die Empfangsleistung auch bei gleicher Entfernung schwanken kann.

== Von den Maxwell-Gleichungen zur Wellengleichung

Die Maxwell-Gleichungen verknüpfen elektrische und magnetische Felder mit Ladungen und Strömen. Im Vakuum lauten sie:

$ nabla dot bold(E) = rho / epsilon_0, quad nabla dot bold(B) = 0, $
$
  nabla times bold(E) = - (partial bold(B)) / (partial t), quad nabla times bold(B) = mu_0 bold(J) + mu_0 epsilon_0 (partial bold(E)) / (partial t).
$

Dabei bezeichnet $bold(E)$ die elektrische Feldstärke in V/m, $bold(B)$ die magnetische Flussdichte in Tesla, $rho$ die Ladungsdichte in C/m³ und $bold(J)$ die Stromdichte in A/m². Fettdruck kennzeichnet Vektoren. $epsilon_0$ und $mu_0$ sind die elektrische beziehungsweise magnetische Feldkonstante. Die partiellen Ableitungen nach $t$ beschreiben die zeitliche Änderung am festgehaltenen Ort.

Die Divergenz $nabla dot$ beschreibt die lokale Quellenstärke eines Feldes, die Rotation $nabla times$ seinen Wirbelanteil. Elektrische Ladungen sind Quellen des elektrischen Feldes; für das magnetische Feld gibt es keine entsprechenden isolierten Quellen. Ein zeitlich veränderliches Magnetfeld ist mit einem elektrischen Wirbelfeld verbunden. Zur Rotation des Magnetfeldes tragen sowohl der elektrische Strom als auch die zeitliche Änderung des elektrischen Feldes bei. Dieser letzte Beitrag ist der Maxwell’sche Verschiebungsstromterm. @lit:feynman18[Abschn. 18–1, Tabelle 18–1] @lit:stutzman2013[S. 23–26]

Im betrachteten Vakuumbereich seien keine Ladungen und Ströme vorhanden, also $rho = 0$ und $bold(J) = 0$. Die Quellen der Funkwelle liegen außerhalb dieses Bereichs. Bildet man die Rotation der Faraday-Gleichung, folgt durch Einsetzen der Ampère-Maxwell-Gleichung:

$
  nabla times (nabla times bold(E))
  = - partial / (partial t) (nabla times bold(B))
  = - mu_0 epsilon_0 (partial^2 bold(E)) / (partial t^2).
$

#block(breakable: false)[
  Mit der Vektoridentität

  $
    nabla times (nabla times bold(E))
    = nabla (nabla dot bold(E)) - nabla^2 bold(E)
  $

  und $nabla dot bold(E) = 0$ ergibt sich die Wellengleichung:

  $
    nabla^2 bold(E) - mu_0 epsilon_0 (partial^2 bold(E)) / (partial t^2) = 0.
  $ <gl-wellengleichung>
]

Der Operator $nabla^2$ fasst die zweiten räumlichen Ableitungen zusammen; auf ein Vektorfeld wirkt er komponentenweise. Die Gleichung verknüpft damit räumliche und zeitliche Änderungen des Feldes. Analog lässt sich eine Wellengleichung für $bold(B)$ herleiten.

#block(breakable: false)[
  Ein Vergleich mit der allgemeinen Wellengleichung liefert die Ausbreitungsgeschwindigkeit

  $ c = 1 / sqrt(mu_0 epsilon_0) approx 2.998 dot 10^8 thin "m/s". $
]

Die quellenfreie Wellengleichung erlaubt somit Felder, die sich auch außerhalb der erzeugenden Antenne ausbreiten. In Materie sind die Materialgleichungen und gegebenenfalls Leitfähigkeit und Verluste einzubeziehen. Die Vakuumherleitung wird hier als Näherung für die Ausbreitung in Luft verwendet. @lit:feynman20[Abschn. 20–2, Gl. (20.8)–(20.12)]

== Ebene Welle, Frequenz und Wellenlänge

Eine mögliche Lösung ist eine sinusförmige ebene Welle, die sich in positiver $z$-Richtung ausbreitet:

$ bold(E)(z,t) = bold(e)_x E_0 cos(omega t - k z + phi_0), $
$ omega = 2 pi f, quad k = 2 pi / lambda. $

Dabei sind $bold(e)_x$ der Einheitsvektor in $x$-Richtung, $E_0$ die Spitzenamplitude und $phi_0$ die Anfangsphase. $f$ zählt die Schwingungen pro Sekunde; $lambda$ ist der Abstand benachbarter Punkte gleicher Phase. $omega$ heißt Kreisfrequenz, $k$ Wellenzahl. Bei konstanter Phase $omega t - k z + phi_0$ nimmt $z$ mit der Zeit zu: Die Welle läuft in positive $z$-Richtung. Einsetzen in @gl-wellengleichung ergibt $k^2 = mu_0 epsilon_0 omega^2$ und damit

$ lambda = c/f. $

Das zugehörige Magnetfeld lautet ohne zusätzliche statische Felder

$ bold(B)(z,t) = bold(e)_y E_0/c cos(omega t - k z + phi_0). $

Beide Felder schwingen gleichphasig. Sie stehen senkrecht zueinander und zur Ausbreitungsrichtung; die Welle ist transversal. Ihre Amplituden erfüllen $E_0 = c B_0$. Eine ebene Welle ist eine Idealisierung: Über jede Ebene senkrecht zur Ausbreitung sind die Felder gleich. Ein kleiner Ausschnitt einer weit entfernten Wellenfront kann näherungsweise so behandelt werden. @lit:feynman20[Abschn. 20–3, Gl. (20.12)–(20.19)]

Bei 2,4 GHz folgt $lambda approx 0.1249 thin "m"$, bei 868 MHz dagegen $lambda approx 0.3454 thin "m"$. Die Wellenlänge verbindet somit die Betriebsfrequenz mit den räumlichen Abmessungen von Antennen und mit den Wegunterschieden reflektierter Signale. Stutzman und Thiele verknüpfen diese Beziehung mit der Laufzeit: Ein Weg von einer Viertelwellenlänge entspricht einer Viertelperiode und damit einer Phasenänderung von 90 Grad. @lit:stutzman2013[S. 30, Gl. (2-53)–(2-54)]

== Feldamplitude, Leistungsfluss und Überlagerung

Die magnetische Feldstärke lautet im Vakuum $bold(H) = bold(B)/mu_0$ und hat die Einheit A/m. Der Poynting-Vektor beschreibt die Richtung und Dichte des elektromagnetischen Energieflusses:

$ bold(S)(t) = bold(E)(t) times bold(H)(t). $

#block(breakable: false)[
  Seine Einheit ist Watt pro Quadratmeter. Bei der oben beschriebenen Welle zeigt $bold(S)$ in positive $z$-Richtung. Für eine ebene Vakuumwelle gilt $E_0/H_0 = eta_0$ mit dem Feldwellenwiderstand $eta_0 = sqrt(mu_0/epsilon_0) approx 377 thin Omega$. Damit folgt für die zeitlich gemittelte Leistungsflussdichte:

  $ overline(S) = E_0^2 / (2 eta_0) = E_"eff"^2 / eta_0. $
]

Der Faktor $1/2$ entsteht aus dem zeitlichen Mittel von $cos^2$ über eine Periode; der Effektivwert beträgt $E_"eff" = E_0/sqrt(2)$. Bei Verwendung des Effektivwerts ist die Mittelung bereits berücksichtigt. Eine Verdopplung der Feldamplitude vervierfacht daher die Leistungsflussdichte. @lit:staelin2[Abschn. 2.7.3, S. 61, Gl. (2.7.36)]

Im Fernfeld einer räumlich begrenzten Antenne fällt die Feldamplitude bei fester Richtung wie $1/r$, die Leistungsflussdichte wie $1/r^2$. Im Nahfeld kommen weitere Abstandsterme hinzu; das Fernfeldgesetz lässt sich dort nicht fortsetzen. @lit:staelin10[Abschn. 10.2.1–10.2.2, S. 308–310] @lit:stutzman2013[S. 34–35]

Die Fernfeldnäherung erfordert einen hinreichenden Abstand. Für eine maximale Quellenausdehnung $D_"max"$ liefert ein zugelassener geometrischer Phasenfehler von 22,5 Grad das häufig verwendete Kriterium $r > 2 D_"max"^2/lambda$. Bei elektrisch kleinen Antennen genügt diese Bedingung allein nicht: Auch die höheren Abstandsterme der Felder müssen klein sein. Ein geringer rechnerischer Wert dieser Grenze belegt deshalb noch keine Fernfeldbedingungen. @lit:stutzman2013[S. 42–44]

Reflexionen können dazu führen, dass ein Signal den Empfänger auf mehreren Wegen erreicht. Dort überlagern sich die Feldbeiträge. Für zwei Beiträge gleicher Frequenz mit derselben Empfangspolarisation seien $a_1$ und $a_2$ ihre nichtnegativen Amplituden am Empfänger und $Delta phi$ ihr Phasenunterschied. Mit der imaginären Einheit $j$ ($j^2 = -1$) stellt $exp(j Delta phi) = cos(Delta phi) + j sin(Delta phi)$ die relative Phase dar. Für das Betragsquadrat der Summe gilt

$
  abs(a_1 + a_2 exp(j Delta phi))^2
  = a_1^2 + a_2^2 + 2 a_1 a_2 cos(Delta phi).
$

Die am selben Empfangsport aufgenommene Leistung ist proportional zu diesem Betragsquadrat. Der letzte Term beschreibt die Interferenz. Bei gleich großen Beiträgen und $Delta phi = 0$ ist die Leistung viermal so groß wie bei einem einzelnen Beitrag. Für $Delta phi = pi$ löschen sich beide am betrachteten Empfangsort idealerweise aus. Diese lokale Verstärkung oder Auslöschung bedeutet keine Erzeugung oder Vernichtung von Energie.

Ein Wegunterschied $Delta r$ trägt je nach Vorzeichenkonvention die Phasenänderung $2 pi Delta r/lambda$ bei; zusätzlich kann die Reflexion die Phase ändern. Bereits ein halber Wellenlängenunterschied entspricht einer Phasenänderung von $pi$. Deshalb können kleine Ortsänderungen den Empfang stark verändern. Bei kohärenten Beiträgen, deren relative Phase während der Betrachtung fest bleibt, müssen zuerst die Amplituden mit ihren Phasen addiert werden. Erst wenn der Interferenzterm im betrachteten Mittel verschwindet, ergibt sich die Summe der Einzelleistungen. @lit:feynman-interferenz[Abschn. 29–4]

== Polarisation und Antennenorientierung

Die Polarisation beschreibt die Bahn der Spitze des elektrischen Feldvektors an einem festen Ort. Bei linearer Polarisation schwingt er entlang einer festen Achse; bei zirkularer Polarisation dreht sich seine Spitze mit konstantem Betrag. @lit:staelin2[Abschn. 2.3.4, S. 35–36] @lit:stutzman2013[S. 61–64]

Allgemein beschreibt die Feldspitze eine Ellipse. Lineare und zirkulare Polarisation sind deren Grenz- beziehungsweise Spezialfälle. Zwei orthogonale Feldkomponenten gleicher Amplitude ergeben bei einer Phasendifferenz von 90 Grad eine zirkulare Polarisation. Die Polarisation einer Antenne ist dabei richtungsabhängig; ihre Angabe für die Hauptstrahlrichtung beschreibt nicht zwangsläufig alle anderen Richtungen. @lit:stutzman2013[S. 64–65]

Eine ideal linear polarisierte Empfangsantenne nimmt den zu ihrer Empfangspolarisation parallelen Feldanteil auf. Bei einem Winkel $psi$ zwischen zwei linearen Polarisationen wird die Amplitude mit $abs(cos psi)$ und die Empfangsleistung mit

$ eta_"pol" = cos^2 psi $

gewichtet. Dabei werden Ausbreitungsrichtung und Richtungsgewinne festgehalten. Bei 45 Grad bleibt die halbe Leistung, entsprechend etwa 3,01 dB Verlust; bei 90 Grad verschwindet der ideale Beitrag. Reflexionen und nichtideal polarisierte Antennen können im realen Versuch dennoch zu einem Empfang führen. @lit:staelin10[Abschn. 10.3.3, Gl. (10.3.19), und Beispiel 10.3C]

Wird in einem Empfangsversuch eine Antenne gedreht, können sich zugleich Richtungsgewinn und Polarisation ändern. Eine dabei gemessene RSSI-Kurve lässt sich daher nur zusammen mit Drehachse, Antennenlage und Umgebung interpretieren.

== Logarithmische Größen: Dezibel und dBm

#block(breakable: false)[
  Mit Dezibel lassen sich Leistungsverhältnisse über mehrere Größenordnungen übersichtlich angeben. Für positive Leistungen ist der Pegelunterschied

  $ Delta L / "dB" = 10 log_10(P_2/P_1). $
]

Eine Verdopplung entspricht ungefähr 3,01 dB, eine Verzehnfachung 10 dB. Ein Verhältnis von einem Zehntel ergibt −10 dB. Weil der Logarithmus Produkte in Summen überführt, werden aus aufeinanderfolgenden Leistungsfaktoren addierbare Pegelbeiträge. dB bezeichnet dabei ein Verhältnis. @lit:nist-pegel[Abschn. 8.7]

#block(breakable: false)[
  Für eine absolute Leistungsangabe wird ein Bezug benötigt. Bei dBm ist dieser ein Milliwatt:

  $
    P_"dBm" = 10 log_10(P/(1 thin "mW")), quad
    P = (1 thin "mW") dot 10^(P_"dBm"/10).
  $
]

$P_"dBm"$ bezeichnet hier den Zahlenwert des in dBm angegebenen Pegels. Somit entsprechen 0 dBm einem Milliwatt, −30 dBm einem Mikrowatt und −60 dBm einem Nanowatt. Negative dBm-Werte bezeichnen positive Leistungen unter einem Milliwatt. −70 dBm liegt um 10 dB über −80 dBm und entspricht der zehnfachen Leistung. @lit:ntia-handbuch[S. 2–15, Gl. (2–43)–(2–44)]

Für Spannungsamplituden an gleichem reellem Widerstand gilt $P = U_"eff"^2/R$. Daraus folgt

$ 10 log_10(P_2/P_1) = 20 log_10(abs(U_2/U_1)). $

Der Faktor 20 setzt hier denselben Widerstand voraus; bei verschiedenen Widerständen muss deren Verhältnis mitgerechnet werden. Entsprechend wird später der logarithmische Betrag des Reflexionskoeffizienten mit $20 log_10(abs(Gamma))$ berechnet, weil $Gamma$ ein Amplitudenverhältnis beschreibt. Eine Dämpfung von 3 dB kann von einem Leistungspegel in dBm abgezogen werden; zwei unabhängige Leistungen in dBm werden dagegen vor dem Addieren in lineare Leistungen umgerechnet.

== Freiraumübertragung und Linkbudget

Eine isotrope Bezugsantenne verteilt ihre Strahlungsleistung gleichmäßig über alle Raumrichtungen. Der dimensionslose Antennengewinn $G_t$ vergleicht die Leistungsflussdichte in einer Richtung mit der einer verlustlosen isotropen Antenne bei gleicher aufgenommener Leistung. Er berücksichtigt sowohl die Richtwirkung als auch den Strahlungswirkungsgrad. Die Richtwirkung vergleicht die räumliche Bündelung bei gleicher abgestrahlter Gesamtleistung; der Gewinn bezieht zusätzlich Verluste in der Antenne ein. @lit:stutzman2013[S. 52–55] In Richtung des Empfängers gilt

$ overline(S)(r) = (P_t G_t)/(4 pi r^2). $

Für eine reziproke Empfangsantenne mit Gewinn $G_r$ beträgt die effektive Empfangsfläche bei passender Polarisation und Anpassung

$ A_"eff" = (G_r lambda^2)/(4 pi). $

#block(breakable: false)[
  Mit $P_r = overline(S) A_"eff"$ folgt die Friis-Gleichung:

  $ P_r = P_t G_t G_r (lambda/(4 pi r))^2. $ <gl-friis>
]

Dabei ist $P_t$ die von der Sendeantenne aufgenommene Leistung und $P_r$ die maximal an einen angepassten Empfänger abgebbare Leistung. Die effektive Empfangsfläche ist keine bloße geometrische Querschnittsfläche. Die Gewinne gelten jeweils in Richtung der anderen Antenne; Fehlanpassungsverluste sind in der hier gewählten Gewinnkonvention nicht enthalten. Die einfache Form setzt Freiraumausbreitung, passende Polarisation und das Fernfeld beider Antennen voraus; Mehrwegeausbreitung und Abschattung fehlen. Sie gilt deshalb nicht bei beliebig kleinem $r$. @lit:staelin10[Abschn. 10.3.4–10.3.5, S. 321–323, Gl. (10.3.33)–(10.3.37)]

#block(breakable: false)[
  Die logarithmische Freiraumdämpfung zwischen isotropen Bezugsantennen lautet

  $
    L_"FS" / "dB" = 20 log_10(4 pi r/lambda)
    = 20 log_10(4 pi r f/c).
  $
]

Diese Form verwendet dieselbe Längeneinheit für $r$ und $lambda$. Die Freiraumdämpfung entsteht durch die räumliche Ausbreitung und die effektive Empfangsfläche; sie beschreibt keine Absorption im Vakuum. @lit:itu-freiraum[Anhang, Abschn. 2.3, S. 3, Gl. (4)–(6)]

Mit positiven Zusatzverlusten ergibt sich daraus das Linkbudget:

$
  P_(r,"dBm") = P_(t,"dBm") + G_(t,"dBi") + G_(r,"dBi")
  - L_("FS","dB") - L_("zus","dB").
$

Die Indizes kennzeichnen die jeweiligen Zahlenwerte. dBi bezeichnet den Gewinn gegenüber der isotropen Antenne. Anders als in der einfachen Form von @gl-friis liegt der Bezugspunkt von $P_t$ hier am Senderausgang vor den zusätzlich bilanzierten Sendeverlusten, der von $P_r$ am Empfängereingang. $L_"zus"$ fasst etwa Kabel-, Steckverbinder- und Fehlanpassungsverluste sowie gegebenenfalls Polarisationsverluste zusammen. Bereits im Gewinn enthaltene Verluste dürfen nicht nochmals abgezogen werden. @lit:ntia-handbuch[Abschn. 3, S. 3–1, Gl. (3–2)]

=== Durchgerechnetes Modellbeispiel

Für eine hypothetische Verbindung werden $f = 2.4 thin "GHz"$, $r = 100 thin "m"$, $P_t = 10 thin "mW"$ und beidseitig 2 dBi Gewinn angenommen. Die Polarisationen seien gleich; alle Zusatzverluste zusammen betragen 2 dB. Dies sind gewählte Rechenparameter, keine Messwerte der vorhandenen Geräte.

Aus $lambda = c/f approx 0.1249 thin "m"$ und $P_(t,"dBm") = 10$ folgt

$
  L_"FS" / "dB" = 20 log_10((4 pi dot 100 thin "m")/(0.1249 thin "m")) approx 80.05,
$
$ P_(r,"dBm") = 10 + 2 + 2 - 80.05 - 2 = -68.05. $

Die Rückrechnung ergibt $P_r approx 1.57 dot 10^(-10) thin "W"$, also 157 pW. Eine unabhängige Rechnung in linearen Einheiten verwendet $G_t = G_r = 10^(2/10) approx 1.585$ und den Zusatzfaktor $10^(-2/10) approx 0.631$:

$
  P_r = 0.01 thin "W" dot 1.585^2
  dot (0.1249/(4 pi dot 100))^2 dot 0.631
  approx 1.57 dot 10^(-10) thin "W".
$

Eine Verdopplung der Entfernung erhöht im selben Modell die Dämpfung um $20 log_10(2) approx 6.02$ dB. Bei 200 m ergeben sich damit etwa −74,07 dBm. #block(breakable: false)[
  Zwischen 868 MHz und 2,4 GHz beträgt die Dämpfungsdifferenz bei gleicher Entfernung und gleichen Gewinnen

  $ Delta L / "dB" = 20 log_10(2400/868) approx 8.83. $
]

Der Vergleich hält die Antennengewinne fest; für Antennen gleicher physischer Größe folgt daraus keine allgemeine Regel. Auch eine Reichweite lässt sich aus dem Linkbudget allein nicht bestimmen. Dafür muss bekannt sein, welche Empfangsleistung der jeweilige Empfänger bei gewählter Bandbreite, Modulation und geforderter Fehlerrate benötigt. Im folgenden CSS-Modell wird deshalb untersucht, wie sich Signalenergie, Symbolzeit und Störungen auf die Erkennung auswirken.
