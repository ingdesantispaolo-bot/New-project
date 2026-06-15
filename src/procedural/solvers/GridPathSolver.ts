import type { GridCommand, GridFacing } from "../ProceduralTypes";

type Cell = { col: number; row: number };
type State = Cell & { facing: GridFacing };

const facings: GridFacing[] = ["N", "E", "S", "W"];
const deltas: Record<GridFacing, Cell> = {
  N: { col: 0, row: -1 },
  E: { col: 1, row: 0 },
  S: { col: 0, row: 1 },
  W: { col: -1, row: 0 },
};

export class GridPathSolver {
  findCommandPath(
    cols: number,
    rows: number,
    start: State,
    target: Cell,
    obstacles: Cell[],
    maxCommands = 48,
  ): GridCommand[] | undefined {
    const obstacleKeys = new Set(obstacles.map((cell) => `${cell.col}:${cell.row}`));
    const queue: Array<{ state: State; commands: GridCommand[] }> = [{ state: start, commands: [] }];
    const visited = new Set<string>([this.key(start)]);

    while (queue.length > 0) {
      const current = queue.shift();
      if (!current) {
        break;
      }
      if (current.state.col === target.col && current.state.row === target.row) {
        return current.commands;
      }
      if (current.commands.length >= maxCommands) {
        continue;
      }

      for (const next of this.nextStates(current.state)) {
        if (
          next.state.col < 0 ||
          next.state.row < 0 ||
          next.state.col >= cols ||
          next.state.row >= rows ||
          obstacleKeys.has(`${next.state.col}:${next.state.row}`)
        ) {
          continue;
        }
        const key = this.key(next.state);
        if (!visited.has(key)) {
          visited.add(key);
          queue.push({ state: next.state, commands: [...current.commands, next.command] });
        }
      }
    }
    return undefined;
  }

  private nextStates(state: State): Array<{ state: State; command: GridCommand }> {
    const facingIndex = facings.indexOf(state.facing);
    const leftFacing = facings[(facingIndex + facings.length - 1) % facings.length];
    const rightFacing = facings[(facingIndex + 1) % facings.length];
    const delta = deltas[state.facing];
    return [
      { state: { ...state, facing: leftFacing }, command: "TURN_LEFT" },
      { state: { ...state, facing: rightFacing }, command: "TURN_RIGHT" },
      { state: { col: state.col + delta.col, row: state.row + delta.row, facing: state.facing }, command: "MOVE_FORWARD" },
    ];
  }

  simulate(start: State, commands: GridCommand[]): State {
    return commands.reduce((state, command) => {
      if (command === "TURN_LEFT") {
        const facingIndex = facings.indexOf(state.facing);
        return { ...state, facing: facings[(facingIndex + facings.length - 1) % facings.length] };
      }
      if (command === "TURN_RIGHT") {
        const facingIndex = facings.indexOf(state.facing);
        return { ...state, facing: facings[(facingIndex + 1) % facings.length] };
      }
      if (command === "MOVE_FORWARD") {
        const delta = deltas[state.facing];
        return { ...state, col: state.col + delta.col, row: state.row + delta.row };
      }
      return state;
    }, start);
  }

  private key(state: State): string {
    return `${state.col}:${state.row}:${state.facing}`;
  }
}
