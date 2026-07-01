import { it } from "vitest";
import { LanguageCorruptionGenerator } from "../generators/LanguageCorruptionGenerator";
import { Random } from "../Random";

const gen = new LanguageCorruptionGenerator();

function show(type: "agreement-sprint" | "verb-mastery", seeds: string[], level: number): void {
  console.log(`\n===== ${type} (L${level}) =====`);
  for (const s of seeds) {
    const p = gen.generateMinigame(new Random(s), level as never, [type]).minigame?.prompts?.[0];
    if (!p) continue;
    const correct = p.tiles.find((t) => t.isCorrect)?.label;
    console.log(`\nContesto: ${p.context}`);
    console.log(`✓ ${correct}`);
    for (const t of p.tiles.filter((x) => !x.isCorrect)) {
      console.log(`✗ ${t.label}  →  ${t.feedback}`);
    }
  }
}

it("sample diagnostics", () => {
  show("agreement-sprint", ["s1", "s2", "s3"], 2);
  show("agreement-sprint", ["s7", "s8"], 6);
  show("verb-mastery", ["v1", "v2", "v3"], 2);
});
