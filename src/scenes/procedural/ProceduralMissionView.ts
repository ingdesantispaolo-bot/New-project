import Phaser from "phaser";
import { propRenderer } from "../../core/PropRenderer";
import { proceduralRunRules } from "../../core/ProceduralRunRules";
import { saveSystem } from "../../core/SaveSystem";
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
import { MissionProgressMap } from "./components/MissionProgressMap";

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

    // Path chip — colour-matches the menu cards for cross-screen continuity.
    const pathColor = mode === "training" ? 0x70d68a : mode === "progressive" ? 0xff8f6b : 0x6be7d6;
    const pathName = mode === "training" ? "ALLENAMENTO" : mode === "progressive" ? "SCALATA" : "MISSIONE RAPIDA";
    const chipX = layout.top.x + layout.top.width - 204;
    const chipY = layout.top.y + 24;
    scene.add.rectangle(chipX, chipY, 188, 34, 0x07151d, 0.85).setOrigin(0).setStrokeStyle(2, pathColor, 0.85);
    scene.add.rectangle(chipX, chipY, 5, 34, pathColor, 0.95).setOrigin(0);
    scene.add.text(chipX + 98, chipY + 17, pathName, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: Phaser.Display.Color.IntegerToColor(pathColor).rgba,
      fontStyle: "bold",
    }).setOrigin(0.5);

    SceneChrome.section(scene, layout.left, "Supporto");
    scene.add.rectangle(layout.left.x + 18, layout.left.y + 48, layout.left.width - 36, 34, mode === "training" ? 0x1f5a51 : mode === "progressive" ? 0x33261a : 0x173244, 0.82)
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
    scene.add.text(layout.left.x + 22, layout.left.y + 100, this.briefingLines(mode, requiredIds.length, focus).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: layout.left.width - 44 },
      lineSpacing: 4,
    });

    scene.add.rectangle(layout.left.x + 22, layout.left.y + 178, layout.left.width - 44, 138, 0x07151d, 0.72)
      .setOrigin(0)
      .setStrokeStyle(1, theme.secondary, 0.25);
    scene.add.text(layout.left.x + 38, layout.left.y + 196, theme.ruleTitle, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
    scene.add.text(layout.left.x + 38, layout.left.y + 220, theme.ruleText, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: layout.left.width - 76 },
      lineSpacing: 4,
    });

    scene.add.text(layout.left.x + 22, layout.left.y + 348, "Legenda essenziale", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.drawLegendRow(scene, layout.left.x + 38, layout.left.y + 378, statusColors.active, "aperta");
    this.drawLegendRow(scene, layout.left.x + 136, layout.left.y + 378, statusColors.complete, "fatta");
    this.drawLegendRow(scene, layout.left.x + 222, layout.left.y + 378, statusColors.failed, "da rivedere");

    scene.add.rectangle(layout.left.x + 22, layout.left.y + 430, layout.left.width - 44, 56, 0x0b221f, 0.72)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.24);
    scene.add.text(layout.left.x + 38, layout.left.y + 444, `Prossimo passo: ${pendingProceduralPuzzleLabel(run.solvedPuzzleIds, requiredIds, run.failedPuzzleIds ?? [])}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      wordWrap: { width: layout.left.width - 76 },
      lineSpacing: 3,
    });

    drawProceduralStageAtmosphere(scene, layout.stage, theme, run.solvedPuzzleIds.length, requiredIds.length, run.seed);
    const stability = requiredIds.length > 0 ? Phaser.Math.Clamp(run.solvedPuzzleIds.length / requiredIds.length, 0, 1) : 0;
    const prismaticCore = saveSystem.data.inventory.includes("nora-prismatic-core");
    const stabilityColor = prismaticCore ? 0x9f8cff : stability >= 1 ? theme.secondary : theme.accent;
    const stabilityWidth = layout.stage.width - 150;
    scene.add.rectangle(layout.stage.x + layout.stage.width / 2, layout.stage.y + 46, stabilityWidth, 14, 0x07151d, 0.88)
      .setStrokeStyle(1, theme.accent, 0.4);
    if (stability > 0) {
      scene.add.rectangle(layout.stage.x + 75, layout.stage.y + 46, stabilityWidth * stability, 10, stabilityColor, 0.92)
        .setOrigin(0, 0.5);
    }
    scene.add.text(layout.stage.x + layout.stage.width / 2, layout.stage.y + 24, `STABILITÀ STANZA ${Math.round(stability * 100)}%`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: stability >= 1 ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5);
    SceneChrome.section(scene, layout.right, "Obiettivo");
  }

  static createHud(
    scene: Phaser.Scene,
    run: ProceduralRunSave,
    onRegenerate: () => void,
    onHub: () => void,
    onUseNoraCharge?: () => void,
  ): ProceduralMissionHud {
    const layout = SceneChrome.layout;
    const objectiveText = scene.add.text(layout.right.x + 18, layout.right.y + 58, "", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: layout.right.width - 36 },
      lineSpacing: 5,
    });
    scene.add.rectangle(layout.right.x + 18, layout.right.y + 292, layout.right.width - 36, 150, 0x07151d, 0.68)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.2);
    scene.add.text(layout.right.x + 34, layout.right.y + 310, "Stato", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    const progressText = scene.add.text(layout.right.x + 34, layout.right.y + 336, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: layout.right.width - 68 },
      lineSpacing: 3,
    });
    const feedbackText = SceneChrome.bottomLog(scene, layout.bottom, "", 330);
    const chargeStep = saveSystem.data.inventory.includes("nora-reserve") ? 1 : 2;
    const earnedCharges = Math.min(2, Math.floor(run.solvedPuzzleIds.length / chargeStep));
    const availableCharges = Math.max(0, earnedCharges - (run.noraChargesUsed ?? 0));
    if (onUseNoraCharge && proceduralRunRules.modeFor(run) !== "training" && availableCharges > 0) {
      new Button(scene, layout.bottom.x + layout.bottom.width - 430, layout.bottom.y + 28, `Impulso NORA ×${availableCharges}`, onUseNoraCharge, {
        width: 190,
        height: 38,
        fill: 0x173b36,
        stroke: 0xf6c85f,
        fontSize: 12,
      });
    }
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

  /**
   * HUD compatta per la stanza esplorabile: una sola plancia superiore con
   * obiettivo immediato, stato essenziale, comandi e azioni. Evita seed e
   * spiegazioni ridondanti: lo studente deve guardare la stanza, non leggere UI.
   */
  static createExploreChrome(
    scene: Phaser.Scene,
    run: ProceduralRunSave,
    onRegenerate: () => void,
    onHub: () => void,
    onUseNoraCharge?: () => void,
  ): ProceduralMissionHud {
    const theme = proceduralVisualThemeFor(run);
    const mode = proceduralRunRules.modeFor(run);
    const T = SceneChrome.layout.top;
    const DEPTH = 1000;
    const fx = <G extends Phaser.GameObjects.GameObject>(o: G): G => {
      (o as unknown as { setScrollFactor?: (v: number) => void }).setScrollFactor?.(0);
      (o as unknown as { setDepth?: (v: number) => void }).setDepth?.(DEPTH);
      return o;
    };

    const modeLabel = mode === "training" ? "Allenamento" : mode === "progressive" ? "Scalata" : "Missione";
    const panelH = 104;
    fx(scene.add.rectangle(T.x, T.y, T.width, panelH, 0x07151d, 0.92).setOrigin(0).setStrokeStyle(2, theme.accent, 0.5));
    fx(scene.add.rectangle(T.x, T.y, 6, panelH, theme.accent, 0.95).setOrigin(0));
    fx(scene.add.rectangle(T.x + 312, T.y + 18, 2, panelH - 36, theme.accent, 0.22).setOrigin(0));
    fx(scene.add.rectangle(T.x + 828, T.y + 18, 2, panelH - 36, theme.accent, 0.22).setOrigin(0));

    fx(scene.add.text(T.x + 22, T.y + 16, run.mission.title, {
      fontFamily: "Inter, Arial",
      fontSize: "21px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 268 },
    }));
    fx(scene.add.text(T.x + 22, T.y + 58, `${modeLabel} · Livello ${run.difficulty}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    fx(scene.add.text(T.x + 338, T.y + 16, "ORA", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const objectiveText = fx(scene.add.text(T.x + 338, T.y + 36, "", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 456 },
      lineSpacing: 2,
    }));
    const feedbackText = fx(scene.add.text(T.x + 338, T.y + 74, "", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 456 },
    }));

    fx(scene.add.text(T.x + 854, T.y + 16, "STATO", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const progressText = fx(scene.add.text(T.x + 854, T.y + 38, "", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 210 },
      lineSpacing: 2,
    }));
    fx(scene.add.text(T.x + 854, T.y + 74, "WASD/frecce/tap · E", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c7dce7",
      fontStyle: "bold",
    }));

    // Azioni compatte dentro la stessa plancia.
    const chargeStep = saveSystem.data.inventory.includes("nora-reserve") ? 1 : 2;
    const earnedCharges = Math.min(2, Math.floor(run.solvedPuzzleIds.length / chargeStep));
    const availableCharges = Math.max(0, earnedCharges - (run.noraChargesUsed ?? 0));
    const restartLabel = mode === "training" ? "Nuovo focus" : mode === "progressive" ? "Reset scalata" : "Ricomincia";
    fx(new Button(scene, T.x + 1148, T.y + 30, restartLabel, onRegenerate, { width: 160, height: 30, fill: 0x263743, fontSize: 12 }));
    fx(new Button(scene, T.x + 1148, T.y + 70, "Menu", onHub, { width: 160, height: 30, fill: 0x142736, fontSize: 13 }));
    if (onUseNoraCharge && mode !== "training" && availableCharges > 0) {
      fx(new Button(scene, T.x + 1012, T.y + 70, `NORA ×${availableCharges}`, onUseNoraCharge, { width: 92, height: 30, fill: 0x173b36, stroke: 0xf6c85f, fontSize: 11 }));
    }
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
    MissionProgressMap.draw({
      scene,
      rect: SceneChrome.layout.stage,
      hotspots: ordered,
      points,
      run,
      allSolved,
      theme,
      primaryPuzzle: path.primaryPuzzle,
    });
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
      SceneChrome.deviceHotspot(
        scene,
        point.x,
        point.y,
        proceduralHotspotKind(hotspot),
        hotspot.label,
        proceduralHotspotState(hotspot, run.solvedPuzzleIds, allSolved, run.failedPuzzleIds ?? []),
        () => onOpen(hotspot),
        hotspot.id === "door" ? 84 : isPrimary ? 78 : 70,
        { labelMode: "hover", statusMode: "hidden", visualMode: "glyph" },
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
      "Scegli una console nella zona d'azione, risolvi, poi torna alla stanza.",
    ];
  }

}
