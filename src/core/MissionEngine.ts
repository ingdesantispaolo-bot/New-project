import { missions } from "../data/missions";
import type { JournalEntry } from "../types/gameTypes";
import type { MissionDefinition, MissionObjective, ObjectiveStatus } from "../types/missionTypes";
import { isMissionComplete } from "./MissionCompletion";
import { competencyTracker } from "./CompetencyTracker";
import { EventBus, GameEvents } from "./EventBus";
import { playerSystem } from "./PlayerSystem";
import { formatDuration, proceduralScoring } from "./ProceduralScoring";
import { proceduralRunRules } from "./ProceduralRunRules";
import { saveSystem } from "./SaveSystem";
import { assessTrainingRun } from "./TrainingAssessment";

const proceduralOnlyMission: MissionDefinition = {
  id: "mission-procedural-laboratorio-sempre-diverso",
  title: "Laboratorio Sempre Diverso",
  description: "Una stanza generata da seed con sistemi interdipendenti e puzzle validati.",
  openingDialogueId: "procedural-opening",
  objectives: [
    {
      id: "procedural-run",
      label: "Completa una run procedurale",
      description: "Stabilizza testo, circuito, terminale, inglese, robot e porta.",
      competencies: ["problemSolving", "pensieroCritico"],
    },
  ],
  requiredItems: [],
  puzzles: [],
  dialogues: [],
  rewards: [
    {
      badgeId: "custode-del-seed",
      label: "Custode del Seed",
      description: "Completa missioni riproducibili e validate.",
    },
  ],
  competencies: ["problemSolving", "pensieroCritico"],
};

export class MissionEngine {
  getMission(missionId: string): MissionDefinition | undefined {
    return missionId === proceduralOnlyMission.id ? proceduralOnlyMission : proceduralOnlyMission;
  }

  getActiveMission(): MissionDefinition {
    return proceduralOnlyMission;
  }

  /**
   * The active hand-crafted *story* mission: the first campaign mission not yet
   * complete (or the last one if all are done). Unlike getActiveMission(), which
   * returns the procedural stub, this drives the Hub's mission card, primary
   * action and copy so they reflect real story progress.
   */
  getActiveStoryMission(): MissionDefinition {
    return missions.find((mission) => !isMissionComplete(mission.id)) ?? missions[missions.length - 1];
  }

  getObjectiveStatus(objective: MissionObjective): ObjectiveStatus {
    const flags = saveSystem.data.flags;
    if (flags[objective.unlocksFlag ?? objective.id]) {
      return "complete";
    }

    const requiredFlags = objective.requiredFlags ?? [];
    return requiredFlags.every((flag) => flags[flag]) ? "active" : "locked";
  }

  completeObjective(flag: string, competencyIds: string[] = [], amount = 14): void {
    saveSystem.setFlag(flag, true);
    competencyTracker.award(competencyIds, amount);
    EventBus.emit(GameEvents.MissionChanged, this.getActiveMission());
  }

  canOpenFinalDoor(): boolean {
    const flags = saveSystem.data.flags;
    return Boolean(
      flags.grammarFixed &&
        flags.circuitFixed &&
        flags.mathLockSolved &&
        flags.englishInstructionSolved &&
        flags.robotKeyRecovered,
    );
  }

  completeMissionOne(): void {
    const mission = this.getMission("mission-01-laboratorio-spento") ?? this.getActiveMission();
    this.completeMission(mission.id, {
      id: "mission-01-summary",
      title: "Il Laboratorio Spento",
      lines: [
        "Oggi hai scoperto che un circuito deve essere chiuso.",
        "Hai usato un codice matematico.",
        "Hai programmato un robot.",
        "Hai capito un'istruzione in inglese.",
        "Hai riparato una frase corrotta.",
      ],
      badges: mission.rewards.map((reward) => reward.label),
      createdAt: new Date().toISOString(),
    });
    saveSystem.setFlag("mission1Complete", true);
  }

