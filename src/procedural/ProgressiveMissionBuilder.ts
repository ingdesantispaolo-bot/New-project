import type {
  CircuitFaultType,
  CodingChallengeType,
  DifficultyLevel,
  GeneratedMathPuzzle,
  GeneratedMission,
  GeneratedObjective,
  GeneratedRoomHotspot,
  ProceduralPuzzleKind,
  ProceduralSpecialization,
} from "./ProceduralTypes";
import { Random } from "./Random";
import { difficultyModel } from "./DifficultyModel";
import { MathPuzzleGenerator } from "./generators/MathPuzzleGenerator";
import { EnglishInstructionGenerator } from "./generators/EnglishInstructionGenerator";
import { LanguageCorruptionGenerator } from "./generators/LanguageCorruptionGenerator";
import { CircuitFaultGenerator } from "./generators/CircuitFaultGenerator";
import { CodingPuzzleGenerator } from "./generators/CodingPuzzleGenerator";
import { MusicNoteGenerator } from "./generators/MusicNoteGenerator";
import { MathPuzzleValidator } from "./validators/MathPuzzleValidator";
import { CodingPuzzleValidator } from "./validators/CodingPuzzleValidator";
import { CircuitPuzzleValidator } from "./validators/CircuitPuzzleValidator";
import { LanguagePuzzleValidator } from "./validators/LanguagePuzzleValidator";
import { exerciseDirector } from "../core/ExerciseDirector";

/** Rolling memory of recently shown exercise signatures, across levels and runs. */
const RECENT_SIGNATURES_KEY = "eli-quest:progressive-recent-signatures";
const RECENT_SIGNATURES_CAP = 48;

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
  synthesisSteps: [string, string, string];
  synthesisExplanation: string;
};

