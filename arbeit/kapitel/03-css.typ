= Chirp Spread Spectrum und vereinfachtes LoRa-Modell

Chirp Spread Spectrum (CSS) überträgt Information mit Signalen, deren Frequenz sich während eines Symbols verändert. Ein Symbol ist dabei eine auswählbare Signalform, die eine bestimmte Bitfolge darstellt. Im Folgenden werden der Chirp, seine diskrete Darstellung und die Symbolerkennung hergeleitet. Sie bilden die Grundlage der eigenen Untersuchung zu Rauschen und Frequenzoffset. Betrachtet werden synchronisierte Einzelsymbole; vollständige LoRa- oder ExpressLRS-Pakete sind nicht Teil des Modells.

== Chirp und Symbolzeit

Ein linearer Aufwärtschirp ist eine Schwingung, deren momentane Frequenz gleichmäßig mit der Zeit steigt. Dabei sind $t$ die Zeit und $T_s$ die Symboldauer, jeweils in Sekunden; $B$ ist die positive nominelle Bandbreite in Hertz. $B$ bezeichnet hier den durchlaufenen Frequenzhub; das Spektrum eines zeitlich begrenzten Chirps ist nicht streng auf dieses Intervall beschränkt. Anders als $bold(B)$ in Kapitel 2 steht das skalare $B$ hier also für eine Frequenzbreite und nicht für die magnetische Flussdichte. @lit:chiani2019[Abschn. II und III]

Zur Beschreibung wird eine komplexe Zahl verwendet. Die *imaginäre Einheit* $j$ ist durch #box[$j^2 = -1$] definiert; sie entspricht dem in der Mathematik üblichen $i$. @lit:orloff-komplex[Abschn. 4.2–4.3] Eine komplexe Zahl $z = a + j b$ fasst zwei reelle Zahlen zusammen: den Realteil $a$ und den Imaginärteil $b$. Für eine reelle Phase $phi$ gilt die Euler’sche Formel:

$ exp(j phi) = e^(j phi) = cos(phi) + j sin(phi). $

$exp$ ist die Exponentialfunktion mit der Euler’schen Zahl $e approx 2.71828$ als Basis. Die Kreiszahl $pi approx 3.14159$ ist das Verhältnis von Kreisumfang zu Durchmesser; eine volle Schwingung umfasst $2 pi$ Radiant. $j$, $e$ und $pi$ sind dimensionslose mathematische Konstanten. Die komplexe Schreibweise enthält somit zwei um eine Viertelperiode versetzte Komponenten. Ihr Betrag ist $abs(exp(j phi)) = 1$: Eine veränderliche Phase bedeutet hier keine wachsende Amplitude. @lit:wyatt-signale[Abschn. 2.6 und 2.6.4]

Die *komplexe Hüllkurve* beschreibt diese beiden Komponenten im Basisband, also relativ zur Trägerfrequenz. „Hüllkurve“ meint hier nicht nur den Betrag, sondern auch die Phase. Für den Referenzchirp werden die Amplitude auf eins und die Anfangsphase auf null gesetzt:

$ s_0(t) = exp(j phi(t)), quad phi(t) = 2 pi (- B/2 t + B/(2 T_s) t^2), quad 0 <= t < T_s. $

Der Index $0$ kennzeichnet den Symbolwert null; $phi(t)$ ist die Phase im Bogenmaß. Die Faktoren $B t$ und $B t^2/T_s$ sind dimensionslos, wie es für das Argument der Exponentialfunktion erforderlich ist. Die quadratische Zeitabhängigkeit der Phase erzeugt den linearen Frequenzanstieg. @lit:maleki2023[Abschn. II-A–II-B, Gl. (6)–(10)]

Die momentane Frequenz ist die Phasenänderung pro Zeit, geteilt durch $2 pi$. Die Schreibweise $("d" phi)/("d" t)$ bezeichnet die Ableitung nach der Zeit. Aus der gerade angegebenen Phase folgt:

$ f_i(t) = 1/(2 pi) ("d" phi(t))/("d" t) = -B/2 + B/T_s t. $

