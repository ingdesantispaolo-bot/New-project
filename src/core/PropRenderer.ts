import Phaser from "phaser";
import type { GeneratedRoomHotspot } from "../procedural/ProceduralTypes";
import type { LaboratoryObject } from "../data/laboratoryObjects";
import type { ProceduralPropTheme } from "../scenes/procedural/ProceduralVisualThemes";
import { drawVectorProp, type PropArchetype } from "../scenes/procedural/VectorProps";

type PropLayout = { x: number; y: number; width?: number; height?: number; radius?: number };

// Lab object id -> vector housing archetype.
const labArchetypes: Record<string, PropArchetype> = {
  "corrupted-message": "console",
  "electric-panel": "panel",
  "final-door": "door",
  "floor-trace": "trace",
  "journal-station": "journal",
  "nora-core": "core",
  "observation-window": "window",
  robot: "robotDock",
  terminal: "terminal",
  workbench: "workbench",
};

// Procedural puzzle kind -> vector housing archetype.
const proceduralArchetypes: Record<string, PropArchetype> = {
  circuit: "panel",
  coding: "terminal",
  door: "door",
  english: "console",
  language: "console",
  math: "terminal",
  music: "music",
  robot: "robotDock",
};

const themeAccent: Record<ProceduralPropTheme, number> = {
  lab: 0x6be7d6,
  circuit: 0x6be7d6,
  academy: 0x6be7d6,
  greenhouse: 0x70d68a,
  factory: 0xf6c85f,
  archive: 0x9f8cff,
};

class PropRenderer {
  renderLaboratoryProps(
    scene: Phaser.Scene,
    objects: LaboratoryObject[],
    layoutFor: (object: LaboratoryObject) => PropLayout,
    completed: (object: LaboratoryObject) => boolean,
    locked: (object: LaboratoryObject) => boolean,
  ): void {
    objects.forEach((object) => {
      const archetype = labArchetypes[object.id];
      if (!archetype) {
        return;
      }
      const layout = layoutFor(object);
      const state = completed(object) ? "complete" : locked(object) ? "locked" : "ready";
      const size = object.radius * this.scaleFor(object.id);
      drawVectorProp(scene, archetype, layout.x, layout.y, size, state, 0x6be7d6);
    });
  }

  renderProceduralProps(
    scene: Phaser.Scene,
    hotspots: GeneratedRoomHotspot[],
    positionFor: (hotspot: GeneratedRoomHotspot) => { x: number; y: number },
    solved: (puzzleId: string | undefined, hotspot: GeneratedRoomHotspot) => boolean,
    propTheme: ProceduralPropTheme = "lab",
  ): void {
    const accent = themeAccent[propTheme] ?? 0x6be7d6;
    hotspots.forEach((hotspot) => {
      const kind = hotspot.id === "door" ? "door" : hotspot.puzzleKind ?? hotspot.puzzleId ?? "";
      const archetype = proceduralArchetypes[kind];
      if (!archetype) {
        return;
      }
      const point = positionFor(hotspot);
      const size = hotspot.id === "door" ? 120 : 104;
      const state = solved(hotspot.puzzleId, hotspot) ? "complete" : "ready";
      drawVectorProp(scene, archetype, point.x, point.y, size, state, accent);
    });
  }

  private scaleFor(id: string): number {
    if (id === "final-door") return 2.42;
    if (id === "terminal") return 1.82;
    if (id === "electric-panel") return 1.68;
    if (id === "robot") return 1.62;
    if (id === "floor-trace") return 1.36;
    if (id === "workbench") return 1.58;
    if (id === "observation-window") return 1.52;
    return 1.5;
  }
}

export const propRenderer = new PropRenderer();
