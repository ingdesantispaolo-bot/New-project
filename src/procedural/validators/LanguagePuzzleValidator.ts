import type { GeneratedEnglishPuzzle, GeneratedLanguagePuzzle } from "../ProceduralTypes";

export class LanguagePuzzleValidator {
  validateItalian(puzzle: GeneratedLanguagePuzzle): boolean {
    return (
      puzzle.corrupted !== puzzle.repaired &&
      puzzle.options.includes(puzzle.repaired) &&
      new Set(puzzle.options).size === puzzle.options.length &&
      puzzle.diagnosticSteps.length >= 2 &&
      Boolean(puzzle.learningPurpose) &&
      Boolean(puzzle.repairGoal) &&
      Boolean(puzzle.method) &&
      (puzzle.conceptTags?.length ?? 0) >= 2 &&
      puzzle.options.every((option) => option === puzzle.repaired || Boolean(puzzle.optionFeedback?.[option]))
    );
  }

  validateEnglish(puzzle: GeneratedEnglishPuzzle): boolean {
    const needsData = puzzle.challengeType === "data-reading";
    const needsSource = puzzle.challengeType === "procedure-debug" || puzzle.challengeType === "inference";
    return (
      puzzle.choices.filter((choice) => choice.isCorrect).length === 1 &&
      puzzle.choices.length >= 3 &&
      puzzle.diagnosticSteps.length >= 2 &&
      puzzle.hints.length >= 2 &&
      Boolean(puzzle.learningPurpose) &&
      Boolean(puzzle.commandGoal) &&
      Boolean(puzzle.method) &&
      (!needsData || (puzzle.dataPoints?.length ?? 0) >= 1) &&
      (!needsSource || Boolean(puzzle.sourceText)) &&
      (puzzle.conceptTags?.length ?? 0) >= 2 &&
      puzzle.choices.every((choice) => choice.isCorrect || choice.feedback.length >= 30)
    );
  }
}