  completeMissionTwo(savedPlantNames: string[]): void {
    const mission = this.getMission("mission-02-serra-biologica") ?? this.getActiveMission();
    this.completeMission(mission.id, {
      id: "mission-02-summary",
      title: "La Serra Biologica",
      lines: [
        `Hai salvato ${savedPlantNames.length} piante: ${savedPlantNames.join(", ")}.`,
        "Hai letto sensori di acqua, luce e temperatura prima di regolare la serra.",
        "Hai usato una tabella dati e un grafico semplice per osservare le conseguenze.",
        "Hai confrontato bisogni diversi: non tutte le piante vogliono le stesse condizioni.",
        "Hai interpretato note scientifiche brevi in inglese.",
      ],
      badges: mission.rewards.map((reward) => reward.label),
      createdAt: new Date().toISOString(),
    });
    saveSystem.setFlag("mission2Complete", true);
  }

  completeMissionThree(completedOrderTitles: string[]): void {
    const mission = this.getMission("mission-03-fabbrica-numeri") ?? this.getActiveMission();
    this.completeMission(mission.id, {
      id: "mission-03-summary",
      title: "La Fabbrica dei Numeri",
      lines: [
        `Hai stabilizzato ${completedOrderTitles.length} ordini: ${completedOrderTitles.join(", ")}.`,
        "Hai scelto percorsi di macchine usando calcolo mentale e controllo dei risultati intermedi.",
        "Hai usato filtri pari e multipli di 3 per evitare divisioni impossibili.",
        "Hai letto trasformazioni come piccole espressioni, rispettando l'ordine delle operazioni.",
        "Hai corretto errori osservando dove la linea industriale si bloccava.",
      ],
      badges: mission.rewards.map((reward) => reward.label),
      createdAt: new Date().toISOString(),
    });
    saveSystem.setFlag("mission3Complete", true);
  }

  completeMissionFour(reportText: string): void {
    const mission = this.getMission("mission-04-archivio-parole") ?? this.getActiveMission();
    const preview = reportText.trim().slice(0, 120);
    this.completeMission(mission.id, {
      id: "mission-04-summary",
      title: "Archivio delle Parole",
      lines: [
        "Hai riparato messaggi corrotti per far riaprire cassetti e fascicoli corretti.",
        "Hai distinto informazioni utili da dettagli veri ma non decisivi.",
        "Hai interpretato un'istruzione bilingue senza cancellare una fonte importante.",
        `Rapporto consegnato: ${preview}${reportText.length > 120 ? "..." : ""}`,
        "Hai usato le parole come strumenti di indagine, non come risposte da indovinare.",
      ],
      badges: mission.rewards.map((reward) => reward.label),
      createdAt: new Date().toISOString(),
    });
    saveSystem.setFlag("mission4Complete", true);
  }

  completeMissionFive(sourceLabel: string): void {
    const mission = missions.find((entry) => entry.id === "mission-05-atlante-perduto");
    this.completeMission(mission?.id ?? "mission-05-atlante-perduto", {
      id: "mission-05-summary",
      title: "L'Atlante Perduto",
      lines: [
        "Hai tradotto tre rilevamenti radio in inglese in direzioni cardinali precise.",
        "Hai collocato le stazioni d'ascolto sulla griglia leggendo le coordinate (colonna, riga).",
        "Hai usato la scala dell'atlante per convertire le celle della mappa in chilometri reali.",
        `Hai triangolato l'origine del segnale incrociando tre rilevamenti: ${sourceLabel}.`,
        "Hai trovato un punto unico usando indizi indipendenti, non un'ipotesi sola.",
      ],
      badges: (mission?.rewards ?? []).map((reward) => reward.label),
      createdAt: new Date().toISOString(),
    });
    saveSystem.setFlag("mission5Complete", true);
  }

