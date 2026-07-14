import { getProceduralFocusPath, proceduralFocusChallengeCount } from "../data/procedural/focusPaths";
import { MapGenerator } from "./MapGenerator";
import { PuzzleGenerator } from "./PuzzleGenerator";
import type { DifficultyPreset, GeneratedMission } from "./ProceduralTypes";
import { Random } from "./Random";
import { ValidationEngine } from "./ValidationEngine";
import { ChallengeQualityValidator } from "./validators/ChallengeQualityValidator";
import { MapValidator } from "./validators/MapValidator";

export class MissionGenerator {
  private validationEngine = new ValidationEngine();
  private puzzleGenerator = new PuzzleGenerator(this.validationEngine);
  private mapGenerator = new MapGenerator();
  private mapValidator = new MapValidator();
  private qualityValidator = new ChallengeQualityValidator();

  generate(seed: string, random: Random, difficulty: DifficultyPreset, focus: string[]): GeneratedMission {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const candidate = this.buildMission(seed, random.fork(`mission-${attempt}`), difficulty, focus);
      if (this.qualityValidator.validateMission(candidate, difficulty).valid) {
        return candidate;
      }
    }
    return this.buildMission(seed, new Random(`${seed}:quality-fallback`), difficulty, focus);
  }

  private buildMission(seed: string, random: Random, difficulty: DifficultyPreset, focus: string[]): GeneratedMission {
    const path = getProceduralFocusPath(focus);
    const puzzles = this.puzzleGenerator.generate(random.fork("puzzles"), difficulty, focus);
    const focusStages = path.primaryPuzzle
      ? path.challengeStages.slice(0, proceduralFocusChallengeCount(difficulty.level))
      : [];
    const focusChallenges = path.primaryPuzzle
      ? this.puzzleGenerator.generateFocusChallenges(random.fork("focus-series"), difficulty, focus, path.primaryPuzzle, focusStages)
      : undefined;
    const map = this.validationEngine.generateWithRetries(
      () => this.mapGenerator.generate(random.fork("map"), difficulty, focus),
      (candidate) => this.mapValidator.validate(candidate),
      () => this.mapGenerator.generate(random.fork("fallback-map"), difficulty, focus),
    );
    const competencies = Array.from(
      new Set([
        ...focus,
        ...(focusChallenges
          ? focusChallenges.flatMap((challenge) => challenge.puzzle.competencies)
          : [
              ...puzzles.math.competencies,
              ...puzzles.robot.competencies,
              ...puzzles.circuit.competencies,
              ...puzzles.language.competencies,
              ...puzzles.english.competencies,
              ...puzzles.coding.competencies,
              ...puzzles.music.competencies,
              ...puzzles.physics.competencies,
              ...puzzles.latin.competencies,
            ]),
      ]),
    );

    return {
      id: `mission-procedural-${path.id}`,
      seed,
      difficulty: difficulty.level,
      title: path.title,
      intro: `${random.pick(path.introFragments)} ${this.focusLine(focus)}`,
      objectives: focusChallenges ? focusChallenges.map((challenge) => ({
        id: `procedural-${challenge.id}`,
        label: challenge.title,
        description: challenge.description,
        competencies: challenge.puzzle.competencies,
      })) : [
        {
          id: "procedural-language",
          label: path.objectives.language.label,
          description: path.objectives.language.description,
          competencies: puzzles.language.competencies,
        },
        {
          id: "procedural-circuit",
          label: path.objectives.circuit.label,
          description: path.objectives.circuit.description,
          competencies: puzzles.circuit.competencies,
        },
        {
          id: "procedural-math",
          label: path.objectives.math.label,
          description: path.objectives.math.description,
          competencies: puzzles.math.competencies,
        },
        {
          id: "procedural-english",
          label: path.objectives.english.label,
          description: path.objectives.english.description,
          competencies: puzzles.english.competencies,
        },
        {
          id: "procedural-robot",
          label: path.objectives.robot.label,
          description: path.objectives.robot.description,
          competencies: puzzles.robot.competencies,
        },
        {
          id: "procedural-coding",
          label: path.objectives.coding?.label ?? "Verifica l'algoritmo",
          description: path.objectives.coding?.description ?? "Segui variabili, condizioni e bug con metodo.",
          competencies: puzzles.coding.competencies,
        },
        {
          id: "procedural-music",
          label: path.objectives.music.label,
          description: path.objectives.music.description,
          competencies: puzzles.music.competencies,
        },
        {
          id: "procedural-physics",
          label: path.objectives.physics?.label ?? "Leggi il fenomeno",
          description: path.objectives.physics?.description ?? "Collega grandezze, unità, dati e modello fisico.",
          competencies: puzzles.physics.competencies,
        },
        {
          id: "procedural-latin",
          label: path.objectives.latin?.label ?? "Analizza la forma latina",
          description: path.objectives.latin?.description ?? "Riconosci desinenza, caso, numero, tempo e funzione.",
          competencies: puzzles.latin.competencies,
        },
      ],
      map,
      puzzles,
      focusChallenges,
      rewards: [
        path.badge,
        {
          badgeId: "custode-del-seed",
          label: "Custode del Seed",
          description: "Sa riprodurre una missione usando il seed.",
        },
      ],
      competencies,
    };
  }

  private focusLine(focus: string[]): string {
    const label = this.focusLabel(focus);
    if (label === "libera") {
      return "Puoi iniziare da qualunque console: la porta finale controllerà il sistema completo.";
    }
    return `Calibrazione attiva: ${label}. Le console generate appartengono a questo settore e misurano tempo, precisione e uso degli aiuti.`;
  }

  private focusLabel(focus: string[]): string {
    if (focus.includes("matematica")) return "matematica";
    if (focus.includes("italiano")) return "italiano";
    if (focus.includes("inglese")) return "inglese";
    if (focus.includes("elettronica")) return "elettronica";
    if (focus.includes("coding")) return "coding";
    if (focus.includes("musica")) return "musica";
    if (focus.includes("fisica")) return "fisica";
    if (focus.includes("latino")) return "latino";
    return "libera";
  }
}
