import Phaser from "phaser";
import { formatDuration } from "../../../core/ProceduralScoring";
import type { CodingMinigamePrompt } from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";
import { choiceTileFontSize, choiceTileLabel } from "../ChoiceTileText";
import type { CodingMinigameSession } from "../ProceduralMissionDefs";
import {
  codingMinigameMethodText,
  codingSelectionInstruction,
  codingSelectionPanelTitle,
} from "../SprintPromptText";

type PanelDrawer = (x: number, y: number, width: number, height: number, title: string) => void;

type CodingSprintConsoleOptions = {
  scene: Phaser.Scene;
  overlay: Phaser.GameObjects.Container;
  session: CodingMinigameSession;
  prompt: CodingMinigamePrompt;
  showCoach: boolean;
  remainingMs: number;
  accuracy: number;
  scoringRule: string;
  addPanel: PanelDrawer;
  onToggleTile: (tileId: string) => void;
  onToggleOrderTile: (tileId: string) => void;
  onClearOrder: () => void;
  onConfirm: () => void;
  onHint: () => void;
};

type CodingSprintConsoleResult = {
  timerText: Phaser.GameObjects.Text;
};

export function renderCodingSprintConsole(options: CodingSprintConsoleOptions): CodingSprintConsoleResult {
  const { scene, overlay, session, prompt, showCoach, remainingMs, accuracy, scoringRule, addPanel } = options;
  const isOrdering = prompt.type === "algorithm-order";

  addPanel(28, 112, 582, 432, showCoach ? "1 · Leggi e simula il codice" : "Codice");
  overlay.add(scene.add.text(60, 154, prompt.targetLabel, {
    fontFamily: "Inter, Arial",
    fontSize: "25px",
    color: "#f7d37a",
    fontStyle: "bold",
    shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
  }));
  drawCodingCodePanel(scene, overlay, prompt, 60, 206, 522, 228);
  overlay.add(scene.add.text(60, 458, `Concetto: ${prompt.concept}`, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#9ff5e9",
    fontStyle: "bold",
    wordWrap: { width: 500 },
  }));
  if (showCoach) {
    overlay.add(scene.add.text(60, 488, codingMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 506, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
  }

  addPanel(636, 112, 616, 432, showCoach ? codingSelectionPanelTitle(prompt) : "Scelte");
  if (showCoach) {
    overlay.add(scene.add.text(668, 154, codingSelectionInstruction(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 532 },
      lineSpacing: 4,
    }));
  }
  overlay.add(scene.add.text(668, showCoach ? (isOrdering ? 188 : 210) : 164, prompt.question, {
    fontFamily: "Inter, Arial",
    fontSize: prompt.question.length > 92 ? "16px" : "18px",
    color: "#f5fbff",
    fontStyle: "bold",
    wordWrap: { width: 532, useAdvancedWrap: true },
    lineSpacing: 5,
  }));
  if (isOrdering) {
    renderCodingOrderingTiles(options);
  } else {
    renderCodingChoiceTiles(options);
  }

  addPanel(28, 558, 1224, 130, showCoach ? "3 · Conferma e controlla l'esito" : "Esito");
  const timerText = scene.add.text(64, 604, `Tempo: ${formatDuration(remainingMs)}`, {
    fontFamily: "Inter, Arial",
    fontSize: "24px",
    color: remainingMs <= 10_000 ? "#ff8f8f" : "#f7d37a",
    fontStyle: "bold",
  });
  overlay.add(timerText);
  overlay.add(scene.add.text(260, 592, `Serie: ${session.streak}    ·    Punti: ${session.netScore}    ·    Precisione: ${accuracy}%`, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#d9eaf1",
    wordWrap: { width: 640 },
    lineSpacing: 4,
  }));
  if (showCoach || session.feedback) {
    overlay.add(scene.add.text(260, 636, session.feedback || scoringRule, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: session.feedback ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 390, useAdvancedWrap: true },
    }));
  }
  overlay.add(new Button(scene, 1080, 640, "Conferma", options.onConfirm, {
    width: 220,
    height: 44,
    fontSize: 14,
    fill: 0x173b36,
  }));
  overlay.add(new Button(scene, 820, 640, "Indizio", options.onHint, {
    width: 180,
    height: 44,
    fontSize: 13,
    fill: 0x263743,
  }));

  return { timerText };
}

