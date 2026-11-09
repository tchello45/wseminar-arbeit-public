// Formale Orientierung: Philips seminararbeit/template.typ.
// Die Vorlage ersetzt keine verbindliche schulische Formatvorgabe.
#let seminararbeit(
  title: "Physik der Funkübertragung mit LoRa-CSS",
  subtitle: "Signalverarbeitung, theoretischer PCB-Antennenentwurf und ergänzende NanoVNA-Messungen",
  author: "Tilman Kurmayer",
  // Aus der Vergleichsarbeit übernommen; vor Abgabe persönlich abgleichen.
  school: "Oskar-von-Miller-Gymnasium",
  supervisor: "Roman Störmer",
  body,
) = {
  set document(title: title, author: author)
  set page(paper: "a4", margin: (left: 3cm, right: 2cm, top: 2.5cm, bottom: 2.5cm), numbering: none, number-align: center)
  set text(font: "Libertinus Serif", size: 11pt, lang: "de", costs: (orphan: 100%, widow: 100%))
  set par(justify: true, leading: 0.65em, first-line-indent: 0em)
  set heading(numbering: "1.1")
  set math.equation(numbering: "(1)")
  set figure(supplement: [Abbildung])

  show heading: set text(hyphenate: false)
  show heading: set par(justify: false)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    block(sticky: true, above: 0.5em, below: 1em)[
      #text(size: 18pt, weight: "bold", it)
      #v(0.3em)
      #line(length: 100%, stroke: 0.6pt + luma(170))
    ]
  }
  show heading.where(level: 2): set text(size: 13pt, weight: "bold")
  show heading.where(level: 2): set block(above: 1.1em, below: 0.45em, sticky: true)
  show heading.where(level: 3): set text(size: 11.5pt, weight: "bold")
  show heading.where(level: 3): set block(above: 0.85em, below: 0.3em, sticky: true)
  set table(
    stroke: (x, y) => if y == 0 { (bottom: 0.7pt + luma(100)) },
    fill: (x, y) => if y == 0 { luma(243) },
    inset: (x: 7pt, y: 5.5pt),
  )
  show table: set text(size: 9.5pt)
  show table.cell.where(y: 0): set text(weight: "bold")
  show figure: set block(above: 1.4em, below: 1.4em)
  show figure.caption: set text(size: 9.5pt, fill: luma(60))
  show raw.where(block: true): it => block(
    fill: luma(247), stroke: 0.5pt + luma(215), radius: 3pt,
    inset: (x: 6pt, y: 5pt), width: 100%, text(size: 8pt, it),
  )

  align(center)[
    #set par(justify: false)
    #v(1.5cm)
    #text(size: 13pt)[#school]
    #v(0.3cm)
    #text(size: 12pt)[Wissenschaftspropädeutisches Seminar im Leitfach Physik]
    #linebreak()
    #text(size: 12pt)[Rahmenthema: Wellen und Teilchen]
    #v(2.5cm)
    #text(size: 22pt, weight: "bold")[#title]
    #v(0.5cm)
    #text(size: 14pt, style: "italic", hyphenate: false)[#subtitle]
    #v(2.5cm)
    #text(size: 13pt)[Seminararbeit von #author]
    #v(0.5cm)
    #text(size: 12pt)[Kursleitung: #supervisor]
    #v(1fr)
    #v(1cm)
  ]
  pagebreak()
  outline(title: [Inhaltsverzeichnis], indent: auto, depth: 2)
  pagebreak()
  set page(numbering: "1")
  counter(page).update(1)
  body
}