Der Index $i$ steht hier für „instantan“, also momentan. Zu Beginn gilt $f_i(0) = -B/2$, in der Mitte $f_i(T_s/2) = 0$; am Ende nähert sich die Frequenz $+B/2$. Die Steigung $B/T_s$ hat die Einheit Hertz pro Sekunde. Negative Frequenzen bezeichnen in dieser Basisbanddarstellung eine Lage unterhalb der Trägerfrequenz. Zur Hochfrequenz gelangt man durch Addition der Trägerfrequenz. @lit:maleki2023[Abschn. II-A, Gl. (2)–(4)]

LoRa unterscheidet $M = 2^"SF"$ Symbolwerte. Der *Spreading Factor* $"SF"$ ist eine dimensionslose ganze Zahl; $M$ ist die Anzahl möglicher Symbole. Da $"SF"$ Bits genau $2^"SF"$ Bitfolgen bilden, trägt ein uncodiertes Symbol $"SF"$ Bits. Die LoRa-Parameter erfüllen $B T_s = M$. Daraus folgen die Symbolzeit und die uncodierte Bitrate $R_b$ in Bit pro Sekunde:

$ T_s = M/B = 2^"SF"/B, quad R_b = "SF"/T_s = ("SF" B) / 2^"SF". $

Bei festem $B$ verdoppelt ein um eins erhöhter SF die Symbolzeit. Die Bitrate sinkt dabei, obwohl ein Symbol ein zusätzliches Bit enthält. Für die hier gewählten Modellparameter $B = 125 thin "kHz"$ und $"SF" = 7$ ergeben sich:

$ M = 128, quad T_s = 1.024 thin "ms", quad R_b = 6835.94 thin "bit/s". $

Bei $"SF" = 8$ folgen dagegen $M = 256$, $T_s = 2.048 thin "ms"$ und $R_b = 3906.25 thin "bit/s"$. Dies sind Rechenbeispiele, keine Geräte- oder Messwerte. Präambel, Header und Fehlerkorrektur benötigen zusätzliche Übertragungszeit beziehungsweise Bits. $R_b$ ist deshalb keine Angabe zum Netto-Datendurchsatz von ExpressLRS. @lit:chiani2019[Abschn. II, Bitrate und Symbolintervall]

== Diskretes Modell und Dechirping

Die Simulation verarbeitet einzelne *Samples*, also Abtastwerte. Bei der gewählten Abtastrate $f_s = B$ in Samples pro Sekunde gilt $t_n = n/f_s$ und $f_s T_s = M$: Ein Symbol enthält genau $M$ komplexe Werte. $n = 0, dots, M-1$ ist der dimensionslose Abtastindex; der Endpunkt $T_s$ gehört bereits zum nächsten Symbol. Diese Abtastwahl betrifft das idealisierte komplexe Basisband. Sie ist keine allgemeine Abtastvorschrift für ein reales Hochfrequenzsignal. @lit:demeslay2022[Abschn. III-A, S. 2]

Einsetzen von $t_n = n/B$ und $T_s = M/B$ in die Referenzphase ergibt den Anteil $n^2/(2M) - n/2$. Für den Symbolwert $m$ wird eine zusätzliche Phasenrampe eingeführt:

$ x_m[n] = exp(j 2 pi (n^2/(2M) - n/2 + m n/M)), quad m,n = 0, dots, M-1. $

Dabei ist $m$ der Symbolwert, $M$ die Alphabetgröße und $x_m[n]$ das komplexe Sample. Runde Klammern wie in $s_0(t)$ kennzeichnen kontinuierliche Zeit, eckige Klammern wie in $x_m[n]$ eine Folge von Abtastwerten. Das diskrete Modell entspricht der Darstellung bei Demeslay et al.; deren Symbolindex $a$ und Abtastindex $k$ heißen hier $m$ und $n$. @lit:demeslay2022[Abschn. III-A, Gl. (1)]

Der zusätzliche Term verschiebt die momentane Frequenz um $m B/M$. Im kontinuierlichen LoRa-Signal wird die Frequenz beim Erreichen des oberen Bandrands um $B$ zurückgesetzt und steigt dann weiter. Die Rücksetzung erfolgt bei $t = (M-m)/B$. Danach unterscheidet sich die Phase von der ungebrochenen Fortsetzung um $-2 pi B (t-(M-m)/B)$. Für $t=n/B$ ist dies $-2 pi (n-M+m)$, also ein ganzzahliges Vielfaches von $2 pi$. Beide Darstellungen liefern deshalb dieselben Samples. Die diskrete Formel gilt somit an den Abtastzeitpunkten, darf aber nicht unverändert als kontinuierliche Chirpform interpretiert werden. @lit:chiani2019[Abschn. II-A–II-B]

