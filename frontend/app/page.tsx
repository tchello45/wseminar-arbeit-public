import Image from "next/image"
import {
  ArrowDown,
  ArrowUpRight,
  FileText,
  Info,
  Radio,
  Waves,
} from "lucide-react"
import { Navigation, NavigateButton } from "@/components/seminar/navigation"
import { CssLab } from "@/components/seminar/css-lab"
import { Results } from "@/components/seminar/results"
import { Badge } from "@/components/ui/badge"
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from "@/components/ui/card"
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert"
import { Separator } from "@/components/ui/separator"
import referenceSymbol from "@/data/reference-symbol.json"
import results from "@/data/results.json"

function HeroSignal() {
  const signal = referenceSymbol
  const points = signal.samples
    .map(
      (sample, index) =>
        `${30 + (index / 127) * 660},${160 - sample.received * 74}`
    )
    .join(" ")
  return (
    <figure className="hero-signal">
      <div className="flex items-center justify-between gap-3 border-b border-border px-5 py-4">
        <span className="flex items-center gap-2 text-sm">
          <Waves className="size-4 text-primary" />
          CSS-Symbol im Zeitbereich
        </span>
        <Badge variant="outline">SF 7</Badge>
      </div>
      <svg
        viewBox="0 0 720 300"
        role="img"
        aria-label="Realteil eines idealen CSS-Symbols: Die Schwingungsfrequenz verändert sich mit der Zeit."
      >
        {Array.from({ length: 12 }, (_, i) => (
          <line
            key={`x${i}`}
            x1={30 + i * 60}
            x2={30 + i * 60}
            y1="35"
            y2="255"
            stroke="var(--border)"
          />
        ))}
        {[50, 105, 160, 215, 255].map((y) => (
          <line key={y} x1="30" x2="690" y1={y} y2={y} stroke="var(--border)" />
        ))}
        <line
          x1="30"
          x2="690"
          y1="160"
          y2="160"
          stroke="var(--muted-foreground)"
          strokeDasharray="4 5"
        />
        <polyline
          points={points}
          fill="none"
          stroke="var(--chart-1)"
          strokeWidth="1.8"
        />
        <text x="30" y="285" fill="var(--muted-foreground)" fontSize="12">
          0 ms
        </text>
        <text
          x="690"
          y="285"
          textAnchor="end"
          fill="var(--muted-foreground)"
          fontSize="12"
        >
          1,024 ms
        </text>
      </svg>
      <figcaption className="flex flex-wrap justify-between gap-3 border-t border-border px-5 py-4 text-xs text-muted-foreground">
        <span>Symbol 17 · ohne Rauschen</span>
        <span>B = 125 kHz · 128 Samples</span>
      </figcaption>
    </figure>
  )
}

function SectionHeading({
  id,
  children,
  description,
}: {
  id: string
  children: React.ReactNode
  description: string
}) {
  return (
    <div className="section-heading">
      <h2 id={id}>{children}</h2>
      <p>{description}</p>
    </div>
  )
}

