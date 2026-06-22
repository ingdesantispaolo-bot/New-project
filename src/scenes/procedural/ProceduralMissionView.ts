import Phaser from "phaser";
import { propRenderer } from "../../core/PropRenderer";
import { proceduralRunRules } from "../../core/ProceduralRunRules";
import { getProceduralFocusPath } from "../../data/procedural/focusPaths";
import type { GeneratedRoomHotspot, ProceduralRunSave } from "../../procedural/ProceduralTypes";
import { Button } from "../../ui/Button";
import { SceneChrome } from "../../ui/SceneChrome";
import {
  pendingProceduralPuzzleLabel,
  isProceduralHotspotSolved,
  proceduralHotspotKind,
  proceduralHotspotPosition,
  proceduralRequiredPuzzleIds,
  proceduralHotspotState,
  sortProceduralHotspots,
} from "./ProceduralMissionLayout";
import { drawProceduralStageAtmosphere, proceduralVisualThemeFor } from "./ProceduralVisualThemes";

export type ProceduralMissionHud = {
  objectiveText: Phaser.GameObjects.Text;
  progressText: Phaser.GameObjects.Text;
  feedbackText: Phaser.GameObjects.Text;
};

const statusColors = {
  active: 0xe85b63,
  complete: 0x2ed889,
  failed: 0xf6c85f,
  locked: 0x6b7d84,
};