*Dechirping* bedeutet, den empfangenen Chirp mit dem komplex konjugierten Referenzchirp zu multiplizieren. Der Stern $*$ bezeichnet die Konjugation: Aus $a + j b$ wird $a - j b$, also aus $exp(j phi)$ der Wert $exp(-j phi)$. Im störungsfreien, zeitlich und frequenzmäßig synchronen Fall gilt damit:

$ d_m[n] = x_m[n] x_0[n]^* = exp(j 2 pi m n/M). $

$d_m[n]$ ist die dechirpte Folge. Beim Multiplizieren werden die Phasen addiert; die quadratischen Chirpanteile heben sich auf. Übrig bleibt eine Schwingung mit konstanter Frequenz. @lit:demeslay2022[Abschn. III-B, Gl. (2)–(3)]

Die diskrete Fouriertransformation (DFT) zerlegt diese Folge in $M$ diskrete Frequenzanteile. Ihre schnelle Berechnung heißt FFT (*Fast Fourier Transform*). Ein *Bin* ist einer dieser Frequenzplätze. Mit dem Binindex $k$ wird die unnormierte DFT definiert als

$ D_m[k] = sum_(n=0)^(M-1) d_m[n] exp(-j 2 pi k n/M), quad k = 0, dots, M-1. $

$D_m[k]$ ist der komplexe Spektralwert. Für $k = m$ sind alle Summanden gleich eins, sodass $D_m[m] = M$ gilt. Für die übrigen Bins löschen sich die gleichmäßig verteilten Phasen aus. Im idealen Fall liegt somit nur im Bin $m$ ein von null verschiedener Wert. Die Aussage gilt exakt für diese diskreten Modellfolgen. Daraus folgt keine exakte Orthogonalität der kontinuierlichen LoRa-Signalformen. @lit:chiani2019[Abschn. II-A–II-B]

Für eine beliebige Empfangsfolge $y[n]$ wird entsprechend $d[n]=y[n] x_0[n]^*$ gebildet und deren DFT $D[k]$ berechnet. Der Detektor entscheidet nach

