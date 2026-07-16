import type { GeneratedRobotPuzzle, GridCommand, GridFacing, RobotCheckpoint } from "../../procedural/ProceduralTypes";

export type RobotExecutionState = {
  col: number;
  row: number;
  facing: GridFacing;
  hasKey: boolean;
  checkpointIndex: number;
};

export type RobotCommandOutcome =
  | { kind: "turned"; state: RobotExecutionState }
  | { kind: "moved"; state: RobotExecutionState; checkpoint?: RobotCheckpoint; nextCheckpoint?: RobotCheckpoint }
  | { kind: "picked"; state: RobotExecutionState }
  | { kind: "exited"; state: RobotExecutionState }
  | { kind: "failed"; state: RobotExecutionState; failure: RobotFailure };

export type RobotFailure =
  | { kind: "wall"; col: number; row: number; commandIndex: number }
  | { kind: "missing-checkpoint-end"; checkpoint: RobotCheckpoint }
  | { kind: "missing-checkpoint-pickup"; checkpoint: RobotCheckpoint }
  | { kind: "missing-checkpoint-exit"; checkpoint: RobotCheckpoint }
  | { kind: "premature-pickup"; commandIndex: number }
  | { kind: "not-exited" }
  | { kind: "missing-key" };

const turnOrder: GridFacing[] = ["N", "E", "S", "W"];
const deltas: Record<GridFacing, [number, number]> = {
  N: [0, -1],
  E: [1, 0],
  S: [0, 1],
  W: [-1, 0],
};

export function sortedRobotCheckpoints(puzzle: Pick<GeneratedRobotPuzzle, "checkpoints">): RobotCheckpoint[] {
  return [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order);
}

export function initialRobotExecutionState(puzzle: Pick<GeneratedRobotPuzzle, "start">): RobotExecutionState {
  return { ...puzzle.start, hasKey: false, checkpointIndex: 0 };
}

export function turnRobot(facing: GridFacing, direction: "L" | "R"): GridFacing {
  const index = turnOrder.indexOf(facing);
  return turnOrder[(index + (direction === "L" ? 3 : 1)) % turnOrder.length];
}

export function robotFailureText(failure: RobotFailure): string | undefined {
  switch (failure.kind) {
    case "missing-checkpoint-end":
      return `Il programma si ferma prima del checkpoint ${failure.checkpoint.label}: dividi la rotta in tappe e completa la prossima tappa.`;
    case "missing-checkpoint-pickup":
      return `Hai provato a raccogliere prima di validare il checkpoint ${failure.checkpoint.label}. Il programma deve rispettare l'ordine dei sotto-obiettivi.`;
    case "missing-checkpoint-exit":
      return `La porta robot rifiuta il programma: manca il checkpoint ${failure.checkpoint.label}.`;
    default:
      return undefined;
  }
}

export function stepRobotCommand(
  puzzle: Pick<GeneratedRobotPuzzle, "cols" | "rows" | "key" | "exit" | "obstacles">,
  checkpoints: RobotCheckpoint[],
  state: RobotExecutionState,
  command: GridCommand,
  commandIndex: number,
): RobotCommandOutcome {
  if (command === "TURN_LEFT" || command === "TURN_RIGHT") {
    return {
      kind: "turned",
      state: {
        ...state,
        facing: turnRobot(state.facing, command === "TURN_LEFT" ? "L" : "R"),
      },
    };
  }

  if (command === "MOVE_FORWARD") {
    const delta = deltas[state.facing];
    const nextState: RobotExecutionState = {
      ...state,
      col: state.col + delta[0],
      row: state.row + delta[1],
    };
    const blocked = nextState.col < 0
      || nextState.row < 0
      || nextState.col >= puzzle.cols
      || nextState.row >= puzzle.rows
      || puzzle.obstacles.some((cell) => cell.col === nextState.col && cell.row === nextState.row);
    if (blocked) {
      return { kind: "failed", state, failure: { kind: "wall", col: nextState.col, row: nextState.row, commandIndex } };
    }
    const checkpoint = checkpoints[state.checkpointIndex];
    if (checkpoint && nextState.col === checkpoint.col && nextState.row === checkpoint.row) {
      const advancedState = { ...nextState, checkpointIndex: state.checkpointIndex + 1 };
      return {
        kind: "moved",
        state: advancedState,
        checkpoint,
        nextCheckpoint: checkpoints[advancedState.checkpointIndex],
      };
    }
    return { kind: "moved", state: nextState };
  }

  if (command === "PICK_UP") {
    const checkpoint = checkpoints[state.checkpointIndex];
    if (checkpoint) {
      return { kind: "failed", state, failure: { kind: "missing-checkpoint-pickup", checkpoint } };
    }
    if (state.col !== puzzle.key.col || state.row !== puzzle.key.row) {
      return { kind: "failed", state, failure: { kind: "premature-pickup", commandIndex } };
    }
    return { kind: "picked", state: { ...state, hasKey: true } };
  }

  if (command === "EXIT") {
    if (state.hasKey && state.checkpointIndex === checkpoints.length && state.col === puzzle.exit.col && state.row === puzzle.exit.row) {
      return { kind: "exited", state };
    }
    const checkpoint = checkpoints[state.checkpointIndex];
    if (checkpoint) {
      return { kind: "failed", state, failure: { kind: "missing-checkpoint-exit", checkpoint } };
    }
    return { kind: "failed", state, failure: { kind: state.hasKey ? "not-exited" : "missing-key" } };
  }

  return { kind: "failed", state, failure: { kind: state.hasKey ? "not-exited" : "missing-key" } };
}

export function robotProgramEndFailure(
  checkpoints: RobotCheckpoint[],
  state: RobotExecutionState,
): RobotFailure {
  const checkpoint = checkpoints[state.checkpointIndex];
  if (checkpoint) {
    return { kind: "missing-checkpoint-end", checkpoint };
  }
  return { kind: state.hasKey ? "not-exited" : "missing-key" };
}
