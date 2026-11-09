import { readFile, writeFile, copyFile, mkdir } from "node:fs/promises"
import { fileURLToPath } from "node:url"
import path from "node:path"
import { initSync, simulate_json } from "@wseminar/css-wasm"
import { DEFAULT_PARAMETERS } from "../lib/css-model.ts"

const frontend = fileURLToPath(new URL("../", import.meta.url))
const binary = new URL(import.meta.resolve("@wseminar/css-wasm/css_wasm_bg.wasm"))

await mkdir(path.join(frontend, "public/wasm"), { recursive: true })
await copyFile(binary, path.join(frontend, "public/wasm/css_wasm_bg.wasm"))

// Use the installed package for both the browser binary and the static preview.
initSync({ module: await readFile(binary) })
await mkdir(path.join(frontend, "data"), { recursive: true })
await writeFile(
  path.join(frontend, "data/reference-symbol.json"),
  simulate_json(JSON.stringify(DEFAULT_PARAMETERS)) + "\n"
)
console.log("Installiertes WASM-Paket und statisches Referenzsymbol vorbereitet.")
