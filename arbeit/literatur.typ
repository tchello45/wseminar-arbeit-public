// Gruppen wie in Philips Vergleichsarbeit. Alexandria 0.2.2 ist lokal beigelegt.
// Fest zugeordnete IEEE-Nummern vermeiden eine Rückkopplung zwischen
// Literaturzustand und Seitenberechnung. check_gesamt.py prüft die Zuordnung.
#import "vendor/alexandria-0.2.2/src/hayagriva.typ" as hayagriva
#import "vendor/alexandria-0.2.2/src/lib.typ": render-bibliography

#let gruppen = json("literaturgruppen.json")
#let alle = gruppen.map(g => g.keys).flatten()
#assert.eq(alle.len(), alle.dedup().len(), message: "Quelle mehrfach einer Gruppe zugeordnet")
#let basiszitate = alle.map(key => ((key: key, form: "normal", supplement: none, locale: "de"),))
#let quellen = ((path: "literatur.bib", data: read("literatur.bib")),)
#let lesen(zitate) = hayagriva.read(quellen, false, (built-in: "ieee"), "de", zitate)
#let bib = (prefix: "lit:", ..lesen(basiszitate))

#let zitieren(key, supplement: none) = {
  assert(key in alle, message: "Quelle fehlt in literaturgruppen.json: " + key)
  let daten = if supplement == none {
    bib.citations.at(alle.position(x => x == key))
  } else {
    // Der Bibliografieprozessor formatiert auch Seiten- und Abschnittszusätze.
    lesen(basiszitate + (((key: key, form: "normal", supplement: repr(supplement), locale: "de"),),)).citations.last()
  }
  let footnote = daten.footnote
  let inhalt = daten.content
  assert(not footnote, message: "IEEE-Zitate müssen im Text stehen")
  hayagriva.render(inhalt, keys: (label("lit:" + key),), supplement)
}

#let literatur-setup(read: none) = body => {
  show ref: it => {
    let key = str(it.target)
    if key.starts-with("lit:") {
      zitieren(key.slice(4), supplement: if it.supplement != auto { it.supplement })
    } else { it }
  }
  show cite: it => {
    let key = str(it.key)
    if key.starts-with("lit:") {
      assert(it.form == "normal", message: "Literaturadapter unterstützt normale IEEE-Zitate")
      zitieren(key.slice(4), supplement: if it.supplement != auto { it.supplement })
    } else { it }
  }
  body
}

#let literaturverzeichnis() = context {
  heading(numbering: none)[Literaturverzeichnis]
  for gruppe in gruppen {
    let refs = bib.references.filter(r => r.key in gruppe.keys)
    if refs.len() > 0 {
      heading(level: 2, numbering: none, outlined: false, gruppe.title)
      render-bibliography((..bib, references: refs), title: none)
    }
  }
}
