import { numberMachines, type NumberMachineDefinition, type ProductionOrder } from "../data/numberFactory";

type FactoryState = {
  value: number;
  machineIds: string[];
  labels: string[];
};

export class NumberFactorySolver {
  findSolution(order: ProductionOrder): string[] | undefined {
    const queue: FactoryState[] = [{ value: order.start, machineIds: [], labels: [] }];
    const visited = new Set<string>([`${order.start}:`]);

    while (queue.length > 0) {
      const state = queue.shift();
      if (!state) break;
      if (
        state.value === order.target &&
        order.requiredMachineIds.every((machineId) => state.machineIds.includes(machineId))
      ) {
        return state.labels;
      }
      if (state.machineIds.length >= order.maxSteps) continue;

      for (const machine of numberMachines) {
        const next = this.apply(machine, state.value);
        if (next === undefined || next < -999 || next > 9999) continue;
        const ids = [...state.machineIds, machine.id];
        const key = `${next}:${ids.join(",")}`;
        if (visited.has(key)) continue;
        visited.add(key);
        queue.push({ value: next, machineIds: ids, labels: [...state.labels, machine.expressionLabel] });
      }
    }

    return undefined;
  }

  isSolvable(order: ProductionOrder): boolean {
    return Boolean(this.findSolution(order));
  }

  private apply(machine: NumberMachineDefinition, input: number): number | undefined {
    if (machine.kind === "evenGate") return input % 2 === 0 ? input : undefined;
    if (machine.kind === "multipleOfThreeGate") return input % 3 === 0 ? input : undefined;
    if (machine.kind === "divide") {
      const divisor = machine.value ?? 1;
      return input % divisor === 0 ? input / divisor : undefined;
    }
    if (machine.kind === "add") return input + (machine.value ?? 0);
    if (machine.kind === "subtract") return input - (machine.value ?? 0);
    if (machine.kind === "multiply") return input * (machine.value ?? 1);
    return input * 2 + (machine.value ?? 1);
  }
}

export const numberFactorySolver = new NumberFactorySolver();
