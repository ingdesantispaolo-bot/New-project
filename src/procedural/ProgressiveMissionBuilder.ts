import type {
  DifficultyLevel,
  GeneratedMission,
  GeneratedObjective,
  GeneratedRoomHotspot,
  ProceduralPuzzleKind,
  ProceduralSpecialization,
} from "./ProceduralTypes";
import { Random } from "./Random";

type ProgressiveDiscipline = Exclude<ProceduralPuzzleKind, "robot">;

const disciplineLabels: Record<ProgressiveDiscipline, { label: string; description: string }> = {
  language: {
    label: "Ripara il segnale",
    description: "Sistema un messaggio tecnico: forma e significato devono restare operativi.",
  },
  circuit: {
    label: "Diagnostica energia",
    description: "Leggi sintomi e componenti prima di scegliere l'intervento sul circuito.",
  },
  math: {
    label: "Calcola il codice",
    description: "Usa un ragionamento numerico verificabile, non tentativi a caso.",
  },
  english: {
    label: "Decodifica comando",
    description: "Trasforma l'istruzione inglese in una scelta sicura.",
  },
  coding: {
    label: "Verifica algoritmo",
    description: "Segui righe, variabili, condizioni o debug per prevedere il sistema.",
  },
  music: {
    label: "Leggi il pentagramma",
    description: "Riconosci la nota dal segno sul pentagramma prima che il timer prema.",
  },
};

const disciplinePositions: Record<ProgressiveDiscipline, { x: number; y: number; radius: number }> = {
  language: { x: 382, y: 472, radius: 42 },
  circuit: { x: 312, y: 256, radius: 52 },
  math: { x: 640, y: 220, radius: 56 },
  english: { x: 914, y: 254, radius: 50 },
  coding: { x: 914, y: 502, radius: 54 },
  music: { x: 640, y: 502, radius: 52 },
};

const levelFocuses: Record<DifficultyLevel, ProceduralSpecialization> = {
  1: "italiano",
  2: "matematica",
  3: "inglese",
  4: "coding",
  5: "elettronica",
  6: "musica",
  7: "matematica",
  8: "coding",
};

type ProgressiveLevelBlueprint = {
  goal: string;
  synthesisPrompt: string;
  synthesisCorrect: string;
  synthesisDistractors: [string, string];
  synthesisExplanation: string;
};

