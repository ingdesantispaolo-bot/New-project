import { masterySystem } from "./MasterySystem";
import { proceduralRunRules } from "./ProceduralRunRules";
import { proceduralScoring } from "./ProceduralScoring";
import { saveSystem } from "./SaveSystem";
import type { ProceduralRunSave, ProceduralPuzzleKind, ProceduralSpecialization } from "../procedural/ProceduralTypes";

export type NoraContextBeat =
  | "enter"
  | "open"
  | "solve"
  | "mistake"
  | "hint"
  | "streak"
  | "lowLife"
  | "victory"
  | "defeat"
  | "scaffold";

export type NoraContext = {
  run?: ProceduralRunSave;
  kind?: ProceduralPuzzleKind;
  attempts?: number;
  hintsUsed?: number;
  streak?: number;
};

const KIND_LABELS: Record<ProceduralPuzzleKind, string> = {
  language: "segnale linguistico",
  latin: "tavola latina",
  circuit: "circuito",
  math: "terminale numerico",
  english: "comando inglese",
  robot: "robot",
  coding: "console algoritmica",
  music: "sequenza musicale",
  physics: "banco fisico",
};

const KIND_METHODS: Record<ProceduralPuzzleKind, string> = {
  language: "cerca prima chi fa cosa, poi scegli la forma più chiara",
  latin: "parti dalla desinenza: funzione, numero, poi senso",
  circuit: "segui il percorso della corrente prima di toccare i pezzi",
  math: "nomina il vincolo, poi fai un passaggio alla volta",
  english: "isola azione, limite e condizione: il resto è rumore",
  robot: "guarda ostacoli e direzione prima della prima mossa",
  coding: "simula una riga alla volta: stato, ciclo, uscita",
  music: "aggancia la nota guida, poi conta posizione e intervallo",
  physics: "metti insieme grandezza, unità e modello prima del numero",
};

function kindLabel(kind?: ProceduralPuzzleKind): string {
  return kind ? KIND_LABELS[kind] : "sistema";
}

function kindMethod(kind?: ProceduralPuzzleKind): string {
  return kind ? KIND_METHODS[kind] : "osserva il sintomo chiave prima di agire";
}

function recurrentMistakes(kind?: ProceduralPuzzleKind): number {
  if (!kind) return 0;
  const concept = saveSystem.data.learningMemory?.[`${kind}:concept`]?.count ?? 0;
  const evidence = saveSystem.data.learningMemory?.[`${kind}:evidence`]?.count ?? 0;
  return Math.max(concept, evidence);
}

class NoraContextEngine {
  line(beat: NoraContextBeat, context: NoraContext = {}): string {
    const run = context.run;
    const mode = run ? proceduralRunRules.modeFor(run) : "mission";
    const focus = run ? proceduralRunRules.focusFor(run) : "libera";
    const kind = context.kind;
    const recurrent = recurrentMistakes(kind);
    const depth = run?.difficulty ?? 1;

    if (beat === "enter") {
      if (mode === "progressive") return `Sono con te nella scalata. Profondità ${depth}: non corriamo, leggiamo il settore.`;
      if (mode === "training") return `Calibrazione aperta su ${proceduralScoring.domainLabel(focus)}. Io osservo il metodo, non il voto.`;
      if (run?.chapterMissionId) return "Il sabotatore forza il tempo. Io tengo stabile il segnale, tu resta sulla causa.";
      return `Stanza aperta. Profondità ${depth}: una console alla volta, e la mappa diventa leggibile.`;
    }

    if (beat === "open") {
      if (recurrent >= 3) return `Questo ${kindLabel(kind)} ti ha già fatto inciampare. Ti resto vicina: ${kindMethod(kind)}.`;
      return `Apro il ${kindLabel(kind)}. Prima diagnosi, poi risposta: ${kindMethod(kind)}.`;
    }

    if (beat === "mistake") {
      const attempts = context.attempts ?? 1;
      if (attempts >= 2) return `Secondo segnale sullo stesso nodo. Non cambiare tutto: cambia un solo passaggio e verifica.`;
      return `Errore registrato, non giudizio. Il sintomo utile è ancora lì: ${kindMethod(kind)}.`;
    }

    if (beat === "hint") {
      return `Ti apro una lente, non una scorciatoia. Usala per vedere il primo vincolo del ${kindLabel(kind)}.`;
    }

    if (beat === "solve") {
      const hints = context.hintsUsed ?? 0;
      if (hints === 0 && (context.attempts ?? 1) <= 1) return `Soluzione pulita. L'ho vista: hai scelto metodo prima della velocità.`;
      return `Sistema stabile. Hai corretto la rotta e il settore ha risposto.`;
    }

    if (beat === "streak") {
      return `Serie ${context.streak ?? ""} in corso. Ti sto seguendo: stai anticipando i sintomi, non inseguendoli.`;
    }

    if (beat === "lowLife") return "Siamo al limite, ma non siamo cieche. Una causa, una mossa, una verifica.";
    if (beat === "victory") return "Accademia stabile. Non l'ho fatto io: io ho tenuto la luce, tu hai letto i sistemi.";
    if (beat === "defeat") return "Ci fermiamo, non ci spegniamo. Ora conosco meglio il punto fragile, e anche tu.";
    if (beat === "scaffold") return `Riconosco lo schema. Ti preparo il primo controllo, poi il sistema lo governi tu.`;
    return "Sono qui. Dimmi dove guardiamo.";
  }

  observations(): string[] {
    const observations: string[] = [];
    const weak = masterySystem.weakestPracticedFocus();
    if (weak) {
      observations.push(`Il settore più delicato ora è ${proceduralScoring.domainLabel(weak as ProceduralSpecialization)}. Non è una crepa: è il prossimo punto da rendere stabile.`);
    }

    const memory = Object.entries(saveSystem.data.learningMemory ?? {})
      .filter(([, value]) => value.count > 0)
      .sort((a, b) => b[1].count - a[1].count);
    const [topKey, topValue] = memory[0] ?? [];
    if (topKey && topValue) {
      const kind = topKey.split(":")[0] as ProceduralPuzzleKind;
      observations.push(`Ho notato un nodo ricorrente nel ${kindLabel(kind)}: quando appare, conviene rallentare e nominare il vincolo prima del click.`);
    }

    const records = Object.values(saveSystem.data.trainingRecords ?? {});
    const best = [...records].sort((a, b) => b.bestGrade - a.bestGrade)[0];
    if (best) {
      observations.push(`Quando lavori su ${proceduralScoring.domainLabel(best.focus)}, il tuo metodo è già molto leggibile: miglior voto ${best.bestGrade}/10.`);
    }

    if (observations.length === 0) {
      observations.push("Ti sto ancora conoscendo. Per ora so questo: quando osservi prima di agire, l'Accademia risponde meglio.");
    }
    return observations.slice(0, 3);
  }
}

export const noraContextEngine = new NoraContextEngine();
