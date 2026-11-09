"use client"

import { useEffect, useMemo, useState } from "react"
import { RotateCcw, Shuffle, Info } from "lucide-react"
import {
  CartesianGrid,
  Line,
  LineChart,
  XAxis,
  YAxis,
  Bar,
  BarChart,
  ReferenceLine,
} from "recharts"
import { DEFAULT_PARAMETERS, type LabParameters } from "@/lib/css-model"
import { loadCssWasm, simulate } from "@/lib/css-wasm"
import { EXPERIMENTS, explainExperiment } from "@/lib/css-experiments"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from "@/components/ui/card"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectGroup,
  SelectItem,
} from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { Switch } from "@/components/ui/switch"
import { Input } from "@/components/ui/input"
import {
  Field,
  FieldGroup,
  FieldLabel,
  FieldDescription,
} from "@/components/ui/field"
import { Separator } from "@/components/ui/separator"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart"

const format = (n: number, digits = 2) =>
  n.toLocaleString("de-DE", { maximumFractionDigits: digits })
const sfOptions = [7, 8, 9].map((sf) => ({
  value: String(sf),
  label: `SF ${sf} · ${2 ** sf} Symbole`,
}))
const scalar = (value: number | readonly number[]) =>
  typeof value === "number" ? value : value[0]

type PlotProps = {
  title: string
  description: string
  data: Record<string, number | null>[]
  x: string
  y: string
  xLabel: string
  yLabel: string
  color: string
  bars?: boolean
  peak?: number
}
function SignalPlot({
  title,
  description,
  data,
  x,
  y,
  xLabel,
  yLabel,
  color,
  bars,
  peak,
}: PlotProps) {
  const axes = (
    <>
      <CartesianGrid vertical={false} strokeDasharray="3 5" />
      <XAxis
        dataKey={x}
        type="number"
        domain={["dataMin", "dataMax"]}
        tickLine={false}
        axisLine={false}
        minTickGap={35}
        tickFormatter={(value) => format(value)}
        label={{ value: xLabel, position: "insideBottom", offset: -12 }}
      />
      <YAxis
        width={43}
        tickLine={false}
        axisLine={false}
        tickCount={4}
        tickFormatter={(value) => format(value, 1)}
      />
      <ChartTooltip
        content={
          <ChartTooltipContent
            labelFormatter={(value) => `${xLabel}: ${format(Number(value), 3)}`}
            formatter={(value) => `${format(Number(value), 3)} ${yLabel}`}
          />
        }
      />
    </>
  )
  return (
    <Card className="min-w-0 gap-3">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent className="px-3">
        <p className="mb-2 pl-3 text-xs text-muted-foreground">{yLabel}</p>
        <ChartContainer
          config={{ [y]: { label: title, color } }}
          className="aspect-auto h-48 min-h-48 w-full"
          aria-label={`${title}: ${yLabel} über ${xLabel}`}
        >
          {bars ? (
            <BarChart
              accessibilityLayer
              data={data}
              margin={{ top: 6, right: 12, bottom: 17, left: 0 }}
            >
              {axes}
              <Bar
                dataKey={y}
                fill={`var(--color-${y})`}
                isAnimationActive={false}
              />
              <ReferenceLine
                x={peak}
                stroke="var(--foreground)"
                strokeDasharray="3 3"
              />
            </BarChart>
          ) : (
            <LineChart
              accessibilityLayer
              data={data}
              margin={{ top: 6, right: 12, bottom: 17, left: 0 }}
            >
              {axes}
              <Line
                dataKey={y}
                type="linear"
                stroke={`var(--color-${y})`}
                strokeWidth={1.5}
                dot={false}
                isAnimationActive={false}
              />
            </LineChart>
          )}
        </ChartContainer>
      </CardContent>
    </Card>
  )
}

export function CssLab() {
  const [status, setStatus] = useState<"loading" | "ready" | "error">("loading")
  const [attempt, setAttempt] = useState(0)
  useEffect(() => {
    let active = true
    loadCssWasm().then(
      () => {
        if (active) setStatus("ready")
      },
      () => {
        if (active) setStatus("error")
      }
    )
    return () => {
      active = false
    }
  }, [attempt])
  if (status === "ready") return <LoadedCssLab />
  return (
    <Card>
      <CardHeader>
        <CardTitle>
          {status === "error"
            ? "Simulation konnte nicht geladen werden"
            : "CSS-Simulation wird geladen"}
        </CardTitle>
        <CardDescription role="status">
          {status === "error"
            ? "Das WebAssembly-Modul ist nicht verfügbar. Die Simulation kann erneut geladen werden."
            : "Der Rust-Rechenkern wird für die Berechnung im Browser initialisiert."}
        </CardDescription>
      </CardHeader>
      {status === "error" && (
        <CardFooter>
          <Button
            variant="outline"
            onClick={() => {
              setStatus("loading")
              setAttempt((value) => value + 1)
            }}
          >
            Erneut laden
          </Button>
        </CardFooter>
      )}
    </Card>
  )
}

