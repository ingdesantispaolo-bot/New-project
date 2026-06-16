import type { GeneratedRoomHotspot } from "../../procedural/ProceduralTypes";
import type { DeviceKind, DeviceState, ChromeRect } from "../../ui/SceneChrome";

export type ProceduralPuzzleId = "language" | "circuit" | "math" | "english" | "robot" | "music";
export type ProceduralHotspotKey = ProceduralPuzzleId | "door";

export const proceduralPuzzleOrder: ProceduralPuzzleId[] = ["language", "circuit", "math", "english", "robot", "music"];

const hotspotOrder: Record<ProceduralHotspotKey, number> = {
  language: 0,
  circuit: 1,
  math: 2,
  english: 3,
  robot: 4,
  music: 5,
  door: 6,
};

const hotspotKinds: Record<ProceduralHotspotKey, DeviceKind> = {
  language: "language",
  circuit: "circuit",
  math: "terminal",
  english: "english",
  robot: "robot",
  music: "music",
  door: "door",
};

export function proceduralHotspotKey(hotspot: GeneratedRoomHotspot): ProceduralHotspotKey | undefined {
  if (hotspot.id === "door") {
    return "door";
  }
  if (hotspot.puzzleKind && proceduralPuzzleOrder.includes(hotspot.puzzleKind)) {
    return hotspot.puzzleKind;
  }
  if (hotspot.puzzleId && proceduralPuzzleOrder.includes(hotspot.puzzleId as ProceduralPuzzleId)) {
    return hotspot.puzzleId as ProceduralPuzzleId;
  }
  return undefined;
}

export function sortProceduralHotspots(hotspots: GeneratedRoomHotspot[]): GeneratedRoomHotspot[] {
  return [...hotspots].sort((a, b) => {
    const aKey = proceduralHotspotKey(a);
    const bKey = proceduralHotspotKey(b);
    return (aKey ? hotspotOrder[aKey] : 99) - (bKey ? hotspotOrder[bKey] : 99);
  });
}

export function proceduralHotspotKind(hotspot: GeneratedRoomHotspot): DeviceKind {
  const key = proceduralHotspotKey(hotspot);
  return key ? hotspotKinds[key] : "core";
}

export function proceduralHotspotPosition(hotspot: GeneratedRoomHotspot, stage: ChromeRect): { x: number; y: number } {
  const key = proceduralHotspotKey(hotspot);
  if (hotspot.puzzleKind && hotspot.puzzleId !== hotspot.puzzleKind) {
    return {
      x: stage.x + (hotspot.x / 1280) * stage.width,
      y: stage.y + (hotspot.y / 720) * stage.height,
    };
  }
  const positions: Record<ProceduralHotspotKey, { x: number; y: number }> = {
    language: { x: stage.x + 142, y: stage.y + 342 },
    circuit: { x: stage.x + 142, y: stage.y + 160 },
    math: { x: stage.x + 318, y: stage.y + 112 },
    english: { x: stage.x + 494, y: stage.y + 160 },
    robot: { x: stage.x + 494, y: stage.y + 342 },
    music: { x: stage.x + 318, y: stage.y + 286 },
    door: { x: stage.x + 318, y: stage.y + 420 },
  };
  return key ? positions[key] : { x: stage.x + stage.width / 2, y: stage.y + stage.height / 2 };
}

export function proceduralHotspotState(
  hotspot: GeneratedRoomHotspot,
  solvedPuzzleIds: string[],
  allSolved: boolean,
): DeviceState {
  const key = proceduralHotspotKey(hotspot);
  const solved = isProceduralHotspotSolved(hotspot, solvedPuzzleIds);
  if (key === "door") {
    return allSolved ? "ready" : "locked";
  }
  if (!key) {
    return "ready";
  }
  if (solved) {
    return "complete";
  }
  return "active";
}

export function isProceduralHotspotSolved(hotspot: GeneratedRoomHotspot, solvedPuzzleIds: string[]): boolean {
  if (hotspot.puzzleId) {
    const kind = puzzleKindFromId(hotspot.puzzleId);
    return solvedPuzzleIds.some((id) => id === hotspot.puzzleId || id === kind);
  }
  const key = proceduralHotspotKey(hotspot);
  return Boolean(key && solvedPuzzleIds.some((id) => id === key || id.startsWith(`${key}-`)));
}

export function proceduralRequiredPuzzleIds(objectives: Array<{ id: string }>): string[] {
  const required = new Set(
    objectives
      .map((objective) => objective.id.replace("procedural-", ""))
      .filter(Boolean),
  );
  if (required.size === 0) {
    return proceduralPuzzleOrder;
  }
  return [...required].sort((a, b) => {
    const aKind = puzzleKindFromId(a);
    const bKind = puzzleKindFromId(b);
    const kindDelta = proceduralPuzzleOrder.indexOf(aKind) - proceduralPuzzleOrder.indexOf(bKind);
    return kindDelta !== 0 ? kindDelta : a.localeCompare(b, "it", { numeric: true });
  });
}

export function pendingProceduralPuzzleLabel(solvedPuzzleIds: string[], requiredIds: string[] = proceduralPuzzleOrder): string {
  const labels: Record<ProceduralPuzzleId, string> = {
    language: "stabilizza il segnale",
    circuit: "diagnostica il circuito",
    math: "ricostruisci il codice",
    english: "decodifica il comando",
    robot: "guida il robot",
    music: "riconosci la nota",
  };
  const pending = requiredIds.find((id) => !isProceduralPuzzleSolved(id, solvedPuzzleIds));
  return pending ? labels[puzzleKindFromId(pending)] : "apri la porta finale";
}

export function puzzleKindFromId(id: string): ProceduralPuzzleId {
  const kind = proceduralPuzzleOrder.find((candidate) => id === candidate || id.startsWith(`${candidate}-`));
  return kind ?? "language";
}

export function isProceduralPuzzleSolved(id: string, solvedPuzzleIds: string[]): boolean {
  const kind = puzzleKindFromId(id);
  return solvedPuzzleIds.some((solvedId) => solvedId === id || solvedId === kind || (id === kind && solvedId.startsWith(`${kind}-`)));
}
