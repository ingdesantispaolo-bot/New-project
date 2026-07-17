import { Button } from "../../ui/Button";
import { placeHiddenAnomaly } from "../../ui/HiddenAnomaly";
import type { ActivityMeta } from "./LogicGymTypes";

type Track = <T extends Phaser.GameObjects.GameObject>(object: T) => T;

export type LogicGymHubActivity = ActivityMeta & {
  levelLine: string;
  record: number;
};

export function renderLogicGymHub(scene: Phaser.Scene, track: Track, input: {
  gymLevel: number;
  levelSubtitle: string;
  activities: LogicGymHubActivity[];
  onLevelDelta: (delta: number) => void;
  onMenu: () => void;
}): void {
  track(scene.add.text(56, 28, "Palestra della Mente", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }));
  track(scene.add.text(58, 68, "Calibrazione autonoma: scegli la profondità, poi gioca. I record sono separati per settore.", { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", wordWrap: { width: 760 } }));
  track(scene.add.rectangle(1004, 54, 296, 54, 0x0c1d2a, 0.92).setStrokeStyle(2, 0xf6c85f, 0.48));
  track(scene.add.text(1004, 40, `Profondità ${input.gymLevel}/8`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
  track(scene.add.text(1004, 66, input.levelSubtitle, { fontFamily: "Inter, Arial", fontSize: "11px", color: "#c7dce7" }).setOrigin(0.5));
  track(new Button(scene, 870, 54, "−", () => input.onLevelDelta(-1), { width: 42, height: 38, fontSize: 24, fill: 0x263743 }));
  track(new Button(scene, 1138, 54, "+", () => input.onLevelDelta(1), { width: 42, height: 38, fontSize: 22, fill: 0x263743 }));
  placeHiddenAnomaly(scene, "LogicGymScene");

  const cols = 4;
  const w = 288;
  const h = 172;
  const gap = 10;
  const startX = 40;
  const startY = 110;
  input.activities.forEach((activity, index) => {
    const x = startX + (index % cols) * (w + gap);
    const y = startY + Math.floor(index / cols) * (h + gap);
    track(scene.add.rectangle(x, y, w, h, 0x0c1d2a, 0.94).setOrigin(0).setStrokeStyle(2, activity.color, 0.55));
    track(scene.add.rectangle(x, y, w, 5, activity.color, 0.9).setOrigin(0));
    renderActivityIcon(scene, track, activity, x + 34, y + 38);
    track(scene.add.text(x + 70, y + 14, activity.title, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: w - 88 } }));
    track(scene.add.text(x + 72, y + 42, activity.theme.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "11px", color: Phaser.Display.Color.IntegerToColor(activity.color).rgba, fontStyle: "bold" }));
    track(scene.add.text(x + 20, y + 60, activity.desc, { fontFamily: "Inter, Arial", fontSize: "10px", color: "#c7dce7", wordWrap: { width: w - 40, useAdvancedWrap: true }, lineSpacing: 1 }));
    track(scene.add.text(x + 20, y + 110, activity.levelLine, { fontFamily: "Inter, Arial", fontSize: "9px", color: "#9ff5e9", wordWrap: { width: w - 40, useAdvancedWrap: true } }));
    track(scene.add.text(x + 20, y + 142, `Record: ${activity.record}`, { fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", fontStyle: "bold" }));
    track(new Button(scene, x + w - 62, y + 146, "Gioca", () => activity.start(), { width: 100, height: 34, fill: 0x1f5a51, stroke: activity.color, fontSize: 13 }));
  });

  track(new Button(scene, 132, 686, "Menu", input.onMenu, { width: 170, height: 44, fill: 0x263743 }));
}

export function renderLogicGymBackBar(scene: Phaser.Scene, track: Track, input: {
  bonusMode: boolean;
  gymLevel: number;
  levelSubtitle: string;
  onBack: () => void;
}): void {
  track(scene.add.text(640, 686, `${input.bonusMode ? "Evento bonus" : `Profondità ${input.gymLevel}/8`} · ${input.levelSubtitle}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
  track(new Button(scene, 132, 686, input.bonusMode ? "Missione" : "Palestra", input.onBack, { width: 170, height: 44, fill: 0x263743 }));
}

function renderActivityIcon(scene: Phaser.Scene, track: Track, activity: ActivityMeta, x: number, y: number): void {
  if (scene.textures.exists("logic-gym") && scene.textures.getFrame("logic-gym", activity.icon)) {
    track(scene.add.image(x, y, "logic-gym", activity.icon).setDisplaySize(46, 46));
    return;
  }
  track(scene.add.circle(x, y, 22, activity.color, 0.24).setStrokeStyle(2, activity.color, 0.72));
  track(scene.add.text(x, y, activity.glyph, {
    fontFamily: "Inter, Arial",
    fontSize: "16px",
    color: "#f5fbff",
    fontStyle: "bold",
  }).setOrigin(0.5));
}
