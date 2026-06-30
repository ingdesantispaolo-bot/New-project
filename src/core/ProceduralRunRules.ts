import type { DifficultyLevel, ProceduralRunSave, ProceduralRunMode, ProceduralSpecialization } from "../procedural/ProceduralTypes";
import { settingsSystem } from "./SettingsSystem";

const focusDomains: ProceduralSpecialization[] = ["matematica", "italiano", "inglese", "elettronica", "coding", "musica", "fisica"];

export const proceduralRunRules = {
  maxLives: 3,

  modeFor(run: Pick<ProceduralRunSave, "mode" | "focus">): ProceduralRunMode {
    if (run.mode) return run.mode;
    return run.focus.some((focus) => focusDomains.includes(focus as ProceduralSpecialization)) ? "training" : "mission";
  },

  focusFor(run: Pick<ProceduralRunSave, "focus">): ProceduralSpecialization {
    return (run.focus.find((focus): focus is ProceduralSpecialization => focusDomains.includes(focus as ProceduralSpecialization)) ?? "libera");
  },

  missionTimeLimitMs(difficulty: DifficultyLevel, objectiveCount: number): number {
    const secondsPerObjective = Math.max(62, 118 - difficulty * 5);
    return Math.max(300, objectiveCount * secondsPerObjective) * 1000;
  },

  pressureEnabledForMode(mode: ProceduralRunMode): boolean {
    return mode === "progressive" || (mode === "mission" && settingsSystem.pressureEnabled());
  },

  mistakesBeforeLifeLoss(difficulty: DifficultyLevel): number {
    return difficulty >= 7 ? 2 : 3;
  },

  deadlineFrom(startedAt: string, timeLimitMs: number): string {
    return new Date(new Date(startedAt).getTime() + timeLimitMs).toISOString();
  },

  remainingMs(run: ProceduralRunSave): number {
    if (run.timerState === "preparing" || run.timerState === "ready") {
      return run.timeLimitMs ?? Number.POSITIVE_INFINITY;
    }
    if (run.timerState === "paused" && run.pausedRemainingMs !== undefined) {
      return run.pausedRemainingMs;
    }
    if (!run.deadlineAt) return Number.POSITIVE_INFINITY;
    return new Date(run.deadlineAt).getTime() - Date.now();
  },

  elapsedMs(run: ProceduralRunSave, now = Date.now()): number {
    const accumulated = Math.max(0, run.activeElapsedMs ?? 0);
    if (run.timerState !== "running" || !run.startedAt) return accumulated;
    const sessionStart = new Date(run.startedAt).getTime();
    return accumulated + (Number.isFinite(sessionStart) ? Math.max(0, now - sessionStart) : 0);
  },

  trainingRecordKey(focus: ProceduralSpecialization, difficulty: DifficultyLevel): string {
    return `${focus}:${difficulty}`;
  },
};
