import type { GeneratedPhysicsPuzzle } from "../../../procedural/ProceduralTypes";

export const PhysicsConsole = {
  exerciseLabel(type: GeneratedPhysicsPuzzle["exerciseType"]): string {
    return {
      "motion-graph": "grafico del moto",
      "unit-check": "unita e misure",
      "force-diagram": "diagramma forze",
      "energy-transfer": "energia",
      "experiment-order": "metodo sperimentale",
      "density-pressure": "densita e pressione",
      "heat-temperature": "calore e temperatura",
      "wave-reading": "onde",
      "optics-ray": "ottica geometrica",
    }[type];
  },

  drawVisual(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedPhysicsPuzzle,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    overlay.add(scene.add.rectangle(x, y, width, height, 0x0b1f2b, 0.88).setOrigin(0).setStrokeStyle(1, 0x8fd3ff, 0.34));
    overlay.add(scene.add.text(x + 14, y + 12, puzzle.visual.title.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#8fd3ff",
      fontStyle: "bold",
    }));
    const g = scene.add.graphics();
    overlay.add(g);
    const cx = x + width / 2;
    const cy = y + height / 2 + 18;
    g.lineStyle(2, 0x8fd3ff, 0.56);

    if (puzzle.visual.kind === "motion-graph") {
      const left = x + 54;
      const bottom = y + height - 42;
      g.lineBetween(left, bottom, x + width - 36, bottom);
      g.lineBetween(left, bottom, left, y + 48);
      const values = puzzle.visual.values ?? [0, 1, 2, 3, 4];
      g.lineStyle(3, 0xf6c85f, 0.86);
      values.forEach((value, index) => {
        const px = left + index * ((width - 106) / Math.max(1, values.length - 1));
        const py = bottom - Math.min(height - 100, value * 11);
        g.fillStyle(0xf6c85f, 0.92);
        g.fillCircle(px, py, 5);
        if (index > 0) {
          const prevValue = values[index - 1];
          const prevX = left + (index - 1) * ((width - 106) / Math.max(1, values.length - 1));
          const prevY = bottom - Math.min(height - 100, prevValue * 11);
          g.lineBetween(prevX, prevY, px, py);
        }
      });
    } else if (puzzle.visual.kind === "force-diagram") {
      g.fillStyle(0x1b3d4e, 0.92);
      g.fillRoundedRect(cx - 44, cy - 26, 88, 52, 6);
      g.lineStyle(4, 0xf6c85f, 0.9);
      g.lineBetween(cx, cy - 30, cx, cy - 82);
      g.lineBetween(cx, cy + 30, cx, cy + 84);
      g.fillTriangle(cx, cy - 88, cx - 8, cy - 72, cx + 8, cy - 72);
      g.fillTriangle(cx, cy + 90, cx - 8, cy + 74, cx + 8, cy + 74);
    } else if (puzzle.visual.kind === "energy-flow" || puzzle.visual.kind === "experiment-steps") {
      puzzle.visual.labels.slice(0, 4).forEach((label, index, labels) => {
        const px = x + 62 + index * ((width - 124) / Math.max(1, labels.length - 1));
        g.fillStyle(index % 2 ? 0x153545 : 0x1f5a51, 0.9);
        g.fillRoundedRect(px - 44, cy - 30, 88, 60, 8);
        if (index < labels.length - 1) {
          g.lineStyle(2, 0xf6c85f, 0.72);
          g.lineBetween(px + 48, cy, px + ((width - 124) / Math.max(1, labels.length - 1)) - 48, cy);
        }
      });
    } else if (puzzle.visual.kind === "wave") {
      g.lineStyle(3, 0x8fd3ff, 0.9);
      const startX = x + 42;
      const midY = cy;
      let prevX = startX;
      let prevY = midY;
      for (let step = 0; step <= 96; step += 1) {
        const px = startX + step * ((width - 84) / 96);
        const py = midY + Math.sin(step / 7) * 42;
        if (step > 0) g.lineBetween(prevX, prevY, px, py);
        prevX = px;
        prevY = py;
      }
    } else if (puzzle.visual.kind === "ray") {
      g.lineStyle(3, 0xf6c85f, 0.9);
      g.lineBetween(x + 58, cy + 44, cx, cy);
      g.lineBetween(cx, cy, x + width - 58, cy - 44);
      g.lineStyle(2, 0x8fd3ff, 0.48);
      g.lineBetween(cx, cy - 76, cx, cy + 76);
      g.strokeCircle(cx, cy, 42);
    } else {
      const values = puzzle.visual.values ?? [1, 2, 3];
      values.slice(0, 4).forEach((value, index) => {
        const barH = Math.min(height - 92, Math.max(24, Number(value) * 18));
        const px = x + 78 + index * 82;
        g.fillStyle(index % 2 ? 0xf6c85f : 0x8fd3ff, 0.62);
        g.fillRoundedRect(px, y + height - 42 - barH, 44, barH, 5);
      });
    }

    puzzle.visual.labels.slice(0, 4).forEach((label, index) => {
      overlay.add(scene.add.text(x + 18 + index * 112, y + height - 24, label, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: index % 2 ? "#f7d37a" : "#d9eaf1",
        wordWrap: { width: 104 },
      }));
    });
    if (puzzle.visual.highlight) {
      overlay.add(scene.add.text(x + width - 154, y + 12, puzzle.visual.highlight, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: 136 },
      }));
    }
  },
};
