import { CircuitFaultGenerator } from "./generators/CircuitFaultGenerator";
import { CodingPuzzleGenerator } from "./generators/CodingPuzzleGenerator";
import { EnglishInstructionGenerator } from "./generators/EnglishInstructionGenerator";
import { LanguageCorruptionGenerator } from "./generators/LanguageCorruptionGenerator";
import { MathPuzzleGenerator } from "./generators/MathPuzzleGenerator";
import { MusicNoteGenerator } from "./generators/MusicNoteGenerator";
import { PhysicsPuzzleGenerator } from "./generators/PhysicsPuzzleGenerator";
import { RobotGridGenerator } from "./generators/RobotGridGenerator";
import { exerciseDirector } from "../core/ExerciseDirector";
import type {
  CodingChallengeType,
  CodingMinigameType,
  DifficultyPreset,
  EnglishMinigameType,
  PhysicsExerciseType,
  GeneratedFocusChallenge,
  GeneratedMission,
  LanguageMinigameType,
  MathMinigameType,
  ProceduralPuzzleKind,
  RobotChallengeType,
} from "./ProceduralTypes";
import type { Random } from "./Random";
import { ValidationEngine } from "./ValidationEngine";
import { CircuitPuzzleValidator } from "./validators/CircuitPuzzleValidator";
import { CodingPuzzleValidator } from "./validators/CodingPuzzleValidator";
import { LanguagePuzzleValidator } from "./validators/LanguagePuzzleValidator";
import { MathPuzzleValidator } from "./validators/MathPuzzleValidator";
import { PhysicsPuzzleValidator } from "./validators/PhysicsPuzzleValidator";
import { RobotPuzzleValidator } from "./validators/RobotPuzzleValidator";

export class PuzzleGenerator {
  private mathGenerator = new MathPuzzleGenerator();
  private robotGenerator = new RobotGridGenerator();
  private codingGenerator = new CodingPuzzleGenerator();
  private musicGenerator = new MusicNoteGenerator();
  private physicsGenerator = new PhysicsPuzzleGenerator();
  private circuitGenerator = new CircuitFaultGenerator();
  private languageGenerator = new LanguageCorruptionGenerator();
  private englishGenerator = new EnglishInstructionGenerator();
  private mathValidator = new MathPuzzleValidator();
  private robotValidator = new RobotPuzzleValidator();
  private codingValidator = new CodingPuzzleValidator();
  private circuitValidator = new CircuitPuzzleValidator();
  private physicsValidator = new PhysicsPuzzleValidator();
  private languageValidator = new LanguagePuzzleValidator();

  constructor(private validationEngine: ValidationEngine) {}