const levelBlueprints: Record<DifficultyLevel, ProgressiveLevelBlueprint> = {
  1: {
    goal: "Riconoscere il dato chiave e rispettare una sequenza semplice.",
    synthesisPrompt: "Quale metodo collega messaggio, calcolo e comando finale?",
    synthesisCorrect: "Leggo il segnale, ricavo il dato e solo dopo eseguo il comando.",
    synthesisDistractors: ["Provo subito ogni comando disponibile.", "Scelgo la console con il punteggio più alto e ignoro le altre."],
    synthesisExplanation: "Le tre discipline formano una catena: comprensione, trasformazione del dato, azione sicura.",
  },
  2: {
    goal: "Combinare dati numerici e vincoli tecnici senza perdere l'ordine.",
    synthesisPrompt: "Il codice è corretto ma il circuito non risponde: quale controllo viene prima?",
    synthesisCorrect: "Verifico continuità e vincoli del circuito, poi applico il codice nel punto corretto.",
    synthesisDistractors: ["Cambio il risultato matematico finché il circuito si accende.", "Ignoro il circuito perché il calcolo è già corretto."],
    synthesisExplanation: "Un risultato corretto non basta se il sistema che deve usarlo non rispetta i propri vincoli.",
  },
  3: {
    goal: "Tradurre condizioni linguistiche in decisioni logiche verificabili.",
    synthesisPrompt: "Come trasformi un comando inglese con una condizione in un'azione sicura?",
    synthesisCorrect: "Isolo condizione e divieto, li trasformo in controlli logici, poi verifico il dato.",
    synthesisDistractors: ["Traduco soltanto il verbo principale.", "Eseguo prima l'azione e controllo la condizione dopo."],
    synthesisExplanation: "Lingua, matematica e coding convergono quando una frase diventa una regola eseguibile.",
  },
  4: {
    goal: "Prevedere una procedura prima di eseguirla e riconoscere pattern.",
    synthesisPrompt: "Qual è il controllo migliore prima di avviare un algoritmo?",
    synthesisCorrect: "Simulo i passaggi con un caso concreto e confronto il risultato con tutti i vincoli.",
    synthesisDistractors: ["Controllo soltanto la prima istruzione.", "Avvio più volte il programma e tengo il risultato più comune."],
    synthesisExplanation: "Calcolo, linguaggio e pattern diventano strumenti per prevedere l'effetto del codice.",
  },
  5: {
    goal: "Diagnosticare cause multiple distinguendo sintomo, dato e intervento.",
    synthesisPrompt: "Due console segnalano lo stesso sintomo: come scegli la riparazione?",
    synthesisCorrect: "Confronto le prove di ogni sistema e intervengo solo sulla causa compatibile con tutte.",
    synthesisDistractors: ["Applico entrambe le riparazioni per sicurezza.", "Scelgo la causa indicata dalla console più veloce."],
    synthesisExplanation: "La diagnosi interdisciplinare usa più fonti per escludere interventi inutili.",
  },
  6: {
    goal: "Riconoscere strutture e ritmi trasformandoli in sequenze controllabili.",
    synthesisPrompt: "Come può un pattern musicale aiutare a verificare una sequenza tecnica?",
    synthesisCorrect: "Confronto ordine, ripetizioni e variazioni: lo stesso pattern deve restare coerente nei due sistemi.",
    synthesisDistractors: ["Uso soltanto la nota più alta come comando.", "La musica non può fornire informazioni a un algoritmo."],
    synthesisExplanation: "Ritmo e algoritmo condividono ordine, ripetizione, previsione e controllo delle variazioni.",
  },
  7: {
    goal: "Gestire informazioni incomplete e scegliere una conclusione proporzionata alle prove.",
    synthesisPrompt: "I dati sono coerenti ma incompleti: quale conclusione è certificabile?",
    synthesisCorrect: "Formulo una conclusione limitata ai dati disponibili e segnalo ciò che resta da verificare.",
    synthesisDistractors: ["Completo i dati mancanti con l'ipotesi più probabile.", "Dichiaro il sistema risolto perché non ci sono contraddizioni."],
    synthesisExplanation: "Pensiero critico significa distinguere ciò che le prove mostrano da ciò che resta ipotesi.",
  },
  8: {
    goal: "Integrare tutte le discipline in una decisione tecnica spiegabile.",
    synthesisPrompt: "Quando il nucleo può essere dichiarato stabile?",
    synthesisCorrect: "Quando dati, istruzioni, calcoli e simulazione sostengono la stessa conclusione senza conflitti.",
    synthesisDistractors: ["Quando ogni console ha prodotto almeno un risultato.", "Quando il punteggio totale supera quello della run precedente."],
    synthesisExplanation: "La certificazione finale richiede coerenza tra prove diverse, non una somma di risposte isolate.",
  },
};

const levelPools: Record<DifficultyLevel, ProgressiveDiscipline[]> = {
  1: ["language", "math", "english"],
  2: ["language", "math", "english", "circuit"],
  3: ["math", "english", "coding", "circuit"],
  4: ["language", "math", "coding", "music"],
  5: ["circuit", "math", "english", "coding", "music"],
  6: ["language", "circuit", "math", "english", "coding"],
  7: ["circuit", "math", "english", "coding", "music"],
  8: ["language", "circuit", "math", "english", "coding", "music"],
};

const focusDisciplines: Record<ProceduralSpecialization, ProgressiveDiscipline | undefined> = {
  libera: undefined,
  matematica: "math",
  italiano: "language",
  inglese: "english",
  elettronica: "circuit",
  coding: "coding",
  musica: "music",
};

export class ProgressiveMissionBuilder {
  focusForLevel(level: DifficultyLevel): ProceduralSpecialization {
    return levelFocuses[level];
  }

  blueprintForLevel(level: DifficultyLevel): ProgressiveLevelBlueprint {
    return levelBlueprints[level];
  }

