export type NumberMachine =
  | { type: "add"; value: number }
  | { type: "subtract"; value: number }
  | { type: "multiply"; value: number }
  | { type: "divide"; value: number }
  | { type: "only-even" }
  | { type: "only-multiple"; value: number }
  | { type: "transform-2n-plus-1"; value: number };

export type FactoryRunResult = {
  accepted: boolean;
  value: number;
  trace: string[];
};

export class NumberFactorySimulator {
  run(input: number, machines: NumberMachine[]): FactoryRunResult {
    let value = input;
    const trace: string[] = [`Ingresso ${input}`];
    for (const machine of machines) {
      if (machine.type === "only-even") {
        if (value % 2 !== 0) return { accepted: false, value, trace: [...trace, `${value} non è pari`] };
        trace.push(`${value} passa il filtro pari`);
      } else if (machine.type === "only-multiple") {
        if (value % machine.value !== 0) return { accepted: false, value, trace: [...trace, `${value} non è multiplo di ${machine.value}`] };
        trace.push(`${value} passa il filtro multiplo di ${machine.value}`);
      } else if (machine.type === "divide") {
        if (value % machine.value !== 0) return { accepted: false, value, trace: [...trace, `${value} non si divide esattamente per ${machine.value}`] };
        value /= machine.value;
        trace.push(`dividi per ${machine.value} -> ${value}`);
      } else if (machine.type === "add") {
        value += machine.value;
        trace.push(`aggiungi ${machine.value} -> ${value}`);
      } else if (machine.type === "subtract") {
        value -= machine.value;
        trace.push(`sottrai ${machine.value} -> ${value}`);
      } else if (machine.type === "transform-2n-plus-1") {
        value = value * 2 + machine.value;
        trace.push(`applica 2n+${machine.value} -> ${value}`);
      } else {
        value *= machine.value;
        trace.push(`moltiplica per ${machine.value} -> ${value}`);
      }
    }
    return { accepted: true, value, trace };
  }

  isInteresting(input: number, target: number, machines: NumberMachine[]): boolean {
    const result = this.run(input, machines);
    return result.accepted && result.value === target && result.trace.length >= 4;
  }
}
