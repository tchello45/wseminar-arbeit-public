# CSS-AWGN-Lauf vom 3. November 2026

KI-gestützte technische Auswertung zum Python-Simulator. Die Aussagen beruhen
auf den neu erzeugten CSV-Dateien, nicht auf Hardwaremessungen. Aufruf und
Methode: `tools/README.md`; genaue Versionen, Hashes und Prüfwerte: `lauf.json`.

## Kontrollfälle

Alle Symbole wurden ohne Rauschen korrekt erkannt: SF 7: 128/128,
SF 8: 256/256, SF 9: 512/512. Der gemeinsame Sender wurde zusätzlich auf
Einheitsbetrag und diskrete Orthogonalität geprüft.

Bei 100.000 komplexen Rauschsamples und 0 dB beträgt die mittlere Leistung
1,006756. Die Varianzen von Real- und Imaginärteil betragen 0,502922 und
0,503832. Erwartet sind 1 beziehungsweise je 0,5. Die vorgegebenen absoluten
Toleranzen von 0,02 für die Leistung und 0,01 für beide Varianzen werden
eingehalten. Mittelwerte −0,0000394 und −0,0012192 sowie Kovarianz −0,0001155
liegen ebenfalls innerhalb ± 0,01. Der Zufallsgenerator zieht Real- und
Imaginärteil unabhängig; Stichprobenwerte allein beweisen Unabhängigkeit nicht.

## Symbolzeit und Bitrate

Bei B = f_s = 125 kHz wächst die Symbolzeit M/B von 1,024 ms (SF 7)
über 2,048 ms (SF 8) auf 4,096 ms (SF 9). Die uncodierte Bitrate SF/T_s
sinkt dabei von 6835,94 über 3906,25 auf 2197,27 bit/s. Ein SF-Schritt
verdoppelt die Symbolzeit, transportiert aber nur ein zusätzliches Bit pro
Symbol. Diese Werte sind keine Paket- oder Netto-Datenraten eines realen Systems.

## Vergleich bei gleichem SNR pro Sample

39 simulierte Punkte, je 5000 Symbole, −24 bis 0 dB in 2-dB-Schritten.
Bei −12 dB wurden für SF 7 insgesamt 1023 Fehler (SER 0,2046,
95-%-Wilson-Intervall [0,193647; 0,216007]), für SF 8 insgesamt 75 Fehler
(SER 0,0150, Intervall [0,011984; 0,018761]) und für SF 9 keine Fehler
(Intervall [0; 0,000767702]) beobachtet.

Im Übergangsbereich verschieben sich die Kurven mit größerem SF zu kleinerem
benötigtem Sample-SNR. Bei gleicher Signalleistung und gleicher Bandbreite
steigt mit der längeren Symbolzeit die Symbolenergie. Pro SF-Schritt wächst
M um Faktor zwei und E_s/N_0 bei gleichem Sample-SNR um 3,0103 dB. Der
FFT-Detektor integriert über das längere Symbol; zugleich wächst die Zahl
möglicher Symbolentscheidungen. Ein pauschaler Gewinn von exakt 3 dB in der
Fehlerrate lässt sich deshalb nicht ableiten.

## Vergleich bei gemeinsamem E_s/N_0

30 weitere, unabhängig simulierte Punkte, je 5000 Symbole, 0 bis 18 dB in
2-dB-Schritten. Die notwendige Rauschleistung wurde für jeden SF neu aus
SNR_sample = E_s/N_0 − 10 log10(M) bestimmt. Beispiel bei 10 dB:
Sample-SNR −11,0721/−14,0824/−17,0927 dB und Rauschleistungen
12,8/25,6/51,2 für SF 7/8/9.

Bei E_s/N_0 = 10 dB sind die Fehlerraten 0,1082 (541 Fehler, SF 7),
0,1434 (717 Fehler, SF 8) und 0,1906 (953 Fehler, SF 9).
Ihre punktweisen Wilson-Intervalle sind [0,099889; 0,117113],
[0,133959; 0,153389] und [0,179952; 0,201723]. Der deutliche Vorteil des
höheren SF auf der Sample-SNR-Achse verschwindet. In diesem Bereich steigt
die Fehlerrate sogar mit SF: Bei gleichem Verhältnis von Symbolenergie zu
Rauschdichte konkurriert der Nutzbin mit mehr möglichen Rauschbins im
größeren Alphabet. Die Kurven müssen deshalb nicht exakt zusammenfallen.
Die Kampagne vergleicht E_s/N_0, nicht E_b/N_0 oder gleiche Netto-Datenrate.

## Grenzen und Darstellung

Die Grafiken `css-awgn` und `css-awgn-energy` liegen jeweils als SVG und PNG
vor. Fehlerbalken sind punktweise 95-%-Wilson-Intervalle, kein simultanes
Konfidenzband. Bei null beobachteten Fehlern liegt die obere Grenze bei
0,000767702, entsprechend etwa 0,07677 %. Diese obere Intervallgrenze wird
auf der logarithmischen Achse als offenes Abwärtsdreieck dargestellt;
die beobachtete Rate null ist dort nicht direkt darstellbar. Die Stichprobe
belegt keine Fehlerwahrscheinlichkeit von null und löst sehr kleine
Fehlerraten nicht zuverlässig auf.

Keine Frequenzoffsets, Synchronisationsfehler, Codierung, Paketfehler,
Mehrwege, Antenneneffekte oder reale Empfänger wurden untersucht. Die
Ergebnisse gelten für das definierte ideale, diskrete CSS-Modell.
