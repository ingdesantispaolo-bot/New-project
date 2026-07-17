import type { DailyObjective, GreenhouseRunSave, JournalEntry, NumberFactoryRunSave, SaveData, TrainingRecord } from "../types/gameTypes";
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
        proceduralRun: this.normalizeProceduralRun(parsed.proceduralRun),
        proceduralMissionRun: this.normalizeProceduralRun(parsed.proceduralMissionRun),
        proceduralTrainingRun: this.normalizeProceduralRun(parsed.proceduralTrainingRun),
        proceduralProgressiveRun: this.normalizeProceduralRun(parsed.proceduralProgressiveRun),
        trainingRecords: parsed.trainingRecords ?? {},
        learningMemory: parsed.learningMemory ?? {},
        masteryAutonomy: parsed.masteryAutonomy ?? {},
        outdoorAdventure: this.normalizeOutdoorAdventure(parsed.outdoorAdventure),
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
      if (
        this.saveData.flags.mission4Complete &&
        !this.saveData.flags.mission5Complete &&
        this.saveData.activeMissionId !== "mission-05-atlante-perduto"
      ) {
        this.saveData.activeMissionId = "mission-05-atlante-perduto";
        this.persist();
      }
      if (
        this.saveData.flags.mission5Complete &&
        !this.saveData.flags.mission6Complete &&
        this.saveData.activeMissionId !== "mission-06-citta-intelligente"
      ) {
        this.saveData.activeMissionId = "mission-06-citta-intelligente";
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

  /** Normalised reward state (energy currency + unlocked/equipped cosmetics). */
  get rewards(): { energy: number; earned: number; unlocked: string[]; equipped: Record<string, string> } {
    const current = this.saveData.rewards;
    if (!current) {
      this.saveData.rewards = { energy: 0, earned: 0, unlocked: [], equipped: {} };
    }
    return this.saveData.rewards!;
  }

  /** Grants energy (currency) earned by answering correctly. */
  addEnergy(amount: number): void {
    if (amount <= 0) return;
    const rewards = this.rewards;
    rewards.energy += amount;
    rewards.earned += amount;
    this.persist();
    EventBus.emit(GameEvents.RewardsChanged, rewards);
  }

  // --- Daily loop ----------------------------------------------------------

  private todayKey(date = new Date()): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, "0");
    const d = String(date.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }

  /** Cumulative lifetime stats used to compute daily deltas. */
  private cumulativeStats(): { runs: number; mastered: number; unlocked: number } {
    const records = Object.values(this.saveData.trainingRecords ?? {});
    const runs = records.reduce((sum, record) => sum + (record.runs ?? 0), 0);
    const mastered = new Set(records.filter((record) => (record.runs ?? 0) > 0).map((record) => record.focus)).size;
    const unlocked = Object.keys(this.saveData.flags).filter((key) => key.startsWith("area-unlocked-") && this.saveData.flags[key]).length;
    return { runs, mastered, unlocked };
  }

  /** Refreshes the daily objective set on a new calendar day and advances the streak. */
  rolloverDaily(): void {
    const today = this.todayKey();
    const daily = this.saveData.daily;
    if (daily && daily.date === today) return;
    const yesterday = this.todayKey(new Date(Date.now() - 86_400_000));
    const streak = daily && daily.date === yesterday ? daily.streak + 1 : 1;
    this.saveData.daily = {
      date: today,
      streak,
      snapshot: this.cumulativeStats(),
      claimed: false,
      energySubjects: [],
      varietyMilestonesClaimed: [],
    };
    this.persist();
  }

  private dailyHash(): number {
    const seed = this.saveData.daily?.date ?? this.todayKey();
    let hash = 2166136261;
    for (let index = 0; index < seed.length; index += 1) {
      hash ^= seed.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
  }

  /** Today's objectives with live progress (snapshot-diff from cumulative stats). */
  dailyObjectives(): DailyObjective[] {
    this.rolloverDaily();
    const snapshot = this.saveData.daily!.snapshot;
    const stats = this.cumulativeStats();
    const delta = {
      runs: Math.max(0, stats.runs - snapshot.runs),
      mastered: Math.max(0, stats.mastered - snapshot.mastered),
      unlocked: Math.max(0, stats.unlocked - snapshot.unlocked),
    };
    const runsTarget = 2 + (this.dailyHash() % 3); // 2..4, varies by day
    const objectives: DailyObjective[] = [];
    const add = (id: string, label: string, target: number, value: number): void => {
      objectives.push({ id, label, target, current: Math.min(value, target), done: value >= target });
    };
    add("runs", `Completa ${runsTarget} calibrazioni`, runsTarget, delta.runs);
    if (stats.mastered < 7) add("master", "Padroneggia un nuovo settore", 1, delta.mastered);
    else add("runs-long", "Calibra a lungo: 6 sessioni", 6, delta.runs);
    if (stats.unlocked < 4) add("unlock", "Sblocca una nuova area", 1, delta.unlocked);
    else add("runs-marathon", "Maratona: 8 calibrazioni", 8, delta.runs);
    return objectives;
  }

  /** Energy granted for completing the daily loop, with a gentle streak bonus. */
  dailyRewardAmount(): number {
    this.rolloverDaily();
    const streakBonus = Math.min(140, Math.max(0, (this.saveData.daily?.streak ?? 1) - 1) * 10);
    return 60 + streakBonus;
  }

  /**
   * Records a subject/activity family that generated energy today and returns
   * one-shot bonus packets for new variety. The caller grants the energy so UI
   * feedback can include the same breakdown shown to the player.
   */
  recordDailyEnergySubject(subject: string): Array<{ amount: number; label: string }> {
    this.rolloverDaily();
    const normalized = subject.trim().toLowerCase();
    if (!normalized) return [];
    const daily = this.saveData.daily!;
    daily.energySubjects = daily.energySubjects ?? [];
    daily.varietyMilestonesClaimed = daily.varietyMilestonesClaimed ?? [];
    const bonuses: Array<{ amount: number; label: string }> = [];
    if (!daily.energySubjects.includes(normalized)) {
      daily.energySubjects.push(normalized);
      bonuses.push({ amount: 15, label: `nuova attività: ${subject}` });
    }
    const milestones: Array<{ count: number; amount: number; label: string }> = [
      { count: 3, amount: 40, label: "varietà giornaliera 3" },
      { count: 5, amount: 80, label: "varietà giornaliera 5" },
      { count: 7, amount: 120, label: "giro completo del giorno" },
    ];
    for (const milestone of milestones) {
      if (
        daily.energySubjects.length >= milestone.count
        && !daily.varietyMilestonesClaimed.includes(milestone.count)
      ) {
        daily.varietyMilestonesClaimed.push(milestone.count);
        bonuses.push({ amount: milestone.amount, label: milestone.label });
      }
    }
    if (bonuses.length > 0) this.persist();
    return bonuses;
  }

  get outdoorAdventure(): NonNullable<SaveData["outdoorAdventure"]> {
    this.saveData.outdoorAdventure = this.normalizeOutdoorAdventure(this.saveData.outdoorAdventure);
    return this.saveData.outdoorAdventure!;
  }

  recordOutdoorEncounter(encounterId: string, victory: boolean, fragments: number, guardian = false): NonNullable<SaveData["outdoorAdventure"]> {
    const outdoor = this.outdoorAdventure;
    if (!outdoor.completedEncounterIds.includes(encounterId)) {
      outdoor.completedEncounterIds.push(encounterId);
    }
    outdoor.fragments += Math.max(0, fragments);
    outdoor.currentStreak = victory ? outdoor.currentStreak + 1 : 0;
    outdoor.bestStreak = Math.max(outdoor.bestStreak, outdoor.currentStreak);
    if (victory && guardian) {
      outdoor.guardianWins += 1;
      outdoor.guardianWinsToday = (outdoor.guardianWinsToday ?? 0) + 1;
    }
    outdoor.lastPlayedAt = new Date().toISOString();
    this.persist();
    return outdoor;
  }

  claimOutdoorBounty(id: string, energy: number, fragments: number): boolean {
    const outdoor = this.outdoorAdventure;
    outdoor.claimedBountyIds = outdoor.claimedBountyIds ?? [];
    if (outdoor.claimedBountyIds.includes(id)) return false;
    outdoor.claimedBountyIds.push(id);
    outdoor.fragments += Math.max(0, fragments);
    if (energy > 0) {
      const rewards = this.rewards;
      rewards.energy += energy;
      rewards.earned += energy;
      EventBus.emit(GameEvents.RewardsChanged, rewards);
    }
    this.persist();
    return true;
  }

  spendOutdoorFragments(amount: number): boolean {
    if (amount <= 0) return false;
    const outdoor = this.outdoorAdventure;
    if (outdoor.fragments < amount) return false;
    outdoor.fragments -= amount;
    this.persist();
    return true;
  }

  /** Grants a one-time energy bonus the first time all today's objectives are done. */
  claimDailyIfComplete(bonus = this.dailyRewardAmount()): number {
    this.rolloverDaily();
    const daily = this.saveData.daily!;
    if (daily.claimed || !this.dailyObjectives().every((objective) => objective.done)) return 0;
    daily.claimed = true;
    this.addEnergy(bonus);
    return bonus;
  }

  get dailyStreak(): number {
    this.rolloverDaily();
    return this.saveData.daily?.streak ?? 1;
  }

  /** Buys a cosmetic if affordable and not already owned. Returns success. */
  purchaseCosmetic(id: string, cost: number): boolean {
    const rewards = this.rewards;
    if (rewards.unlocked.includes(id) || rewards.energy < cost) return false;
    rewards.energy -= cost;
    rewards.unlocked.push(id);
    this.persist();
    EventBus.emit(GameEvents.RewardsChanged, rewards);
    return true;
  }

  unlockCosmetic(id: string): boolean {
    const rewards = this.rewards;
    if (rewards.unlocked.includes(id)) return false;
    rewards.unlocked.push(id);
    this.persist();
    EventBus.emit(GameEvents.RewardsChanged, rewards);
    return true;
  }

  /** Equips an owned cosmetic in its slot (pass empty id to clear the slot). */
  equipCosmetic(slot: string, id: string): void {
    const rewards = this.rewards;
    if (id && !rewards.unlocked.includes(id)) return;
    if (id) rewards.equipped[slot] = id;
    else delete rewards.equipped[slot];
    this.persist();
    EventBus.emit(GameEvents.RewardsChanged, rewards);
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
    this.saveData.proceduralRun = this.prepareRunForResume(run);
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
    if (!run || run.completedAt || run.failedAt) {
      return false;
    }
    if ((mode === "mission" || mode === "progressive") && (run.lives ?? proceduralRunRules.maxLives) <= 0) {
      return false;
    }
    return true;
  }

  pauseActiveProceduralRun(): void {
    const run = this.saveData.proceduralRun;
    if (!run || run.completedAt || run.failedAt) {
      return;
    }
    const mode = proceduralRunRules.modeFor(run);
    const pausedRemainingMs = proceduralRunRules.pressureEnabledForMode(mode) && run.deadlineAt
      ? Math.max(0, proceduralRunRules.remainingMs(run))
      : run.pausedRemainingMs;
    const now = Date.now();
    const activeElapsedMs = run.timerState === "running" && run.startedAt
      ? (run.activeElapsedMs ?? 0) + Math.max(0, now - new Date(run.startedAt).getTime())
      : run.activeElapsedMs ?? 0;
    const paused = {
      ...run,
      pausedRemainingMs,
      activeElapsedMs,
      timerState: "paused" as const,
      deadlineAt: undefined,
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
    this.updateProceduralRun({
      solvedPuzzleIds: [...run.solvedPuzzleIds, puzzleId],
      failedPuzzleIds: (run.failedPuzzleIds ?? []).filter((id) => id !== puzzleId),
    });
    const kind = puzzleId.split("-")[0];
    this.resolveLearningMistake(`${kind}:concept`);
    this.resolveLearningMistake(`${kind}:evidence`);
  }

  markProceduralPuzzleFailed(puzzleId: string): void {
    const run = this.saveData.proceduralRun;
    if (!run || run.solvedPuzzleIds.includes(puzzleId) || run.failedPuzzleIds?.includes(puzzleId)) {
      return;
    }
    this.updateProceduralRun({ failedPuzzleIds: [...(run.failedPuzzleIds ?? []), puzzleId] });
  }

  incrementProceduralHints(): void {
    const run = this.saveData.proceduralRun;
    if (!run) {
      return;
    }
    this.updateProceduralRun({ hintsUsed: run.hintsUsed + 1 });
  }

  recordMasteryAutonomy(branch: string): number {
    const previous = this.saveData.masteryAutonomy?.[branch] ?? 0;
    const count = previous + 1;
    this.saveData.masteryAutonomy = {
      ...(this.saveData.masteryAutonomy ?? {}),
      [branch]: count,
    };
    this.persist();
    return count;
  }

  recordLearningMistake(category: string): number {
    const previous = this.saveData.learningMemory?.[category];
    const count = (previous?.count ?? 0) + 1;
    this.saveData.learningMemory = {
      ...(this.saveData.learningMemory ?? {}),
      [category]: { count, lastAt: new Date().toISOString() },
    };
    this.persist();
    return count;
  }

  /** True se NORA ha già presentato questo concetto al profilo attivo. */
  isConceptIntroduced(topicId: string): boolean {
    return Boolean(this.saveData.introducedConcepts?.[topicId]);
  }

  /**
   * Registra la prima spiegazione di un concetto: da qui in poi la teoria non
   * si apre più da sola per quel topic (resta il pulsante "Teoria NORA").
   */
  markConceptIntroduced(topicId: string): void {
    this.saveData.introducedConcepts = {
      ...(this.saveData.introducedConcepts ?? {}),
      [topicId]: new Date().toISOString(),
    };
    this.persist();
  }

  private resolveLearningMistake(category: string): void {
    const previous = this.saveData.learningMemory?.[category];
    if (!previous || previous.count <= 0) return;
    this.saveData.learningMemory = {
      ...(this.saveData.learningMemory ?? {}),
      [category]: { count: Math.max(0, previous.count - 1), lastAt: new Date().toISOString() },
    };
    this.persist();
  }

  updateCompetency(id: string, amount: number): void {
    const current = this.saveData.competencies[id] ?? 0;
    this.saveData.competencies[id] = Math.min(100, Math.max(0, current + amount));
    this.persist();
    EventBus.emit(GameEvents.CompetencyChanged, id, this.saveData.competencies[id]);
  }

  /** Public persistence hook for systems that mutate saveData directly. */
  persistData(): void {
    this.persist();
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

  private normalizeProceduralRun(run: ProceduralRunSave | undefined): ProceduralRunSave | undefined {
    if (!run) return undefined;
    const mode = proceduralRunRules.modeFor(run);
    const pressureEnabled = proceduralRunRules.pressureEnabledFor(run);
    const timerState = run.timerState
      ?? (run.pausedRemainingMs !== undefined ? "paused" : run.deadlineAt ? "running" : "preparing");
    return {
      ...run,
      failedPuzzleIds: run.failedPuzzleIds ?? [],
      createdAt: run.createdAt ?? run.startedAt,
      activeElapsedMs: run.activeElapsedMs ?? 0,
      timerState: pressureEnabled || mode === "training" || run.chapterExploreMissionId ? timerState : "paused",
    };
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
      learningMemory: {},
      masteryAutonomy: {},
      outdoorAdventure: this.normalizeOutdoorAdventure(),
    };
  }

  private normalizeOutdoorAdventure(outdoor?: SaveData["outdoorAdventure"]): NonNullable<SaveData["outdoorAdventure"]> {
    const today = this.todayKey();
    const sameDay = outdoor?.date === today;
    return {
      date: today,
      completedEncounterIds: sameDay ? outdoor?.completedEncounterIds ?? [] : [],
      fragments: Math.max(0, outdoor?.fragments ?? 0),
      guardianWins: Math.max(0, outdoor?.guardianWins ?? 0),
      guardianWinsToday: sameDay ? Math.max(0, outdoor?.guardianWinsToday ?? 0) : 0,
      bestStreak: Math.max(0, outdoor?.bestStreak ?? 0),
      currentStreak: sameDay ? Math.max(0, outdoor?.currentStreak ?? 0) : 0,
      claimedBountyIds: sameDay ? outdoor?.claimedBountyIds ?? [] : [],
      lastPlayedAt: outdoor?.lastPlayedAt,
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

  private prepareRunForResume(run: ProceduralRunSave): ProceduralRunSave {
    if (run.completedAt || run.failedAt) return run;
    return {
      ...run,
      timerState: "ready",
      deadlineAt: undefined,
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
