#import "layout.typ": seminararbeit
#import "literatur.typ": literatur-setup, literaturverzeichnis
#show: literatur-setup(read: path => read(path))
#show: seminararbeit


#include "kapitel/01-einleitung.typ"
#include "kapitel/02-grundlagen.typ"
#include "kapitel/03-css.typ"
#include "kapitel/04-antennen.typ"
#include "kapitel/04b-pcb-entwurf.typ"
#include "kapitel/05-simulation.typ"
#include "kapitel/06-messung.typ"
#include "kapitel/07-diskussion.typ"
#include "kapitel/08-fazit.typ"

#pagebreak()
#literaturverzeichnis()


// Nach dem Haupttext und dem Literaturverzeichnis folgt der Anhang.
#counter(heading).update(0)
#set heading(numbering: "A.1", supplement: [Anhang])
#include "anhang.typ"
#include "erklaerung.typ"
