"use client"

import { useState } from "react"
import { CartesianGrid, Line, LineChart, XAxis, YAxis } from "recharts"
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from "@/components/ui/card"
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  ChartLegend,
  ChartLegendContent,
} from "@/components/ui/chart"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectGroup,
  SelectItem,
} from "@/components/ui/select"
import { Field, FieldLabel } from "@/components/ui/field"
import {
  Table,
  TableHeader,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
} from "@/components/ui/table"
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion"

export type Trial = {
  sf: number
  snr_per_sample_db: number
  es_n0_db: number
  ser: number
  trials: number
  errors: number
  wilson95_lower: number
  wilson95_upper: number
  delta?: number
}
export type ResultsData = { snr: Trial[]; energy: Trial[]; offset: Trial[] }
const config = {
  sf7: { label: "SF 7", color: "var(--chart-1)" },
  sf8: { label: "SF 8", color: "var(--chart-2)" },
  sf9: { label: "SF 9", color: "var(--chart-3)" },
}
const descriptions = {
  snr: {
    title: "Vergleich bei gleichem SNR pro Sample",
    text: "Bei gleichem SNR pro Sample verbessert ein größerer SF die Erkennung. Gleichzeitig dauern die Symbole länger: SF 9 benötigt viermal so viel Zeit wie SF 7. Bei gleicher Signalleistung steigt auch die Symbolenergie auf das Vierfache.",
    axis: "SNR pro Sample (dB)",
  },
  energy: {
    title: "Vergleich bei gleichem Eₛ/N₀",
    text: "Bei gleichem Eₛ/N₀ entfällt der Vorteil zusätzlicher Symbolenergie. Im größeren Alphabet konkurriert der Nutzbin mit mehr Rauschbins. Ein größerer SF ist in diesem Vergleich deshalb nicht automatisch besser.",
    axis: "Eₛ/N₀ (dB)",
  },
  offset: {
    title: "Einfluss des Frequenzoffsets",
    text: "Ein unkorrigierter Frequenzoffset verteilt die Energie auf benachbarte FFT-Bins. Ein ganzer Bin verschiebt die Symbolentscheidung zyklisch. Entscheidend ist der Offset relativ zum Binabstand B/M.",
    axis: "Frequenzoffset (Bins)",
  },
}