$ hat(m) = op("arg max", limits: #true)_(k in {0, dots, M-1}) abs(D[k]). $

$hat(m)$ bezeichnet den geschätzten Symbolwert; $op("arg max")$ liefert den Index des größten Betrags. Bei SF 7 und $m=17$ beträgt der ideale Peak im Bin 17 somit 128. Diese Entscheidung ist *nichtkohärent*: Eine konstante unbekannte Empfangsphase dreht alle Spektralwerte um denselben Winkel und ändert ihre Beträge nicht. @lit:demeslay2022[Abschn. III-B, S. 3, Gl. (3)–(4)]

// Kontrollierte Modellgrafik; numerische Prüfwerte in Kapitel 6.
#figure(image("../abbildungen/css-dechirping.svg", width: 100%), caption: [Eigene Modellrechnung bei SF 7. Links: Frequenz des Referenzchirps. Rechts: Dechirping von Symbol 17, dargestellt als $abs(D[k])/M$ (Peak eins, unnormiert 128). Kein gemessenes HF-Signal.])

== Spreizung und Symbolenergie

Das dimensionslose Zeit-Bandbreite-Produkt beträgt $B T_s=M$. Das Verhältnis von Bandbreite und uncodierter Bitrate ist dagegen

$ B/R_b = M/"SF". $

Beide Größen beschreiben eine Spreizung, liefern aber unterschiedliche Zahlen. Für $"SF" = 7$ sind dies $128$ beziehungsweise rund $18.29$. Chiani und Elzanaty unterscheiden ausdrücklich das Verhältnis $B/R_b$ vom LoRa-Parameter SF. Eine Angabe zum Spreizgewinn muss daher die verwendete Definition nennen. @lit:chiani2019[Abschn. II, Verhältnis von Chiprate und Bitrate, Fußnote 1]

Bei konstanter Signalleistung $P_s$ in Watt beträgt die Symbolenergie $E_s = P_s T_s$ in Joule. Ein längeres Symbol enthält dann mehr Energie. Die zuvor auf eins gesetzte Modellamplitude legt dabei keine reale Sendeleistung von einem Watt fest. Für den Vergleich der Simulationen ist deshalb entscheidend, ob die Leistung oder die Energie pro Symbol konstant gehalten wird. Eine Verbesserung der Symbolerkennung allein belegt keinen bestimmten Reichweitengewinn; dafür wären zusätzlich Kanal, Empfangsschwelle und Übertragungsbedingungen festzulegen.

== Frequenzoffset und Rauschen

Ein Frequenzoffset bezeichnet hier eine während eines Symbols konstante Frequenzabweichung zwischen Sender und Empfänger. Der DFT-Binabstand beträgt $Delta f_"Bin" = f_s/M = B/M = 1/T_s$ in Hertz. Der Offset $Delta f$ lässt sich daher dimensionslos als

$ delta = (Delta f)/(Delta f_"Bin") = Delta f T_s $

angeben. Im diskreten Signal bewirkt er den zusätzlichen Faktor $exp(j 2 pi delta n/M)$. Nach dem Dechirping steht daher $m + delta$ anstelle von $m$ im Exponenten. Bei ganzzahligem $delta$ verschiebt sich der Peak zyklisch um ganze Bins (modulo $M$), bei nichtganzzahligem $delta$ verteilt sich der Spektralbetrag auf mehrere Bins. Ohne Rauschen liegt der größte Betrag beim zyklisch nächstgelegenen Bin zu $m+delta$. Bei einem halben Bin Abstand sind die beiden benachbarten Maxima gleich groß; die Entscheidung ist dann nicht eindeutig. Dies folgt unmittelbar aus der oben definierten DFT. Bei $B = 125 thin "kHz"$ beträgt der Binabstand für SF 7 rund $976.56 thin "Hz"$, für SF 8 nur $488.28 thin "Hz"$. Derselbe Offset in Hertz wirkt somit bei längerer Symbolzeit relativ zum Binabstand stärker.

Zusätzlich wird *additives weißes gaußsches Rauschen* (AWGN) berücksichtigt. „Additiv“ bedeutet, dass die Störung zum Nutzsignal addiert wird. Im diskreten Modell sind die Rauschwerte verschiedener Samples unabhängig; Real- und Imaginärteil sind voneinander unabhängige gaußverteilte Zufallsgrößen mit Mittelwert null und gleicher Varianz. „Weiß“ bezeichnet die konstante spektrale Leistungsdichte. @lit:gallager-rauschen[Abschn. 7.7–7.8.1, S. 224–230]

Mit beiden Störungen lautet die Empfangsfolge der Simulation

$ y[n] = x_m[n] exp(j 2 pi delta n/M) + w[n]. $

$w[n]$ ist der komplexe Rauschwert. Seine mittlere normierte Leistung $P_N$ ist der Erwartungswert von $abs(w[n])^2$, also der statistische Mittelwert über mögliche Rauschwerte. Jede der beiden reellen Komponenten erhält die Varianz $P_N/2$. Da $abs(x_m[n])^2=1$ gilt, ist das lineare Signal-Rausch-Verhältnis pro Sample $rho=1/P_N$. Dechirping entfernt das Rauschen nicht: Der Faktor $x_0[n]^*$ dreht den jeweiligen Rauschwert, ohne dessen Betrag zu ändern. Die Entscheidung kann deshalb auf einen falschen Bin fallen.

== Gültigkeitsbereich des Modells

Die Symbolfehlerrate zählt Entscheidungen mit $hat(m) != m$ und ist weder Bit- noch Paketfehlerrate. Symbolanfang und Abtastrate sind exakt bekannt; der Frequenzoffset wird nicht korrigiert. Die idealen Samples entstehen unmittelbar, ohne analoges Empfangsfilter. Eine Filterung des kontinuierlichen LoRa-Signals auf die nominelle Bandbreite $B$ kann die Samples verändern und ihre exakte Orthogonalität aufheben. @lit:chiani2019[Abschn. II-B, nach Gl. (17)] Fehlerkorrektur, Präambel, Header, Frequenzhopping, Mehrwege und andere Sender fehlen ebenfalls; aus den Ergebnissen folgt keine allgemeine Robustheit realer LoRa-Empfänger gegen diese Einflüsse. @lit:demeslay2022[Abschn. III–IV]

Die numerischen Kontrollen und Ergebnisse folgen in Kapitel 6.
