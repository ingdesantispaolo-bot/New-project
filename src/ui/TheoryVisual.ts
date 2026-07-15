import Phaser from "phaser";
import type { TheoryTopic, TheoryVisualKind } from "../data/theoryCatalog";

/** Human labels for each schematic, shown under the illustration. */
const VISUAL_LABELS: Record<TheoryVisualKind, string> = {
  formula: "grafico",
  timeline: "linea del tempo",
  "text-map": "frase evidenziata",
  circuit: "circuito",
  "code-trace": "tracing",
  grid: "griglia",
  staff: "pentagramma",
  "physics-diagram": "schema fisico",
  "latin-table": "tabella",
};

type VisualOptions = {
  width?: number;
  height?: number;
  /** Show the small caption under the schematic (default true). */
  label?: boolean;
};

/**
 * Renders a compact schematic illustration for a theory topic's `visualKind`
 * using pure Phaser graphics — no static images. Shared by the mission "Spiega
 * con NORA" panel, the study Atlante and NORA's room, so the same concept always
 * looks the same. Returns the created objects so callers can add them to a
 * container or route them to a UI camera. Draws inside the box (x, y, w, h);
 * coordinates scale from a 220x154 baseline so any size stays proportioned.
 */
export function drawTheoryVisual(
  scene: Phaser.Scene,
  topic: TheoryTopic,
  x: number,
  y: number,
  opts: VisualOptions = {},
): Phaser.GameObjects.GameObject[] {
  const w = opts.width ?? 220;
  const h = opts.height ?? 154;
  const fx = w / 220;
  const fy = h / 154;
  const X = (a: number): number => x + a * fx;
  const Y = (b: number): number => y + b * fy;
  const R = (r: number): number => r * Math.min(fx, fy);

  const teal = 0x6be7d6;
  const gold = 0xf6c85f;
  const cyan = 0x9ff5e9;
  const amber = 0xffb36b;

  const objects: Phaser.GameObjects.GameObject[] = [];
  objects.push(scene.add.rectangle(x, y, w, h, 0x02090e, 0.88).setOrigin(0).setStrokeStyle(1, gold, 0.34));

  const g = scene.add.graphics();
  g.lineStyle(2, teal, 0.88);

  switch (topic.visualKind) {
    case "circuit":
      g.strokeRoundedRect(X(32), Y(44), R(156), R(66), R(10));
      g.fillStyle(gold, 1).fillCircle(X(54), Y(77), R(10));
      g.fillStyle(cyan, 1).fillCircle(X(166), Y(77), R(10));
      g.lineBetween(X(96), Y(44), X(124), Y(28));
      g.lineBetween(X(124), Y(28), X(150), Y(44));
      break;
    case "code-trace":
      for (let i = 0; i < 4; i += 1) g.strokeRect(X(34), Y(30 + i * 26), R(152), R(18));
      g.lineBetween(X(74), Y(39), X(162), Y(39));
      g.lineBetween(X(74), Y(65), X(138), Y(65));
      g.lineBetween(X(74), Y(91), X(170), Y(91));
      g.lineBetween(X(74), Y(117), X(118), Y(117));
      break;
    case "staff":
      for (let i = 0; i < 5; i += 1) g.lineBetween(X(30), Y(42 + i * 18), X(190), Y(42 + i * 18));
      g.fillStyle(gold, 1).fillEllipse(X(116), Y(78), R(25), R(17));
      g.lineBetween(X(128), Y(76), X(128), Y(36));
      break;
    case "grid":
      for (let i = 0; i <= 4; i += 1) {
        g.lineBetween(X(44 + i * 30), Y(26), X(44 + i * 30), Y(146));
        g.lineBetween(X(44), Y(26 + i * 30), X(164), Y(26 + i * 30));
      }
      g.fillStyle(gold, 1).fillTriangle(X(82), Y(82), X(62), Y(94), X(62), Y(70));
      break;
    case "physics-diagram":
      g.lineBetween(X(36), Y(124), X(186), Y(124));
      g.lineBetween(X(46), Y(124), X(170), Y(42));
      g.fillStyle(gold, 1).fillCircle(X(170), Y(42), R(8));
      g.lineStyle(2, amber, 0.9).lineBetween(X(170), Y(42), X(198), Y(42));
      break;
    case "latin-table":
      for (let i = 0; i <= 3; i += 1) g.lineBetween(X(38), Y(36 + i * 30), X(182), Y(36 + i * 30));
      for (let i = 0; i <= 2; i += 1) g.lineBetween(X(38 + i * 72), Y(36), X(38 + i * 72), Y(126));
      g.fillStyle(gold, 0.28).fillRect(X(39), Y(37), R(70), R(28));
      break;
    case "timeline":
      g.lineBetween(X(38), Y(80), X(184), Y(80));
      g.fillStyle(gold, 1).fillCircle(X(62), Y(80), R(7));
      g.fillCircle(X(112), Y(80), R(7));
      g.fillCircle(X(164), Y(80), R(7));
      g.lineStyle(2, amber, 0.85);
      g.lineBetween(X(62), Y(80), X(62), Y(62));
      g.lineBetween(X(112), Y(80), X(112), Y(62));
      break;
    case "text-map": {
      // A sentence with one highlighted segment (frase evidenziata).
      const widths = [150, 168, 112];
      for (let i = 0; i < 3; i += 1) {
        g.fillStyle(cyan, 0.5).fillRoundedRect(X(30), Y(44 + i * 26), R(widths[i]), R(10), R(4));
      }
      g.fillStyle(gold, 0.32).fillRoundedRect(X(72), Y(40), R(56), R(18), R(4));
      g.lineStyle(2, gold, 0.9).strokeRoundedRect(X(72), Y(40), R(56), R(18), R(4));
      break;
    }
    case "formula":
    default: {
      // A cartesian graph with a curve (grafico).
      g.lineStyle(1, teal, 0.5);
      g.lineBetween(X(40), Y(122), X(196), Y(122));
      g.lineBetween(X(52), Y(28), X(52), Y(134));
      const points: Phaser.Math.Vector2[] = [];
      for (let i = 0; i <= 12; i += 1) {
        const t = i / 12;
        const px = 52 + t * 140;
        const py = 118 - 90 * (0.15 + 0.85 * (t - 0.5) * (t - 0.5) * 3.4);
        points.push(new Phaser.Math.Vector2(X(px), Y(Math.max(30, py))));
      }
      g.lineStyle(2, gold, 0.95).strokePoints(points, false, false);
      break;
    }
  }
  objects.push(g);

  if (opts.label !== false) {
    objects.push(scene.add.text(X(14), Y(h / fy - 20), VISUAL_LABELS[topic.visualKind], {
      fontFamily: "Inter, Arial",
      fontSize: `${Math.round(11 * Math.min(fx, fy))}px`,
      color: "#9aaab0",
      wordWrap: { width: w - 24 },
    }));
  }

  return objects;
}
