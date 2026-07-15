import type Phaser from "phaser";
import type { EquationLabVisual, GeneratedMathPuzzle } from "../../../procedural/ProceduralTypes";

/**
 * Vista del Laboratorio Equazioni: pannelli illustrativi (bilancia, passi
 * inversi, forma normale, discriminante, parabola). Solo rendering, nessuno
 * stato: la scena orchestra gli stage e chiama `draw` con il visual corrente.
 */
export const EquationLabView = {
  draw(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    visual: EquationLabVisual,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    const lab = puzzle.equationLab;
    if (!lab) return;
    overlay.add(scene.add.rectangle(x, y, width, height, 0x06131c, 0.86).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.28));
    if (visual === "balance") {
      drawBalance(scene, overlay, lab.equation, x, y, width);
      return;
    }
    if (visual === "inverse-steps" || visual === "substitution") {
      drawSteps(scene, overlay, puzzle, visual, x, y, width);
      return;
    }
    if (visual === "parabola") {
      drawParabola(scene, overlay, puzzle, x, y, width, height);
      return;
    }
    drawQuadraticConcept(scene, overlay, puzzle, visual, x, y, width);
  },
};

function drawBalance(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  equation: string,
  x: number,
  y: number,
  width: number,
): void {
  const centerX = x + width / 2;
  const beamY = y + 116;
  const g = scene.add.graphics();
  g.lineStyle(7, 0xf6c85f, 0.82);
  g.lineBetween(centerX - 218, beamY, centerX + 218, beamY);
  g.lineStyle(4, 0x6be7d6, 0.72);
  g.lineBetween(centerX, beamY, centerX, beamY + 76);
  g.lineBetween(centerX - 46, beamY + 92, centerX + 46, beamY + 92);
  g.lineBetween(centerX - 170, beamY, centerX - 200, beamY + 54);
  g.lineBetween(centerX + 170, beamY, centerX + 200, beamY + 54);
  overlay.add(g);
  overlay.add(scene.add.rectangle(centerX - 200, beamY + 66, 250, 72, 0x102533, 0.94).setStrokeStyle(2, 0x6be7d6, 0.46));
  overlay.add(scene.add.rectangle(centerX + 200, beamY + 66, 250, 72, 0x102533, 0.94).setStrokeStyle(2, 0x6be7d6, 0.46));
  const sides = equation.split("=");
  overlay.add(scene.add.text(centerX - 200, beamY + 66, sides[0]?.trim() ?? equation, {
    fontFamily: "Georgia, serif", fontSize: "23px", color: "#f5fbff", fontStyle: "bold",
  }).setOrigin(0.5));
  overlay.add(scene.add.text(centerX + 200, beamY + 66, sides[1]?.trim() ?? "", {
    fontFamily: "Georgia, serif", fontSize: "23px", color: "#f5fbff", fontStyle: "bold",
  }).setOrigin(0.5));
  overlay.add(scene.add.text(centerX, y + 20, "Stessa operazione a sinistra e a destra", {
    fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold",
  }).setOrigin(0.5));
}