  buildLevelMission(base: GeneratedMission, level: DifficultyLevel): GeneratedMission {
    const random = new Random(`${base.seed}:progressive:${level}`);
    // A progressive level must combine disciplines. Focus challenges are ideal
    // for training mode, but using them here turned the entire level into a
    // sequence from one subject and made levelPools unreachable.
    const selected = this.selectDisciplines(random, level);
    const objectives = selected.map((kind) => this.objectiveFor(base, kind));
    const hotspots = selected.map((kind) => this.hotspotFor(kind));
    const pathLabel = selected.map((kind) => disciplineLabels[kind].label.toLowerCase()).join(" -> ");
    return {
      ...base,
      id: `mission-progressive-level-${level}`,
      title: `Scalata dell'Accademia - Livello ${level}`,
      intro: [
        `Livello ${level}/8: la stanza propone una sequenza guidata a difficolta crescente.`,
        `Obiettivo: ${this.blueprintForLevel(level).goal}`,
        "Completa ogni console entro tempo e vite. Il livello successivo si sblocca solo con successo.",
        `Sequenza: ${pathLabel}.`,
      ].join(" "),
      objectives,
      map: {
        ...base.map,
        id: `progressive-room-${level}`,
        title: this.roomTitle(level),
        hotspots: [
          ...hotspots,
          {
            id: "door",
            label: "Porta di livello",
            x: 610,
            y: 504,
            radius: 64,
            description: "Si apre solo quando tutte le console del livello sono coerenti.",
          },
        ],
      },
      competencies: Array.from(new Set(objectives.flatMap((objective) => objective.competencies))),
      rewards: [
        {
          badgeId: `scalata-livello-${level}`,
          label: `Stanza ${level} stabilizzata`,
          description: "Ha superato una stanza interdisciplinare a difficoltà crescente.",
        },
        ...base.rewards,
      ],
    };
  }

  timeLimitMs(level: DifficultyLevel, objectiveCount: number): number {
    const secondsPerObjective = Math.max(34, 74 - level * 5);
    return Math.max(145, objectiveCount * secondsPerObjective + 35) * 1000;
  }

  private selectDisciplines(random: Random, level: DifficultyLevel): ProgressiveDiscipline[] {
    const pool = levelPools[level];
    const targetCount = Math.min(pool.length, level <= 1 ? 3 : level <= 4 ? 4 : level <= 7 ? 5 : 6);
    const primary = focusDisciplines[this.focusForLevel(level)];
    const mustHave = Array.from(new Set<ProgressiveDiscipline>([
      ...(primary ? [primary] : []),
      ...(level >= 5 ? ["math", "coding"] as ProgressiveDiscipline[] : level >= 3 ? ["math"] as ProgressiveDiscipline[] : []),
    ])).filter((kind) => pool.includes(kind));
    const rest = random.shuffle(pool.filter((kind) => !mustHave.includes(kind)));
    return [...mustHave, ...rest].slice(0, targetCount);
  }

  private objectiveFor(base: GeneratedMission, kind: ProgressiveDiscipline): GeneratedObjective {
    const puzzle = base.puzzles[kind];
    return {
      id: `procedural-${kind}`,
      label: disciplineLabels[kind].label,
      description: disciplineLabels[kind].description,
      competencies: puzzle.competencies,
    };
  }

  private hotspotFor(kind: ProgressiveDiscipline): GeneratedRoomHotspot {
    const position = disciplinePositions[kind];
    return {
      id: kind,
      label: disciplineLabels[kind].label,
      x: position.x,
      y: position.y,
      radius: position.radius,
      puzzleId: kind,
      puzzleKind: kind,
      description: disciplineLabels[kind].description,
    };
  }

  private roomTitle(level: DifficultyLevel): string {
    return [
      "Sala delle Tracce",
      "Sala dei Vincoli",
      "Galleria dei Sistemi",
      "Nucleo delle Decisioni",
      "Anello dei Codici",
      "Camera delle Interferenze",
      "Osservatorio Critico",
      "Nucleo dell'Accademia",
    ][level - 1];
  }
}

export const progressiveMissionBuilder = new ProgressiveMissionBuilder();
