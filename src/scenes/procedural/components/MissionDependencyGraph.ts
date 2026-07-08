import { proceduralPuzzleOrder, type ProceduralPuzzleId } from "../ProceduralMissionLayout";

export type MissionSystemNode = ProceduralPuzzleId | "door";

type SolverState = (node: ProceduralPuzzleId) => boolean;

const dependencies: Record<MissionSystemNode, ProceduralPuzzleId[]> = {
  language: [],
  circuit: [],
  math: [],
  english: [],
  robot: [],
  coding: [],
  music: [],
  physics: [],
  door: [...proceduralPuzzleOrder],
};

const nodeLabels: Record<MissionSystemNode, string> = {
  language: "segnale testuale",
  circuit: "energia del circuito",
  math: "terminale numerico",
  english: "comando operativo",
  robot: "canale robot",
  coding: "console algoritmica",
  music: "pentagramma",
  physics: "banco fisico",
  door: "porta di uscita",
};

const effectLines: Record<MissionSystemNode, string> = {
  language: "Il segnale testuale è stabile: il log della stanza ora è più leggibile.",
  circuit: "Il circuito è stabile: la stanza registra energia affidabile.",
  math: "Il terminale numerico ha accettato una soluzione verificata.",
  english: "Il comando operativo è stato interpretato senza ambiguità.",
  robot: "Il robot ha completato una sequenza coerente.",
  coding: "La console algoritmica ha confermato tracing, stato e logica.",
  music: "Il pentagramma è stato letto con chiave, posizione e ottava corrette.",
  physics: "Il fenomeno fisico è stato letto con misure, modello e controllo.",
  door: "La porta si apre solo quando tutti i sistemi confermano lo stesso stato.",
};

export class MissionDependencyGraph {
  canOperate(node: MissionSystemNode, solved: SolverState): boolean {
    return this.blockers(node, solved).length === 0;
  }

  blockers(node: MissionSystemNode, solved: SolverState): ProceduralPuzzleId[] {
    return dependencies[node].filter((dependency) => !solved(dependency));
  }

  statusLine(node: MissionSystemNode, solved: SolverState): string {
    const blockers = this.blockers(node, solved);
    if (blockers.length === 0) {
      return `${nodeLabels[node]} pronto: puoi intervenire quando vuoi.`;
    }
    return `${nodeLabels[node]} attende ancora conferme da: ${blockers.map((item) => nodeLabels[item]).join(", ")}.`;
  }

  effectLine(node: MissionSystemNode): string {
    return effectLines[node];
  }

  nextAction(solved: SolverState): MissionSystemNode {
    const chain: MissionSystemNode[] = [...proceduralPuzzleOrder, "door"];
    return chain.find((node) => node === "door" || !solved(node)) ?? "door";
  }
}
