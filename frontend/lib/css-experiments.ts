import {
  BANDWIDTH,
  DEFAULT_PARAMETERS,
  type LabParameters,
} from "./css-model.ts"

/** Loading a template replaces every parameter, including the noise seed. */
export const EXPERIMENTS: {
  id: string
  title: string
  description: string
  parameters: LabParameters
}[] = [
  {
    id: "noise",
    title: "Symbolerkennung bei Rauschen",
    description:
      "Symbolerkennung bei −12 dB SNR pro Sample, ohne Frequenzoffset. Die FFT zeigt den Nutzbin und die konkurrierenden Rauschbins.",
    parameters: { ...DEFAULT_PARAMETERS, noise: true, snr: -12 },
  },
  {
    id: "half-bin",
    title: "Offset von 0,5 Bins",
    description:
      "Bei 0,5 Bins Frequenzoffset sind zwei benachbarte FFT-Peaks ohne Rauschen gleich hoch. Kleine Offsetänderungen verändern ihre Rangfolge.",
    parameters: { ...DEFAULT_PARAMETERS, offset: 0.5 },
  },
  {
    id: "full-bin",
    title: "Offset von einem Bin",
    description:
      "Ein ganzzahliger Frequenzoffset verschiebt den FFT-Peak zyklisch. Ohne Rauschen wird das benachbarte Symbol erkannt.",
    parameters: { ...DEFAULT_PARAMETERS, offset: 1 },
  },
]

const format = (value: number, digits = 2) =>
  value.toLocaleString("de-DE", { maximumFractionDigits: digits })

/** Describe the current controls, never a remembered template selection. */
export function explainExperiment(parameters: LabParameters, detected: number) {
  const { sf, symbol, noise, snr, offset } = parameters
  const size = 2 ** sf
  const wrap = (bin: number) => ((bin % size) + size) % size
  const halfBin = Math.abs(Math.abs(offset - Math.round(offset)) - 0.5) < 1e-9
  const wholeBin = Math.abs(offset - Math.round(offset)) < 1e-9
  let title: string
  let explanation: string
  let suggestion: string

  if (halfBin) {
    const lower = wrap(Math.floor(symbol + offset))
    const upper = wrap(Math.ceil(symbol + offset))
    title = noise
      ? "Halb-Bin-Offset mit Rauschen"
      : "Gleich hohe FFT-Peaks bei Halb-Bin-Offset"
    explanation = `Ohne Rauschen sind die FFT-Peaks bei Bin ${lower} und ${upper} gleich hoch. ${noise ? "Rauschen kann die Rangfolge der Peaks verändern; auch andere Bins können das Maximum bilden." : "Numerische Rundung kann entscheiden, welcher der beiden Bins ausgewählt wird. Das ursprüngliche Symbol ist an dieser Grenze nicht eindeutig erkennbar."}`
    suggestion = noise
      ? "Rauschen deaktivieren und die beiden gleich hohen FFT-Peaks vergleichen."
      : "Offset um ±0,05 Bins verändern und die Rangfolge der FFT-Peaks vergleichen."
  } else if (wholeBin && offset !== 0) {
    title = noise
      ? "Ganzzahliger Frequenzoffset mit Rauschen"
      : "Zyklische Verschiebung des Nutzbins"
    explanation = `Der Offset verschiebt den Nutzpeak von Bin ${symbol} zyklisch auf Bin ${wrap(symbol + Math.round(offset))}. Ohne Rauschen wird deshalb dieses andere Symbol erkannt. ${noise ? "Das zusätzliche Rauschen kann die Entscheidung weiter verändern." : "Ein eindeutiges FFT-Maximum belegt daher noch keine korrekte Symbolentscheidung."}`
    suggestion =
      "Frequenzoffset auf 0 Bins zurücksetzen und die Symbolentscheidung vergleichen."
  } else if (offset !== 0) {
    title = "Spektrale Verteilung bei nichtganzzahligem Offset"
    explanation = `Der Frequenzoffset beträgt ${format(offset)} Bins, also ${format((offset * BANDWIDTH) / size)} Hz. Der dechirpte Ton liegt zwischen FFT-Bins; seine Energie verteilt sich deshalb auf mehrere Bins. ${noise ? "Rauschen überlagert diese Verteilung zusätzlich." : "Der stärkste Bin bestimmt weiterhin die Entscheidung."}`
    suggestion =
      "Ergebnisse bei 0,5 Bins und einem ganzen Bin Frequenzoffset vergleichen."
  } else if (noise) {
    title = "Symbolerkennung unter Rauscheinfluss"
    explanation = `Bei ${format(snr)} dB SNR pro Sample beträgt die mittlere Rauschleistung das ${format(10 ** (-snr / 10))}-Fache der Signalleistung. Dechirping und FFT bündeln den Signalanteil im Nutzbin ${symbol}; die Rauschbins konkurrieren mit ihm.`
    suggestion =
      "Über „Neue Rauschrealisierung“ mehrere Einzelversuche vergleichen. Anschließend das SNR variieren. Einzelversuche erlauben keine belastbare Bestimmung der statistischen Fehlerrate."
  } else {
    title = "Ideale Symbolerkennung"
    explanation = `Ohne Rauschen und Frequenzoffset wird aus dem dechirpten Symbol ein Ton genau auf FFT-Bin ${symbol}. Dort bündelt sich die Signalenergie; der Empfänger kann das Symbol eindeutig erkennen.`
    suggestion =
      "Rauschen aktivieren oder eine Versuchsvorlage laden und die Änderung des FFT-Spektrums vergleichen."
  }

  return {
    title,
    explanation,
    outcome: `Gesendetes Symbol: ${symbol}. Erkanntes Symbol: ${detected}. ${detected === symbol ? "Dieser Einzelversuch wurde korrekt erkannt." : "In diesem Einzelversuch wurde das Symbol verwechselt."} SF ${sf} verwendet ${size} mögliche Symbole und eine Symbolzeit von ${format((size / BANDWIDTH) * 1000, 3)} ms.`,
    suggestion,
  }
}
