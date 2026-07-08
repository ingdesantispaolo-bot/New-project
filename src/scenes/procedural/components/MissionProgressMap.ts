import Phaser from "phaser";
import type { GeneratedRoomHotspot, ProceduralRunSave } from "../../../procedural/ProceduralTypes";
import type { ChromeRect, DeviceState } from "../../../ui/SceneChrome";
import {
  isProceduralHotspotFailed,
  isProceduralHotspotSolved,
  proceduralHotspotKey,
  proceduralHotspotState,
  type ProceduralHotspotKey,
} from "../ProceduralMissionLayout";
import type { ProceduralVisualTheme } from "../ProceduralVisualThemes";

type MapPoint = { x: number; y: number };

type MissionMapNode = {
  hotspot: GeneratedRoomHotspot;
  point: MapPoint;
  key?: ProceduralHotspotKey;
  state: DeviceState;
  solved: boolean;
  failed: boolean;
  primary: boolean;
};

export type MissionProgressMapOptions = {
  scene: Phaser.Scene;
  rect: ChromeRect;
  hotspots: GeneratedRoomHotspot[];
  points: MapPoint[];
  run: ProceduralRunSave;
  allSolved: boolean;
  theme: ProceduralVisualTheme;
  primaryPuzzle?: string;
};

const fallbackPoint = (rect: ChromeRect): MapPoint => ({
  x: rect.x + rect.width / 2,
  y: rect.y + rect.height / 2,
});

export class MissionProgressMap {
  static draw(options: MissionProgressMapOptions): void {
    const { scene, rect, hotspots, points, run, allSolved, theme, primaryPuzzle } = options;
    const nodes = hotspots.map((hotspot, index): MissionMapNode => {
      const solved = isProceduralHotspotSolved(hotspot, run.solvedPuzzleIds);
      const failed = !solved && isProceduralHotspotFailed(hotspot, run.failedPuzzleIds ?? []);
      return {
        hotspot,
        point: points[index] ?? fallbackPoint(rect),
        key: proceduralHotspotKey(hotspot),
        state: proceduralHotspotState(hotspot, run.solvedPuzzleIds, allSolved, run.failedPuzzleIds ?? []),
        solved,
        failed,
        primary: Boolean(primaryPuzzle) && (hotspot.puzzleKind === primaryPuzzle || hotspot.puzzleId === primaryPuzzle),
      };
    });
    const recommended = this.recommendedNode(nodes);

    this.drawMapPlane(scene, rect, theme);
    this.drawConnections(scene, nodes, theme, nodes.some((node) => node.solved));
    this.drawNodeRings(scene, nodes, theme, recommended);
  }

  private static drawMapPlane(scene: Phaser.Scene, rect: ChromeRect, theme: ProceduralVisualTheme): void {
    const plate = {
      x: rect.x + 58,
      y: rect.y + 96,
      width: rect.width - 116,
      height: rect.height - 172,
    };
    const graphics = scene.add.graphics();

    // Single floor plane: quiet structure, no stacked panels over the mission area.
    graphics.fillStyle(0x031017, 0.7);
    graphics.fillRoundedRect(plate.x, plate.y, plate.width, plate.height, 8);
    graphics.fillStyle(0x0b2230, 0.18);
    graphics.fillRoundedRect(plate.x + 8, plate.y + 8, plate.width - 16, 42, 6);
    graphics.lineStyle(1, theme.accent, 0.18);
    graphics.strokeRoundedRect(plate.x, plate.y, plate.width, plate.height, 8);

    const laneCount = 3;
    for (let index = 0; index < laneCount; index += 1) {
      const y = plate.y + 78 + index * 74;
      graphics.lineStyle(1, theme.accent, 0.035);
      graphics.lineBetween(plate.x + 32, y, plate.x + plate.width - 32, y);
    }

    for (let index = 0; index < 4; index += 1) {
      const x = plate.x + 62 + index * ((plate.width - 124) / 3);
      graphics.lineStyle(1, 0xffffff, 0.018);
      graphics.lineBetween(x, plate.y + 62, x, plate.y + plate.height - 28);
    }
  }

  private static drawConnections(scene: Phaser.Scene, nodes: MissionMapNode[], theme: ProceduralVisualTheme, hasSolvedNode: boolean): void {
    const graphics = scene.add.graphics();
    nodes.slice(0, -1).forEach((node, index) => {
      const next = nodes[index + 1];
      const warning = node.failed || next.failed;
      const active = node.solved || (next.key === "door" && next.state === "ready");
      const color = warning ? 0xf6c85f : active ? theme.secondary : 0x4a7a83;
      const shadowAlpha = warning ? 0.1 : active ? 0.12 : 0.035;
      const lineAlpha = warning ? 0.46 : active ? 0.54 : 0.14;

      graphics.lineStyle(7, color, shadowAlpha);
      graphics.lineBetween(node.point.x, node.point.y, next.point.x, next.point.y);
      graphics.lineStyle(1.5, color, lineAlpha);
      graphics.lineBetween(node.point.x, node.point.y, next.point.x, next.point.y);

      if (hasSolvedNode && active && !warning) {
        this.drawTravelPulse(scene, node.point, next.point, color, index);
      }
    });
  }

