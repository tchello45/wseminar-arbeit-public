import assert from "node:assert/strict"
import { test } from "node:test"
import { spawnSync } from "node:child_process"
import { readFileSync } from "node:fs"
import { DEFAULT_PARAMETERS } from "../lib/css-model.ts"
import { simulate } from "../lib/css-wasm.ts"
import { initSync, simulate_json } from "@wseminar/css-wasm"

initSync({
  module: readFileSync(
    new URL(import.meta.resolve("@wseminar/css-wasm/css_wasm_bg.wasm"))
  ),
})
import { parseCampaign, campaigns } from "../scripts/export-data.mjs"

test("All 896 symbols at SF 7–9 are detected without disturbances", () => {
  for (const sf of [7, 8, 9])
    for (let symbol = 0; symbol < 2 ** sf; symbol++) {
      const result = simulate({ ...DEFAULT_PARAMETERS, sf, symbol })
      assert.equal(result.detected, symbol)
      assert.ok(Math.abs(result.spectrum[symbol].magnitude - 2 ** sf) < 1e-8)
    }
})
test("Integer offsets wrap cyclically; half-bin offsets split peaks", () => {
  for (const sf of [7, 8, 9])
    for (const symbol of [0, 17, 2 ** sf - 1]) {
      for (const offset of [-2, -1, 1, 2])
        assert.equal(
          simulate({ ...DEFAULT_PARAMETERS, sf, symbol, offset }).detected,
          (symbol + offset + 2 ** sf) % 2 ** sf
        )
      const result = simulate({
        ...DEFAULT_PARAMETERS,
        sf,
        symbol,
        offset: 0.5,
      })
      assert.ok(
        Math.abs(
          result.spectrum[symbol].magnitude -
            result.spectrum[(symbol + 1) % result.size].magnitude
        ) < 1e-8
      )
    }
})
test("Seeded complex noise is reproducible, has expected power, and scales with SNR", () => {
  const params = { ...DEFAULT_PARAMETERS, noise: true }
  assert.deepEqual(simulate(params), simulate(params))
  assert.notDeepEqual(
    simulate(params).received,
    simulate({ ...params, seed: params.seed + 1 }).received
  )
  const clean = simulate(DEFAULT_PARAMETERS).received
  let power = 0
  for (let seed = 1; seed <= 64; seed++) {
    const noisy = simulate({ ...params, seed }).received
    for (let i = 0; i < clean.length; i++)
      power +=
        (noisy[i].re - clean[i].re) ** 2 + (noisy[i].im - clean[i].im) ** 2
  }
  assert.ok(Math.abs(power / (64 * clean.length) / 10 ** 1.2 - 1) < 0.05)
  const loud = simulate({ ...params, snr: -18 }).received
  const quiet = simulate(params).received
  assert.ok(
    Math.abs(
      (loud[0].re - clean[0].re) / (quiet[0].re - clean[0].re) - 10 ** 0.3
    ) < 1e-10
  )
})
test("WASM boundary rejects malformed JSON and invalid model inputs", () => {
  assert.throws(() => simulate_json("{}"))
  assert.throws(() => simulate_json("not-json"))
  assert.throws(() => simulate({ ...DEFAULT_PARAMETERS, seed: -1 }))
  assert.throws(() => simulate({ ...DEFAULT_PARAMETERS, sf: 7.5 }))
  assert.throws(() => simulate({ ...DEFAULT_PARAMETERS, symbol: 128 }))
  assert.throws(() => simulate({ ...DEFAULT_PARAMETERS, offset: NaN }))
})
test("Selected samples and FFT magnitudes match the owning Python model", () => {
  const python = spawnSync(
    "../tools/.venv/bin/python",
    [
      "-c",
      `
import sys,json
sys.path.insert(0, '../tools/src')
from simulation.css import referenzchirp,erzeuge_symbol,frequenzoffset,erkenne_symbol
out=[]
for sf,m,offset in [(7,17,0),(8,255,-1),(9,17,0.5)]:
 _,chirp=referenzchirp(sf,125000)
 rx=frequenzoffset(erzeuge_symbol(chirp,m),offset)
 detected,spectrum=erkenne_symbol(rx,chirp)
 out.append(dict(sf=sf,symbol=m,offset=offset,received=[[float(v.real),float(v.imag)] for v in rx],magnitudes=abs(spectrum).tolist()))
print(json.dumps(out))
`,
    ],
    {
      encoding: "utf8",
      env: { ...process.env, MPLCONFIGDIR: "/tmp/wseminar-frontend-mpl" },
    }
  )
  assert.equal(python.status, 0, python.stderr)
  for (const ref of JSON.parse(python.stdout)) {
    const actual = simulate({
      ...DEFAULT_PARAMETERS,
      sf: ref.sf,
      symbol: ref.symbol,
      offset: ref.offset,
    })
    actual.received.forEach((value, i) => {
      assert.ok(Math.abs(value.re - ref.received[i][0]) < 1e-10)
      assert.ok(Math.abs(value.im - ref.received[i][1]) < 1e-10)
      assert.ok(
        Math.abs(actual.spectrum[i].magnitude - ref.magnitudes[i]) < 1e-8
      )
    })
  }
})
test("Exported results equal every source CSV row; malformed data fails", () => {
  const exported = JSON.parse(readFileSync("data/results.json", "utf8"))
  for (const [name, file] of Object.entries(campaigns)) {
    const source = readFileSync(`../${file}`, "utf8")
    assert.deepEqual(exported[name], parseCampaign(source, name))
    assert.throws(() => parseCampaign(source.replace("5000", "0"), name))
  }
  assert.throws(() => parseCampaign("sf,ser\n7,0", "snr"))
})

test("Experiment templates reproduce their intended physical behaviour", async () => {
  const { EXPERIMENTS } = await import("../lib/css-experiments.ts")
  const noise = simulate(
    EXPERIMENTS.find((item) => item.id === "noise")!.parameters
  )
  assert.notDeepEqual(noise.received, simulate(DEFAULT_PARAMETERS).received)
  const half = simulate(
    EXPERIMENTS.find((item) => item.id === "half-bin")!.parameters
  )
  assert.ok(
    Math.abs(half.spectrum[17].magnitude - half.spectrum[18].magnitude) < 1e-8
  )
  const full = simulate(
    EXPERIMENTS.find((item) => item.id === "full-bin")!.parameters
  )
  assert.equal(full.detected, 18)
  assert.ok(Math.abs(full.spectrum[18].magnitude - full.size) < 1e-8)
})
