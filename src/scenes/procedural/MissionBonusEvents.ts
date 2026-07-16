import Phaser from "phaser";
import type { DifficultyLevel, ProceduralBonusEventState, ProceduralRunSave } from "../../procedural/ProceduralTypes";
import { Random } from "../../procedural/Random";
import type { LogicGymBonusActivityKey } from "../../types/logicGymBonus";
import { Button } from "../../ui/Button";
import { SceneChrome } from "../../ui/SceneChrome";
import { puzzleKindFromId } from "./ProceduralMissionLayout";

export function normalizeMissionBonusEvents(run: Pick<ProceduralRunSave, "bonusEvents">): ProceduralBonusEventState {
  return {
    offeredIds: [...(run.bonusEvents?.offeredIds ?? [])],
    resolvedIds: [...(run.bonusEvents?.resolvedIds ?? [])],
    skippedIds: [...(run.bonusEvents?.skippedIds ?? [])],
  };
}

export function compactMissionBonusEvents(events: ProceduralBonusEventState): ProceduralBonusEventState {
  const unique = (items: string[]): string[] => [...new Set(items)];
  return {
    offeredIds: unique(events.offeredIds),
    resolvedIds: unique(events.resolvedIds),
    skippedIds: unique(events.skippedIds),
  };
}

export function missionBonusEventLimit(isChapterTrial: boolean): number {
  return isChapterTrial ? 1 : 2;
}

export function shouldOfferMissionBonus(
  eventId: string,
  solvedCount: number,
  offeredCount: number,
  difficulty: DifficultyLevel,
  isChapterTrial: boolean,
): boolean {
  if (offeredCount === 0 && solvedCount >= 3) return true;
  const chance = isChapterTrial ? 0.18 : 0.26;
  return new Random(`${eventId}:roll:${difficulty}`).bool(chance);
}

export function selectMissionBonusActivity(eventId: string, lastSolvedPuzzleId: string): LogicGymBonusActivityKey {
  const random = new Random(`${eventId}:activity`);
  const kind = puzzleKindFromId(lastSolvedPuzzleId);
  const weighted: LogicGymBonusActivityKey[] =
    kind === "math" ? ["tables", "mental", "mental"]
      : kind === "coding" || kind === "circuit" || kind === "robot" ? ["mental", "tables", "tables"]
        : kind === "physics" ? ["geoPhysical", "mental", "geoPhysical"]
          : kind === "english" || kind === "language" || kind === "latin" ? ["geo", "mental", "geo"]
            : ["tables", "mental", "geo", "geoPhysical"];
  return random.pick(weighted);
}

export function missionBonusActivityTitle(activityKey: LogicGymBonusActivityKey): string {
  switch (activityKey) {
    case "tables": return "Tabelline Reactor";
    case "mental": return "Calcolo Mentale";
    case "geo": return "Geo Atlante";
    case "geoPhysical": return "Geo Rilievi";
  }
}

export function missionBonusActivityTheme(activityKey: LogicGymBonusActivityKey): string {
  switch (activityKey) {
    case "tables": return "moltiplicazioni, fattori mancanti e inverse";
    case "mental": return "strategie rapide, compensazioni e catene";
    case "geo": return "capitali, paesi e continenti";
    case "geoPhysical": return "fiumi, laghi, rilievi, deserti e mari";
  }
}

export function missionBonusActivityColor(activityKey: LogicGymBonusActivityKey): number {
  switch (activityKey) {
    case "tables": return 0xf6c85f;
    case "mental": return 0x5ec8ff;
    case "geo": return 0x70d68a;
    case "geoPhysical": return 0x9f8cff;
  }
}

export function missionBonusRounds(activityKey: LogicGymBonusActivityKey, difficulty: DifficultyLevel): number {
  if (activityKey === "geo" || activityKey === "geoPhysical") return difficulty >= 6 ? 5 : 4;
  return difficulty >= 6 ? 6 : 5;
}

export type MissionBonusOfferOverlayOptions = {
  scene: Phaser.Scene;
  activityKey: LogicGymBonusActivityKey;
  difficulty: DifficultyLevel;
  offeredCount: number;
  maxEvents: number;
  onAccept: () => void;
  onSkip: () => void;
};

export function createMissionBonusOfferOverlay(options: MissionBonusOfferOverlayOptions): Phaser.GameObjects.Container {
  const { scene, activityKey, difficulty, offeredCount, maxEvents, onAccept, onSkip } = options;
  const overlay = scene.add.container(0, 0).setDepth(2100);
  const color = missionBonusActivityColor(activityKey);
  const rounds = missionBonusRounds(activityKey, difficulty);

  SceneChrome.modalInputBlocker(scene, overlay, 0, 0, 0x02070b, 0.84);
  overlay.add(scene.add.rectangle(640, 360, 760, 416, 0x07151d, 0.99).setStrokeStyle(2, color, 0.82));
  overlay.add(scene.add.circle(320, 210, 46, color, 0.18).setStrokeStyle(2, color, 0.58));
  overlay.add(scene.add.text(320, 204, "⚡", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f7d37a" }).setOrigin(0.5));
  overlay.add(scene.add.text(390, 178, "Frattura energetica", {
    fontFamily: "Inter, Arial",
    fontSize: "30px",
    color: "#f7d37a",
    fontStyle: "bold",
  }));
  overlay.add(scene.add.text(390, 222, `NORA intercetta una scarica stabile: ${missionBonusActivityTitle(activityKey)}.`, {
    fontFamily: "Inter, Arial",
    fontSize: "16px",
    color: "#f5fbff",
    fontStyle: "bold",
    wordWrap: { width: 560 },
  }));
  overlay.add(scene.add.text(390, 268, `Sfida breve: ${rounds} round su ${missionBonusActivityTheme(activityKey)}. Se superi la soglia, ottieni energia bonus e, con precisione alta, stabilità timer. Se fallisci, la missione riprende senza penalità.`, {
    fontFamily: "Inter, Arial",
    fontSize: "14px",
    color: "#d9eaf1",
    wordWrap: { width: 560 },
    lineSpacing: 5,
  }));
  overlay.add(scene.add.text(390, 384, `Eventi run: ${offeredCount}/${maxEvents} · Profondità ${difficulty}/8`, {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#9ff5e9",
    fontStyle: "bold",
  }));

  let leaving = false;
  overlay.add(new Button(scene, 500, 474, "Affronta frattura", () => {
    if (leaving) return;
    leaving = true;
    onAccept();
  }, {
    width: 260,
    height: 54,
    fill: 0x1f5a51,
    stroke: color,
    fontSize: 16,
  }));
  overlay.add(new Button(scene, 794, 474, "Ignora", () => {
    if (leaving) return;
    leaving = true;
    onSkip();
  }, {
    width: 190,
    height: 54,
    fill: 0x263743,
    fontSize: 15,
  }));

  return overlay;
}
