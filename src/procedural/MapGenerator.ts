import { getProceduralFocusPath, proceduralFocusChallengeCount } from "../data/procedural/focusPaths";
import type { DifficultyPreset, GeneratedRoomHotspot, GeneratedRoomMap } from "./ProceduralTypes";
import type { Random } from "./Random";

export class MapGenerator {
  generate(random: Random, difficulty: DifficultyPreset, focus: string[] = []): GeneratedRoomMap {
    const path = getProceduralFocusPath(focus);
    const title = random.pick(path.roomTitles);
    const allHotspots: GeneratedRoomHotspot[] = [
      {
        id: "language",
        label: path.hotspots.language.label,
        x: 382,
        y: 472,
        radius: 42,
        puzzleId: "language",
        description: path.hotspots.language.description,
      },
      {
        id: "circuit",
        label: path.hotspots.circuit.label,
        x: 312,
        y: 256,
        radius: 52,
        puzzleId: "circuit",
        description: path.hotspots.circuit.description,
      },
      {
        id: "math",
        label: path.hotspots.math.label,
        x: 640,
        y: 220,
        radius: 56,
        puzzleId: "math",
        description: path.hotspots.math.description,
      },
      {
        id: "english",
        label: path.hotspots.english.label,
        x: 914,
        y: 254,
        radius: 50,
        puzzleId: "english",
        description: path.hotspots.english.description,
      },
      {
        id: "robot",
        label: path.hotspots.robot.label,
        x: 914,
        y: 502,
        radius: 56,
        puzzleId: "robot",
        description: path.hotspots.robot.description,
      },
      {
        id: "music",
        label: path.hotspots.music.label,
        x: 640,
        y: 502,
        radius: 52,
        puzzleId: "music",
        description: path.hotspots.music.description,
      },
    ];
    const activeHotspots = path.primaryPuzzle
      ? this.focusHotspots(path.primaryPuzzle, path.challengeStages, difficulty.level)
      : allHotspots;
    return {
      id: `procedural-room-map-${path.id}`,
      title,
      roomCount: difficulty.roomCount,
      hotspots: [
        ...activeHotspots,
        {
          id: "door",
          label: "Porta di uscita",
          x: 610,
          y: 504,
          radius: 64,
          description: "La porta si apre solo quando tutti i sistemi della missione sono coerenti.",
        },
      ],
    };
  }

  private focusHotspots(
    puzzleKind: NonNullable<ReturnType<typeof getProceduralFocusPath>["primaryPuzzle"]>,
    stages: Array<{ label: string; description: string }>,
    level: number,
  ): GeneratedRoomHotspot[] {
    const positions = [
      { x: 382, y: 256 },
      { x: 640, y: 220 },
      { x: 914, y: 256 },
      { x: 458, y: 502 },
      { x: 830, y: 502 },
    ];
    return stages.slice(0, proceduralFocusChallengeCount(level)).map((stage, index) => ({
      id: `${puzzleKind}-${index + 1}`,
      label: stage.label,
      x: positions[index].x,
      y: positions[index].y,
      radius: index === 0 ? 56 : 50,
      puzzleId: `${puzzleKind}-${index + 1}`,
      puzzleKind,
      description: stage.description,
    }));
  }
}