function LoadedCssLab() {
  const [parameters, setParameters] = useState<LabParameters>({
    ...DEFAULT_PARAMETERS,
  })
  const result = useMemo(() => simulate(parameters), [parameters])
  const explanation = explainExperiment(parameters, result.detected)
  const update = <K extends keyof LabParameters>(
    key: K,
    value: LabParameters[K]
  ) => setParameters((previous) => ({ ...previous, [key]: value }))
  const frequency = result.samples.map((sample, index, array) => ({
    ...sample,
    frequency:
      index > 0 && sample.frequency < array[index - 1].frequency
        ? null
        : sample.frequency,
  }))
  return (
    <div className="flex flex-col gap-6">
      <section
        aria-labelledby="experiments-title"
        className="flex flex-col gap-4"
      >
        <div>
          <Badge variant="outline" className="mb-3">
            Rust / WebAssembly
          </Badge>
          <h3 id="experiments-title" className="text-lg font-medium">
            Vordefinierte Versuche
          </h3>
          <p className="text-sm text-muted-foreground">
            Die Vorlagen laden einen vollständigen Parametersatz. Alle
            Einstellungen bleiben anschließend anpassbar.
          </p>
        </div>
        <div className="grid gap-4 md:grid-cols-3">
          {EXPERIMENTS.map((experiment) => (
            <Card key={experiment.id} className="flex flex-col">
              <CardHeader className="flex-1">
                <CardTitle>{experiment.title}</CardTitle>
                <CardDescription>{experiment.description}</CardDescription>
              </CardHeader>
              <CardFooter>
                <Button
                  variant="outline"
                  className="w-full"
                  aria-label={`${experiment.title} laden`}
                  onClick={() => setParameters({ ...experiment.parameters })}
                >
                  Versuch laden
                </Button>
              </CardFooter>
            </Card>
          ))}
        </div>
      </section>
      <div className="grid min-w-0 gap-5 lg:grid-cols-[280px_minmax(0,1fr)]">
        <Card className="h-fit">
          <CardHeader>
            <CardTitle>Simulationsparameter</CardTitle>
            <CardDescription>
              Parameter für die Übertragung und Erkennung eines CSS-Symbols.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="sf">Spreading Factor</FieldLabel>
                <Select
                  items={sfOptions}
                  value={String(parameters.sf)}
                  onValueChange={(value) => {
                    if (value)
                      setParameters((old) => ({
                        ...old,
                        sf: Number(value),
                        symbol: Math.min(old.symbol, 2 ** Number(value) - 1),
                      }))
                  }}
                >
                  <SelectTrigger id="sf" className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectGroup>
                      {sfOptions.map((option) => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectGroup>
                  </SelectContent>
                </Select>
                <FieldDescription>
                  Ein höherer SF vergrößert das Alphabet und verlängert das
                  Symbol.
                </FieldDescription>
              </Field>
              <Field>
                <FieldLabel htmlFor="symbol">Gesendetes Symbol</FieldLabel>
                <Input
                  id="symbol"
                  type="number"
                  min={0}
                  max={result.size - 1}
                  step={1}
                  value={parameters.symbol}
                  onChange={(event) =>
                    update(
                      "symbol",
                      Math.min(
                        result.size - 1,
                        Math.max(0, Math.trunc(Number(event.target.value)) || 0)
                      )
                    )
                  }
                />
                <FieldDescription>
                  Eine ganze Zahl von 0 bis {result.size - 1}.
                </FieldDescription>
              </Field>
              <Separator />
              <Field orientation="horizontal">
                <FieldLabel htmlFor="noise">Rauschen hinzufügen</FieldLabel>
                <Switch
                  id="noise"
                  checked={parameters.noise}
                  onCheckedChange={(checked) => update("noise", checked)}
                />
              </Field>
              <Field data-disabled={!parameters.noise}>
                <FieldLabel id="snr-label">
                  SNR pro Sample: {parameters.snr} dB
                </FieldLabel>
                <Slider
                  aria-labelledby="snr-label"
                  min={-24}
                  max={0}
                  step={1}
                  value={[parameters.snr]}
                  disabled={!parameters.noise}
                  onValueChange={(value) => update("snr", scalar(value))}
                />
                <FieldDescription>
                  Je negativer der Wert, desto stärker das Rauschen relativ zum
                  Signal.
                </FieldDescription>
              </Field>
              <Field>
                <FieldLabel id="offset-label">
                  Frequenzoffset: {format(parameters.offset)} Bins
                </FieldLabel>
                <Slider
                  aria-labelledby="offset-label"
                  min={-2}
                  max={2}
                  step={0.05}
                  value={[parameters.offset]}
                  onValueChange={(value) => update("offset", scalar(value))}
                />
                <FieldDescription>
                  Δf = {format(parameters.offset * result.binWidth)} Hz. Ein Bin
                  entspricht {format(result.binWidth)} Hz.
                </FieldDescription>
              </Field>
            </FieldGroup>
          </CardContent>
          <CardFooter className="flex flex-col items-stretch gap-2">
            <Button
              variant="outline"
              disabled={!parameters.noise}
              onClick={() => update("seed", (parameters.seed + 1) >>> 0)}
            >
              <Shuffle data-icon="inline-start" />
              Neue Rauschrealisierung
            </Button>
            <Button
              variant="ghost"
              onClick={() => setParameters({ ...DEFAULT_PARAMETERS })}
            >
              <RotateCcw data-icon="inline-start" />
              Zurücksetzen
            </Button>
          </CardFooter>
        </Card>
        <div className="flex min-w-0 flex-col gap-5">
          <div
            className="lab-readout"
            role="status"
            aria-live="polite"
            aria-atomic="true"
          >
            <div>
              <p className="text-sm text-muted-foreground">
                Gesendet → erkannt
              </p>
              <p className="readout-value">
                {parameters.symbol}{" "}
                <span className="text-muted-foreground">→</span>{" "}
                {result.detected}
              </p>
            </div>
            <Badge
              variant={
                result.detected === parameters.symbol
                  ? "secondary"
                  : "destructive"
              }
            >
              {result.detected === parameters.symbol
                ? "Symbol erkannt"
                : "Symbol verwechselt"}
            </Badge>
            <dl className="flex flex-wrap gap-x-8 gap-y-3">
              <div>
                <dt className="text-xs text-muted-foreground">Symbolzeit</dt>
                <dd className="font-mono text-sm">
                  {format(result.duration, 3)} ms
                </dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">
                  Bandbreite / Abtastrate
                </dt>
                <dd className="font-mono text-sm">125 kHz</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">FFT-Bins</dt>
                <dd className="font-mono text-sm">{result.size}</dd>
              </div>
            </dl>
          </div>
          <Alert role="region" aria-labelledby="experiment-explanation-title">
            <Info />
            <AlertTitle id="experiment-explanation-title">
              {explanation.title}
            </AlertTitle>
            <AlertDescription>
              <p>{explanation.explanation}</p>
              <p>{explanation.outcome}</p>
              <p>
                <strong>Vergleichsversuch:</strong> {explanation.suggestion}
              </p>
            </AlertDescription>
          </Alert>
          <div className="grid min-w-0 gap-4 md:grid-cols-2">
            <SignalPlot
              title="Sendesignal"
              description="Idealer Frequenzverlauf des Symbols, vor Störungen."
              data={frequency}
              x="time"
              y="frequency"
              xLabel="Zeit (ms)"
              yLabel="Frequenz (kHz)"
              color="var(--chart-1)"
            />
            <SignalPlot
              title="Empfangssignal"
              description="Realteil nach Frequenzoffset und optionalem Rauschen."
              data={result.samples}
              x="time"
              y="received"
              xLabel="Zeit (ms)"
              yLabel="Normierte Amplitude"
              color="var(--chart-2)"
            />
            <SignalPlot
              title="Dechirping"
              description="Realteil nach Multiplikation mit dem konjugierten Referenzchirp."
              data={result.samples}
              x="time"
              y="dechirped"
              xLabel="Zeit (ms)"
              yLabel="Normierte Amplitude"
              color="var(--chart-3)"
            />
            <SignalPlot
              title="FFT und Symbolentscheidung"
              description="Der stärkste FFT-Bin bestimmt die Entscheidung."
              data={result.spectrum}
              x="bin"
              y="magnitude"
              xLabel="FFT-Bin"
              yLabel="FFT-Betrag (unnormiert)"
              color="var(--chart-4)"
              bars
              peak={result.detected}
            />
          </div>
        </div>
      </div>
      <Alert>
        <Info />
        <AlertTitle>Modellumfang und Aussagekraft</AlertTitle>
        <AlertDescription>
          Die Demo zeigt eine Symbolentscheidung, keine statistische Fehlerrate.
          Das Modell ist synchron und uncodiert; es bildet keine vollständige
          LoRa- oder ExpressLRS-Verbindung ab. Der Zufallsseed bleibt bei
          Parameteränderungen gleich. Bei genau einem halben Bin können zwei
          Peaks gleich hoch sein; Rundung entscheidet dann über den gewählten
          Bin.
        </AlertDescription>
      </Alert>
    </div>
  )
}