export default function Page() {
  return (
    <>
      <a href="#inhalt" className="skip-link">
        Zum Inhalt springen
      </a>
      <Navigation />
      <main id="inhalt">
        <section id="start" className="hero page-width">
          <div className="hero-copy">
            <Badge variant="outline">
              <Radio data-icon="inline-start" />
              W-Seminar · Physik der Funkübertragung
            </Badge>
            <h1>LoRa-CSS. Simulation und Messung.</h1>
            <p className="hero-description">
              Untersuchung der Symbolerkennung unter Rauschen und
              Frequenzoffset. Interaktive CSS-Simulation, reproduzierbare
              Ergebnisse und ergänzende NanoVNA-Messungen zur komplexen
              Reflexion.
            </p>
            <div className="flex flex-wrap gap-3">
              <NavigateButton target="/#labor">
                Simulation starten
                <ArrowDown data-icon="inline-end" />
              </NavigateButton>
              <NavigateButton target="/arbeit.pdf" variant="outline">
                <FileText data-icon="inline-start" />
                Arbeit als PDF
              </NavigateButton>
            </div>
          </div>
          <HeroSignal />
          <div className="hero-footnote">
            <p>Numerische Simulation und HF-Messtechnik</p>
            <p>Signalverarbeitung · Reflexion · Antennenentwurf</p>
          </div>
        </section>

        <section className="intro-band">
          <div className="page-width grid gap-8 md:grid-cols-[1fr_1.4fr]">
            <h2>Fragestellung und Methodik</h2>
            <div className="flex flex-col gap-4">
              <p>
                Wie beeinflussen Spreading Factor, Rauschen und
                Frequenzabweichungen die Symbolerkennung in einem vereinfachten
                LoRa-CSS-Modell?
              </p>
              <p className="text-muted-foreground">
                ExpressLRS liefert den Anwendungskontext der Arbeit. Untersucht
                wird ein vereinfachtes Modell der LoRa-Modulation auf Grundlage
                von Chirp Spread Spectrum. LoRa ist die Modulation; LoRaWAN
                bezeichnet ein Netzwerkprotokoll. Ergänzende NanoVNA-Messungen
                zeigen, wie Abschlüsse und Leitungen die Reflexion verändern.
              </p>
            </div>
          </div>
        </section>

        <section
          id="labor"
          className="page-width content-section"
          aria-labelledby="labor-title"
        >
          <SectionHeading
            id="labor-title"
            description="Einfluss von Spreading Factor, Rauschen und Frequenzoffset auf Sendesignal, Dechirping und FFT-basierte Symbolerkennung."
          >
            Interaktive CSS-Simulation
          </SectionHeading>
          <CssLab />
        </section>

        <section
          id="ergebnisse"
          className="page-width content-section"
          aria-labelledby="ergebnisse-title"
        >
          <SectionHeading
            id="ergebnisse-title"
            description="Statistische Auswertung der Symbolerkennung bei gleichem SNR pro Sample, gleichem Energieverhältnis und unterschiedlichen Frequenzoffsets."
          >
            Simulationsergebnisse
          </SectionHeading>
          <Results data={results} />
          <p className="source-note">
            Quelle: die drei numerischen Versuchskampagnen der Arbeit, Kapitel
            6. Alle 135 Datenpunkte werden aus den gespeicherten CSV-Dateien
            übernommen.
          </p>
        </section>

        <section
          id="nanovna"
          className="measurement-band"
          aria-labelledby="nanovna-title"
        >
          <div className="page-width content-section">
            <SectionHeading
              id="nanovna-title"
              description="Messung der komplexen Reflexion an verschiedenen Abschlüssen und Untersuchung des Leitungseinflusses auf Betrag und Phase."
            >
              NanoVNA-Messungen
            </SectionHeading>
            <div className="grid gap-5 md:grid-cols-2">
              <Card className="min-w-0">
                <CardHeader>
                  <CardTitle>OPEN, SHORT und LOAD</CardTitle>
                  <CardDescription>
                    Vergleich von Leerlauf, Kurzschluss und angepasster Last.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Image
                    src="/media/nanovna-standards.svg"
                    width={527}
                    height={386}
                    alt="Originalgrafik der Arbeit: Betrag und Phase der Reflexion für OPEN, SHORT und LOAD im Bereich 2,3 bis 2,5 GHz."
                    className="measurement-image"
                  />
                </CardContent>
                <CardFooter>
                  <p className="text-sm text-muted-foreground">
                    Leerlauf und Kurzschluss reflektieren stark, unterscheiden
                    sich aber in der Phase. Eine angepasste Last reflektiert
                    deutlich weniger. Betrag und Phase beschreiben gemeinsam die
                    komplexe Reflexion.
                  </p>
                </CardFooter>
              </Card>
              <Card className="min-w-0">
                <CardHeader>
                  <CardTitle>Leitungseinfluss und Referenzebene</CardTitle>
                  <CardDescription>
                    Änderung der komplexen Reflexion durch ein eingefügtes
                    Koaxialkabel.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Image
                    src="/media/nanovna-kabel.svg"
                    width={527}
                    height={367}
                    alt="Originalgrafik der Arbeit zum Einfluss des eingefügten Koaxialkabels auf Betrag und Phase der komplexen Reflexion."
                    className="measurement-image"
                  />
                </CardContent>
                <CardFooter>
                  <p className="text-sm text-muted-foreground">
                    Das eingefügte Kabel verändert besonders die Phase. Das
                    Signal läuft bis zum Abschluss und zurück. Deshalb ist der
                    am Gerät gemessene S11-Wert zusammen mit der Referenzebene
                    zu interpretieren.
                  </p>
                </CardFooter>
              </Card>
            </div>
            <div className="mt-6">
              <Alert>
                <Info />
                <AlertTitle>Aussagekraft der 18 Messaufnahmen</AlertTitle>
                <AlertDescription>
                  Drei Anschlusswiederholungen je Konfiguration zeigen
                  beobachtete Unterschiede. Der Abgleich von Rust, Python und
                  gerundeter Geräteanzeige prüft den Datenweg und die
                  Umrechnung. Daraus folgen weder eine vollständige
                  Unsicherheitsbilanz noch eine unabhängige Bestimmung der
                  absoluten Gerätegenauigkeit.
                </AlertDescription>
              </Alert>
            </div>
          </div>
        </section>

        <section
          className="page-width content-section"
          aria-labelledby="fazit-title"
        >
          <SectionHeading
            id="fazit-title"
            description="Die Ergebnisse lassen sich nur zusammen mit ihren Bezugsgrößen und Modellgrenzen sinnvoll bewerten."
          >
            Erkenntnisse und Grenzen
          </SectionHeading>
          <div className="findings-grid">
            <article>
              <h3>Symbolzeit und Energiebedarf</h3>
              <p>
                Ein größerer SF verbessert im untersuchten Modell die Erkennung
                bei gleichem SNR pro Sample. Gleichzeitig steigen Symbolzeit und
                Symbolenergie bei gleicher Signalleistung.
              </p>
            </article>
            <article>
              <h3>Empfindlichkeit gegenüber Frequenzoffset</h3>
              <p>
                Ein Frequenzfehler kann den Vorteil aufheben. Derselbe Fehler in
                Hz entspricht bei höherem SF mehr FFT-Bins.
              </p>
            </article>
            <article>
              <h3>Grenzen der S11-Bewertung</h3>
              <p>
                Ein kleiner S11-Wert allein belegt weder einen hohen
                Antennenwirkungsgrad noch ausreichenden Gewinn in allen
                Richtungen.
              </p>
            </article>
          </div>
          <Separator className="my-12" />
          <div className="grid items-center gap-8 md:grid-cols-2">
            <div className="flex flex-col gap-4">
              <Badge variant="outline">Theoretische Entwurfsstudie</Badge>
              <h3 className="text-2xl font-medium tracking-tight">
                PCB-Antennenentwurf
              </h3>
              <p className="max-w-xl text-muted-foreground">
                Die Arbeit ergänzt Simulation und Messung um einen theoretischen
                PCB-Antennenentwurf: Anforderungen, eine IFA als Referenz sowie
                analytische Leitungs- und Anpassrechnungen. Die Studie umfasst
                keine Fertigung, elektromagnetische Feldsimulation oder Messung
                einer eigenen Antenne.
              </p>
            </div>
            <Image
              src="/media/pcb-ifa-prinzip.svg"
              width={720}
              height={396}
              alt="Prinzipdarstellung einer Inverted-F-Antenne aus dem theoretischen PCB-Entwurf der Arbeit."
              className="measurement-image"
            />
          </div>
        </section>

        <section
          id="quellen"
          className="page-width content-section"
          aria-labelledby="quellen-title"
        >
          <div className="paper-panel">
            <div>
              <h2 id="quellen-title">Vollständige W-Seminararbeit</h2>
              <p>
                Herleitung, Methoden, Ergebnisse und Grenzen der Untersuchung
                stehen in der vollständigen W-Seminararbeit.
              </p>
            </div>
            <NavigateButton target="/arbeit.pdf">
              <FileText data-icon="inline-start" />
              PDF öffnen
              <ArrowUpRight data-icon="inline-end" />
            </NavigateButton>
          </div>
          <div className="sources-grid">
            <h3>Ausgewählte Fachquellen</h3>
            <ul>
              <li>
                <a
                  href="https://www.semtech.com/lora/what-is-lora"
                  target="_blank"
                  rel="noreferrer"
                >
                  Semtech: Grundlagen der LoRa-Modulation
                  <ArrowUpRight aria-hidden="true" />
                </a>
              </li>
              <li>
                <a
                  href="https://arxiv.org/abs/2310.10503v1"
                  target="_blank"
                  rel="noreferrer"
                >
                  Maleki et al.: LoRa-Signalverarbeitung
                  <ArrowUpRight aria-hidden="true" />
                </a>
              </li>
              <li>
                <a
                  href="https://arxiv.org/abs/2201.03825v1"
                  target="_blank"
                  rel="noreferrer"
                >
                  Demeslay et al.: CSS-Modell und Detektion
                  <ArrowUpRight aria-hidden="true" />
                </a>
              </li>
              <li>
                <a
                  href="https://www.ti.com/lit/pdf/swra117"
                  target="_blank"
                  rel="noreferrer"
                >
                  Texas Instruments: PCB-Antennenreferenz AN043
                  <ArrowUpRight aria-hidden="true" />
                </a>
              </li>
            </ul>
            <p>
              Das vollständige Literaturverzeichnis ist in der W-Seminararbeit
              enthalten.
            </p>
          </div>
        </section>
      </main>
      <footer className="page-width site-footer">
        <span>Funkübertragung / LoRa-CSS</span>
        <span>Tilman Kurmayer · Begleitwebsite zur W-Seminararbeit</span>
        <NavigateButton target="/#start" variant="ghost">
          Nach oben
        </NavigateButton>
      </footer>
    </>
  )
}