function Campaign({ kind, rows }: { kind: keyof ResultsData; rows: Trial[] }) {
  const [energy, setEnergy] = useState("16")
  const selection =
    kind === "offset"
      ? rows.filter((row) => row.es_n0_db === Number(energy))
      : rows
  const x = (row: Trial) =>
    kind === "offset"
      ? row.delta!
      : kind === "snr"
        ? row.snr_per_sample_db
        : row.es_n0_db
  const points = [...new Set(selection.map(x))]
    .sort((a, b) => a - b)
    .map((value) => {
      const row: Record<string, number> = { x: value }
      for (const sf of [7, 8, 9]) {
        const trial = selection.find(
          (item) => item.sf === sf && x(item) === value
        )
        if (trial) row[`sf${sf}`] = trial.ser
      }
      return row
    })
  const info = descriptions[kind]
  return (
    <Card className="min-w-0">
      <CardHeader className="gap-3">
        <CardTitle>{info.title}</CardTitle>
        <CardDescription className="max-w-3xl">{info.text}</CardDescription>
        {kind === "offset" && (
          <Field className="max-w-56">
            <FieldLabel htmlFor="result-energy">
              Energieverhältnis Eₛ/N₀
            </FieldLabel>
            <Select
              items={[
                { value: "10", label: "10 dB" },
                { value: "16", label: "16 dB" },
              ]}
              value={energy}
              onValueChange={(value) => value && setEnergy(value)}
            >
              <SelectTrigger id="result-energy" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="10">10 dB</SelectItem>
                  <SelectItem value="16">16 dB</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </Field>
        )}
      </CardHeader>
      <CardContent className="min-w-0 px-2 sm:px-6">
        <p className="mb-3 pl-3 text-xs text-muted-foreground">
          Beobachtete Symbolfehlerrate
        </p>
        <ChartContainer
          config={config}
          className="aspect-auto h-80 min-h-80 w-full"
          aria-label={`Symbolfehlerrate über ${info.axis}, Vergleich von SF 7, 8 und 9`}
        >
          <LineChart
            accessibilityLayer
            data={points}
            margin={{ top: 8, right: 18, left: 0, bottom: 20 }}
          >
            <CartesianGrid vertical={false} strokeDasharray="3 5" />
            <XAxis
              type="number"
              dataKey="x"
              domain={["dataMin", "dataMax"]}
              tickLine={false}
              axisLine={false}
              minTickGap={30}
              label={{
                value: info.axis,
                position: "insideBottom",
                offset: -12,
              }}
            />
            <YAxis
              domain={[0, 1]}
              width={45}
              tickLine={false}
              axisLine={false}
              tickFormatter={(v) => Number(v).toLocaleString("de-DE")}
            />
            <ChartTooltip
              content={
                <ChartTooltipContent
                  labelFormatter={(value) => `${info.axis}: ${value}`}
                  formatter={(value, name) =>
                    `${String(name).toUpperCase().replace("SF", "SF ")}: ${Number(value).toLocaleString("de-DE", { maximumFractionDigits: 4 })}`
                  }
                />
              }
            />
            <ChartLegend verticalAlign="top" content={<ChartLegendContent />} />
            {[7, 8, 9].map((sf) => (
              <Line
                key={sf}
                type="linear"
                dataKey={`sf${sf}`}
                stroke={`var(--color-sf${sf})`}
                strokeWidth={2}
                dot={{ r: 3 }}
                isAnimationActive={false}
              />
            ))}
          </LineChart>
        </ChartContainer>
      </CardContent>
      <CardFooter className="flex-col items-start gap-3">
        <p className="text-sm text-muted-foreground">
          Jeder Punkt beruht auf {selection[0].trials.toLocaleString("de-DE")}{" "}
          Symbolversuchen. Null beobachtete Fehler bedeuten keine
          Fehlerwahrscheinlichkeit von null. Die 95-%-Wilson-Intervalle stehen
          in den Datenpunkten.
        </p>
        <Accordion className="w-full">
          <AccordionItem value="data">
            <AccordionTrigger>
              Datenpunkte und Unsicherheitsintervalle
            </AccordionTrigger>
            <AccordionContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>SF</TableHead>
                    <TableHead>{info.axis}</TableHead>
                    <TableHead>Fehler / Versuche</TableHead>
                    <TableHead>Fehlerrate</TableHead>
                    <TableHead>95-%-Wilson-Intervall</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {selection.map((row, i) => (
                    <TableRow key={i}>
                      <TableCell>{row.sf}</TableCell>
                      <TableCell>{x(row)}</TableCell>
                      <TableCell>
                        {row.errors} / {row.trials}
                      </TableCell>
                      <TableCell>{row.ser.toLocaleString("de-DE")}</TableCell>
                      <TableCell>
                        {row.wilson95_lower.toLocaleString("de-DE", {
                          maximumFractionDigits: 5,
                        })}
                        –
                        {row.wilson95_upper.toLocaleString("de-DE", {
                          maximumFractionDigits: 5,
                        })}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </AccordionContent>
          </AccordionItem>
        </Accordion>
      </CardFooter>
    </Card>
  )
}
export function Results({ data }: { data: ResultsData }) {
  return (
    <Tabs defaultValue="snr" className="min-w-0 gap-5">
      <TabsList className="h-auto! w-full flex-wrap justify-start">
        <TabsTrigger value="snr">Gleiches SNR</TabsTrigger>
        <TabsTrigger value="energy">Gleiches Eₛ/N₀</TabsTrigger>
        <TabsTrigger value="offset">Frequenzoffset</TabsTrigger>
      </TabsList>
      {(["snr", "energy", "offset"] as const).map((kind) => (
        <TabsContent key={kind} value={kind}>
          <Campaign kind={kind} rows={data[kind]} />
        </TabsContent>
      ))}
    </Tabs>
  )
}