  private static drawNodeRings(
    scene: Phaser.Scene,
    nodes: MissionMapNode[],
    theme: ProceduralVisualTheme,
    recommended?: MissionMapNode,
  ): void {
    nodes.forEach((node) => {
      const radius = node.key === "door" ? 39 : 30;
      const color = this.colorFor(node, theme);
      const ring = scene.add.graphics();

      scene.add.ellipse(node.point.x, node.point.y + radius * 0.76, radius * 1.5, radius * 0.36, 0x000000, 0.22);
      ring.lineStyle(5, 0x000000, 0.16);
      ring.strokeCircle(node.point.x, node.point.y, radius + 7);
      ring.lineStyle(1.5, color, node.state === "locked" ? 0.12 : 0.22);
      ring.strokeCircle(node.point.x, node.point.y, radius + 6);
      this.strokeProgressArc(ring, node.point, radius + 6, this.progressFor(node), color, node.state === "locked" ? 0.14 : 0.74);

      if (node === recommended) {
        this.drawBeacon(scene, node.point, radius + 13, color, true);
      } else if (node.primary) {
        this.drawBeacon(scene, node.point, radius + 10, theme.secondary, false);
      }

      if (node.solved) {
        scene.add.circle(node.point.x + radius * 0.58, node.point.y - radius * 0.58, 5, 0x2ed889, 0.95)
          .setStrokeStyle(1, 0xffffff, 0.36);
      } else if (node.failed) {
        scene.add.circle(node.point.x + radius * 0.58, node.point.y - radius * 0.58, 5, 0xf6c85f, 0.95)
          .setStrokeStyle(1, 0x1b1308, 0.6);
      }
    });
  }

  private static drawTravelPulse(scene: Phaser.Scene, from: MapPoint, to: MapPoint, color: number, index: number): void {
    const pulse = scene.add.circle(from.x, from.y, 3, color, 0.48);
    pulse.setBlendMode(Phaser.BlendModes.ADD);
    scene.tweens.add({
      targets: pulse,
      x: to.x,
      y: to.y,
      alpha: 0,
      scale: 1.18,
      duration: 1550,
      delay: index * 110,
      repeat: -1,
      repeatDelay: 450,
      onRepeat: () => {
        pulse.setPosition(from.x, from.y);
        pulse.setAlpha(0.48);
        pulse.setScale(0.85);
      },
    });
  }

  private static drawBeacon(scene: Phaser.Scene, point: MapPoint, radius: number, color: number, animated: boolean): void {
    const beacon = scene.add.circle(point.x, point.y, radius, color, animated ? 0.04 : 0.025)
      .setStrokeStyle(2, color, animated ? 0.34 : 0.22);
    if (animated) {
      scene.tweens.add({
        targets: beacon,
        alpha: 0.1,
        scale: 1.05,
        duration: 1100,
        yoyo: true,
        repeat: -1,
      });
    }
  }

  private static strokeProgressArc(graphics: Phaser.GameObjects.Graphics, point: MapPoint, radius: number, progress: number, color: number, alpha: number): void {
    if (progress <= 0) {
      return;
    }
    graphics.lineStyle(4, color, alpha);
    graphics.beginPath();
    graphics.arc(point.x, point.y, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Phaser.Math.Clamp(progress, 0, 1), false);
    graphics.strokePath();
  }

  private static progressFor(node: MissionMapNode): number {
    if (node.solved || (node.key === "door" && node.state === "ready")) {
      return 1;
    }
    if (node.failed) {
      return 0.42;
    }
    if (node.state === "active") {
      return 0.22;
    }
    return node.state === "locked" ? 0.08 : 0.18;
  }

  private static colorFor(node: MissionMapNode, theme: ProceduralVisualTheme): number {
    if (node.failed) {
      return 0xf6c85f;
    }
    const stateColors: Record<DeviceState, number> = {
      active: theme.accent,
      complete: 0x2ed889,
      failed: 0xf6c85f,
      locked: 0x6b7d84,
      ready: theme.secondary,
    };
    return stateColors[node.state];
  }

  private static recommendedNode(nodes: MissionMapNode[]): MissionMapNode | undefined {
    return nodes.find((node) => node.failed)
      ?? nodes.find((node) => node.state === "active")
      ?? nodes.find((node) => node.key === "door" && node.state === "ready");
  }
}
