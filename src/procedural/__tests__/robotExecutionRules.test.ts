import { describe, expect, it } from "vitest";
import {
  initialRobotExecutionState,
  robotFailureText,
  robotProgramEndFailure,
  sortedRobotCheckpoints,
  stepRobotCommand,
  turnRobot,
} from "../../scenes/procedural/RobotExecutionRules";
import type { GeneratedRobotPuzzle } from "../ProceduralTypes";

function puzzle(overrides: Partial<GeneratedRobotPuzzle> = {}): GeneratedRobotPuzzle {
  return {
    id: "robot-test",
    title: "Robot test",
    instructions: [],
    cols: 4,
    rows: 4,
    start: { col: 0, row: 3, facing: "E" },
    key: { col: 2, row: 2 },
    exit: { col: 3, row: 3 },
    obstacles: [{ col: 1, row: 3 }],
    solutionCommands: [],
    hints: [],
    competencies: [],
    checkpoints: [{ col: 0, row: 2, label: "A", order: 1 }],
    ...overrides,
  };
}

describe("RobotExecutionRules", () => {
  it("turns and sorts checkpoints deterministically", () => {
    expect(turnRobot("N", "L")).toBe("W");
    expect(turnRobot("W", "R")).toBe("N");
    expect(sortedRobotCheckpoints(puzzle({
      checkpoints: [
        { col: 2, row: 2, label: "B", order: 2 },
        { col: 1, row: 1, label: "A", order: 1 },
      ],
    })).map((checkpoint) => checkpoint.label)).toEqual(["A", "B"]);
  });

  it("fails when moving into a wall or outside the grid", () => {
    const base = puzzle();
    const state = initialRobotExecutionState(base);

    expect(stepRobotCommand(base, sortedRobotCheckpoints(base), state, "MOVE_FORWARD", 0)).toMatchObject({
      kind: "failed",
      failure: { kind: "wall", col: 1, row: 3, commandIndex: 0 },
    });
  });

  it("advances checkpoints when moving onto the next required checkpoint", () => {
    const base = puzzle({ obstacles: [] });
    const state = { ...initialRobotExecutionState(base), facing: "N" as const };

    expect(stepRobotCommand(base, sortedRobotCheckpoints(base), state, "MOVE_FORWARD", 0)).toMatchObject({
      kind: "moved",
      checkpoint: { label: "A" },
      state: { col: 0, row: 2, checkpointIndex: 1 },
    });
  });

  it("blocks pickup before checkpoints and away from the key", () => {
    const base = puzzle({ obstacles: [] });
    const checkpoints = sortedRobotCheckpoints(base);
    const beforeCheckpoint = initialRobotExecutionState(base);
    const awayFromKey = { ...beforeCheckpoint, checkpointIndex: checkpoints.length };

    expect(stepRobotCommand(base, checkpoints, beforeCheckpoint, "PICK_UP", 0)).toMatchObject({
      kind: "failed",
      failure: { kind: "missing-checkpoint-pickup" },
    });
    expect(stepRobotCommand(base, checkpoints, awayFromKey, "PICK_UP", 1)).toMatchObject({
      kind: "failed",
      failure: { kind: "premature-pickup", commandIndex: 1 },
    });
  });

  it("picks the key and exits only from the exit cell with all checkpoints done", () => {
    const base = puzzle({ obstacles: [] });
    const checkpoints = sortedRobotCheckpoints(base);
    const atKey = { col: 2, row: 2, facing: "E" as const, hasKey: false, checkpointIndex: checkpoints.length };
    const picked = stepRobotCommand(base, checkpoints, atKey, "PICK_UP", 0);

    expect(picked).toMatchObject({ kind: "picked", state: { hasKey: true } });
    expect(stepRobotCommand(base, checkpoints, { col: 3, row: 3, facing: "E", hasKey: true, checkpointIndex: checkpoints.length }, "EXIT", 1)).toMatchObject({
      kind: "exited",
    });
  });

  it("describes checkpoint end failures", () => {
    const base = puzzle();
    const failure = robotProgramEndFailure(sortedRobotCheckpoints(base), initialRobotExecutionState(base));

    expect(robotFailureText(failure)).toContain("checkpoint A");
  });
});
