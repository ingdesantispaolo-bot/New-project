import type { GreenhouseRunSave, JournalEntry, NumberFactoryRunSave, SaveData, TrainingRecord } from "../types/gameTypes";
import type { ProceduralRunSave } from "../procedural/ProceduralTypes";
import { firstMissionId } from "../data/missions";
import { competencies } from "../data/competencies";
import { EventBus, GameEvents } from "./EventBus";
import { playerSystem } from "./PlayerSystem";
import { proceduralRunRules } from "./ProceduralRunRules";

const SAVE_KEY = "eli-quest-save-v1";
const LEGACY_MIGRATION_KEY = `${SAVE_KEY}:legacy-migrated`;

function createDefaultCompetencies(): Record<string, number> {
  return Object.fromEntries(competencies.map((competency) => [competency.id, 0]));
}

export class SaveSystem {
  private saveData: SaveData = this.createNewSave();

  load(): SaveData {
    const key = this.storageKey();
    let raw = localStorage.getItem(key);
    if (!raw && !localStorage.getItem(LEGACY_MIGRATION_KEY)) {
      const legacy = localStorage.getItem(SAVE_KEY);
      if (legacy) {
        raw = legacy;
        localStorage.setItem(key, legacy);
        localStorage.setItem(LEGACY_MIGRATION_KEY, "1");
      }
    }
    if (!raw) {
      this.saveData = this.createNewSave();
      this.persist();
      return this.saveData;
    }

    try {
      const parsed = JSON.parse(raw) as SaveData;
      this.saveData = {
        ...this.createNewSave(),
        ...parsed,
        playerId: this.activePlayerId(),
        competencies: {
          ...createDefaultCompetencies(),
          ...parsed.competencies,
        },
        exerciseSeed: parsed.exerciseSeed ?? this.createExerciseSeed(),
        flags: {
          ...parsed.flags,
        },
        journalEntries: parsed.journalEntries ?? [],
        proceduralRun: parsed.proceduralRun,
        proceduralMissionRun: parsed.proceduralMissionRun,
        proceduralTrainingRun: parsed.proceduralTrainingRun,
        proceduralProgressiveRun: parsed.proceduralProgressiveRun,
        trainingRecords: parsed.trainingRecords ?? {},
        greenhouseRun: parsed.greenhouseRun,
        numberFactoryRun: parsed.numberFactoryRun,
      };
      this.migrateProceduralSlots();
      if (
        this.saveData.flags.mission1Complete &&
        !this.saveData.flags.mission2Complete &&
        this.saveData.activeMissionId === firstMissionId
      ) {
        this.saveData.activeMissionId = "mission-02-serra-biologica";
        this.persist();
      }
      if (
        this.saveData.flags.mission2Complete &&
        !this.saveData.flags.mission3Complete &&
        this.saveData.activeMissionId !== "mission-03-fabbrica-numeri"
      ) {
        this.saveData.activeMissionId = "mission-03-fabbrica-numeri";
        this.persist();
      }
      if (
        this.saveData.flags.mission3Complete &&
        !this.saveData.flags.mission4Complete &&
        this.saveData.activeMissionId !== "mission-04-archivio-parole"
      ) {
        this.saveData.activeMissionId = "mission-04-archivio-parole";
        this.persist();
      }
    } catch {
      this.saveData = this.createNewSave();
      this.persist();
    }

    return this.saveData;
  }

  newGame(): SaveData {
    this.saveData = this.createNewSave();
    this.persist();
    return this.saveData;
  }

  get data(): SaveData {
    return this.saveData;
  }

  setFlag(flag: string, value = true): void {
    this.saveData.flags[flag] = value;
    this.persist();
  }

  addInventoryItem(itemId: string): void {
    if (!this.saveData.inventory.includes(itemId)) {
      this.saveData.inventory.push(itemId);
      this.persist();
      EventBus.emit(GameEvents.InventoryChanged, this.saveData.inventory);
    }
  }

  addJournalEntry(entry: JournalEntry): void {
    if (!this.saveData.journalEntries.some((existing) => existing.id === entry.id)) {
      this.saveData.journalEntries.push(entry);
      this.persist();
    }
  }

  completeMission(missionId: string): void {
    if (!this.saveData.completedMissionIds.includes(missionId)) {
      this.saveData.completedMissionIds.push(missionId);
      this.persist();
    }
  }

  setActiveMission(missionId: string): void {
    this.saveData.activeMissionId = missionId;
    this.persist();
  }

  setProceduralRun(run: ProceduralRunSave): void {
    this.saveData.proceduralRun = run;
    this.setProceduralSlot(run);
    this.persist();
  }

  setActiveProceduralRun(run: ProceduralRunSave): void {
    this.saveData.proceduralRun = this.resumeRunTimer(run);
    this.setProceduralSlot(this.saveData.proceduralRun);
    this.persist();
  }

  getProceduralMissionRun(): ProceduralRunSave | undefined {
    return this.saveData.proceduralMissionRun;
  }

  getProceduralTrainingRun(): ProceduralRunSave | undefined {
    return this.saveData.proceduralTrainingRun;
  }

  getProceduralProgressiveRun(): ProceduralRunSave | undefined {
    return this.saveData.proceduralProgressiveRun;
  }

  hasResumableProceduralRun(mode: "mission" | "training" | "progressive"): boolean {
    const run = mode === "mission"
      ? this.saveData.proceduralMissionRun
      : mode === "training"
        ? this.saveData.proceduralTrainingRun
        : this.saveData.proceduralProgressiveRun;
    return Boolean(run && !run.completedAt && !run.failedAt);
  }

