import Phaser from "phaser";
import type { GeneratedCodingPuzzle, GeneratedEnglishPuzzle } from "../../procedural/ProceduralTypes";
import type { ProceduralPuzzleId } from "./ProceduralMissionLayout";

export function exerciseBackgroundKey(kind: ProceduralPuzzleId | undefined): string {
  return {
    language: "mission-bg-italian",
    latin: "mission-bg-italian",
    circuit: "mission-bg-electronics",
    math: "mission-bg-math",
    english: "mission-bg-english",
    robot: "mission-bg-coding",
    coding: "mission-bg-coding",
    music: "mission-bg-music",
    physics: "mission-bg-synthesis",
  }[kind ?? "coding"];
}

export function englishChallengeLabel(type: GeneratedEnglishPuzzle["challengeType"]): string {
  return {
    command: "Comando",
    safety: "Sicurezza",
    sequence: "Sequenza",
    condition: "Condizione",
    "data-reading": "Dati",
    "procedure-debug": "Debug procedura",
    "vocabulary-in-context": "Lessico in contesto",
    "translation-recognition": "Traduzione lessicale",
    inference: "Inferenza",
  }[type ?? "command"];
}

export function codingChallengeLabel(type: GeneratedCodingPuzzle["challengeType"]): string {
  return {
    "trace-output": "tracing output",
    "variable-state": "stato variabili",
    "loop-count": "ciclo",
    "conditional-branch": "condizione",
    "boolean-logic": "logica booleana",
    "debug-line": "debug",
  }[type];
}

export function addMethodStrip(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  x: number,
  y: number,
  width: number,
  title: string,
  steps: string[],
): void {
  overlay.add(scene.add.rectangle(x, y, width, 52, 0x07151d, 0.82).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.32));
  overlay.add(scene.add.text(x + 12, y + 8, title, {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#f7d37a",
    fontStyle: "bold",
  }));
  overlay.add(scene.add.text(x + 12, y + 27, steps.join("  ->  "), {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#d9eaf1",
    wordWrap: { width: width - 24 },
  }));
}
