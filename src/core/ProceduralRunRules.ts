import type { DifficultyLevel, ProceduralRunSave, ProceduralRunMode, ProceduralSpecialization } from "../procedural/ProceduralTypes";

const focusDomains: ProceduralSpecialization[] = ["matematica", "italiano", "inglese", "elettronica", "coding"];

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
    const secondsPerObjective = Math.max(48, 102 - difficulty * 6);
    return Math.max(210, objectiveCount * secondsPerObjective) * 1000;
  },

  deadlineFrom(startedAt: string, timeLimitMs: number): string {
    return new Date(new Date(startedAt).getTime() + timeLimitMs).toISOString();
  },

  remainingMs(run: ProceduralRunSave): number {
    if (!run.deadlineAt) return Number.POSITIVE_INFINITY;
    return new Date(run.deadlineAt).getTime() - Date.now();
  },

  trainingRecordKey(focus: ProceduralSpecialization, difficulty: DifficultyLevel): string {
    return `${focus}:${difficulty}`;
  },
};
