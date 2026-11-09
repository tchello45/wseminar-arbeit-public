/** UI parameters and transfer types. All numerical simulation runs in css-wasm. */
export const BANDWIDTH = 125_000
export const INITIAL_SEED = 20261103
export type LabParameters = {
  sf: number
  symbol: number
  noise: boolean
  snr: number
  offset: number
  seed: number
}
export const DEFAULT_PARAMETERS: LabParameters = {
  sf: 7,
  symbol: 17,
  noise: false,
  snr: -12,
  offset: 0,
  seed: INITIAL_SEED,
}
export type Complex = { re: number; im: number }
export type SimulationResult = {
  samples: {
    time: number
    frequency: number
    received: number
    dechirped: number
  }[]
  spectrum: { bin: number; magnitude: number }[]
  detected: number
  received: Complex[]
  dechirped: Complex[]
  size: number
  duration: number
  binWidth: number
}
