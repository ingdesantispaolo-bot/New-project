import type Phaser from "phaser";
import type { GeneratedGraphWorkshop, GraphParameterKey } from "../../../procedural/ProceduralTypes";

type GraphValues = Partial<Record<GraphParameterKey, number>>;

/**
 * Vista e helper puri dell'Officina dei Grafici: piano cartesiano, curve,
 * formule e diagnosi testuali. Lo stato (valori correnti, mosse, letture)
 * resta nella scena; qui non c'è nulla di mutabile.
 */
export const GraphWorkshopView = {
  /** Numero minimo di mosse per portare tutti i parametri al bersaglio. */
  par(workshop: GeneratedGraphWorkshop): number {
    return workshop.parameters.reduce(
      (total, parameter) => {
        const raw = Math.abs(parameter.target - parameter.initial) / parameter.step;
        const skipsZero = parameter.key === "a" && parameter.target * parameter.initial < 0;
        return total + raw - (skipsZero ? 1 : 0);
      },
      0,
    );
  },

  formula(workshop: GeneratedGraphWorkshop, values: GraphValues): string {
    if (workshop.functionKind === "linear") {
      const m = values.m ?? 0;
      const q = values.q ?? 0;
      if (m === 0) return `y = ${q}`;
      const slope = m === 0 ? "0" : m === 1 ? "x" : m === -1 ? "−x" : `${m}x`;
      const intercept = q === 0 ? "" : q > 0 ? ` + ${q}` : ` − ${Math.abs(q)}`;
      return `y = ${slope}${intercept}`;
    }
    const a = values.a ?? 1;
    const h = values.h ?? 0;
    const k = values.k ?? 0;
    const leading = a === 1 ? "" : a === -1 ? "−" : `${a}`;
    const horizontal = h === 0 ? "x" : h > 0 ? `(x − ${h})` : `(x + ${Math.abs(h)})`;
    const vertical = k === 0 ? "" : k > 0 ? ` + ${k}` : ` − ${Math.abs(k)}`;
    return `y = ${leading}${horizontal}²${vertical}`;
  },

  properties(workshop: GeneratedGraphWorkshop, values: GraphValues): string {
    if (workshop.functionKind === "linear") {
      const m = values.m ?? 0;
      const q = values.q ?? 0;
      return `Lettura attuale\n• retta ${m > 0 ? "crescente" : m < 0 ? "decrescente" : "orizzontale"}\n• intercetta asse y: (0, ${q})`;
    }
    const a = values.a ?? 1;
    const h = values.h ?? 0;
    const k = values.k ?? 0;
    const discriminantLike = -k / a;
    const roots = discriminantLike >= 0 ? Math.sqrt(discriminantLike) : undefined;
    const rootText = roots === undefined
      ? "nessuna intersezione reale"
      : Number.isInteger(roots)
        ? `radici: ${h - roots}, ${h + roots}`
        : "intersezioni non intere";
    return `Lettura attuale\n• apertura ${a > 0 ? "verso l'alto" : "verso il basso"}\n• vertice V(${h}, ${k})\n• ${rootText}`;
  },

  /** The reading method to derive the parameters, so the task teaches reading. */
  readingMethod(workshop: GeneratedGraphWorkshop): string {
    if (workshop.mode === "beacon-line") {
      const yAxisBeacon = workshop.targetPoints.find((point) => point.x === 0);
      return yAxisBeacon
        ? `Leggi la retta dai beacon, non a tentativi: ${yAxisBeacon.label} sta sull'asse y, quindi q è la sua y; poi calcola m = dy / dx tra i due beacon.`
        : "Leggi la retta dai beacon, non a tentativi: calcola prima m = dy / dx tra i due beacon; poi usa un punto nella formula q = y - m*x.";
    }
    return workshop.principle;
  },

  diagnosis(workshop: GeneratedGraphWorkshop, values: GraphValues): string {
    const wrong = workshop.parameters.filter((parameter) => values[parameter.key] !== parameter.target);
    if (workshop.functionKind === "linear") {
      const slopeWrong = wrong.some((parameter) => parameter.key === "m");
      const interceptWrong = wrong.some((parameter) => parameter.key === "q");
      if (slopeWrong && interceptWrong) return "Rileggi i beacon dall'inizio: prima ricava m (quanto sale la y ÷ quanto avanza la x tra i due punti), poi q (la y del punto dove x = 0).";
      if (slopeWrong) return "L'intercetta va bene, ma la pendenza no: conta di quanto sale la y quando la x avanza di 1 passando da un beacon all'altro — quel rapporto è m.";
      if (interceptWrong) return "La pendenza è giusta, ma l'altezza no: q è la y del beacon che sta sull'asse y (dove x = 0). Leggila e imposta q.";
    }
    const aWrong = wrong.some((parameter) => parameter.key === "a");
    const hWrong = wrong.some((parameter) => parameter.key === "h");
    const kWrong = wrong.some((parameter) => parameter.key === "k");
    if (hWrong) return "L'asse di simmetria non passa ancora per il punto medio richiesto. Regola h prima degli altri parametri.";
    if (kWrong) return "La posizione orizzontale è coerente, ma il vertice è alla quota sbagliata. Regola k.";
    if (aWrong) return "Vertice e asse sono corretti, ma verso o apertura non coincidono. Regola a.";
    return "Il grafico è vicino al bersaglio, ma non soddisfa ancora tutti i vincoli esatti.";
  },

  evaluate(workshop: GeneratedGraphWorkshop, values: GraphValues, x: number): number {
    if (workshop.functionKind === "linear") {
      return (values.m ?? 0) * x + (values.q ?? 0);
    }
    return (values.a ?? 1) * (x - (values.h ?? 0)) ** 2 + (values.k ?? 0);
  },

  drawCartesian(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    workshop: GeneratedGraphWorkshop,
    values: GraphValues,
    x: number,
    y: number,
    width: number,
    height: number,
    showActiveCurve = true,
  ): void {
    overlay.add(scene.add.rectangle(x, y, width, height, 0x02090e, 0.94).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.34));
    const [minX, maxX] = workshop.xRange;
    const [minY, maxY] = workshop.yRange;
    const left = x + 48;
    const right = x + width - 24;
    const top = y + 24;
    const bottom = y + height - 42;
    const mapX = (value: number) => left + ((value - minX) / (maxX - minX)) * (right - left);
    const mapY = (value: number) => bottom - ((value - minY) / (maxY - minY)) * (bottom - top);
    const g = scene.add.graphics();

    for (let gx = Math.ceil(minX); gx <= Math.floor(maxX); gx += 1) {
      const px = mapX(gx);
      g.lineStyle(gx === 0 ? 3 : 1, gx === 0 ? 0x9ff5e9 : 0x315766, gx === 0 ? 0.68 : 0.28);
      g.lineBetween(px, top, px, bottom);
      if (gx !== 0 && gx % 2 === 0) {
        overlay.add(scene.add.text(px, bottom + 10, `${gx}`, {
          fontFamily: "Inter, Arial", fontSize: "9px", color: "#78909b",
        }).setOrigin(0.5));
      }
    }
    for (let gy = Math.ceil(minY); gy <= Math.floor(maxY); gy += 1) {
      const py = mapY(gy);
      g.lineStyle(gy === 0 ? 3 : 1, gy === 0 ? 0x9ff5e9 : 0x315766, gy === 0 ? 0.68 : 0.28);
      g.lineBetween(left, py, right, py);
      if (gy !== 0 && gy % 2 === 0) {
        overlay.add(scene.add.text(left - 10, py, `${gy}`, {
          fontFamily: "Inter, Arial", fontSize: "9px", color: "#78909b",
        }).setOrigin(1, 0.5));
      }
    }
    overlay.add(g);
    overlay.add(scene.add.text(right + 8, mapY(0), "x", {
      fontFamily: "Georgia, serif", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0, 0.5));
    overlay.add(scene.add.text(mapX(0), top - 14, "y", {
      fontFamily: "Georgia, serif", fontSize: "14px", color: "#9ff5e9", fontStyle: "bold",
    }).setOrigin(0.5));

    const targetValues = Object.fromEntries(
      workshop.parameters.map((parameter) => [parameter.key, parameter.target]),
    ) as GraphValues;
    if (workshop.showTargetCurve) {
      drawCurve(scene, overlay, workshop, targetValues, mapX, mapY, minX, maxX, minY, maxY, 0xf6c85f, 0.52, true);
    }
    if (showActiveCurve) {
      drawCurve(scene, overlay, workshop, values, mapX, mapY, minX, maxX, minY, maxY, 0x6be7d6, 0.96, false);
    }

    // Beacons stay a neutral target colour (never turn green "on hit"): a live
    // success signal would let the student align by trial-and-error. Their
    // coordinates are shown so m and q can be READ, then verified on certify.
    workshop.targetPoints.forEach((point) => {
      const color = 0xf6c85f;
      overlay.add(scene.add.circle(mapX(point.x), mapY(point.y), 16, color, 0.1).setStrokeStyle(3, color, 0.92));
      overlay.add(scene.add.circle(mapX(point.x), mapY(point.y), 5, color, 1));
      overlay.add(scene.add.text(mapX(point.x) + 14, mapY(point.y) - 22, `${point.label}(${point.x}, ${point.y})`, {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", fontStyle: "bold",
      }));
    });

    if (workshop.functionKind === "quadratic") {
      const h = values.h ?? 0;
      const k = values.k ?? 0;
      if (h >= minX && h <= maxX && k >= minY && k <= maxY) {
        overlay.add(scene.add.circle(mapX(h), mapY(k), 7, 0x9f8cff, 1).setStrokeStyle(2, 0xf5fbff, 0.72));
        overlay.add(scene.add.text(mapX(h) + 10, mapY(k) + 8, `V(${h}, ${k})`, {
          fontFamily: "Inter, Arial", fontSize: "10px", color: "#d8c9ff", fontStyle: "bold",
        }));
      }
    }

    overlay.add(scene.add.rectangle(x + width - 226, y + 18, 198, workshop.showTargetCurve || !showActiveCurve ? 58 : 38, 0x07151d, 0.84)
      .setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.2));
    overlay.add(scene.add.text(x + width - 210, y + 28, showActiveCurve ? "— curva attiva" : "● beacon da leggere", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: showActiveCurve ? "#9ff5e9" : "#f7d37a",
    }));
    if (workshop.showTargetCurve) {
      overlay.add(scene.add.text(x + width - 210, y + 48, "┄ traccia bersaglio", {
        fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a",
      }));
    }
  },
};

function drawCurve(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  workshop: GeneratedGraphWorkshop,
  values: GraphValues,
  mapX: (value: number) => number,
  mapY: (value: number) => number,
  minX: number,
  maxX: number,
  minY: number,
  maxY: number,
  color: number,
  alpha: number,
  dashed: boolean,
): void {
  const curve = scene.add.graphics();
  curve.lineStyle(dashed ? 3 : 4, color, alpha);
  const samples = 180;
  let previous: { x: number; y: number } | undefined;
  for (let index = 0; index <= samples; index += 1) {
    const graphX = minX + ((maxX - minX) * index) / samples;
    const graphY = GraphWorkshopView.evaluate(workshop, values, graphX);
    const inside = graphY >= minY && graphY <= maxY;
    const point = { x: mapX(graphX), y: mapY(graphY) };
    if (inside && previous && (!dashed || Math.floor(index / 5) % 2 === 0)) {
      curve.lineBetween(previous.x, previous.y, point.x, point.y);
    }
    previous = inside ? point : undefined;
  }
  overlay.add(curve);
}
