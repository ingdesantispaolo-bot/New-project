import type {
  DifficultyPreset,
  GeneratedCircuitPuzzle,
  GeneratedEnglishPuzzle,
  GeneratedLanguagePuzzle,
  GeneratedMathPuzzle,
  GeneratedMission,
  GeneratedMusicPuzzle,
  GeneratedRobotPuzzle,
} from "../ProceduralTypes";

export type ChallengeQualityReport = {
  valid: boolean;
  reasons: string[];
};

export class ChallengeQualityValidator {
  validateMission(mission: GeneratedMission, difficulty: DifficultyPreset): ChallengeQualityReport {
    const reports = [
      this.validateMath(mission.puzzles.math, difficulty),
      this.validateRobot(mission.puzzles.robot, difficulty),
      this.validateCircuit(mission.puzzles.circuit, difficulty),
      this.validateLanguage(mission.puzzles.language),
      this.validateEnglish(mission.puzzles.english),
      this.validateMusic(mission.puzzles.music),
    ];
    const reasons = reports.flatMap((report) => report.reasons);
    return { valid: reasons.length === 0, reasons };
  }

  validateMath(puzzle: GeneratedMathPuzzle, difficulty: DifficultyPreset): ChallengeQualityReport {
    const reasons: string[] = [];
    const steps = puzzle.solutionSteps?.length ?? 0;
    const asksRounding = /arrotond/i.test(puzzle.prompt);
    if (steps < Math.min(3, Math.max(2, difficulty.mathComplexity))) {
      reasons.push("math: meno di 2-3 passaggi cognitivi");
    }
    if (difficulty.level >= 3 && /^.*\b(triplo|doppio|metà)\b.*$/i.test(puzzle.prompt) && steps < 3) {
      reasons.push("math: troppo vicino al calcolo diretto");
    }
    if (puzzle.hints.length < 2 || puzzle.hints.some((hint) => String(puzzle.answer) === hint.trim())) {
      reasons.push("math: indizi insufficienti o troppo espliciti");
    }
    if (!puzzle.difficultyLabel || !puzzle.learningPurpose || !puzzle.calculationAid) {
      reasons.push("math: mancano livello, scopo didattico o supporto al calcolo");
    }
    if (!puzzle.prompt.includes("Situazione:") || !puzzle.prompt.includes("Richiesta:")) {
      reasons.push("math: formulazione non separa contesto e richiesta");
    }
    if (!Number.isInteger(puzzle.answer) || !/numero intero/i.test(puzzle.prompt)) {
      reasons.push("math: risposta numerica non esplicitamente intera");
    }
    if (asksRounding && !/,5|superiore|inferiore|regola indicata|senza arrotondare/i.test(puzzle.prompt)) {
      reasons.push("math: arrotondamento non univoco");
    }
    return { valid: reasons.length === 0, reasons };
  }

  validateRobot(puzzle: GeneratedRobotPuzzle, difficulty: DifficultyPreset): ChallengeQualityReport {
    const reasons: string[] = [];
    if (puzzle.solutionCommands.length < Math.max(6, difficulty.robotGrid.cols + difficulty.robotGrid.rows - 2)) {
      reasons.push("robot: soluzione troppo breve");
    }
    if (difficulty.level >= 3 && puzzle.obstacles.length < Math.max(2, difficulty.robotObstacleCount - 1)) {
      reasons.push("robot: pochi vincoli spaziali");
    }
    if (puzzle.hints.length < 2 || puzzle.instructions.length < 2) {
      reasons.push("robot: istruzioni o indizi insufficienti");
    }
    if ((puzzle.challengeType === "checkpoint-order" || puzzle.challengeType === "pattern-routing") && (puzzle.checkpoints?.length ?? 0) === 0) {
      reasons.push("robot: sfida checkpoint senza checkpoint");
    }
    if (
      puzzle.solutionCommands.filter((command) => command === "PICK_UP").length !== 1
      || puzzle.solutionCommands.filter((command) => command === "EXIT").length !== 1
      || puzzle.solutionCommands[puzzle.solutionCommands.length - 1] !== "EXIT"
    ) {
      reasons.push("robot: soluzione senza raccolta unica e uscita finale chiara");
    }
    if (puzzle.challengeType === "debug-program" && (!puzzle.buggedCommands || puzzle.buggedCommands.join(",") === puzzle.solutionCommands.join(","))) {
      reasons.push("robot: debug senza programma guasto plausibile");
    }
    if (puzzle.challengeType === "minimal-route" && (puzzle.maxCommands ?? 999) > puzzle.solutionCommands.length + 2) {
      reasons.push("robot: percorso minimo con budget troppo largo");
    }
    return { valid: reasons.length === 0, reasons };
  }

