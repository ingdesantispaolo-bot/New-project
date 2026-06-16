import type { GeneratedRobotPuzzle, GridCommand, GridFacing } from "../ProceduralTypes";
import { GridPathSolver } from "../solvers/GridPathSolver";

export class RobotPuzzleValidator {
  private solver = new GridPathSolver();

  validate(puzzle: GeneratedRobotPuzzle): boolean {
    const obstacleKeys = new Set(puzzle.obstacles.map((cell) => `${cell.col}:${cell.row}`));
    const keyBlocked = obstacleKeys.has(`${puzzle.key.col}:${puzzle.key.row}`);
    const exitBlocked = obstacleKeys.has(`${puzzle.exit.col}:${puzzle.exit.row}`);
    const checkpointBlocked = (puzzle.checkpoints ?? []).some((cell) => obstacleKeys.has(`${cell.col}:${cell.row}`));
    const toKey = this.solver.findCommandPath(puzzle.cols, puzzle.rows, puzzle.start, puzzle.key, puzzle.obstacles);
    const keyState = toKey ? this.solver.simulate(puzzle.start, toKey) : { ...puzzle.key, facing: puzzle.start.facing };
    const toExit = this.solver.findCommandPath(puzzle.cols, puzzle.rows, keyState, puzzle.exit, puzzle.obstacles);
    const programWorks = this.programSatisfiesPuzzle(puzzle, puzzle.solutionCommands);
    const pickupCount = puzzle.solutionCommands.filter((command) => command === "PICK_UP").length;
    const exitCount = puzzle.solutionCommands.filter((command) => command === "EXIT").length;
    const startKeyDistinct = puzzle.start.col !== puzzle.key.col || puzzle.start.row !== puzzle.key.row;
    const keyExitDistinct = puzzle.key.col !== puzzle.exit.col || puzzle.key.row !== puzzle.exit.row;
    const hasClearFinish = pickupCount === 1 && exitCount === 1 && puzzle.solutionCommands[puzzle.solutionCommands.length - 1] === "EXIT";
    return !keyBlocked
      && !exitBlocked
      && !checkpointBlocked
      && startKeyDistinct
      && keyExitDistinct
      && Boolean(toKey)
      && Boolean(toExit)
      && puzzle.solutionCommands.length > 0
      && hasClearFinish
      && programWorks;
  }

  private programSatisfiesPuzzle(puzzle: GeneratedRobotPuzzle, commands: GridCommand[]): boolean {
    const turn = (facing: GridFacing, direction: "L" | "R"): GridFacing => {
      const order: GridFacing[] = ["N", "E", "S", "W"];
      const offset = direction === "R" ? 1 : -1;
      return order[(order.indexOf(facing) + offset + order.length) % order.length];
    };
    const checkpoints = [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order);
    let checkpointIndex = 0;
    let state = { ...puzzle.start };
    let hasKey = false;

    for (const command of commands) {
      if (command === "TURN_LEFT") {
        state.facing = turn(state.facing, "L");
      } else if (command === "TURN_RIGHT") {
        state.facing = turn(state.facing, "R");
      } else if (command === "MOVE_FORWARD") {
        const delta = { N: [0, -1], E: [1, 0], S: [0, 1], W: [-1, 0] }[state.facing];
        const next = { col: state.col + delta[0], row: state.row + delta[1], facing: state.facing };
        const blocked = next.col < 0 || next.row < 0 || next.col >= puzzle.cols || next.row >= puzzle.rows || puzzle.obstacles.some((cell) => cell.col === next.col && cell.row === next.row);
        if (blocked) {
          return false;
        }
        state = next;
        const checkpoint = checkpoints[checkpointIndex];
        if (checkpoint && state.col === checkpoint.col && state.row === checkpoint.row) {
          checkpointIndex += 1;
        }
      } else if (command === "PICK_UP") {
        if (checkpointIndex < checkpoints.length || state.col !== puzzle.key.col || state.row !== puzzle.key.row) {
          return false;
        }
        hasKey = true;
      } else if (command === "EXIT") {
        return hasKey && checkpointIndex === checkpoints.length && state.col === puzzle.exit.col && state.row === puzzle.exit.row;
      }
    }
    return false;
  }
}
