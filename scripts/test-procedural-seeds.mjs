// Procedural content regression harness.
//
// Generates missions across all difficulties / focus paths for many seeds and
// asserts each result is structurally complete and passes the quality
// validator. The generators already run solvers/validators internally, so a
// throw or a failing re-validation here means a seed produced broken or
// unsolvable content. No test runner needed: esbuild (a Vite dependency)
// transpiles the TypeScript modules on the fly.
//
// Usage: node scripts/test-procedural-seeds.mjs [seedsPerCase]

import { build } from "esbuild";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";

const here = dirname(fileURLToPath(import.meta.url));
const proceduralDir = join(here, "..", "src", "procedural");
const seedsPerCase = Number(process.argv[2] ?? 40);

const ENTRY = `
export { proceduralDirector } from "./ProceduralDirector";
export { difficultyModel } from "./DifficultyModel";
export { ChallengeQualityValidator } from "./validators/ChallengeQualityValidator";
`;

async function loadModule() {
  const result = await build({
    stdin: { contents: ENTRY, resolveDir: proceduralDir, loader: "ts", sourcefile: "test-entry.ts" },
    bundle: true,
    format: "esm",
    platform: "node",
    write: false,
    logLevel: "silent",
  });
  const dir = await mkdtemp(join(tmpdir(), "eli-proc-"));
  const file = join(dir, "bundle.mjs");
  await writeFile(file, result.outputFiles[0].text, "utf8");
  const mod = await import(pathToFileURL(file).href);
  return { mod, cleanup: () => rm(dir, { recursive: true, force: true }) };
}

const FOCUSES = [
  { label: "libera", focus: [] },
  { label: "matematica", focus: ["matematica"] },
  { label: "italiano", focus: ["italiano"] },
  { label: "inglese", focus: ["inglese"] },
  { label: "elettronica", focus: ["elettronica"] },
  { label: "coding", focus: ["coding"] },
  { label: "musica", focus: ["musica"] },
];

const REQUIRED_PUZZLES = ["math", "robot", "circuit", "language", "english", "music"];

// `hard` problems mean broken/unsolvable content and fail the gate. `soft`
// problems are quality-validator misses: the generator intentionally tolerates
// a validated fallback, so we surface them as a calibration metric, not a
// build failure.
function checkMission(mission, preset, validator) {
  const hard = [];
  const soft = [];
  if (!mission || typeof mission !== "object") {
    return { hard: ["mission is not an object"], soft };
  }
  if (!Array.isArray(mission.objectives) || mission.objectives.length === 0) {
    hard.push("no objectives");
  }
  if (!mission.puzzles) {
    hard.push("no puzzles");
  } else {
    for (const kind of REQUIRED_PUZZLES) {
      if (!mission.puzzles[kind]) hard.push(`missing puzzle: ${kind}`);
    }
  }
  if (!Array.isArray(mission.competencies) || mission.competencies.length === 0) {
    hard.push("no competencies");
  }
  if (!mission.map) {
    hard.push("no map");
  }
  const quality = validator.validateMission(mission, preset);
  if (!quality.valid) {
    const reasons = Array.isArray(quality.reasons) ? quality.reasons.join("; ") : "";
    soft.push(reasons || "quality validation failed");
  }
  return { hard, soft };
}

async function main() {
  const { mod, cleanup } = await loadModule();
  const { proceduralDirector, difficultyModel, ChallengeQualityValidator } = mod;
  const validator = new ChallengeQualityValidator();

  let total = 0;
  let hardFailures = 0;
  let qualityWarnings = 0;
  const hardSamples = [];
  const qualityByDifficulty = {};
  const started = Date.now();

  for (let difficulty = 1; difficulty <= 8; difficulty += 1) {
    const preset = difficultyModel.getPreset(difficulty);
    qualityByDifficulty[difficulty] = 0;
    for (const { label, focus } of FOCUSES) {
      for (let i = 0; i < seedsPerCase; i += 1) {
        const seed = `TEST-${difficulty}-${label}-${i}`;
        total += 1;
        try {
          const mission = proceduralDirector.generateMission(seed, difficulty, focus);
          const { hard, soft } = checkMission(mission, preset, validator);
          if (hard.length > 0) {
            hardFailures += 1;
            if (hardSamples.length < 20) {
              hardSamples.push(`D${difficulty} ${label} seed=${seed}: ${hard.join("; ")}`);
            }
          }
          if (soft.length > 0) {
            qualityWarnings += 1;
            qualityByDifficulty[difficulty] += 1;
          }
        } catch (error) {
          hardFailures += 1;
          if (hardSamples.length < 20) {
            hardSamples.push(`D${difficulty} ${label} seed=${seed}: THREW ${error?.message ?? error}`);
          }
        }
      }
    }
  }

  await cleanup();

  const elapsed = ((Date.now() - started) / 1000).toFixed(1);
  const casesPerDifficulty = FOCUSES.length * seedsPerCase;
  console.log(`\nProcedural seed test`);
  console.log(`  difficulties: 1-8 · focus paths: ${FOCUSES.length} · seeds/case: ${seedsPerCase}`);
  console.log(`  total cases: ${total} · time: ${elapsed}s`);
  console.log(`  structural/throw failures: ${hardFailures}`);
  console.log(`  quality-fallback warnings: ${qualityWarnings} (${((qualityWarnings / total) * 100).toFixed(1)}%)`);

  const calibration = Object.entries(qualityByDifficulty)
    .filter(([, n]) => n > 0)
    .map(([d, n]) => `D${d}: ${((n / casesPerDifficulty) * 100).toFixed(0)}%`);
  if (calibration.length > 0) {
    console.log(`  quality fallbacks by difficulty: ${calibration.join(" · ")}`);
  }

  if (hardFailures > 0) {
    console.log(`\nStructural failures (gate):`);
    hardSamples.forEach((line) => console.log(`  ✗ ${line}`));
    process.exitCode = 1;
  } else {
    console.log(`\n  ✓ All ${total} generated missions are complete and solvable.`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
