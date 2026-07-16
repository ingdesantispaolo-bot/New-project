import Phaser from "phaser";
import { formatDuration } from "../../../core/ProceduralScoring";
import type { EnglishMinigamePrompt } from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";
import { choiceTileFontSize, choiceTileLabel } from "../ChoiceTileText";
import type { EnglishMinigameSession } from "../ProceduralMissionDefs";
import {
  englishMinigameMethodText,
  englishSelectionInstruction,
  englishSelectionPanelTitle,
} from "../SprintPromptText";

type PanelDrawer = (x: number, y: number, width: number, height: number, title: string) => void;

type EnglishSprintConsoleOptions = {
  scene: Phaser.Scene;
  overlay: Phaser.GameObjects.Container;
  session: EnglishMinigameSession;
  prompt: EnglishMinigamePrompt;
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

type EnglishSprintConsoleResult = {
  timerText: Phaser.GameObjects.Text;
};

export function renderEnglishSprintConsole(options: EnglishSprintConsoleOptions): EnglishSprintConsoleResult {
  const { scene, overlay, session, prompt, showCoach, remainingMs, accuracy, scoringRule, addPanel } = options;
  const isOrdering = prompt.type === "sentence-build";

  addPanel(28, 112, 560, 432, showCoach ? "1 · Leggi il comando operativo" : "Comando");
  overlay.add(scene.add.text(60, 154, prompt.targetLabel, {
    fontFamily: "Inter, Arial",
    fontSize: "25px",
    color: "#f7d37a",
    fontStyle: "bold",
    shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
  }));
  drawEnglishSprintVisualizer(scene, overlay, prompt, 60, 204, 500, 226, showCoach);
  overlay.add(scene.add.text(60, showCoach ? 456 : 438, `Concept: ${prompt.concept}`, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#9ff5e9",
    fontStyle: "bold",
    wordWrap: { width: 488 },
  }));
  if (showCoach) {
    overlay.add(scene.add.text(60, 486, englishMinigameMethodText(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 492, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
  }

  addPanel(616, 112, 636, 432, showCoach ? englishSelectionPanelTitle(prompt) : prompt.targetLabel);
  if (showCoach) {
    overlay.add(scene.add.text(648, 154, englishSelectionInstruction(prompt), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 548 },
      lineSpacing: 4,
    }));
  }
  overlay.add(scene.add.text(648, showCoach ? (isOrdering ? 190 : 214) : 164, prompt.instruction, {
    fontFamily: "Inter, Arial",
    fontSize: prompt.instruction.length > 92 ? "17px" : "20px",
    color: "#f5fbff",
    fontStyle: "bold",
    wordWrap: { width: 548, useAdvancedWrap: true },
    lineSpacing: 5,
  }));
  overlay.add(scene.add.text(648, showCoach ? (isOrdering ? 224 : 290) : 246, prompt.glossary.slice(0, 4).map((entry) => `${entry.term}: ${entry.meaning}`).join("   "), {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#f7d37a",
    wordWrap: { width: 548, useAdvancedWrap: true },
  }));

  if (isOrdering) {
    renderEnglishOrderingTiles(options);
  } else {
    renderEnglishChoiceTiles(options);
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

function drawEnglishSprintVisualizer(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  prompt: EnglishMinigamePrompt,
  x: number,
  y: number,
  width: number,
  height: number,
  showCoach = true,
): void {
  const g = scene.add.graphics();
  g.fillStyle(0x07151d, 0.8);
  g.fillRoundedRect(x, y, width, height, 12);
  g.lineStyle(2, 0x6be7d6, 0.3);
  g.strokeRoundedRect(x, y, width, height, 12);
  overlay.add(g);

  const accent = prompt.type === "action-relay" ? 0x6be7d6
    : prompt.type === "sequence-switchboard" ? 0xf6c85f
      : prompt.type === "reading-detective" ? 0x70d68a
        : prompt.type === "error-diagnosis" ? 0xffb86b
          : prompt.type === "dialogue-response" ? 0x5ec8ff
            : 0x9f8cff;
  overlay.add(scene.add.rectangle(x + 24, y + 28, width - 48, 82, 0x102533, 0.84)
    .setOrigin(0)
    .setStrokeStyle(1, accent, 0.45));
  overlay.add(scene.add.text(x + 42, y + 46, prompt.context, {
    fontFamily: "Inter, Arial",
    fontSize: showCoach ? "14px" : "17px",
    color: "#f5fbff",
    wordWrap: { width: width - 84, useAdvancedWrap: true },
    lineSpacing: 4,
  }));
  if (prompt.dataPoints && prompt.dataPoints.length > 0) {
    prompt.dataPoints.slice(0, 4).forEach((point, index) => {
      const rowY = y + 128 + index * 24;
      overlay.add(scene.add.rectangle(x + 42, rowY - 3, width - 84, 20, 0x0c2531, 0.9).setOrigin(0)
        .setStrokeStyle(1, 0x6be7d6, 0.18));
      overlay.add(scene.add.text(x + 54, rowY, `${point.label}: ${point.value}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        wordWrap: { width: width - 110 },
      }));
    });
    return;
  }
  if (!showCoach) {
    return;
  }
  const visualLine = prompt.type === "action-relay"
    ? "VERB -> OBJECT -> EVIDENCE"
    : prompt.type === "grammar-fix"
      ? "SIGNAL WORD -> RULE -> FORM"
      : prompt.type === "sentence-build"
        ? "SUBJECT -> VERB -> REST"
        : prompt.type === "vocab-lab"
          ? "CONTEXT -> MEANING -> BEST WORD"
          : prompt.type === "translation-match"
            ? "ENGLISH TERM -> ITALIAN MEANING -> CHECK"
            : prompt.type === "reading-detective"
              ? "QUESTION -> ANSWER -> TEXT EVIDENCE"
              : prompt.type === "error-diagnosis"
                ? "WRONG SENTENCE -> REPAIR -> ERROR TYPE"
                : prompt.type === "dialogue-response"
                  ? "SITUATION -> PURPOSE -> POLITE RESPONSE"
                  : "TIME WORD -> FIRST EVENT -> SAFE ACTION";
  overlay.add(scene.add.text(x + 42, y + 138, visualLine, {
    fontFamily: "Inter, Arial",
    fontSize: "16px",
    color: prompt.type === "action-relay" ? "#9ff5e9"
      : (prompt.type === "grammar-fix" || prompt.type === "vocab-lab" || prompt.type === "translation-match" || prompt.type === "error-diagnosis") ? "#d8c9ff"
        : prompt.type === "reading-detective" ? "#9ff5a7"
          : prompt.type === "dialogue-response" ? "#a8ddff"
            : "#f7d37a",
    fontStyle: "bold",
    wordWrap: { width: width - 84 },
  }));
  overlay.add(scene.add.text(x + 42, y + 176, englishVisualizerHint(prompt), {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#9aaab0",
    wordWrap: { width: width - 84, useAdvancedWrap: true },
    lineSpacing: 3,
  }));
}

function englishVisualizerHint(prompt: EnglishMinigamePrompt): string {
  if (prompt.type === "action-relay") {
    return "Scegli il significato operativo e la prova nel testo: verbo, oggetto e limitatore devono combaciare.";
  }
  if (prompt.type === "grammar-fix") {
    return "Cerca il segnale grammaticale: tempo, quantità, comparativo, modale o preposizione.";
  }
  if (prompt.type === "sentence-build") {
    return "Costruisci una frase inglese stabile: ordine naturale, o ausiliare prima del soggetto nelle domande.";
  }
  if (prompt.type === "vocab-lab") {
    return "Non tradurre a orecchio: scegli la parola che rispetta contesto, registro e significato tecnico.";
  }
  if (prompt.type === "translation-match") {
    return "Riconosci la traduzione corretta: attenzione ai falsi amici e alle parole troppo simili.";
  }
  if (prompt.type === "reading-detective") {
    return "Scegli risposta e prova testuale: un'inferenza vale solo se il log la sostiene.";
  }
  if (prompt.type === "error-diagnosis") {
    return "Ripara la frase e nomina l'errore: forma corretta e diagnosi devono combaciare.";
  }
  if (prompt.type === "dialogue-response") {
    return "Scegli una risposta naturale per situazione, registro e scopo comunicativo.";
  }
  return "Before, after, until e unless cambiano quando un comando è permesso.";
}

function renderEnglishChoiceTiles(options: EnglishSprintConsoleOptions): void {
  const { scene, overlay, session, prompt } = options;
  const multiSelect = prompt.requiredSelectionCount > 1;
  const tileStartX = multiSelect ? 792 : 788;
  const tileStartY = 356;
  const tileWidth = multiSelect ? 274 : 226;
  const colSpacing = multiSelect ? 304 : 252;
  const rowSpacing = multiSelect ? 76 : 68;
  const tileHeight = multiSelect ? 64 : 52;
  prompt.tiles.forEach((tile, index) => {
    const selected = session.selectedIds.has(tile.id);
    const col = index % 2;
    const row = Math.floor(index / 2);
    const displayLabel = choiceTileLabel(tile.label, selected);
    overlay.add(new Button(scene, tileStartX + col * colSpacing, tileStartY + row * rowSpacing, displayLabel, () => options.onToggleTile(tile.id), {
      width: tileWidth,
      height: tileHeight,
      fontSize: choiceTileFontSize(tile.label, multiSelect ? 13 : 15),
      wordWrapWidth: tileWidth - 28,
      fill: selected ? 0x174d42 : 0x263743,
      stroke: selected ? 0xf7d37a : 0x6be7d6,
    }));
  });
}

function renderEnglishOrderingTiles(options: EnglishSprintConsoleOptions): void {
  const { scene, overlay, session, prompt } = options;
  const labelOf = (id: string): string => prompt.tiles.find((tile) => tile.id === id)?.label ?? "";
  const assembled = session.orderedSelection.map(labelOf).join(" ");
  overlay.add(scene.add.rectangle(648, 262, 572, 56, 0x07151d, 0.9).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.7));
  overlay.add(scene.add.text(664, 276, assembled.length > 0 ? assembled : "(tap the words below)", {
    fontFamily: "Inter, Arial",
    fontSize: "16px",
    color: assembled.length > 0 ? "#f5fbff" : "#7da2af",
    wordWrap: { width: 544 },
    lineSpacing: 3,
  }));

  let tileX = 648;
  let tileY = 338;
  prompt.tiles.forEach((tile) => {
    const placedIndex = session.orderedSelection.indexOf(tile.id);
    const placed = placedIndex >= 0;
    const labelText = placed ? `${placedIndex + 1}. ${tile.label}` : tile.label;
    const tileWidth = Math.max(56, labelText.length * 11 + 22);
    if (tileX + tileWidth > 1232) {
      tileX = 648;
      tileY += 50;
    }
    overlay.add(new Button(scene, tileX + tileWidth / 2, tileY + 20, labelText, () => options.onToggleOrderTile(tile.id), {
      width: tileWidth,
      height: 40,
      fontSize: 14,
      fill: placed ? 0x174d42 : 0x263743,
      stroke: placed ? 0xf7d37a : 0x6be7d6,
    }));
    tileX += tileWidth + 10;
  });

  overlay.add(new Button(scene, 1150, 520, "Clear", options.onClearOrder, {
    width: 110,
    height: 34,
    fontSize: 12,
    fill: 0x3a2525,
    stroke: 0xf6c85f,
  }));
}
