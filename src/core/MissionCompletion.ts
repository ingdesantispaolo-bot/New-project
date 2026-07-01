import { saveSystem } from "./SaveSystem";

/**
 * Single source of truth for hand-crafted campaign mission completion.
 *
 * The campaign missions track progress through these per-mission flags (set in
 * MissionEngine.completeMissionX). The shared `completedMissionIds` array must
 * NOT be used for campaign progress: it only ever receives the procedural stub
 * id, so any consumer reading it desyncs from the real story state.
 */
export const MISSION_COMPLETION_FLAG: Record<string, string> = {
  "mission-01-laboratorio-spento": "mission1Complete",
  "mission-02-serra-biologica": "mission2Complete",
  "mission-03-fabbrica-numeri": "mission3Complete",
  "mission-04-archivio-parole": "mission4Complete",
  "mission-05-atlante-perduto": "mission5Complete",
  "mission-06-citta-intelligente": "mission6Complete",
};

const MISSION_EXPLORATION_FLAG: Record<string, string> = {
  "mission-01-laboratorio-spento": "mission1Explored",
  "mission-02-serra-biologica": "mission2Explored",
  "mission-03-fabbrica-numeri": "mission3Explored",
  "mission-04-archivio-parole": "mission4Explored",
  "mission-05-atlante-perduto": "mission5Explored",
  "mission-06-citta-intelligente": "mission6Explored",
};

/** Pure check against an explicit flags map (use for SaveData-derived helpers). */
export function isMissionCompleteIn(flags: Record<string, boolean>, missionId: string): boolean {
  const flag = MISSION_COMPLETION_FLAG[missionId];
  return Boolean(flag && flags?.[flag]);
}

/** Whether a campaign mission is complete, against the active save. */
export function isMissionComplete(missionId: string): boolean {
  return isMissionCompleteIn(saveSystem.data.flags, missionId);
}

export function isMissionExplored(missionId: string): boolean {
  const flag = MISSION_EXPLORATION_FLAG[missionId];
  return Boolean(flag && saveSystem.data.flags?.[flag]);
}

/** How many campaign missions are complete in the given flags map. */
export function countCompletedMissions(flags: Record<string, boolean>): number {
  return Object.values(MISSION_COMPLETION_FLAG).filter((flag) => flags?.[flag]).length;
}

/**
 * Marks a campaign chapter as cleared by setting its authoritative flag. Used by
 * the "Prova del Capitolo" gate when the graded trial is passed.
 */
export function markMissionComplete(missionId: string): void {
  const flag = MISSION_COMPLETION_FLAG[missionId];
  if (flag) {
    saveSystem.setFlag(flag, true);
  }
}

/**
 * Marks the low-pressure chapter exploration as completed. This is deliberately
 * separate from mission completion: exploration prepares the student, the
 * graded trial remains the only gate that unlocks the next chapter.
 */
export function markMissionExplored(missionId: string): void {
  const flag = MISSION_EXPLORATION_FLAG[missionId];
  if (flag) {
    saveSystem.setFlag(flag, true);
  }
}
