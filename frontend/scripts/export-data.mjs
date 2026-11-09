import { readFile, mkdir, copyFile, writeFile } from "node:fs/promises"
import { createHash } from "node:crypto"
import { fileURLToPath } from "node:url"
import path from "node:path"

const frontend = fileURLToPath(new URL("../", import.meta.url))
const root = path.resolve(frontend, "..")
export const campaigns = {
  snr: "tools/src/simulation/ergebnisse/css-awgn.csv",
  energy: "tools/src/simulation/ergebnisse/css-awgn-energy.csv",
  offset: "tools/src/simulation/ergebnisse/css-offset-awgn.csv",
}
export function parseCampaign(text, name) {
  const [header, ...lines] = text.trim().split(/\r?\n/)
  const columns = header.split(",")
  const required = [
    "sf",
    "bandwidth_hz",
    "snr_per_sample_db",
    "es_n0_db",
    "trials",
    "errors",
    "ser",
    "wilson95_lower",
    "wilson95_upper",
  ]
  if (name === "offset") required.push("delta", "frequency_offset_hz")
  if (
    required.some((key) => !columns.includes(key)) ||
    new Set(columns).size !== columns.length
  )
    throw new Error(`${name}: CSV-Spalten fehlen oder sind doppelt.`)
  const rows = lines.map((line, index) => {
    const cells = line.split(",")
    if (
      cells.length !== columns.length ||
      cells.some((cell) => !cell.trim() || !Number.isFinite(Number(cell)))
    )
      throw new Error(`${name}: Ungültige CSV-Zeile ${index + 2}.`)
    const row = Object.fromEntries(
      columns.map((key, i) => [key, Number(cells[i])])
    )
    if (
      ![7, 8, 9].includes(row.sf) ||
      row.bandwidth_hz !== 125000 ||
      !Number.isInteger(row.trials) ||
      row.trials <= 0 ||
      !Number.isInteger(row.errors) ||
      row.errors < 0 ||
      row.errors > row.trials ||
      Math.abs(row.ser - row.errors / row.trials) > 1e-12 ||
      row.wilson95_lower < 0 ||
      row.wilson95_upper > 1 ||
      row.wilson95_lower > row.ser + 1e-12 ||
      row.wilson95_upper < row.ser - 1e-12
    )
      throw new Error(
        `${name}: Inkonsistente Versuchswerte in Zeile ${index + 2}.`
      )
    return row
  })
  const key =
    name === "offset"
      ? "delta"
      : name === "energy"
        ? "es_n0_db"
        : "snr_per_sample_db"
  const keys = rows.map(
    (row) => `${row.sf}:${row[key]}:${name === "offset" ? row.es_n0_db : ""}`
  )
  if (
    !rows.length ||
    new Set(keys).size !== rows.length ||
    [7, 8, 9].some((sf) => !rows.some((row) => row.sf === sf))
  )
    throw new Error(`${name}: Leere, doppelte oder unvollständige Messreihe.`)
  return rows
}

export async function exportData() {
  const result = {}
  const sources = []
  // Read and validate all inputs before writing any output.
  for (const [name, source] of Object.entries(campaigns)) {
    const text = await readFile(path.join(root, source), "utf8")
    result[name] = parseCampaign(text, name)
    sources.push({
      source,
      sha256: createHash("sha256").update(text).digest("hex"),
    })
  }
  const assets = [
    "nanovna-aufbau.svg",
    "nanovna-standards.svg",
    "nanovna-kabel.svg",
    "pcb-ifa-prinzip.svg",
  ]
  const copies = assets.map((name) => [
    `arbeit/abbildungen/${name}`,
    `public/media/${name}`,
  ])
  copies.push(["arbeit.pdf", "public/arbeit.pdf"])
  for (const [source] of copies) {
    const bytes = await readFile(path.join(root, source))
    if (
      !bytes.length ||
      (source.endsWith(".pdf") && bytes.subarray(0, 5).toString() !== "%PDF-")
    )
      throw new Error(`Ungültige Datei: ${source}`)
    sources.push({
      source,
      sha256: createHash("sha256").update(bytes).digest("hex"),
    })
  }
  await mkdir(path.join(frontend, "public/media"), { recursive: true })
  await mkdir(path.join(frontend, "data"), { recursive: true })
  for (const [source, target] of copies)
    await copyFile(path.join(root, source), path.join(frontend, target))
  await writeFile(
    path.join(frontend, "data/results.json"),
    JSON.stringify(result, null, 2) + "\n"
  )
  await writeFile(
    path.join(frontend, "public/media/sources.json"),
    JSON.stringify(sources, null, 2) + "\n"
  )
  console.log(
    `Export: ${Object.values(result).flat().length} Versuchspunkte, ${copies.length} Dateien; Quellen geprüft.`
  )
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  exportData().catch((error) => {
    console.error(`Frontend-Datenexport fehlgeschlagen: ${error.message}`)
    process.exitCode = 1
  })
}