function drawCodingCodePanel(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  prompt: CodingMinigamePrompt,
  x: number,
  y: number,
  width: number,
  height: number,
): void {
  const g = scene.add.graphics();
  g.fillStyle(0x07151d, 0.84);
  g.fillRoundedRect(x, y, width, height, 12);
  g.lineStyle(2, 0x6be7d6, 0.3);
  g.strokeRoundedRect(x, y, width, height, 12);
  overlay.add(g);
  overlay.add(scene.add.text(x + 24, y + 18, prompt.title, {
    fontFamily: "Inter, Arial",
    fontSize: "14px",
    color: "#9ff5e9",
    fontStyle: "bold",
  }));
  const codeY = y + 52;
  overlay.add(scene.add.rectangle(x + 24, codeY, width - 48, Math.min(142, height - 82), 0x0b1f2b, 0.94).setOrigin(0)
    .setStrokeStyle(1, 0x315766, 0.58));
  prompt.codeLines.slice(0, 6).forEach((line, index) => {
    const rowY = codeY + 14 + index * 22;
    overlay.add(scene.add.text(x + 40, rowY, String(index + 1).padStart(2, "0"), {
      fontFamily: "Consolas, 'Courier New', monospace",
      fontSize: "11px",
      color: "#6f8793",
    }));
    overlay.add(scene.add.text(x + 76, rowY, line, {
      fontFamily: "Consolas, 'Courier New', monospace",
      fontSize: "13px",
      color: line.includes("?") ? "#f7d37a" : "#f5fbff",
      wordWrap: { width: width - 116 },
    }));
  });
}

function renderCodingChoiceTiles(options: CodingSprintConsoleOptions): void {
  const { scene, overlay, prompt, session, showCoach } = options;
  if (showCoach) {
    overlay.add(scene.add.text(668, 288, prompt.methodSteps.join("  ->  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 532, useAdvancedWrap: true },
    }));
  }
  const tileStartX = 802;
  const tileStartY = 356;
  prompt.tiles.forEach((tile, index) => {
    const selected = session.selectedIds.has(tile.id);
    const col = index % 2;
    const row = Math.floor(index / 2);
    overlay.add(new Button(scene, tileStartX + col * 244, tileStartY + row * 68, choiceTileLabel(tile.label, selected), () => options.onToggleTile(tile.id), {
      width: 218,
      height: 52,
      fontSize: choiceTileFontSize(tile.label, 15),
      wordWrapWidth: 198,
      fill: selected ? 0x174d42 : 0x263743,
      stroke: selected ? 0xf7d37a : 0x6be7d6,
    }));
  });
}

function renderCodingOrderingTiles(options: CodingSprintConsoleOptions): void {
  const { scene, overlay, prompt, session } = options;
  const labelOf = (id: string): string => prompt.tiles.find((tile) => tile.id === id)?.label ?? "";
  const assembled = session.orderedSelection.map((id, position) => `${position + 1}. ${labelOf(id)}`).join("\n");
  overlay.add(scene.add.rectangle(668, 232, 556, 150, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
  overlay.add(scene.add.text(684, 244, assembled.length > 0 ? assembled : "(tocca i passi qui sotto)", {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
    wordWrap: { width: 528 },
    lineSpacing: 4,
  }));

  let tileY = 398;
  prompt.tiles.forEach((tile) => {
    const placedIndex = session.orderedSelection.indexOf(tile.id);
    const placed = placedIndex >= 0;
    const labelText = placed ? `${placedIndex + 1}. ${tile.label}` : tile.label;
    overlay.add(new Button(scene, 914, tileY, labelText, () => options.onToggleOrderTile(tile.id), {
      width: 556,
      height: 32,
      fontSize: 12,
      wordWrapWidth: 528,
      fill: placed ? 0x174d42 : 0x263743,
      stroke: placed ? 0xf7d37a : 0x6be7d6,
    }));
    tileY += 38;
  });

  overlay.add(new Button(scene, 1150, 520, "Svuota", options.onClearOrder, {
    width: 110,
    height: 30,
    fontSize: 12,
    fill: 0x3a2525,
    stroke: 0xf6c85f,
  }));
}
