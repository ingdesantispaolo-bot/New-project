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
  "fraction-pie": "parti di un intero",
  "bar-chart": "grafico a barre",
  "number-line": "linea dei numeri",
  "area-shape": "base × altezza",
  proportion: "stessa proporzione",
  "dot-array": "gruppi uguali",
  triangle: "triangolo",
  "circle-radius": "raggio r",
  balance: "bilancia (=)",
  "line-graph": "grafico: la retta",
  "nested-shapes": "stessa forma, scala diversa",
  solid: "solido (volume)",
  "lines-cross": "due rette: soluzione",
  angle: "angolo",
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
    case "fraction-pie": {
      // Un cerchio diviso in spicchi, con una parte riempita (parti di un intero).
      const cx = X(110), cy = Y(80), r = R(48);
      g.fillStyle(gold, 0.8);
      g.slice(cx, cy, r, Phaser.Math.DegToRad(-90), Phaser.Math.DegToRad(180), true);
      g.fillPath();
      g.lineStyle(2, teal, 0.9).strokeCircle(cx, cy, r);
      g.lineBetween(cx, cy, cx, cy - r);
      g.lineBetween(cx, cy, cx + r, cy);
      g.lineBetween(cx, cy, cx, cy + r);
      g.lineBetween(cx, cy, cx - r, cy);
      break;
    }
    case "bar-chart": {
      // Barre verticali su una base (grafico a barre).
      g.lineStyle(1, teal, 0.5).lineBetween(X(38), Y(124), X(190), Y(124));
      const heights = [42, 72, 54, 90, 62];
      heights.forEach((hh, i) => {
        g.fillStyle(i % 2 === 0 ? gold : cyan, 0.85);
        g.fillRect(X(50 + i * 28), Y(124) - R(hh), R(18), R(hh));
      });
      break;
    }
    case "number-line": {
      // Retta con tacche e un punto marcato (linea dei numeri).
      g.lineStyle(2, teal, 0.85).lineBetween(X(28), Y(80), X(192), Y(80));
      for (let i = 0; i <= 8; i += 1) {
        const tx = X(28 + i * 20.5);
        const tall = i === 4;
        g.lineStyle(tall ? 3 : 2, tall ? gold : teal, 0.85);
        g.lineBetween(tx, Y(tall ? 68 : 74), tx, Y(tall ? 92 : 86));
      }
      g.fillStyle(gold, 1).fillCircle(X(28 + 6 * 20.5), Y(80), R(7));
      break;
    }
    case "area-shape": {
      // Rettangolo con base e altezza evidenziate (base × altezza).
      g.fillStyle(gold, 0.16).fillRect(X(54), Y(46), R(112), R(64));
      g.lineStyle(2, teal, 0.9).strokeRect(X(54), Y(46), R(112), R(64));
      g.lineStyle(3, amber, 0.9);
      g.lineBetween(X(54), Y(124), X(166), Y(124));
      g.lineBetween(X(40), Y(46), X(40), Y(110));
      break;
    }
    case "proportion": {
      // Due barre con lo stesso rapporto (2:3 e 4:6): la proporzione si conserva.
      const seg = R(15);
      for (let i = 0; i < 2; i += 1) { g.fillStyle(gold, 0.85); g.fillRect(X(38) + i * seg, Y(48), seg - 3, R(18)); }
      for (let i = 0; i < 3; i += 1) { g.fillStyle(cyan, 0.7); g.fillRect(X(38) + (2 + i) * seg, Y(48), seg - 3, R(18)); }
      const seg2 = R(9.5);
      for (let i = 0; i < 4; i += 1) { g.fillStyle(gold, 0.85); g.fillRect(X(38) + i * seg2, Y(96), seg2 - 2, R(18)); }
      for (let i = 0; i < 6; i += 1) { g.fillStyle(cyan, 0.7); g.fillRect(X(38) + (4 + i) * seg2, Y(96), seg2 - 2, R(18)); }
      break;
    }
    case "dot-array": {
      // Griglia di pallini: gruppi uguali (divisibilità), quadrato (potenze/radice).
      const cols = 4, rows = 3, gap = R(30);
      const sx = X(72), sy = Y(48);
      for (let row = 0; row < rows; row += 1) {
        for (let col = 0; col < cols; col += 1) {
          g.fillStyle(row === rows - 1 ? gold : cyan, 0.85);
          g.fillCircle(sx + col * gap, sy + row * gap, R(8));
        }
      }
      break;
    }
    case "triangle": {
      // Triangolo rettangolo con base, altezza e angolo retto marcato.
      g.fillStyle(gold, 0.16).fillTriangle(X(52), Y(120), X(52), Y(48), X(172), Y(120));
      g.lineStyle(2, teal, 0.9).strokeTriangle(X(52), Y(120), X(52), Y(48), X(172), Y(120));
      g.lineStyle(2, amber, 0.9).strokeRect(X(52), Y(106), R(14), R(14));
      break;
    }
    case "circle-radius": {
      // Cerchio con centro e raggio.
      const cx = X(110), cy = Y(80), r = R(48);
      g.lineStyle(2, teal, 0.9).strokeCircle(cx, cy, r);
      g.fillStyle(gold, 1).fillCircle(cx, cy, R(4));
      g.lineStyle(2, amber, 0.95).lineBetween(cx, cy, cx + r, cy);
      break;
    }
    case "balance": {
      // Bilancia in equilibrio: i due lati valgono uguale (equazioni).
      g.lineStyle(3, gold, 0.92).lineBetween(X(46), Y(60), X(174), Y(60));
      g.lineStyle(2, teal, 0.85).lineBetween(X(110), Y(60), X(110), Y(112));
      g.fillStyle(teal, 0.8).fillTriangle(X(96), Y(122), X(124), Y(122), X(110), Y(104));
      g.lineStyle(2, cyan, 0.85);
      g.lineBetween(X(60), Y(60), X(60), Y(82));
      g.lineBetween(X(160), Y(60), X(160), Y(82));
      g.strokeRect(X(44), Y(82), R(32), R(13));
      g.strokeRect(X(144), Y(82), R(32), R(13));
      break;
    }
    case "line-graph": {
      // Assi cartesiani con una RETTA (per le funzioni lineari).
      g.lineStyle(1, teal, 0.5);
      g.lineBetween(X(40), Y(122), X(196), Y(122));
      g.lineBetween(X(52), Y(28), X(52), Y(134));
      g.lineStyle(2, gold, 0.95).lineBetween(X(56), Y(116), X(188), Y(40));
      break;
    }
    case "nested-shapes": {
      // Due figure simili: stessa forma, scala diversa (similitudine).
      g.lineStyle(2, cyan, 0.8).strokeRect(X(38), Y(74), R(52), R(36));
      g.lineStyle(2, gold, 0.9).strokeRect(X(104), Y(44), R(84), R(58));
      break;
    }
    case "solid": {
      // Cubo in proiezione: un solido occupa spazio (volume).
      g.lineStyle(2, teal, 0.9).strokeRect(X(56), Y(62), R(72), R(72));
      g.lineStyle(2, cyan, 0.7).strokeRect(X(88), Y(38), R(72), R(72));
      g.lineStyle(2, teal, 0.7);
      g.lineBetween(X(56), Y(62), X(88), Y(38));
      g.lineBetween(X(128), Y(62), X(160), Y(38));
      g.lineBetween(X(56), Y(134), X(88), Y(110));
      g.lineBetween(X(128), Y(134), X(160), Y(110));
      break;
    }
    case "lines-cross": {
      // Due rette che si incrociano: la soluzione di un sistema.
      g.lineStyle(1, teal, 0.5);
      g.lineBetween(X(40), Y(122), X(196), Y(122));
      g.lineBetween(X(52), Y(28), X(52), Y(134));
      g.lineStyle(2, gold, 0.9).lineBetween(X(56), Y(118), X(188), Y(42));
      g.lineStyle(2, amber, 0.85).lineBetween(X(56), Y(42), X(188), Y(118));
      break;
    }
    case "angle": {
      // Due semirette da un vertice con l'arco dell'angolo.
      const vx = X(46), vy = Y(120);
      g.lineStyle(2, teal, 0.9);
      g.lineBetween(vx, vy, X(190), vy);
      g.lineBetween(vx, vy, X(150), Y(46));
      g.lineStyle(2, gold, 0.95);
      g.beginPath();
      g.arc(vx, vy, R(36), Phaser.Math.DegToRad(-34), 0, false);
      g.strokePath();
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
