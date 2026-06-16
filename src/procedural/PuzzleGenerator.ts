import { CircuitFaultGenerator } from "./generators/CircuitFaultGenerator";
import { EnglishInstructionGenerator } from "./generators/EnglishInstructionGenerator";
import { LanguageCorruptionGenerator } from "./generators/LanguageCorruptionGenerator";
import { MathPuzzleGenerator } from "./generators/MathPuzzleGenerator";
import { RobotGridGenerator } from "./generators/RobotGridGenerator";
import { exerciseDirector } from "../core/ExerciseDirector";
import type { DifficultyPreset, GeneratedFocusChallenge, GeneratedMission, ProceduralPuzzleKind, RobotChallengeType } from "./ProceduralTypes";
import type { Random } from "./Random";
import { ValidationEngine } from "./ValidationEngine";
import { CircuitPuzzleValidator } from "./validators/CircuitPuzzleValidator";
import { LanguagePuzzleValidator } from "./validators/LanguagePuzzleValidator";
import { MathPuzzleValidator } from "./validators/MathPuzzleValidator";
import { RobotPuzzleValidator } from "./validators/RobotPuzzleValidator";

export class PuzzleGenerator {
  private mathGenerator = new MathPuzzleGenerator();
  private robotGenerator = new RobotGridGenerator();
  private circuitGenerator = new CircuitFaultGenerator();
  private languageGenerator = new LanguageCorruptionGenerator();
  private englishGenerator = new EnglishInstructionGenerator();
  private mathValidator = new MathPuzzleValidator();
  private robotValidator = new RobotPuzzleValidator();
  private circuitValidator = new CircuitPuzzleValidator();
  private languageValidator = new LanguagePuzzleValidator();

  constructor(private validationEngine: ValidationEngine) {}

  generate(random: Random, difficulty: DifficultyPreset, focus: string[] = []): GeneratedMission["puzzles"] {
    const mathRandom = random.fork("math");
    const robotRandom = random.fork("robot");
    const circuitRandom = random.fork("circuit");
    const languageRandom = random.fork("language");
    const englishRandom = random.fork("english");
    const mathDifficulty = this.boostForFocus(difficulty, focus, "matematica");
    const robotDifficulty = this.boostForFocus(difficulty, focus, "coding");
    const circuitDifficulty = this.boostForFocus(difficulty, focus, "elettronica");
    const languageLevel = this.levelForFocus(difficulty.level, focus, "italiano");
    const englishLevel = this.levelForFocus(difficulty.level, focus, "inglese");

    const math = this.validationEngine.generateWithRetries(
        () => this.mathGenerator.generate(mathRandom, mathDifficulty),
        (puzzle) => this.mathValidator.validate(puzzle),
        this.mathGenerator.fallback(),
      );
    const robot = this.validationEngine.generateWithRetries(
        () => this.robotGenerator.generate(robotRandom, robotDifficulty),
        (puzzle) => this.robotValidator.validate(puzzle),
        this.robotGenerator.fallback(),
      );
    const circuit = this.validationEngine.generateWithRetries(
        () => this.circuitGenerator.generate(circuitRandom, circuitDifficulty),
        (puzzle) => this.circuitValidator.validate(puzzle),
        this.circuitGenerator.fallback(),
      );

    return {
      math: exerciseDirector.enrichMath(math, mathDifficulty.level),
      robot: exerciseDirector.enrichRobot(robot, robotDifficulty.level),
      circuit: exerciseDirector.enrichCircuit(circuit, circuitDifficulty.level),
      language: this.validationEngine.generateWithRetries(
        () => this.languageGenerator.generate(languageRandom, languageLevel),
        (puzzle) => this.languageValidator.validateItalian(puzzle),
        this.languageGenerator.fallback(),
      ),
      english: this.validationEngine.generateWithRetries(
        () => this.englishGenerator.generate(englishRandom, englishLevel),
        (puzzle) => this.languageValidator.validateEnglish(puzzle),
        this.englishGenerator.fallback(),
      ),
    };
  }

