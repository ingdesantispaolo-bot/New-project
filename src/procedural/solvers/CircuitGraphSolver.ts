import type { GeneratedCircuitPuzzle } from "../ProceduralTypes";

export class CircuitGraphSolver {
  hasClosedPath(circuit: GeneratedCircuitPuzzle): boolean {
    const graph = new Map<string, string[]>();
    circuit.nodes.forEach((node) => graph.set(node, []));
    circuit.edges.forEach((edge) => {
      graph.get(edge.from)?.push(edge.to);
      graph.get(edge.to)?.push(edge.from);
    });

    const visited = new Set<string>();
    const stack = ["battery"];
    while (stack.length > 0) {
      const node = stack.pop();
      if (!node || visited.has(node)) {
        continue;
      }
      visited.add(node);
      graph.get(node)?.forEach((next) => stack.push(next));
    }
    return circuit.nodes.every((node) => visited.has(node));
  }
}