  completeProceduralMission(): void {
    const run = saveSystem.data.proceduralRun;
    if (!run || run.completedAt) {
      return;
    }
    const solvedCount = run.solvedPuzzleIds.length;
    const requiredCount = run.mission.objectives.length || 1;
    const nextDifficulty = Math.min(8, run.difficulty + 1);
    const completedAt = new Date().toISOString();
    if (proceduralRunRules.modeFor(run) === "training") {
      const result = assessTrainingRun(run, completedAt);
      const key = proceduralRunRules.trainingRecordKey(result.focus, result.difficulty);
      const record = saveSystem.upsertTrainingRecord({
        key,
        focus: result.focus,
        difficulty: result.difficulty,
        bestTimeMs: result.elapsedMs,
        bestGrade: result.grade,
        bestScore: result.score,
        lastTimeMs: result.elapsedMs,
        lastGrade: result.grade,
        lastScore: result.score,
        completedAt,
      });
      saveSystem.updateProceduralRun({
        completedAt,
        trainingResult: {
          ...result,
          bestTimeMs: record.bestTimeMs,
        },
      });
      playerSystem.recordProceduralRun({
        ...run,
        completedAt,
        trainingResult: {
          ...result,
          bestTimeMs: record.bestTimeMs,
        },
      });
      saveSystem.addJournalEntry({
        id: `training-summary-${run.seed}`,
        title: "Allenamento completato",
        lines: [
          `Focus concluso: ${proceduralScoring.domainLabel(result.focus)}. Hai completato ${solvedCount}/${requiredCount} esercizi specialistici.`,
          `Difficoltà: ${run.difficulty}. Seed: ${run.seed}`,
          `Tempo: ${formatDuration(result.elapsedMs)}. Miglior tempo su questo focus/livello: ${formatDuration(record.bestTimeMs)}.`,
          `Voto: ${result.grade}/10 (${result.gradeLabel}). Punti: ${result.score}. Indizi usati: ${result.hintsUsed}.`,
          `Obiettivo prossimo: ${result.nextGoal}`,
          "Questo percorso è allenamento: puoi ripeterlo per abbassare il tempo, ma il voto resta legato a precisione, difficoltà e uso degli aiuti.",
        ],
        badges: run.mission.rewards.map((reward) => reward.label),
        createdAt: completedAt,
      });
      return;
    }
    saveSystem.updateProceduralRun({ completedAt });
    playerSystem.recordProceduralRun({ ...run, completedAt });
    const elapsed = proceduralRunRules.elapsedMs(run, new Date(completedAt).getTime());
    const focus = proceduralRunRules.focusFor(run);
    saveSystem.completeMission(run.mission.id);
    saveSystem.addJournalEntry({
      id: `procedural-summary-${run.seed}`,
      title: "Missione completata",
      lines: [
        `Percorso concluso: ${run.mission.title}. La porta si è aperta: Eli ha stabilizzato tutti i sistemi della stanza.`,
        `Seed: ${run.seed}`,
        `Focus: ${proceduralScoring.domainLabel(focus)}. Difficoltà completata: ${run.difficulty}. Prossima run consigliata: ${nextDifficulty}.`,
        `Esercizi risolti: ${solvedCount}/${requiredCount}. Indizi usati: ${run.hintsUsed}. Tempo: ${formatDuration(elapsed)}.`,
        `Punteggio formativo: ${run.score?.total ?? 0}. Bonus assegnati per difficoltà, velocità ragionata e focus disciplinare.`,
        "La stanza non era casuale: ogni enigma era generato, validato e risolvibile.",
        `Prossimo passo narrativo: NORA ha aperto un corridoio instabile verso una stanza di difficoltà ${nextDifficulty}.`,
      ],
      badges: run.mission.rewards.map((reward) => reward.label),
      createdAt: new Date().toISOString(),
    });
  }

  private completeMission(missionId: string, journalEntry: JournalEntry): void {
    const mission = this.getMission(missionId) ?? this.getActiveMission();
    saveSystem.completeMission(mission.id);
    saveSystem.addJournalEntry(journalEntry);
    if (mission.nextMissionId) {
      saveSystem.setActiveMission(mission.nextMissionId);
    }
    EventBus.emit(GameEvents.MissionChanged, mission);
  }
}

export const missionEngine = new MissionEngine();