  generateFocusChallenges(
    random: Random,
    difficulty: DifficultyPreset,
    focus: string[],
    kind: ProceduralPuzzleKind,
    stages: Array<{ label: string; description: string }>,
  ): GeneratedFocusChallenge[] {
    return stages.map((stage, index) => {
      const stagedDifficulty = this.escalateDifficulty(this.boostForFocus(difficulty, focus, this.domainForKind(kind)), index);
      const challengeRandom = random.fork(`${kind}-${index + 1}`);
      const id = `${kind}-${index + 1}`;
      if (kind === "math") {
        const puzzle = this.validationEngine.generateWithRetries(
          () => this.mathGenerator.generate(challengeRandom, stagedDifficulty, this.mathArchetypesForStep(index)),
          (candidate) => this.mathValidator.validate(candidate),
          this.mathGenerator.fallback(),
        );
        return {
          id,
          kind,
          title: stage.label,
          description: stage.description,
          difficultyStep: index + 1,
          puzzle: exerciseDirector.enrichMath(puzzle, stagedDifficulty.level),
        };
      }
      if (kind === "language") {
        const puzzle = this.validationEngine.generateWithRetries(
          () => this.languageGenerator.generate(challengeRandom, stagedDifficulty.level, this.languageTemplatesForStep(index)),
          (candidate) => this.languageValidator.validateItalian(candidate),
          this.languageGenerator.fallback(),
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "english") {
        const puzzle = this.validationEngine.generateWithRetries(
          () => this.englishGenerator.generate(challengeRandom, stagedDifficulty.level, this.englishTemplatesForStep(index)),
          (candidate) => this.languageValidator.validateEnglish(candidate),
          this.englishGenerator.fallback(),
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "circuit") {
        const puzzle = this.validationEngine.generateWithRetries(
          () => this.circuitGenerator.generate(challengeRandom, stagedDifficulty, this.circuitFaultsForStep(index)),
          (candidate) => this.circuitValidator.validate(candidate),
          this.circuitGenerator.fallback(),
        );
        return {
          id,
          kind,
          title: stage.label,
          description: stage.description,
          difficultyStep: index + 1,
          puzzle: exerciseDirector.enrichCircuit(puzzle, stagedDifficulty.level),
        };
      }
      const puzzle = this.validationEngine.generateWithRetries(
        () => this.robotGenerator.generate(challengeRandom, stagedDifficulty, this.robotChallengeTypeForStep(index)),
        (candidate) => this.robotValidator.validate(candidate),
        this.robotGenerator.fallback(this.robotChallengeTypeForStep(index)),
      );
      return {
        id,
        kind,
        title: stage.label,
        description: stage.description,
        difficultyStep: index + 1,
        puzzle: exerciseDirector.enrichRobot(puzzle, stagedDifficulty.level),
      };
    });
  }

  private boostForFocus(difficulty: DifficultyPreset, focus: string[], domain: string): DifficultyPreset {
    if (!this.hasFocus(focus, domain)) {
      return difficulty;
    }
    const boostedLevel = Math.min(8, difficulty.level + 1) as DifficultyPreset["level"];
    return {
      ...difficulty,
      level: boostedLevel,
      mathComplexity: domain === "matematica" ? Math.min(8, difficulty.mathComplexity + 2) : difficulty.mathComplexity,
      robotGrid: domain === "coding"
        ? { cols: Math.min(9, difficulty.robotGrid.cols + 1), rows: difficulty.robotGrid.rows }
        : difficulty.robotGrid,
      robotObstacleCount: domain === "coding" ? difficulty.robotObstacleCount + 2 : difficulty.robotObstacleCount,
      circuitComplexity: domain === "elettronica" ? Math.min(8, difficulty.circuitComplexity + 2) : difficulty.circuitComplexity,
      requiredReasoningSteps: Math.min(5, difficulty.requiredReasoningSteps + 1),
      noiseDataCount: Math.min(4, difficulty.noiseDataCount + 1),
    };
  }

  private levelForFocus(level: DifficultyPreset["level"], focus: string[], domain: string): DifficultyPreset["level"] {
    return this.hasFocus(focus, domain) ? Math.min(8, level + 2) as DifficultyPreset["level"] : level;
  }

  private hasFocus(focus: string[], domain: string): boolean {
    return focus.includes(domain) || focus.some((item) => item.startsWith(`${domain}.`));
  }

  private escalateDifficulty(difficulty: DifficultyPreset, step: number): DifficultyPreset {
    return {
      ...difficulty,
      level: Math.min(8, difficulty.level + step) as DifficultyPreset["level"],
      mathComplexity: Math.min(8, difficulty.mathComplexity + step),
      robotGrid: {
        cols: Math.min(9, difficulty.robotGrid.cols + Math.floor((step + 1) / 2)),
        rows: Math.min(7, difficulty.robotGrid.rows + Math.floor(step / 2)),
      },
      robotObstacleCount: difficulty.robotObstacleCount + step * 2,
      circuitComplexity: Math.min(8, difficulty.circuitComplexity + step),
      requiredReasoningSteps: Math.min(5, difficulty.requiredReasoningSteps + Math.ceil(step / 2)),
      noiseDataCount: Math.min(4, difficulty.noiseDataCount + Math.floor(step / 2)),
    };
  }

  private domainForKind(kind: ProceduralPuzzleKind): string {
    return {
      language: "italiano",
      circuit: "elettronica",
      math: "matematica",
      english: "inglese",
      robot: "coding",
    }[kind];
  }

  private mathArchetypesForStep(step: number): Array<NonNullable<GeneratedMission["puzzles"]["math"]["archetype"]>> {
    return [
      ["calcolo-diretto", "frazioni", "percentuali", "lettura-dati"],
      ["sequenza", "statistica", "coordinate", "lettura-dati", "vincolo"],
      ["vincolo", "proporzione", "geometria", "probabilita", "percentuali", "frazioni"],
      ["ragionamento-inverso", "pre-algebra", "equazione-primo-grado", "funzione-lineare", "coordinate", "statistica"],
      ["diagnosi-errore", "potenze-radici", "geometria", "sistemi-lineari", "probabilita", "equazione-primo-grado", "funzione-lineare", "proporzione"],
    ][Math.min(step, 4)] as Array<NonNullable<GeneratedMission["puzzles"]["math"]["archetype"]>>;
  }

  private robotChallengeTypeForStep(step: number): RobotChallengeType {
    return [
      "route-planning",
      "checkpoint-order",
      "minimal-route",
      "debug-program",
      "pattern-routing",
    ][Math.min(step, 4)] as RobotChallengeType;
  }

  private languageTemplatesForStep(step: number): string[] {
    return [
      ["single-generator", "north-sensor", "sealed-door", "unstable-log", "apostrophe-accent", "ha-a-control"],
      ["cause-effect-cooling", "useful-vs-noise", "sequence-before-after", "direct-indirect-pronouns", "concessive-although"],
      ["pronoun-reference", "robot-report", "relative-clause", "relative-cui", "punctuation-safety"],
      ["conditional-alert", "technical-summary", "source-reliability", "passive-active", "reported-speech-log", "main-idea-summary"],
      ["lexical-precision", "nominalization-precision", "thesis-evidence", "register-formal", "period-hypothesis", "implicit-subject"],
    ][Math.min(step, 4)];
  }

  private englishTemplatesForStep(step: number): string[] {
    return [
      ["green-not-red", "small-key", "main-switch", "where-is-core", "who-can-open"],
      ["left-before-blue", "inspect-record-reset", "measure-before-switch", "simple-vs-now", "past-log-today", "some-any-fuses"],
      ["procedure-debug-charge", "sensor-below-threshold", "at-least-three-pulses", "frequency-adverbs"],
      ["only-if-stable", "compare-two-signals", "neither-red-nor-yellow", "replace-only-damaged", "which-route-safest", "relative-drawer", "going-to-scan"],
      ["cause-report", "between-limits", "unless-blue-blinks", "until-door-unlocks", "not-until-pressure-drops", "must-should-cable", "may-must-not", "passive-reattach-wire", "pronoun-reference"],
    ][Math.min(step, 4)];
  }

  private circuitFaultsForStep(step: number) {
    return [
      ["missing-wire", "open-switch"],
      ["missing-resistor", "wrong-resistor-value", "reversed-led"],
      ["sensor-unpowered", "disconnected-component", "short-circuit"],
      ["parallel-branch-open", "capacitor-discharged", "loose-ground"],
      ["relay-not-armed", "short-circuit", "wrong-resistor-value", "parallel-branch-open"],
    ][Math.min(step, 4)] as Parameters<CircuitFaultGenerator["generate"]>[2];
  }
}