export class ProceduralMissionView {
  static drawShell(scene: Phaser.Scene, run: ProceduralRunSave): void {
    const path = getProceduralFocusPath(run.focus);
    const mode = proceduralRunRules.modeFor(run);
    const theme = proceduralVisualThemeFor(run);
    const requiredIds = proceduralRequiredPuzzleIds(run.mission.objectives);
    const modeLabel = mode === "training" ? "Allenamento" : mode === "progressive" ? "Scalata" : "Missione";
    const focus = proceduralRunRules.focusFor(run);
    const layout = SceneChrome.drawMissionChrome(
      scene,
      theme.palette,
      run.mission.title,
      `${modeLabel}  |  Livello ${run.difficulty}: ${theme.levelName}  |  Seed ${run.seed}`,
      theme.stageTitle,
    );

    SceneChrome.section(scene, layout.left, "Briefing");
    scene.add.rectangle(layout.left.x + 18, layout.left.y + 48, layout.left.width - 36, 32, mode === "training" ? 0x1f5a51 : mode === "progressive" ? 0x33261a : 0x173244, 0.82)
      .setOrigin(0)
      .setStrokeStyle(1, mode === "training" ? 0xf6c85f : 0x6be7d6, 0.45);
    scene.add.text(layout.left.x + 34, layout.left.y + 57, mode === "training"
      ? `FOCUS: ${focus.toUpperCase()}`
      : mode === "progressive"
        ? `SCALATA: LIVELLO ${run.progressive?.currentLevel ?? run.difficulty}/8`
        : "MISSIONE PROCEDURALE", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: mode === "training" ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    });
    scene.add.text(layout.left.x + 18, layout.left.y + 58, this.briefingLines(mode, requiredIds.length, focus).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: layout.left.width - 36 },
      lineSpacing: 4,
    }).setY(layout.left.y + 92);

    scene.add.rectangle(layout.left.x + 22, layout.left.y + 184, layout.left.width - 44, 118, 0x07151d, 0.72)
      .setOrigin(0)
      .setStrokeStyle(1, theme.secondary, 0.25);
    scene.add.text(layout.left.x + 38, layout.left.y + 202, theme.ruleTitle, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
    scene.add.text(layout.left.x + 38, layout.left.y + 226, theme.ruleText, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: layout.left.width - 76 },
      lineSpacing: 4,
    });

    scene.add.text(layout.left.x + 18, layout.left.y + 326, "Stato console", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.drawLegendRow(scene, layout.left.x + 34, layout.left.y + 358, statusColors.active, "Da sistemare");
    this.drawLegendRow(scene, layout.left.x + 34, layout.left.y + 386, statusColors.complete, "Completata");
    this.drawLegendRow(scene, layout.left.x + 34, layout.left.y + 414, statusColors.failed, "Fallita");

    scene.add.rectangle(layout.left.x + 22, layout.left.y + 452, layout.left.width - 44, 42, 0x0b221f, 0.72)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.24);
    scene.add.text(layout.left.x + 38, layout.left.y + 464, `Traccia utile: ${pendingProceduralPuzzleLabel(run.solvedPuzzleIds, requiredIds, run.failedPuzzleIds ?? [])}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      wordWrap: { width: layout.left.width - 76 },
    });

    drawProceduralStageAtmosphere(scene, layout.stage, theme, run.solvedPuzzleIds.length, requiredIds.length, run.seed);
    scene.add.rectangle(layout.stage.x + 68, layout.stage.y + 78, layout.stage.width - 136, 302, 0x000000, 0.05)
      .setStrokeStyle(1, theme.accent, 0.08);
    scene.add.text(layout.stage.x + 52, layout.stage.y + 450, this.stageHint(mode, path.stageHint), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: layout.stage.width - 104 },
    });

    SceneChrome.section(scene, layout.right, mode === "training" ? "Record" : "Obiettivi");
  }

  static createHud(
    scene: Phaser.Scene,
    run: ProceduralRunSave,
    onRegenerate: () => void,
    onHub: () => void,
  ): ProceduralMissionHud {
    const layout = SceneChrome.layout;
    const objectiveText = scene.add.text(layout.right.x + 18, layout.right.y + 58, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: layout.right.width - 36 },
      lineSpacing: 4,
    });
    scene.add.rectangle(layout.right.x + 18, layout.right.y + 338, layout.right.width - 36, 132, 0x07151d, 0.68)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.2);
    scene.add.text(layout.right.x + 34, layout.right.y + 356, "Progresso", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    const progressText = scene.add.text(layout.right.x + 34, layout.right.y + 382, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: layout.right.width - 68 },
      lineSpacing: 3,
    });
    const feedbackText = SceneChrome.bottomLog(scene, layout.bottom, "", 330);
    const restartLabel = proceduralRunRules.modeFor(run) === "training"
      ? "Nuovo focus"
      : proceduralRunRules.modeFor(run) === "progressive"
        ? "Reset scalata"
        : "Ricomincia";
    new Button(scene, layout.bottom.x + layout.bottom.width - 248, layout.bottom.y + 28, restartLabel, onRegenerate, {
      width: 142,
      height: 38,
      fill: 0x263743,
      fontSize: 14,
    });
    new Button(scene, layout.bottom.x + layout.bottom.width - 82, layout.bottom.y + 28, "Menu", onHub, {
      width: 110,
      height: 38,
      fill: 0x142736,
      fontSize: 14,
    });
    return { objectiveText, progressText, feedbackText };
  }

  static createHotspots(
    scene: Phaser.Scene,
    run: ProceduralRunSave,
    allSolved: boolean,
    onOpen: (hotspot: GeneratedRoomHotspot) => void,
  ): void {
    const path = getProceduralFocusPath(run.focus);
    const theme = proceduralVisualThemeFor(run);
    const ordered = sortProceduralHotspots(run.mission.map.hotspots);
    const points = ordered.map((hotspot) => proceduralHotspotPosition(hotspot, SceneChrome.layout.stage));
    SceneChrome.connectDevices(scene, points, run.solvedPuzzleIds.length, theme.accent, theme.secondary);
    propRenderer.renderProceduralProps(
      scene,
      ordered,
      (hotspot) => proceduralHotspotPosition(hotspot, SceneChrome.layout.stage),
      (_puzzleId, hotspot) => isProceduralHotspotSolved(hotspot, run.solvedPuzzleIds),
      theme.propTheme,
    );
    ordered.forEach((hotspot) => {
      const point = proceduralHotspotPosition(hotspot, SceneChrome.layout.stage);
      const isPrimary = Boolean(path.primaryPuzzle) && (hotspot.puzzleKind === path.primaryPuzzle || hotspot.puzzleId === path.primaryPuzzle);
      if (isPrimary) {
        scene.add.circle(point.x, point.y, 50, theme.secondary, 0.055).setStrokeStyle(2, theme.secondary, 0.28);
      }
      SceneChrome.deviceHotspot(
        scene,
        point.x,
        point.y,
        proceduralHotspotKind(hotspot),
        hotspot.label,
        proceduralHotspotState(hotspot, run.solvedPuzzleIds, allSolved, run.failedPuzzleIds ?? []),
        () => onOpen(hotspot),
        hotspot.id === "door" ? 96 : isPrimary ? 84 : 78,
      );
    });
  }

  private static drawLegendRow(scene: Phaser.Scene, x: number, y: number, color: number, label: string): void {
    scene.add.circle(x, y + 8, 6, color, 0.9).setStrokeStyle(1, 0xffffff, 0.18);
    scene.add.text(x + 16, y, label, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
    });
  }

  private static briefingLines(mode: string, requiredCount: number, focus: string): string[] {
    if (mode === "training") {
      return [
        `${requiredCount} console del focus ${focus}.`,
        "Allenati senza vite: contano precisione, tempo e aiuti usati.",
      ];
    }
    if (mode === "progressive") {
      return [
        `${requiredCount} console per superare il livello.`,
        "Sequenza guidata: una console alla volta, senza tentativi casuali.",
      ];
    }
    return [
      `${requiredCount} console da diagnosticare.`,
      "Ordine libero: osserva, scegli e stabilizza il sistema.",
    ];
  }

  private static stageHint(mode: string, focusHint: string): string {
    if (mode === "training") {
      return focusHint;
    }
    if (mode === "progressive") {
      return "La mappa mostra il progresso. La scalata apre automaticamente la prossima console rossa.";
    }
    return "Le linee mostrano relazioni tra sistemi. Puoi partire da qualunque console rossa.";
  }
}
