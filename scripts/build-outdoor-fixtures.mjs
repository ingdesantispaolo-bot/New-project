// Genera la fixture di parità del mondo esterno dal generatore *reale*
// (src/procedural/OutdoorChunkGenerator.ts) verso godot/data/parity-fixtures.json.
//
// La fixture è il contratto condiviso tra TypeScript (Phaser) e GDScript
// (Godot): entrambi i generatori devono riprodurre esattamente questi valori.
// - Il test Vitest (outdoorGeneratorFixture.test.ts) verifica che il generatore
//   TS riproduca la fixture.
// - Lo script Godot fixture_audit.gd la ricarica e verifica il lato GDScript.
//
// Non serve un test runner: esbuild (dipendenza di Vite) transpila il TS al volo.
//
// Uso: node scripts/build-outdoor-fixtures.mjs

import { build } from "esbuild";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";

const here = dirname(fileURLToPath(import.meta.url));
const proceduralDir = join(here, "..", "src", "procedural");
const outFile = join(here, "..", "godot", "data", "parity-fixtures.json");

// Casi di parità: includono l'origine, vicini positivi/negativi e alcuni chunk
// lontani per coprire biomi non ancorati e scaling della difficoltà.
const CASES = [
  { seed: "outdoor-parity-01", x: 0, y: 0 },
  { seed: "outdoor-parity-01", x: 1, y: 0 },
  { seed: "outdoor-parity-01", x: 0, y: 1 },
  { seed: "outdoor-parity-01", x: -1, y: -1 },
  { seed: "outdoor-parity-01", x: 1, y: 1 },
  { seed: "outdoor-parity-01", x: -1, y: 0 },
  { seed: "outdoor-parity-01", x: 3, y: -2 },
  { seed: "outdoor-parity-01", x: -3, y: 2 },
  { seed: "outdoor-2026-07-19-1", x: 0, y: 0 },
  { seed: "outdoor-2026-07-19-1", x: 2, y: 2 },
];

async function loadModule() {
  const result = await build({
    entryPoints: [join(proceduralDir, "OutdoorChunkGenerator.ts")],
    bundle: true,
    format: "esm",
    platform: "node",
    write: false,
    logLevel: "silent",
  });
  const dir = await mkdtemp(join(tmpdir(), "eli-outdoor-fixtures-"));
  const file = join(dir, "bundle.mjs");
  await writeFile(file, result.outputFiles[0].text, "utf8");
  const mod = await import(pathToFileURL(file).href);
  await rm(dir, { recursive: true, force: true });
  return mod;
}

const { generateOutdoorChunk, OUTDOOR_CHUNK_SIZE } = await loadModule();

const cases = CASES.map(({ seed, x, y }) => ({
  seed,
  chunkX: x,
  chunkY: y,
  chunk: generateOutdoorChunk(seed, x, y),
}));

const fixture = {
  schemaVersion: 2,
  generator: "outdoor-chunk",
  chunkSize: OUTDOOR_CHUNK_SIZE,
  seedFormat: "<seed>:chunk:<chunkX>:<chunkY>",
  cases,
};

await writeFile(outFile, JSON.stringify(fixture, null, "\t") + "\n", "utf8");
console.log(`Scritte ${cases.length} fixture di parità in ${outFile}`);
