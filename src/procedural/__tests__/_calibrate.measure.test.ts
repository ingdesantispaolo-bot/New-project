import { describe, it } from "vitest";
import { difficultyPresets } from "../../data/procedural/difficultyPresets";
import { PuzzleGenerator } from "../PuzzleGenerator";
import { ValidationEngine } from "../ValidationEngine";
import { ChallengeQualityValidator } from "../validators/ChallengeQualityValidator";
import { Random } from "../Random";

const FOCUSES = ["libera", "matematica", "italiano", "inglese", "elettronica", "coding", "musica", "fisica"];
const N = 120;

describe("calibrate D1-D4 fallback measure", () => {
  it("measures fallback rate and failure reasons", () => {
    const ve = new ValidationEngine();
    const pg = new PuzzleGenerator(ve);
    const qv = new ChallengeQualityValidator();

    for (let level = 1; level <= 4; level += 1) {
      const preset = difficultyPresets[level - 1];
      let totalSeeds = 0;
      let fallbacks = 0;
      const perGenFail: Record<string, number> = {};
      const reasonCount: Record<string, number> = {};
      let attempt0Checks = 0;

      for (const focus of FOCUSES) {
        for (let s = 0; s < N; s += 1) {
          const top = new Random(`cal:${level}:${focus}:${s}`);
          totalSeeds += 1;
          // attempt-0 per-generator breakdown
          const p0 = pg.generate(top.fork("mission-0").fork("puzzles"), preset, [focus]);
          attempt0Checks += 1;
          const perType: Array<[string, () => { reasons: string[] }]> = [
            ["math", () => qv.validateMath(p0.math, preset)],
            ["robot", () => qv.validateRobot(p0.robot, preset)],
            ["circuit", () => qv.validateCircuit(p0.circuit, preset)],
            ["coding", () => qv.validateCoding(p0.coding)],
            ["language", () => qv.validateLanguage(p0.language)],
            ["english", () => qv.validateEnglish(p0.english)],
            ["music", () => qv.validateMusic(p0.music)],
            ["physics", () => qv.validatePhysics(p0.physics)],
          ];
          for (const [name, fn] of perType) {
            const r = fn();
            if (r.reasons.length > 0) {
              perGenFail[name] = (perGenFail[name] ?? 0) + 1;
              for (const reason of r.reasons) reasonCount[reason] = (reasonCount[reason] ?? 0) + 1;
            }
          }
          // full 12-attempt loop -> fallback?
          let ok = false;
          for (let a = 0; a < 12; a += 1) {
            const puzzles = pg.generate(top.fork(`mission-${a}`).fork("puzzles"), preset, [focus]);
            if (qv.validateMission({ puzzles } as never, preset).valid) { ok = true; break; }
          }
          if (!ok) fallbacks += 1;
        }
      }

      const topReasons = Object.entries(reasonCount).sort((a, b) => b[1] - a[1]).slice(0, 10);
      const genRates = Object.entries(perGenFail).sort((a, b) => b[1] - a[1])
        .map(([k, v]) => `${k}:${((v / attempt0Checks) * 100).toFixed(1)}%`);
      // eslint-disable-next-line no-console
      console.log(`\n===== D${level} ===== seeds=${totalSeeds} fallback=${((fallbacks / totalSeeds) * 100).toFixed(1)}% (${fallbacks})`);
      // eslint-disable-next-line no-console
      console.log(`  attempt-0 per-generator fail rate: ${genRates.join("  ")}`);
      // eslint-disable-next-line no-console
      console.log(`  top reasons:`);
      for (const [reason, count] of topReasons) {
        // eslint-disable-next-line no-console
        console.log(`    ${count}\t${reason}`);
      }
    }
  }, 120_000);
});
