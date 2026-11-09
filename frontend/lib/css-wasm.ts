import init, { simulate_json } from "@wseminar/css-wasm"
import type { LabParameters, SimulationResult } from "./css-model.ts"

let initialization: Promise<unknown> | undefined

/** One instance per browser module; a failed request can be retried explicitly. */
export function loadCssWasm() {
  initialization ??= init({ module_or_path: "/wasm/css_wasm_bg.wasm" }).catch(
    (error: unknown) => {
      initialization = undefined
      throw error
    }
  )
  return initialization
}

/** Transport adapter only: validation and all sample/FFT computation live in Rust. */
export function simulate(parameters: LabParameters): SimulationResult {
  return JSON.parse(
    simulate_json(JSON.stringify(parameters))
  ) as SimulationResult
}
