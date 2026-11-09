# Gerätemarkerabgleich vom 5. November 2026

NanoVNA-F V2, Firmware 0.6.5; Kabel + Adapter + OPEN, unveränderte Kalibrierung
2,3–2,5 GHz am Geräteport. Der zusätzliche eingefrorene Sweep ist keine weitere
Anschlusswiederholung der Hauptreihen.

- `frozen-buffer/`: 101 komplexe Frequenzpunkte, CSV, Metadaten und Originalantworten.
- `frozen-commands.json`: Befehle und Antworten vor und nach dem Bildschirmabruf.
- `screen-frozen.png`: Geräteanzeige mit Marker bei 2,4 GHz, S11 LOGMAG −0,52 dB.
- `abgleich.json`: ursprüngliche numerische Dokumentation des Abgleichs.

Bei 2,4 GHz: Gamma = 0,925653 + j0,172879. Daraus folgen −0,5221318976 dB,
also rund 0,00213 dB Abstand zur Anzeige und weniger als eine halbe
Anzeigeeinheit von 0,005 dB. Die beiden gespeicherten `data 0`-Antworten sind
identisch. Der aktuelle Gesamtprüflauf rechnet alle 101 Punkte mit `auswertung/`
und Python nach und prüft die gerundete Geräteanzeige.

Das LCD zeigte vor dem Aktualisierungssweep eine alte Markerposition. Nur das
hier erhaltene eingefrorene Aufnahmepaar wird als Abgleich verwendet. Veraltete
Vorschaubilder und rohe Bildformat-Duplikate wurden entfernt. Dies prüft den
Datenweg und die Umrechnung; absolute Gerätegenauigkeit und Smith-R/L-Anzeige
werden damit nicht unabhängig validiert.