function drawSteps(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  puzzle: GeneratedMathPuzzle,
  visual: EquationLabVisual,
  x: number,
  y: number,
  width: number,
): void {
  const steps = puzzle.solutionSteps?.slice(0, 4) ?? [];
  const visible = visual === "substitution" ? [steps[steps.length - 1] ?? puzzle.equationLab?.verification ?? "Verifica"] : steps;
  const startY = visual === "substitution" ? y + 96 : y + 54;
  visible.forEach((step, index) => {
    const rowY = startY + index * 52;
    overlay.add(scene.add.rectangle(x + 38, rowY, width - 76, 40, index === visible.length - 1 ? 0x173b36 : 0x102533, 0.9)
      .setOrigin(0, 0.5)
      .setStrokeStyle(1, index === visible.length - 1 ? 0xf6c85f : 0x6be7d6, 0.36));
    overlay.add(scene.add.text(x + 58, rowY, step, {
      fontFamily: "Georgia, serif",
      fontSize: "16px",
      color: "#f5fbff",
      wordWrap: { width: width - 116 },
    }).setOrigin(0, 0.5));
    if (index < visible.length - 1) {
      overlay.add(scene.add.triangle(x + width / 2, rowY + 30, 0, -4, 9, 5, -9, 5, 0x6be7d6, 0.68));
    }
  });
  if (visual === "substitution") {
    overlay.add(scene.add.text(x + width / 2, y + 40, "Una soluzione è valida solo se rende veri entrambi i membri.", {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));
  }
}

function drawQuadraticConcept(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  puzzle: GeneratedMathPuzzle,
  visual: EquationLabVisual,
  x: number,
  y: number,
  width: number,
): void {
  const lab = puzzle.equationLab;
  if (!lab) return;
  const { a, b, c } = lab.coefficients;
  if (visual === "standard-form") {
    [
      { label: "a · x²", value: `${a}x²`, color: 0x6be7d6 },
      { label: "b · x", value: `${b}x`, color: 0xf6c85f },
      { label: "c", value: `${c}`, color: 0x9f8cff },
    ].forEach((item, index) => {
      const cx = x + 114 + index * 204;
      overlay.add(scene.add.rectangle(cx, y + 120, 164, 112, 0x102533, 0.92).setStrokeStyle(2, item.color, 0.62));
      overlay.add(scene.add.text(cx, y + 92, item.label, {
        fontFamily: "Inter, Arial", fontSize: "13px", color: "#c7dce7",
      }).setOrigin(0.5));
      overlay.add(scene.add.text(cx, y + 132, item.value, {
        fontFamily: "Georgia, serif", fontSize: "25px", color: "#f5fbff", fontStyle: "bold",
      }).setOrigin(0.5));
    });
    return;
  }
  if (visual === "discriminant") {
    const delta = lab.discriminant ?? 0;
    const parts = [`b²`, `− 4ac`, `Δ`];
    const values = [`(${b})² = ${b * b}`, `− 4·${a}·${c} = ${-4 * a * c}`, `${delta}`];
    parts.forEach((label, index) => {
      const cx = x + 112 + index * 206;
      overlay.add(scene.add.rectangle(cx, y + 118, 172, 108, index === 2 ? 0x173b36 : 0x102533, 0.92)
        .setStrokeStyle(2, index === 2 ? 0xf6c85f : 0x6be7d6, 0.58));
      overlay.add(scene.add.text(cx, y + 88, label, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
      overlay.add(scene.add.text(cx, y + 132, values[index], { fontFamily: "Georgia, serif", fontSize: index === 2 ? "28px" : "17px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    });
    return;
  }
  overlay.add(scene.add.text(x + width / 2, y + 52, "Formula risolutiva", {
    fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold",
  }).setOrigin(0.5));
  overlay.add(scene.add.text(x + width / 2, y + 116, "x =  (−b ± √Δ) / 2a", {
    fontFamily: "Georgia, serif", fontSize: "30px", color: "#f7d37a", fontStyle: "bold",
  }).setOrigin(0.5));
  overlay.add(scene.add.text(x + width / 2, y + 174, lab.roots.length > 0
    ? `Soluzioni: ${lab.roots.map((root, index) => `x${lab.roots.length > 1 ? index + 1 : ""} = ${root}`).join("    ")}`
    : "Δ < 0: la radice quadrata non è reale", {
    fontFamily: "Inter, Arial", fontSize: "17px", color: "#f5fbff", fontStyle: "bold",
  }).setOrigin(0.5));
}

function drawParabola(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  puzzle: GeneratedMathPuzzle,
  x: number,
  y: number,
  width: number,
  height: number,
): void {
  const lab = puzzle.equationLab;
  if (!lab) return;
  const { a, b, c } = lab.coefficients;
  const roots = lab.roots;
  const vertexX = -b / (2 * a);
  const minX = Math.floor(Math.min(-2, vertexX - 5, ...(roots.length ? roots.map((root) => root - 2) : [0])));
  const maxX = Math.ceil(Math.max(6, vertexX + 5, ...(roots.length ? roots.map((root) => root + 2) : [4])));
  const samples = Array.from({ length: 81 }, (_, index) => minX + ((maxX - minX) * index) / 80);
  const values = samples.map((value) => a * value * value + b * value + c);
  const maxAbsY = Math.max(8, ...values.map((value) => Math.abs(value)));
  const graphLeft = x + 52;
  const graphRight = x + width - 34;
  const graphTop = y + 28;
  const graphBottom = y + height - 38;
  const mapX = (value: number) => graphLeft + ((value - minX) / (maxX - minX)) * (graphRight - graphLeft);
  const mapY = (value: number) => (graphTop + graphBottom) / 2 - (value / maxAbsY) * ((graphBottom - graphTop) * 0.46);
  const g = scene.add.graphics();
  g.lineStyle(2, 0x6b7d84, 0.62);
  g.lineBetween(graphLeft, mapY(0), graphRight, mapY(0));
  if (minX <= 0 && maxX >= 0) g.lineBetween(mapX(0), graphTop, mapX(0), graphBottom);
  g.lineStyle(3, 0x6be7d6, 0.88);
  g.beginPath();
  samples.forEach((value, index) => {
    const px = mapX(value);
    const py = mapY(values[index]);
    if (index === 0) g.moveTo(px, py);
    else g.lineTo(px, py);
  });
  g.strokePath();
  overlay.add(g);
  roots.forEach((root) => {
    overlay.add(scene.add.circle(mapX(root), mapY(0), 8, 0xf6c85f, 1).setStrokeStyle(2, 0xf5fbff, 0.8));
    overlay.add(scene.add.text(mapX(root), mapY(0) + 16, `${root}`, {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", fontStyle: "bold",
    }).setOrigin(0.5, 0));
  });
  overlay.add(scene.add.text(x + 18, y + 12, roots.length === 2
    ? "Due intersezioni con l'asse x"
    : roots.length === 1
      ? "Una tangenza con l'asse x"
      : "Nessuna intersezione con l'asse x", {
    fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold",
  }));
}