  validateCircuit(puzzle: GeneratedCircuitPuzzle, difficulty: DifficultyPreset): ChallengeQualityReport {
    const reasons: string[] = [];
    const minimumFaults = difficulty.level >= 5 ? 2 : 1;
    if (puzzle.faults.length < minimumFaults) {
      reasons.push("circuit: diagnosi troppo corta");
    }
    if (puzzle.observations.length < puzzle.faults.length + 1) {
      reasons.push("circuit: pochi sintomi da interpretare");
    }
    if (!puzzle.diagnosticQuestion || puzzle.hints.length < 2) {
      reasons.push("circuit: domanda diagnostica o indizi mancanti");
    }
    if (!puzzle.testerReadings || puzzle.testerReadings.length < puzzle.faults.length + 1) {
      reasons.push("circuit: letture tester insufficienti");
    }
    if (!puzzle.repairChoices || puzzle.repairChoices.length <= puzzle.requiredRepairs.length) {
      reasons.push("circuit: mancano distrattori plausibili");
    }
    if (!puzzle.learningPurpose || !puzzle.diagnosticPlan || puzzle.diagnosticPlan.length < 3 || !puzzle.conceptTags || puzzle.conceptTags.length < 2) {
      reasons.push("circuit: mancano scopo didattico, piano diagnostico o concetti");
    }
    return { valid: reasons.length === 0, reasons };
  }

  validateLanguage(puzzle: GeneratedLanguagePuzzle): ChallengeQualityReport {
    const reasons: string[] = [];
    const uniqueOptions = new Set(puzzle.options);
    if (puzzle.options.length < 4 || uniqueOptions.size !== puzzle.options.length) {
      reasons.push("language: servono almeno quattro distrattori unici");
    }
    if (!puzzle.options.includes(puzzle.repaired)) {
      reasons.push("language: correzione assente tra le opzioni");
    }
    if (puzzle.diagnosticSteps.length < 2 || puzzle.hints.length < 2) {
      reasons.push("language: diagnostica troppo povera");
    }
    if (!puzzle.learningPurpose || !puzzle.repairGoal || !puzzle.method || !puzzle.conceptTags || puzzle.conceptTags.length < 2) {
      reasons.push("language: mancano scopo, metodo o concetti didattici");
    }
    if (!puzzle.optionFeedback || puzzle.options.some((option) => option !== puzzle.repaired && (puzzle.optionFeedback?.[option]?.length ?? 0) < 40)) {
      reasons.push("language: feedback dei distrattori insufficiente");
    }
    return { valid: reasons.length === 0, reasons };
  }

  validateEnglish(puzzle: GeneratedEnglishPuzzle): ChallengeQualityReport {
    const reasons: string[] = [];
    const correctCount = puzzle.choices.filter((choice) => choice.isCorrect).length;
    const uniqueLabels = new Set(puzzle.choices.map((choice) => choice.label));
    if (puzzle.choices.length < 3 || correctCount !== 1 || uniqueLabels.size !== puzzle.choices.length) {
      reasons.push("english: distrattori non validi");
    }
    if (puzzle.choices.some((choice) => choice.feedback.length < 20)) {
      reasons.push("english: feedback troppo debole");
    }
    if (puzzle.hints.length < 2) {
      reasons.push("english: indizi insufficienti");
    }
    if (!puzzle.learningPurpose || !puzzle.commandGoal || !puzzle.method || !puzzle.conceptTags || puzzle.conceptTags.length < 2) {
      reasons.push("english: mancano scopo, metodo o concetti didattici");
    }
    if (!puzzle.glossary || puzzle.glossary.length === 0) {
      reasons.push("english: glossario operativo mancante");
    }
    if (puzzle.challengeType === "data-reading" && (puzzle.dataPoints?.length ?? 0) === 0) {
      reasons.push("english: sfida dati senza dati leggibili");
    }
    if ((puzzle.challengeType === "procedure-debug" || puzzle.challengeType === "inference") && !puzzle.sourceText) {
      reasons.push("english: sfida testuale senza log o testo sorgente");
    }
    return { valid: reasons.length === 0, reasons };
  }

  validateMusic(puzzle: GeneratedMusicPuzzle): ChallengeQualityReport {
    const reasons: string[] = [];
    const correctCount = puzzle.choices.filter((choice) => choice.isCorrect).length;
    const uniqueLabels = new Set(puzzle.choices.map((choice) => choice.label));
    if (puzzle.choices.length < 4 || correctCount !== 1 || uniqueLabels.size !== puzzle.choices.length) {
      reasons.push("music: servono quattro opzioni uniche e una sola risposta corretta");
    }
    if (puzzle.hints.length < 3 || !puzzle.learningPurpose || !puzzle.method || puzzle.methodSteps.length < 3) {
      reasons.push("music: mancano indizi, scopo o metodo di lettura");
    }
    if (puzzle.timeLimitMs < 6_000 || puzzle.timeLimitMs > 24_000) {
      reasons.push("music: tempo di risposta fuori range didattico");
    }
    if ((puzzle.staffPosition <= -2 || puzzle.staffPosition >= 10) && puzzle.ledgerLines.length === 0) {
      reasons.push("music: nota esterna senza linee addizionali");
    }
    return { valid: reasons.length === 0, reasons };
  }
}
