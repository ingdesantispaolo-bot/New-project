import type { GeneratedMathPuzzle } from "../ProceduralTypes";
import { MathSolver } from "../solvers/MathSolver";

export class MathPuzzleValidator {
  private solver = new MathSolver();

  validate(puzzle: GeneratedMathPuzzle): boolean {
    const answerIsInteger = Number.isInteger(puzzle.answer);
    const asksRounding = /arrotond/i.test(puzzle.prompt);
    const roundingIsExplicit = !asksRounding || /,5|superiore|inferiore|regola indicata|senza arrotondare/i.test(puzzle.prompt);
    const formatIsExplicit = /un solo numero intero|numero intero/i.test(puzzle.prompt) || Boolean(puzzle.equationLab) || Boolean(puzzle.graphWorkshop);
    const equationLabIsValid = !puzzle.equationLab || this.validateEquationLab(puzzle);
    const graphWorkshopIsValid = !puzzle.graphWorkshop || this.validateGraphWorkshop(puzzle);
    return (
      this.solver.isIntegerSolution(puzzle) &&
      answerIsInteger &&
      puzzle.answer >= 0 &&
      puzzle.answer <= 9999 &&
      puzzle.hints.length >= 2 &&
      puzzle.prompt.length > 20 &&
      roundingIsExplicit &&
      formatIsExplicit &&
      equationLabIsValid &&
      graphWorkshopIsValid
    );
  }

  private validateEquationLab(puzzle: GeneratedMathPuzzle): boolean {
    const lab = puzzle.equationLab;
    if (!lab || lab.stages.length < (lab.degree === 1 ? 4 : 5)) return false;
    const stagesAreValid = lab.stages.every((stage) => (
      stage.options.length === 4
      && new Set(stage.options).size === stage.options.length
      && stage.options.includes(stage.correctOption)
      && stage.explanation.length >= 18
    ));
    if (!stagesAreValid) return false;
    if (lab.degree === 1) {
      return lab.roots.length === 1 && Number.isInteger(lab.roots[0]);
    }
    const { a, b, c } = lab.coefficients;
    const discriminant = b * b - 4 * a * c;
    if (a === 0 || discriminant !== lab.discriminant) return false;
    const rootsAreExact = lab.roots.every((root) => a * root * root + b * root + c === 0);
    const expectedRootCount = discriminant > 0 ? 2 : discriminant === 0 ? 1 : 0;
    return rootsAreExact && lab.roots.length === expectedRootCount;
  }

  private validateGraphWorkshop(puzzle: GeneratedMathPuzzle): boolean {
    const workshop = puzzle.graphWorkshop;
    if (!workshop || workshop.parameters.length < 2 || workshop.targetPoints.length === 0) return false;
    const keys = new Set(workshop.parameters.map((parameter) => parameter.key));
    if (keys.size !== workshop.parameters.length) return false;
    const parametersAreValid = workshop.parameters.every((parameter) => (
      Number.isInteger(parameter.target)
      && Number.isInteger(parameter.initial)
      && parameter.target >= parameter.min
      && parameter.target <= parameter.max
      && parameter.initial >= parameter.min
      && parameter.initial <= parameter.max
      && parameter.step > 0
    ));
    if (!parametersAreValid) return false;
    if (workshop.functionKind === "linear") {
      return keys.has("m") && keys.has("q") && workshop.parameters.length === 2;
    }
    const a = workshop.parameters.find((parameter) => parameter.key === "a");
    return keys.has("a") && keys.has("h") && keys.has("k") && workshop.parameters.length === 3 && a?.target !== 0;
  }
}
