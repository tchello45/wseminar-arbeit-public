import { spawnSync } from "node:child_process"
import { readFile, writeFile } from "node:fs/promises"
import { fileURLToPath } from "node:url"
import path from "node:path"

const frontend = fileURLToPath(new URL("../", import.meta.url))
const crate = path.resolve(frontend, "../css-wasm")
const command = process.env.WASM_PACK_BIN ?? "wasm-pack"
const build = spawnSync(
  command,
  [
    "build",
    crate,
    "--target",
    "web",
    "--scope",
    "wseminar",
    "--out-dir",
    "pkg",
    "--release",
    "--no-opt",
    "--locked",
  ],
  { stdio: "inherit" }
)
if (build.error || build.status !== 0) {
  console.error(
    "WASM-Bau fehlgeschlagen. Benötigt: Rust, wasm32-unknown-unknown und wasm-pack 0.15.1. Details: ../css-wasm/README.md"
  )
  process.exit(1)
}
const pkg = path.join(crate, "pkg")
const metadataPath = path.join(pkg, "package.json")
const metadata = JSON.parse(await readFile(metadataPath, "utf8"))
metadata.type = "module"
metadata.private = true
metadata.exports = {
  ".": { types: "./css_wasm.d.ts", import: "./css_wasm.js" },
  "./css_wasm_bg.wasm": "./css_wasm_bg.wasm",
}
await writeFile(metadataPath, JSON.stringify(metadata, null, 2) + "\n")
console.log("Rust/WASM-Paket unter css-wasm/pkg erstellt.")