  generate(random: Random, difficulty: DifficultyPreset, focus: string[] = []): GeneratedMission["puzzles"] {
    const mathRandom = random.fork("math");
    const robotRandom = random.fork("robot");
    const circuitRandom = random.fork("circuit");
    const languageRandom = random.fork("language");
    const englishRandom = random.fork("english");
    const musicRandom = random.fork("music");
    const physicsRandom = random.fork("physics");
    const codingRandom = random.fork("coding");
    const mathDifficulty = this.boostForFocus(difficulty, focus, "matematica");
    const robotDifficulty = this.boostForFocus(difficulty, focus, "coding");
    const circuitDifficulty = this.boostForFocus(difficulty, focus, "elettronica");
    const languageLevel = this.levelForFocus(difficulty.level, focus, "italiano");
    const englishLevel = this.levelForFocus(difficulty.level, focus, "inglese");
    const musicLevel = this.levelForFocus(difficulty.level, focus, "musica");
    const physicsDifficulty = this.boostForFocus(difficulty, focus, "fisica");
    const codingDifficulty = this.boostForFocus(difficulty, focus, "coding");

    const math = this.validationEngine.generateWithRetries(
        () => this.mathGenerator.generateGraphWorkshop(mathRandom, mathDifficulty),
        (puzzle) => this.mathValidator.validate(puzzle),
        () => this.mathGenerator.generateGraphWorkshop(mathRandom.fork("fallback"), mathDifficulty),
      );
    const robot = this.validationEngine.generateWithRetries(
        () => this.robotGenerator.generate(robotRandom, robotDifficulty),
        (puzzle) => this.robotValidator.validate(puzzle),
        () => this.robotGenerator.fallback(undefined, robotRandom.fork("fallback")),
      );
    const circuit = this.validationEngine.generateWithRetries(
        () => this.circuitGenerator.generate(circuitRandom, circuitDifficulty),
        (puzzle) => this.circuitValidator.validate(puzzle),
        () => this.circuitGenerator.fallback(circuitDifficulty.level, circuitRandom.fork("fallback"), circuitDifficulty),
    );
    const coding = this.validationEngine.generateWithRetries(
      () => this.codingGenerator.generate(codingRandom, codingDifficulty),
      (puzzle) => this.codingValidator.validate(puzzle),
      () => this.codingGenerator.fallback(codingRandom.fork("fallback"), codingDifficulty),
    );
    const physics = this.validationEngine.generateWithRetries(
      () => this.physicsGenerator.generate(physicsRandom, physicsDifficulty),
      (puzzle) => this.physicsValidator.validate(puzzle),
      () => this.physicsGenerator.fallback(physicsRandom.fork("fallback"), physicsDifficulty),
    );

    return {
      math: exerciseDirector.enrichMath(math, mathDifficulty.level),
      robot: exerciseDirector.enrichRobot(robot, robotDifficulty.level),
      circuit: exerciseDirector.enrichCircuit(circuit, circuitDifficulty.level),
      coding,
      language: this.validationEngine.generateWithRetries(
        () => this.languageGenerator.generate(languageRandom, languageLevel),
        (puzzle) => this.languageValidator.validateItalian(puzzle),
        () => this.languageGenerator.fallback(languageRandom.fork("fallback"), languageLevel),
      ),
      english: this.validationEngine.generateWithRetries(
        () => this.englishGenerator.generate(englishRandom, englishLevel),
        (puzzle) => this.languageValidator.validateEnglish(puzzle),
        () => this.englishGenerator.fallback(englishRandom.fork("fallback"), englishLevel),
      ),
      music: this.musicGenerator.generate(musicRandom, musicLevel),
      physics,
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
        const graphStageIndex = Math.min(1, Math.max(0, stages.length - 1));
        const useGraphWorkshop = index === graphStageIndex;
        const useMinigame = !useGraphWorkshop && index % 2 === 0;
        const puzzle = this.validationEngine.generateWithRetries(
          () => useGraphWorkshop
            ? this.mathGenerator.generateGraphWorkshop(challengeRandom, stagedDifficulty)
            : useMinigame
            ? this.mathGenerator.generateMinigame(challengeRandom, stagedDifficulty, this.mathMinigameTypesForStep(index))
            : this.mathGenerator.generate(challengeRandom, stagedDifficulty, this.mathArchetypesForStep(index)),
          (candidate) => this.mathValidator.validate(candidate),
          () => useGraphWorkshop
            ? this.mathGenerator.generateGraphWorkshop(challengeRandom.fork("fallback"), stagedDifficulty)
            : this.mathGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty),
        );
        return {
          id,
          kind,
          title: useGraphWorkshop ? "Officina dei Grafici" : stage.label,
          description: useGraphWorkshop
            ? puzzle.graphWorkshop?.objective ?? "Modifica i parametri e certifica il grafico sul piano cartesiano."
            : stage.description,
          difficultyStep: index + 1,
          puzzle: exerciseDirector.enrichMath(puzzle, stagedDifficulty.level),
        };
      }
      if (kind === "language") {
        const useMinigame = [0, 1, 3].includes(index);
        const puzzle = this.validationEngine.generateWithRetries(
          () => useMinigame
            ? this.languageGenerator.generateMinigame(challengeRandom, stagedDifficulty.level, this.languageMinigameTypesForStep(index))
            : this.languageGenerator.generate(challengeRandom, stagedDifficulty.level, this.languageTemplatesForStep(index)),
          (candidate) => this.languageValidator.validateItalian(candidate),
          () => this.languageGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty.level),
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "english") {
        const useMinigame = [0, 1, 2, 4].includes(index);
        const puzzle = this.validationEngine.generateWithRetries(
          () => useMinigame
            ? this.englishGenerator.generateMinigame(challengeRandom, stagedDifficulty.level, this.englishMinigameTypesForStep(index))
            : this.englishGenerator.generate(challengeRandom, stagedDifficulty.level, this.englishTemplatesForStep(index)),
          (candidate) => this.languageValidator.validateEnglish(candidate),
          () => this.englishGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty.level),
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "music") {
        const puzzle = this.musicGenerator.generate(challengeRandom, stagedDifficulty.level);
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "physics") {
        const puzzle = this.validationEngine.generateWithRetries(
          () => this.physicsGenerator.generate(challengeRandom, stagedDifficulty, this.physicsTypesForStep(index)),
          (candidate) => this.physicsValidator.validate(candidate),
          () => this.physicsGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty),
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "coding") {
        const useMinigame = [0, 1, 2, 4].includes(index);
        const puzzle = this.validationEngine.generateWithRetries(
          () => useMinigame
            ? this.codingGenerator.generateMinigame(challengeRandom, stagedDifficulty, this.codingMinigameTypesForStep(index))
            : this.codingGenerator.generate(challengeRandom, stagedDifficulty, this.codingChallengeTypesForStep(index)),
          (candidate) => this.codingValidator.validate(candidate),
          () => this.codingGenerator.fallback(challengeRandom.fork("fallback"), stagedDifficulty),
        );
        return { id, kind, title: stage.label, description: stage.description, difficultyStep: index + 1, puzzle };
      }
      if (kind === "circuit") {
        const useMinigame = [0, 1, 3].includes(index);
        const puzzle = this.validationEngine.generateWithRetries(
          () => useMinigame
            ? this.circuitGenerator.generateMinigame(challengeRandom, stagedDifficulty)
            : this.circuitGenerator.generate(challengeRandom, stagedDifficulty, this.circuitFaultsForStep(index)),
          (candidate) => this.circuitValidator.validate(candidate),
          () => this.circuitGenerator.fallback(stagedDifficulty.level, challengeRandom.fork("fallback"), stagedDifficulty),
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
      const robotType = this.robotChallengeTypeForStep(index, difficulty.level);
      const puzzle = this.validationEngine.generateWithRetries(
        () => this.robotGenerator.generate(challengeRandom, stagedDifficulty, robotType),
        (candidate) => this.robotValidator.validate(candidate),
        () => this.robotGenerator.fallback(robotType, challengeRandom.fork("fallback")),
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
      music: "musica",
      physics: "fisica",
      robot: "coding",
      coding: "coding",
    }[kind];
  }

  private codingChallengeTypesForStep(step: number): CodingChallengeType[] {
    return [
      ["trace-output", "variable-state"],
      ["variable-state", "trace-output"],
      ["loop-count", "conditional-branch"],
      ["conditional-branch", "boolean-logic"],
      ["debug-line", "boolean-logic", "loop-count"],
    ][Math.min(step, 4)] as CodingChallengeType[];
  }

  private codingMinigameTypesForStep(step: number): CodingMinigameType[] {
    return [
      ["sequence-builder", "state-tracer"],
      ["state-tracer", "sequence-builder", "binary-bits"],
      ["bug-hunt", "state-tracer", "loop-output", "conditional-path"],
      ["bug-hunt", "state-tracer", "sequence-builder", "logic-gate", "binary-bits"],
      ["bug-hunt", "state-tracer", "sequence-builder", "binary-bits", "logic-gate", "loop-output", "conditional-path", "algorithm-order"],
    ][Math.min(step, 4)] as CodingMinigameType[];
  }

  private mathArchetypesForStep(step: number): Array<NonNullable<GeneratedMission["puzzles"]["math"]["archetype"]>> {
    return [
      ["calcolo-diretto", "frazioni", "percentuali", "lettura-dati"],
      ["sequenza", "statistica", "coordinate", "lettura-dati", "vincolo"],
      ["vincolo", "proporzione", "geometria", "probabilita", "percentuali", "frazioni"],
      ["ragionamento-inverso", "pre-algebra", "equazione-primo-grado", "funzione-lineare", "grafici-cartesiani", "coordinate", "statistica"],
      ["diagnosi-errore", "potenze-radici", "geometria", "sistemi-lineari", "probabilita", "equazione-primo-grado", "equazione-secondo-grado", "grafici-cartesiani", "funzione-lineare", "proporzione"],
    ][Math.min(step, 4)] as Array<NonNullable<GeneratedMission["puzzles"]["math"]["archetype"]>>;
  }

  private mathMinigameTypesForStep(step: number): MathMinigameType[] {
    return [
      ["target-sum"],
      ["target-sum", "factor-hunt"],
      ["factor-hunt", "operation-chain"],
      ["operation-chain", "target-sum"],
      ["operation-chain", "factor-hunt", "target-sum"],
    ][Math.min(step, 4)] as MathMinigameType[];
  }

  private robotChallengeTypeForStep(step: number, level = 1): RobotChallengeType {
    if (step >= 4 && level >= 7) {
      return "loop-compression";
    }
    if (step >= 4 && level >= 5) {
      return "conditional-gate";
    }
    return [
      "route-planning",
      "coordinate-routing",
      "checkpoint-order",
      "minimal-route",
      "debug-program",
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

  private languageMinigameTypesForStep(step: number): LanguageMinigameType[] {
    return [
      ["agreement-sprint", "verb-mastery", "word-order", "lexicon-lab"],
      ["verb-mastery", "intruder-hunt", "connector-route", "lexicon-lab"],
      ["connector-route", "verb-mastery", "agreement-sprint", "word-order", "lexicon-lab"],
      ["verb-mastery", "connector-route", "intruder-hunt", "word-order", "lexicon-lab"],
      ["verb-mastery", "intruder-hunt", "agreement-sprint", "connector-route", "word-order", "lexicon-lab"],
    ][Math.min(step, 4)] as LanguageMinigameType[];
  }

  private englishTemplatesForStep(step: number): string[] {
    return [
      ["green-not-red", "small-key", "main-switch", "where-is-core", "who-can-open", "possessive-their-its", "movement-prepositions-route"],
      ["left-before-blue", "inspect-record-reset", "measure-before-switch", "simple-vs-now", "past-log-today", "some-any-fuses", "much-many-supplies", "present-perfect-already-yet"],
      ["procedure-debug-charge", "sensor-below-threshold", "at-least-three-pulses", "frequency-adverbs", "first-conditional-alarm", "zero-conditional-rule", "adverbs-manner-safety"],
      ["only-if-stable", "compare-two-signals", "neither-red-nor-yellow", "replace-only-damaged", "which-route-safest", "relative-drawer", "going-to-scan", "past-vs-present-perfect-log", "although-however-report", "main-idea-log", "detail-not-mentioned", "question-formation-why", "relative-where-lab"],
      ["cause-report", "between-limits", "unless-blue-blinks", "until-door-unlocks", "not-until-pressure-drops", "must-should-cable", "may-must-not", "passive-reattach-wire", "pronoun-reference", "as-as-comparison", "passive-simple-past", "have-to-vs-can", "word-formation-re-over", "scientific-observation-evidence", "reported-warning", "either-neither-tool", "multi-clause-mission-order", "email-register-formal"],
    ][Math.min(step, 4)];
  }

  private englishMinigameTypesForStep(step: number): EnglishMinigameType[] {
    return [
      ["action-relay", "sentence-build", "vocab-lab", "translation-match"],
      ["sequence-switchboard", "grammar-fix", "vocab-lab", "translation-match", "dialogue-response"],
      ["data-command-scan", "action-relay", "grammar-fix", "vocab-lab", "translation-match", "reading-detective"],
      ["sequence-switchboard", "action-relay", "sentence-build", "data-command-scan", "vocab-lab", "translation-match", "reading-detective", "dialogue-response"],
      ["action-relay", "sequence-switchboard", "data-command-scan", "grammar-fix", "sentence-build", "vocab-lab", "translation-match", "reading-detective", "error-diagnosis", "dialogue-response"],
    ][Math.min(step, 4)] as EnglishMinigameType[];
  }

  private physicsTypesForStep(step: number): PhysicsExerciseType[] {
    return [
      ["unit-check", "motion-graph"],
      ["motion-graph", "force-diagram", "energy-transfer"],
      ["experiment-order", "force-diagram", "energy-transfer"],
      ["density-pressure", "heat-temperature", "motion-graph"],
      ["wave-reading", "optics-ray", "density-pressure", "experiment-order"],
    ][Math.min(step, 4)] as PhysicsExerciseType[];
  }

  private circuitFaultsForStep(step: number) {
    return [
      ["missing-wire", "open-switch"],
      ["missing-resistor"],
      ["reversed-led", "wrong-resistor-value"],
      ["sensor-unpowered", "disconnected-component", "parallel-branch-open"],
      ["capacitor-discharged", "loose-ground", "short-circuit", "relay-not-armed"],
    ][Math.min(step, 4)] as Parameters<CircuitFaultGenerator["generate"]>[2];
  }
}