const levelBlueprints: Record<DifficultyLevel, ProgressiveLevelBlueprint> = {
  1: {
    goal: "Riconoscere il dato chiave e rispettare una sequenza semplice.",
    synthesisPrompt: "Quale metodo collega messaggio, calcolo e comando finale?",
    synthesisCorrect: "Leggo il segnale, ricavo il dato e solo dopo eseguo il comando.",
    synthesisDistractors: ["Provo subito ogni comando disponibile.", "Scelgo la console con il punteggio più alto e ignoro le altre."],
    synthesisSteps: ["Leggi il segnale", "Ricava il dato", "Esegui il comando"],
    synthesisExplanation: "Le tre discipline formano una catena: comprensione, trasformazione del dato, azione sicura.",
  },
  2: {
    goal: "Combinare dati numerici e vincoli tecnici senza perdere l'ordine.",
    synthesisPrompt: "Il codice è corretto ma il circuito non risponde: quale controllo viene prima?",
    synthesisCorrect: "Verifico continuità e vincoli del circuito, poi applico il codice nel punto corretto.",
    synthesisDistractors: ["Cambio il risultato matematico finché il circuito si accende.", "Ignoro il circuito perché il calcolo è già corretto."],
    synthesisSteps: ["Controlla il circuito", "Verifica i vincoli", "Applica il codice"],
    synthesisExplanation: "Un risultato corretto non basta se il sistema che deve usarlo non rispetta i propri vincoli.",
  },
  3: {
    goal: "Tradurre condizioni linguistiche in decisioni logiche verificabili.",
    synthesisPrompt: "Come trasformi un comando inglese con una condizione in un'azione sicura?",
    synthesisCorrect: "Isolo condizione e divieto, li trasformo in controlli logici, poi verifico il dato.",
    synthesisDistractors: ["Traduco soltanto il verbo principale.", "Eseguo prima l'azione e controllo la condizione dopo."],
    synthesisSteps: ["Isola condizione e divieto", "Trasforma in controlli", "Verifica il dato"],
    synthesisExplanation: "Lingua, matematica e coding convergono quando una frase diventa una regola eseguibile.",
  },
  4: {
    goal: "Prevedere una procedura prima di eseguirla e riconoscere pattern.",
    synthesisPrompt: "Qual è il controllo migliore prima di avviare un algoritmo?",
    synthesisCorrect: "Simulo i passaggi con un caso concreto e confronto il risultato con tutti i vincoli.",
    synthesisDistractors: ["Controllo soltanto la prima istruzione.", "Avvio più volte il programma e tengo il risultato più comune."],
    synthesisSteps: ["Scegli un caso concreto", "Simula i passaggi", "Confronta tutti i vincoli"],
    synthesisExplanation: "Calcolo, linguaggio e pattern diventano strumenti per prevedere l'effetto del codice.",
  },
  5: {
    goal: "Diagnosticare cause multiple distinguendo sintomo, dato e intervento.",
    synthesisPrompt: "Due console segnalano lo stesso sintomo: come scegli la riparazione?",
    synthesisCorrect: "Confronto le prove di ogni sistema e intervengo solo sulla causa compatibile con tutte.",
    synthesisDistractors: ["Applico entrambe le riparazioni per sicurezza.", "Scelgo la causa indicata dalla console più veloce."],
    synthesisSteps: ["Raccogli le prove", "Escludi cause incompatibili", "Intervieni sulla causa comune"],
    synthesisExplanation: "La diagnosi interdisciplinare usa più fonti per escludere interventi inutili.",
  },
  6: {
    goal: "Riconoscere strutture e ritmi trasformandoli in sequenze controllabili.",
    synthesisPrompt: "Come può un pattern musicale aiutare a verificare una sequenza tecnica?",
    synthesisCorrect: "Confronto ordine, ripetizioni e variazioni: lo stesso pattern deve restare coerente nei due sistemi.",
    synthesisDistractors: ["Uso soltanto la nota più alta come comando.", "La musica non può fornire informazioni a un algoritmo."],
    synthesisSteps: ["Rileva il pattern", "Confronta le variazioni", "Verifica la sequenza tecnica"],
    synthesisExplanation: "Ritmo e algoritmo condividono ordine, ripetizione, previsione e controllo delle variazioni.",
  },
  7: {
    goal: "Gestire informazioni incomplete e scegliere una conclusione proporzionata alle prove.",
    synthesisPrompt: "I dati sono coerenti ma incompleti: quale conclusione è certificabile?",
    synthesisCorrect: "Formulo una conclusione limitata ai dati disponibili e segnalo ciò che resta da verificare.",
    synthesisDistractors: ["Completo i dati mancanti con l'ipotesi più probabile.", "Dichiaro il sistema risolto perché non ci sono contraddizioni."],
    synthesisSteps: ["Separa dati e ipotesi", "Formula una conclusione limitata", "Segnala cosa manca"],
    synthesisExplanation: "Pensiero critico significa distinguere ciò che le prove mostrano da ciò che resta ipotesi.",
  },
  8: {
    goal: "Integrare tutte le discipline in una decisione tecnica spiegabile.",
    synthesisPrompt: "Quando il nucleo può essere dichiarato stabile?",
    synthesisCorrect: "Quando dati, istruzioni, calcoli e simulazione sostengono la stessa conclusione senza conflitti.",
    synthesisDistractors: ["Quando ogni console ha prodotto almeno un risultato.", "Quando il punteggio totale supera quello della run precedente."],
    synthesisSteps: ["Confronta tutte le prove", "Risolvi i conflitti", "Certifica la conclusione comune"],
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
  private readonly mathGen = new MathPuzzleGenerator();
  private readonly languageGen = new LanguageCorruptionGenerator();
  private readonly englishGen = new EnglishInstructionGenerator();
  private readonly circuitGen = new CircuitFaultGenerator();
  private readonly codingGen = new CodingPuzzleGenerator();
  private readonly musicGen = new MusicNoteGenerator();
  private readonly mathValidator = new MathPuzzleValidator();
  private readonly codingValidator = new CodingPuzzleValidator();
  private readonly circuitValidator = new CircuitPuzzleValidator();
  private readonly languageValidator = new LanguagePuzzleValidator();

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
    const selected = this.selectDisciplines(random, level, base.seed);
    const variedBase = this.withNonRepeatingExercises(base, level, selected);
    const objectives = selected.map((kind) => this.objectiveFor(variedBase, kind));
    const hotspots = selected.map((kind) => this.hotspotFor(kind));
    const pathLabel = selected.map((kind) => disciplineLabels[kind].label.toLowerCase()).join(" -> ");
    return {
      ...variedBase,
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
        ...variedBase.map,
        id: `progressive-room-${level}`,
        title: this.roomTitle(level),
        hotspots: [
          ...hotspots,
          {
            id: "door",
            label: "Porta di livello",
            x: 640,
            y: 650,
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
        ...variedBase.rewards,
      ],
    };
  }

  /**
   * Guarantees that no exercise repeats across the climb. For every selected
   * discipline it checks the puzzle's substance signature (template + answer +
   * prompt) against a rolling memory of recently shown exercises and the others
   * in this same level; on a collision it re-rolls that discipline with its own
   * generator — fresh sub-seed and rotated templates/archetypes — until a
   * genuinely new exercise is found, then records it.
   */
  private withNonRepeatingExercises(
    base: GeneratedMission,
    level: DifficultyLevel,
    selected: ProgressiveDiscipline[],
  ): GeneratedMission {
    const recent = this.readRecentSignatures();
    const usedThisLevel = new Set<string>();
    const taken = (signature: string): boolean => recent.includes(signature) || usedThisLevel.has(signature);

    let mission = base;
    for (const kind of selected) {
      let signature = this.signatureFor(mission, kind);
      // The base math objective is always a graph workshop; away from the
      // maths-focus levels (where it is the intended showcase) we vary the form
      // toward the rich template pool so the climb is not all "officina grafici".
      const forceVary = kind === "math"
        && Boolean(mission.puzzles.math.graphWorkshop)
        && this.focusForLevel(level) !== "matematica";
      if (taken(signature) || forceVary) {
        for (let attempt = 0; attempt < 24; attempt += 1) {
          const candidate = this.rerollPuzzle(mission, kind, level, attempt);
          if (candidate === mission) continue;
          const candidateSignature = this.signatureFor(candidate, kind);
          if (!taken(candidateSignature)) {
            mission = candidate;
            signature = candidateSignature;
            break;
          }
        }
      }
      usedThisLevel.add(signature);
    }

    this.writeRecentSignatures([...usedThisLevel, ...recent]);
    return mission;
  }

  private signatureFor(mission: GeneratedMission, kind: ProgressiveDiscipline): string {
    const puzzles = mission.puzzles;
    const norm = (text: string): string => text.replace(/\s+/g, " ").trim();
    switch (kind) {
      case "math": {
        const m = puzzles.math;
        // Workshops carry their distinguishing data in target parameters, not in
        // the (placeholder) answer — include them so different lines/curves count
        // as different exercises.
        const workshop = m.graphWorkshop
          ? `|gw:${m.graphWorkshop.parameters.map((p) => `${p.key}=${p.target}`).join(",")};${m.graphWorkshop.targetPoints.map((pt) => `${pt.x}:${pt.y}`).join("|")}`
          : "";
        const lab = m.equationLab ? `|eq:${m.equationLab.roots.join(",")}` : "";
        return `math|${m.archetype ?? "base"}|${m.answer}|${norm(m.prompt)}${workshop}${lab}`;
      }
      case "language":
        return `language|${puzzles.language.id}|${puzzles.language.repaired}|${puzzles.language.learningPurpose ?? ""}`;
      case "english":
        return `english|${puzzles.english.id}|${norm(puzzles.english.instruction)}|${puzzles.english.choices.find((choice) => choice.isCorrect)?.label ?? ""}`;
      case "coding":
        return `coding|${puzzles.coding.challengeType}|${norm(puzzles.coding.question)}|${puzzles.coding.correctOption}`;
      case "circuit":
        return `circuit|${puzzles.circuit.scenarioType ?? ""}|${norm(puzzles.circuit.symptom)}|${puzzles.circuit.requiredRepairs.join(",")}`;
      case "music":
        return `music|${puzzles.music.clef}|${puzzles.music.noteName}|${puzzles.music.octave}|${puzzles.music.challengeMode}`;
    }
    return "";
  }

  /** Generates a fresh, validated puzzle for one discipline with rotated variety. */
  private rerollPuzzle(
    base: GeneratedMission,
    kind: ProgressiveDiscipline,
    level: DifficultyLevel,
    attempt: number,
  ): GeneratedMission {
    const preset = difficultyModel.getPreset(level);
    const random = new Random(`${base.seed}:reroll:${kind}:${level}:${attempt}`);
    switch (kind) {
      case "math": {
        const raw = this.mathGen.generate(random, preset, this.mathArchetypesForProgressive(level, attempt));
        if (!this.mathValidator.validate(raw)) return base;
        return { ...base, puzzles: { ...base.puzzles, math: exerciseDirector.enrichMath(raw, level) } };
      }
      case "language": {
        const puzzle = this.languageGen.generate(random, level, this.languageTemplateIdsForProgressive(level, attempt));
        return this.languageValidator.validateItalian(puzzle) ? { ...base, puzzles: { ...base.puzzles, language: puzzle } } : base;
      }
      case "english": {
        const puzzle = this.englishGen.generate(random, level, this.englishTemplateIdsForProgressive(level, attempt));
        return this.languageValidator.validateEnglish(puzzle) ? { ...base, puzzles: { ...base.puzzles, english: puzzle } } : base;
      }
      case "coding": {
        const puzzle = this.codingGen.generate(random, preset, this.codingTypesForProgressive(level, attempt));
        return this.codingValidator.validate(puzzle) ? { ...base, puzzles: { ...base.puzzles, coding: puzzle } } : base;
      }
      case "circuit": {
        const raw = this.circuitGen.generate(random, preset, this.circuitFaultsForProgressive(level, attempt));
        if (!this.circuitValidator.validate(raw)) return base;
        return { ...base, puzzles: { ...base.puzzles, circuit: exerciseDirector.enrichCircuit(raw, level) } };
      }
      case "music": {
        const puzzle = this.musicGen.generate(random, level);
        return { ...base, puzzles: { ...base.puzzles, music: puzzle } };
      }
    }
    return base;
  }

  private mathArchetypesForProgressive(level: DifficultyLevel, attempt: number): Array<NonNullable<GeneratedMathPuzzle["archetype"]>> {
    // Avoids graph/equation archetypes on purpose: those route to the low-variety
    // graph workshop / equation lab, defeating de-duplication. Re-rolls always use
    // the rich, high-entropy template pool instead.
    const pools: Array<Array<NonNullable<GeneratedMathPuzzle["archetype"]>>> = [
      ["calcolo-diretto", "frazioni", "percentuali", "lettura-dati", "sequenza"],
      ["sequenza", "statistica", "vincolo", "lettura-dati", "percentuali", "frazioni"],
      ["vincolo", "proporzione", "geometria", "probabilita", "percentuali", "frazioni", "statistica"],
      ["ragionamento-inverso", "pre-algebra", "proporzione", "statistica", "probabilita", "geometria"],
      ["diagnosi-errore", "potenze-radici", "geometria", "sistemi-lineari", "probabilita", "ragionamento-inverso", "pre-algebra", "proporzione"],
    ];
    const maxIndex = level <= 2 ? 1 : level <= 4 ? 2 : level <= 6 ? 3 : 4;
    return pools[(attempt + level) % (maxIndex + 1)];
  }

  private codingTypesForProgressive(level: DifficultyLevel, attempt: number): CodingChallengeType[] {
    const pools: CodingChallengeType[][] = [
      ["trace-output", "variable-state"],
      ["variable-state", "loop-count"],
      ["loop-count", "conditional-branch"],
      ["conditional-branch", "boolean-logic"],
      ["debug-line", "boolean-logic", "loop-count"],
    ];
    const maxIndex = level <= 2 ? 1 : level <= 4 ? 2 : level <= 6 ? 3 : 4;
    return pools[(attempt + level) % (maxIndex + 1)];
  }

  private circuitFaultsForProgressive(level: DifficultyLevel, attempt: number): CircuitFaultType[] {
    const pools: CircuitFaultType[][] = [
      ["missing-wire", "open-switch"],
      ["missing-resistor", "wrong-resistor-value", "reversed-led"],
      ["sensor-unpowered", "disconnected-component", "short-circuit"],
      ["parallel-branch-open", "capacitor-discharged", "loose-ground"],
      ["relay-not-armed", "short-circuit", "wrong-resistor-value", "parallel-branch-open"],
    ];
    const maxIndex = level <= 2 ? 1 : level <= 4 ? 2 : level <= 6 ? 3 : 4;
    return pools[(attempt + level) % (maxIndex + 1)];
  }

  private readRecentSignatures(): string[] {
    try {
      const raw = globalThis.localStorage?.getItem(RECENT_SIGNATURES_KEY);
      const parsed = raw ? (JSON.parse(raw) as unknown) : [];
      return Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === "string") : [];
    } catch {
      return [];
    }
  }

  private writeRecentSignatures(signatures: string[]): void {
    try {
      const unique = Array.from(new Set(signatures)).slice(0, RECENT_SIGNATURES_CAP);
      globalThis.localStorage?.setItem(RECENT_SIGNATURES_KEY, JSON.stringify(unique));
    } catch {
      // Storage is optional; fresh mission entropy still changes most exercises.
    }
  }

  private languageTemplateIdsForProgressive(level: DifficultyLevel, attempt: number): string[] {
    const pools: string[][] = [
      ["single-generator", "north-sensor", "sealed-door", "unstable-log", "robot-report", "apostrophe-accent", "ha-a-control"],
      ["cause-effect-cooling", "sequence-before-after", "useful-vs-noise", "direct-indirect-pronouns", "concessive-although"],
      ["pronoun-reference", "relative-clause", "relative-cui", "punctuation-safety", "technical-summary"],
      ["conditional-alert", "source-reliability", "passive-active", "reported-speech-log", "main-idea-summary"],
      ["lexical-precision", "nominalization-precision", "thesis-evidence", "register-formal", "period-hypothesis", "implicit-subject"],
    ];
    const maxIndex = level <= 2 ? 1 : level <= 4 ? 2 : level <= 6 ? 3 : 4;
    return pools[(attempt + level - 1) % (maxIndex + 1)];
  }

  private englishTemplateIdsForProgressive(level: DifficultyLevel, attempt: number): string[] {
    const pools: string[][] = [
      ["green-not-red", "small-key", "where-is-core", "who-can-open", "main-switch", "possessive-their-its", "movement-prepositions-route"],
      ["left-before-blue", "inspect-record-reset", "measure-before-switch", "simple-vs-now", "past-log-today", "some-any-fuses", "much-many-supplies", "present-perfect-already-yet"],
      ["procedure-debug-charge", "sensor-below-threshold", "at-least-three-pulses", "frequency-adverbs", "first-conditional-alarm", "zero-conditional-rule", "adverbs-manner-safety"],
      ["only-if-stable", "compare-two-signals", "neither-red-nor-yellow", "replace-only-damaged", "which-route-safest", "relative-drawer", "going-to-scan", "past-vs-present-perfect-log", "although-however-report", "main-idea-log", "detail-not-mentioned", "question-formation-why", "relative-where-lab"],
      ["cause-report", "between-limits", "unless-blue-blinks", "until-door-unlocks", "not-until-pressure-drops", "must-should-cable", "may-must-not", "passive-reattach-wire", "pronoun-reference", "as-as-comparison", "passive-simple-past", "have-to-vs-can", "word-formation-re-over", "scientific-observation-evidence", "reported-warning", "either-neither-tool", "multi-clause-mission-order", "email-register-formal"],
    ];
    const maxIndex = level <= 2 ? 1 : level <= 4 ? 2 : level <= 6 ? 3 : 4;
    return pools[(attempt + level) % (maxIndex + 1)];
  }

  timeLimitMs(level: DifficultyLevel, objectiveCount: number): number {
    const secondsPerObjective = Math.max(34, 74 - level * 5);
    return Math.max(145, objectiveCount * secondsPerObjective + 35) * 1000;
  }

  private selectDisciplines(random: Random, level: DifficultyLevel, seed: string): ProgressiveDiscipline[] {
    const pool = levelPools[level];
    const targetCount = Math.min(pool.length, level <= 1 ? 3 : level <= 4 ? 4 : level <= 7 ? 5 : 6);
    const primary = focusDisciplines[this.focusForLevel(level)];
    const mustHave = Array.from(new Set<ProgressiveDiscipline>([
      ...(primary ? [primary] : []),
      ...(level >= 5 ? ["math", "coding"] as ProgressiveDiscipline[] : level >= 3 ? ["math"] as ProgressiveDiscipline[] : []),
    ])).filter((kind) => pool.includes(kind));
    const rest = random.shuffle(pool.filter((kind) => !mustHave.includes(kind)));
    const selected = [...mustHave, ...rest].slice(0, targetCount);
    return this.nonRepeatingOrder(random, level, seed, selected);
  }

  private nonRepeatingOrder(
    random: Random,
    level: DifficultyLevel,
    seed: string,
    selected: ProgressiveDiscipline[],
  ): ProgressiveDiscipline[] {
    if (selected.length < 2) return selected;
    const storageKey = `eli-quest:progressive-order:${level}`;
    let previousSeed = "";
    let previousOrder = "";
    try {
      const stored = JSON.parse(globalThis.localStorage?.getItem(storageKey) ?? "{}") as { seed?: string; order?: string };
      previousSeed = stored.seed ?? "";
      previousOrder = stored.order ?? "";
      if (previousSeed === seed && previousOrder) {
        const restored = previousOrder.split(",") as ProgressiveDiscipline[];
        if (restored.length === selected.length && restored.every((kind) => selected.includes(kind))) return restored;
      }
    } catch {
      // Storage is optional; the random order still varies with the mission seed.
    }

    let ordered = random.shuffle(selected);
    if (ordered.join(",") === previousOrder) {
      ordered = [...ordered.slice(1), ordered[0]];
    }
    try {
      globalThis.localStorage?.setItem(storageKey, JSON.stringify({ seed, order: ordered.join(",") }));
    } catch {
      // Storage is optional.
    }
    return ordered;
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
