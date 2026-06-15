import type { HintStep } from "../procedural/ProceduralTypes";

export class HintLadder {
  fromTexts(texts: string[], fallbackPrinciple: string): HintStep[] {
    const defaults: HintStep[] = [
      { level: 1, kind: "osservazione", text: texts[0] ?? "Osserva prima il sintomo: il sistema mostra dove cambia comportamento." },
      { level: 2, kind: "restrizione", text: texts[1] ?? "Scarta le mosse che non cambiano il punto del guasto." },
      { level: 3, kind: "principio", text: texts[2] ?? fallbackPrinciple },
      { level: 4, kind: "quasi-soluzione", text: texts[3] ?? "Applica il principio al componente o al passaggio che interrompe il sistema." },
    ];
    return defaults;
  }

  next(steps: HintStep[], used: number): HintStep {
    return steps[Math.min(Math.max(used, 0), steps.length - 1)] ?? {
      level: 4,
      kind: "quasi-soluzione",
      text: "Rileggi il sintomo e prova una riparazione che cambi solo la causa più probabile.",
    };
  }
}

export const hintLadder = new HintLadder();