  pauseActiveProceduralRun(): void {
    const run = this.saveData.proceduralRun;
    if (!run || run.completedAt || run.failedAt) {
      return;
    }
    const mode = proceduralRunRules.modeFor(run);
    const pausedRemainingMs = (mode === "mission" || mode === "progressive") && run.deadlineAt
      ? Math.max(0, proceduralRunRules.remainingMs(run))
      : run.pausedRemainingMs;
    const paused = {
      ...run,
      pausedRemainingMs,
    };
    this.saveData.proceduralRun = paused;
    this.setProceduralSlot(paused);
    this.persist();
  }

  upsertTrainingRecord(record: Omit<TrainingRecord, "runs">): TrainingRecord {
    const previous = this.saveData.trainingRecords?.[record.key];
    const bestImproved = !previous || record.bestTimeMs < previous.bestTimeMs;
    const next: TrainingRecord = {
      key: record.key,
      focus: record.focus,
      difficulty: record.difficulty,
      bestTimeMs: bestImproved ? record.bestTimeMs : previous.bestTimeMs,
      bestGrade: bestImproved ? record.bestGrade : previous.bestGrade,
      bestScore: bestImproved ? record.bestScore : previous.bestScore,
      lastTimeMs: record.lastTimeMs,
      lastGrade: record.lastGrade,
      lastScore: record.lastScore,
      completedAt: record.completedAt,
      runs: (previous?.runs ?? 0) + 1,
    };
    this.saveData.trainingRecords = {
      ...(this.saveData.trainingRecords ?? {}),
      [record.key]: next,
    };
    this.persist();
    return next;
  }

  setGreenhouseRun(run: GreenhouseRunSave | undefined): void {
    this.saveData.greenhouseRun = run;
    this.persist();
  }

  setNumberFactoryRun(run: NumberFactoryRunSave | undefined): void {
    this.saveData.numberFactoryRun = run;
    this.persist();
  }

  updateProceduralRun(update: Partial<ProceduralRunSave>): void {
    if (!this.saveData.proceduralRun) {
      return;
    }
    this.saveData.proceduralRun = {
      ...this.saveData.proceduralRun,
      ...update,
    };
    this.setProceduralSlot(this.saveData.proceduralRun);
    this.persist();
  }

  markProceduralPuzzleSolved(puzzleId: string): void {
    const run = this.saveData.proceduralRun;
    if (!run || run.solvedPuzzleIds.includes(puzzleId)) {
      return;
    }
    this.updateProceduralRun({ solvedPuzzleIds: [...run.solvedPuzzleIds, puzzleId] });
  }

  incrementProceduralHints(): void {
    const run = this.saveData.proceduralRun;
    if (!run) {
      return;
    }
    this.updateProceduralRun({ hintsUsed: run.hintsUsed + 1 });
  }

  updateCompetency(id: string, amount: number): void {
    const current = this.saveData.competencies[id] ?? 0;
    this.saveData.competencies[id] = Math.min(100, Math.max(0, current + amount));
    this.persist();
    EventBus.emit(GameEvents.CompetencyChanged, id, this.saveData.competencies[id]);
  }

  private persist(): void {
    try {
      this.saveData.playerId = this.activePlayerId();
      localStorage.setItem(this.storageKey(), JSON.stringify(this.saveData));
    } catch {
      // Some browsers block or cap localStorage; keep the in-memory run alive.
    }
    EventBus.emit(GameEvents.SaveChanged, this.saveData);
  }

  private createNewSave(): SaveData {
    return {
      version: 1,
      playerId: this.activePlayerId(),
      activeMissionId: firstMissionId,
      exerciseSeed: this.createExerciseSeed(),
      completedMissionIds: [],
      inventory: [],
      competencies: createDefaultCompetencies(),
      flags: {},
      journalEntries: [],
      trainingRecords: {},
    };
  }

  private migrateProceduralSlots(): void {
    const run = this.saveData.proceduralRun;
    if (run) {
      const mode = proceduralRunRules.modeFor(run);
      if (mode === "mission" && !this.saveData.proceduralMissionRun) {
        this.saveData.proceduralMissionRun = run;
      }
      if (mode === "training" && !this.saveData.proceduralTrainingRun) {
        this.saveData.proceduralTrainingRun = run;
      }
      if (mode === "progressive" && !this.saveData.proceduralProgressiveRun) {
        this.saveData.proceduralProgressiveRun = run;
      }
    }
  }

  private setProceduralSlot(run: ProceduralRunSave): void {
    const mode = proceduralRunRules.modeFor(run);
    if (mode === "mission") {
      this.saveData.proceduralMissionRun = run;
    } else if (mode === "training") {
      this.saveData.proceduralTrainingRun = run;
    } else {
      this.saveData.proceduralProgressiveRun = run;
    }
  }

  private resumeRunTimer(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    if ((mode !== "mission" && mode !== "progressive") || run.completedAt || run.failedAt || !run.pausedRemainingMs) {
      return run;
    }
    return {
      ...run,
      deadlineAt: new Date(Date.now() + Math.max(0, run.pausedRemainingMs)).toISOString(),
      pausedRemainingMs: undefined,
    };
  }

  private createExerciseSeed(): string {
    const entropy = new Uint32Array(2);
    if (globalThis.crypto?.getRandomValues) {
      globalThis.crypto.getRandomValues(entropy);
    } else {
      entropy[0] = Date.now() >>> 0;
      entropy[1] = Math.floor(performance.now() * 1000) >>> 0;
    }
    return `EX-${entropy[0].toString(36)}-${entropy[1].toString(36)}`.toUpperCase();
  }

  private activePlayerId(): string {
    try {
      return playerSystem.getActivePlayer().id;
    } catch {
      return "default";
    }
  }

  private storageKey(): string {
    return `${SAVE_KEY}:player:${this.activePlayerId()}`;
  }
}

export const saveSystem = new SaveSystem();
