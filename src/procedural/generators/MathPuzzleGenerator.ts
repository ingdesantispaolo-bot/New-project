import { mathTemplates } from "../../data/procedural/mathTemplates";
import type { DifficultyPreset, GeneratedMathPuzzle } from "../ProceduralTypes";
import type { Random } from "../Random";

export class MathPuzzleGenerator {
  generate(random: Random, difficulty: DifficultyPreset, preferredArchetypes: Array<(typeof mathTemplates)[number]["archetype"]> = []): GeneratedMathPuzzle {
    const eligibleTemplates = mathTemplates.filter((template) => template.minComplexity <= difficulty.mathComplexity);
    const floor = Math.max(1, difficulty.mathComplexity - 2);
    const focusedTemplates = eligibleTemplates.filter((template) => template.minComplexity >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates;
    const preferredPool = preferredArchetypes.length > 0
      ? (eligibleTemplates.length > 0 ? eligibleTemplates : mathTemplates).filter((template) => preferredArchetypes.includes(template.archetype))
      : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const base = 4 + difficulty.mathComplexity * 2;
    const a = random.integer(base, base + 8);
    const b = random.integer(3, 6 + difficulty.mathComplexity * 2);
    const c = random.integer(2, 4 + difficulty.mathComplexity);
    const built = template.build(a, b, c);
    return {
      id: `math-${template.id}`,
      title: template.title,
      prompt: `Situazione: ${template.narrative}\nRichiesta: ${built.prompt}`,
      answer: built.answer,
      hints: built.hints,
      archetype: template.archetype,
      curriculumTags: template.curriculumTags ?? [],
      solutionSteps: built.steps ?? [
        `Identifica i dati: ${a}, ${b}, ${c}.`,
        ...built.hints.map((hint) => hint.replace(/\.$/, "")),
        `Valore finale certificato: ${built.answer}.`,
      ],
      competencies: Array.from(new Set([...(template.competencies ?? ["matematica.calcolo", "matematica.logica"]), "problemSolving"])),
    };
  }

  fallback(): GeneratedMathPuzzle {
    return {
      id: "math-fallback",
      title: "Serratura stabile",
      prompt: "Il codice è il triplo di 8, meno 5.",
      answer: 19,
      hints: ["Triplo di 8 significa 8 x 3.", "Dopo il triplo togli 5."],
      archetype: "calcolo-diretto",
      curriculumTags: ["calcolo mentale", "ordine delle operazioni"],
      solutionSteps: ["8 x 3 = 24", "24 - 5 = 19"],
      competencies: ["matematica.calcolo", "matematica.logica"],
    };
  }
}
