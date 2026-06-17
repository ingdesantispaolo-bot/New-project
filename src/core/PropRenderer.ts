import Phaser from "phaser";
import type { GeneratedRoomHotspot } from "../procedural/ProceduralTypes";
import type { LaboratoryObject } from "../data/laboratoryObjects";
import type { ProceduralPropTheme } from "../scenes/procedural/ProceduralVisualThemes";

type PropLayout = { x: number; y: number; width?: number; height?: number; radius?: number };

const labPropKeys: Record<string, { painted?: string; fallback: string }> = {
  "corrupted-message": { painted: "painted-message-console", fallback: "prop-message-console" },
  "electric-panel": { painted: "painted-circuit-panel", fallback: "prop-circuit-panel" },
  "final-door": { painted: "painted-door-lab", fallback: "prop-door-lab" },
  "floor-trace": { fallback: "prop-floor-trace" },
  "journal-station": { painted: "painted-journal", fallback: "prop-journal" },
  "nora-core": { painted: "painted-nora-core", fallback: "prop-nora-core" },
  "observation-window": { fallback: "prop-window" },
  robot: { painted: "painted-robot-dock", fallback: "prop-robot-dock" },
  terminal: { painted: "painted-terminal", fallback: "prop-terminal" },
  workbench: { painted: "painted-workbench", fallback: "prop-workbench" },
};

const proceduralPropKeys: Record<string, { painted?: string; fallback: string }> = {
  circuit: { painted: "painted-circuit-panel", fallback: "prop-circuit-panel" },
  coding: { painted: "painted-terminal", fallback: "prop-terminal" },
  door: { painted: "painted-door-lab", fallback: "prop-door-lab" },
  english: { painted: "painted-message-console", fallback: "prop-message-console" },
  language: { painted: "painted-message-console", fallback: "prop-message-console" },
  math: { painted: "painted-terminal", fallback: "prop-terminal" },
  music: { painted: "painted-terminal", fallback: "prop-terminal" },
  robot: { painted: "painted-robot-dock", fallback: "prop-robot-dock" },
};

const themedProceduralPropKeys: Partial<Record<ProceduralPropTheme, Partial<Record<string, { painted?: string; fallback: string }>>>> = {
  archive: {
    circuit: { painted: "painted-archive-desk", fallback: "prop-terminal" },
    coding: { painted: "painted-archive-terminal", fallback: "prop-terminal" },
    door: { painted: "painted-archive-shelf", fallback: "prop-door-lab" },
    english: { painted: "painted-archive-shelf", fallback: "prop-message-console" },
    language: { painted: "painted-archive-terminal", fallback: "prop-message-console" },
    math: { painted: "painted-archive-desk", fallback: "prop-terminal" },
    music: { painted: "painted-archive-desk", fallback: "prop-terminal" },
    robot: { painted: "painted-archive-terminal", fallback: "prop-robot-dock" },
  },
  factory: {
    circuit: { painted: "painted-factory-core", fallback: "prop-circuit-panel" },
    coding: { painted: "painted-factory-machine", fallback: "prop-terminal" },
    door: { painted: "painted-factory-core", fallback: "prop-door-lab" },
    english: { painted: "painted-factory-machine", fallback: "prop-message-console" },
    language: { painted: "painted-factory-machine", fallback: "prop-message-console" },
    math: { painted: "painted-factory-machine", fallback: "prop-terminal" },
    music: { painted: "painted-factory-machine", fallback: "prop-terminal" },
    robot: { painted: "painted-factory-conveyor", fallback: "prop-robot-dock" },
  },
  greenhouse: {
    circuit: { painted: "painted-greenhouse-valve", fallback: "prop-circuit-panel" },
    coding: { painted: "painted-greenhouse-sensor", fallback: "prop-terminal" },
    door: { painted: "painted-greenhouse-pod", fallback: "prop-door-lab" },
    english: { painted: "painted-greenhouse-sensor", fallback: "prop-message-console" },
    language: { painted: "painted-greenhouse-sensor", fallback: "prop-message-console" },
    math: { painted: "painted-greenhouse-sensor", fallback: "prop-terminal" },
    music: { painted: "painted-greenhouse-sensor", fallback: "prop-terminal" },
    robot: { painted: "painted-greenhouse-pod", fallback: "prop-robot-dock" },
  },
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
      const key = this.resolveTextureKey(scene, labPropKeys[object.id]);
      if (!key || !scene.textures.exists(key)) {
        return;
      }
      const layout = layoutFor(object);
      const state = completed(object) ? "complete" : locked(object) ? "locked" : "ready";
      this.drawProp(scene, key, layout.x, layout.y, object.radius * this.scaleFor(object.id), state);
    });
  }

  renderProceduralProps(
    scene: Phaser.Scene,
    hotspots: GeneratedRoomHotspot[],
    positionFor: (hotspot: GeneratedRoomHotspot) => { x: number; y: number },
    solved: (puzzleId: string | undefined, hotspot: GeneratedRoomHotspot) => boolean,
    propTheme: ProceduralPropTheme = "lab",
  ): void {
    hotspots.forEach((hotspot) => {
      const kind = hotspot.id === "door" ? "door" : hotspot.puzzleKind ?? hotspot.puzzleId ?? "";
      const key = this.resolveTextureKey(scene, themedProceduralPropKeys[propTheme]?.[kind] ?? proceduralPropKeys[kind]);
      if (!key || !scene.textures.exists(key)) {
        return;
      }
      const point = positionFor(hotspot);
      this.drawProp(scene, key, point.x, point.y, hotspot.id === "door" ? 120 : 104, solved(hotspot.puzzleId, hotspot) ? "complete" : "ready");
    });
  }

  private drawProp(
    scene: Phaser.Scene,
    key: string,
    x: number,
    y: number,
    targetSize: number,
    state: "locked" | "ready" | "complete",
  ): Phaser.GameObjects.Image {
    scene.add.ellipse(x, y + targetSize * 0.42, targetSize * 0.8, targetSize * 0.16, 0x000000, 0.22);
    if (state === "complete") {
      scene.add.image(x, y, "soft-glow").setTint(0xf6c85f).setAlpha(0.16).setScale(targetSize / 72);
    }
    const image = scene.add.image(x, y, key);
    const source = scene.textures.get(key).getSourceImage() as HTMLImageElement | HTMLCanvasElement;
    const maxSource = Math.max(source.width || 256, source.height || 256);
    image.setScale(targetSize / maxSource);
    image.setAlpha(state === "locked" ? 0.48 : state === "complete" ? 1 : 0.9);
    image.setTint(state === "locked" ? 0x7f9098 : 0xffffff);
    return image;
  }

  private resolveTextureKey(scene: Phaser.Scene, keys: { painted?: string; fallback: string } | undefined): string | undefined {
    if (!keys) return undefined;
    if (keys.painted && scene.textures.exists(keys.painted)) return keys.painted;
    return keys.fallback;
  }

  private scaleFor(id: string): number {
    if (id === "final-door") return 2.6;
    if (id === "terminal") return 2.05;
    if (id === "electric-panel") return 1.9;
    if (id === "robot") return 1.9;
    if (id === "floor-trace") return 1.65;
    if (id === "workbench") return 1.95;
    if (id === "observation-window") return 1.8;
    return 1.72;
  }
}

export const propRenderer = new PropRenderer();
