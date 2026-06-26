import Phaser from "phaser";

export type PropArchetype =
  | "panel"
  | "terminal"
  | "console"
  | "music"
  | "door"
  | "robotDock"
  | "journal"
  | "window"
  | "workbench"
  | "core"
  | "trace";

export type PropState = "locked" | "ready" | "complete";

// Steel "material" palette shared by every prop housing.
const BODY = 0x16252f;
const BODY_HI = 0x22333e;
const EDGE = 0x0a141b;
const SCREEN = 0x0c1c26;
const COMPLETE = 0x2ed889;
const LOCKED = 0x55656e;
const WARM = 0xf6c85f;

/**
 * Code-drawn vector scenery for mission hotspots. Each archetype is the device
 * "housing" only — clean, with no baked text — so the interactive DeviceHotspot
 * (icon + label) drawn on top stays the single, crisp focal point.
 */
export function drawVectorProp(
  scene: Phaser.Scene,
  archetype: PropArchetype,
  x: number,
  y: number,
  size: number,
  state: PropState,
  accent: number,
): Phaser.GameObjects.Container {
  const container = scene.add.container(x, y);
  const s = size / 104;
  const dim = state === "locked";
  const col = state === "complete" ? COMPLETE : dim ? LOCKED : accent;
  const edgeAlpha = dim ? 0.45 : 0.85;
  const g = scene.add.graphics();

  // Ground contact shadow.
  container.add(scene.add.ellipse(0, size * 0.42, size * 0.82, size * 0.16, 0x000000, 0.26));
  if (state === "complete") {
    container.add(scene.add.image(0, 0, "soft-glow").setTint(COMPLETE).setAlpha(0.16).setScale(size / 70));
  }
  if (archetype === "core") {
    container.add(scene.add.image(0, -6 * s, "soft-glow").setTint(col).setAlpha(dim ? 0.08 : 0.28).setScale(size / 90));
  }

  switch (archetype) {
    case "panel":
      drawPanel(g, s, col, edgeAlpha, dim);
      break;
    case "terminal":
      drawTerminal(g, s, col, edgeAlpha);
      break;
    case "console":
      drawConsole(g, s, col, edgeAlpha);
      break;
    case "music":
      drawMusic(g, s, col, edgeAlpha);
      break;
    case "door":
      drawDoor(g, s, col, edgeAlpha, state);
      break;
    case "robotDock":
      drawRobotDock(g, s, col, edgeAlpha);
      break;
    case "journal":
      drawJournal(g, s, col, edgeAlpha);
      break;
    case "window":
      drawWindow(g, s, col, edgeAlpha);
      break;
    case "workbench":
      drawWorkbench(g, s, col, edgeAlpha);
      break;
    case "core":
      drawCore(g, s, col, edgeAlpha);
      break;
    case "trace":
      drawTrace(g, s, col, dim);
      break;
  }

  container.add(g);
  container.setAlpha(dim ? 0.52 : state === "complete" ? 0.95 : 0.8);
  return container;
}

function body(g: Phaser.GameObjects.Graphics, x: number, y: number, w: number, h: number, r: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY, 1);
  g.fillRoundedRect(x, y, w, h, r);
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(x, y, w, Math.min(h, r + 12), r);
  g.lineStyle(2.5, col, edgeAlpha);
  g.strokeRoundedRect(x, y, w, h, r);
}

function recessedScreen(g: Phaser.GameObjects.Graphics, x: number, y: number, w: number, h: number, r: number, col: number): void {
  g.fillStyle(SCREEN, 1);
  g.fillRoundedRect(x, y, w, h, r);
  g.lineStyle(1.5, col, 0.35);
  g.strokeRoundedRect(x, y, w, h, r);
}

function drawPanel(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number, dim: boolean): void {
  body(g, -44 * s, -50 * s, 88 * s, 100 * s, 8 * s, col, edgeAlpha);
  recessedScreen(g, -30 * s, -26 * s, 60 * s, 46 * s, 5 * s, col);
  // Cooling vents along the base.
  g.lineStyle(2 * s, 0xffffff, 0.06);
  for (let i = 0; i < 4; i += 1) {
    g.lineBetween(-30 * s, (28 + i * 7) * s, 30 * s, (28 + i * 7) * s);
  }
  // Status LEDs.
  g.fillStyle(col, dim ? 0.4 : 0.9);
  g.fillCircle(-32 * s, -40 * s, 3.5 * s);
  g.fillCircle(32 * s, -40 * s, 3.5 * s);
}

function drawTerminal(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY, 1);
  g.fillRect(-6 * s, 24 * s, 12 * s, 20 * s);
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-30 * s, 42 * s, 60 * s, 9 * s, 3 * s);
  body(g, -48 * s, -46 * s, 96 * s, 76 * s, 8 * s, col, edgeAlpha);
  recessedScreen(g, -40 * s, -38 * s, 80 * s, 60 * s, 4 * s, col);
  g.lineStyle(1 * s, col, 0.1);
  for (let i = 0; i < 4; i += 1) {
    g.lineBetween(-36 * s, (-28 + i * 14) * s, 36 * s, (-28 + i * 14) * s);
  }
}

function drawConsole(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-42 * s, 28 * s, 84 * s, 11 * s, 3 * s);
  g.fillStyle(BODY, 1);
  g.fillRect(-8 * s, 16 * s, 16 * s, 14 * s);
  // Slanted reading screen.
  g.fillStyle(BODY, 1);
  g.beginPath();
  g.moveTo(-46 * s, 22 * s);
  g.lineTo(46 * s, 22 * s);
  g.lineTo(36 * s, -44 * s);
  g.lineTo(-36 * s, -44 * s);
  g.closePath();
  g.fillPath();
  g.lineStyle(2.5 * s, col, edgeAlpha);
  g.strokePath();
  g.fillStyle(SCREEN, 1);
  g.beginPath();
  g.moveTo(-38 * s, 15 * s);
  g.lineTo(38 * s, 15 * s);
  g.lineTo(30 * s, -37 * s);
  g.lineTo(-30 * s, -37 * s);
  g.closePath();
  g.fillPath();
}

function drawMusic(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  body(g, -50 * s, -44 * s, 100 * s, 76 * s, 8 * s, col, edgeAlpha);
  // Speaker cones in the upper corners.
  ([[-36, -30], [36, -30]] as Array<[number, number]>).forEach(([cx, cy]) => {
    g.lineStyle(2 * s, col, edgeAlpha * 0.8);
    g.strokeCircle(cx * s, cy * s, 9 * s);
    g.fillStyle(col, 0.2);
    g.fillCircle(cx * s, cy * s, 3 * s);
  });
  // Central display where the note glyph sits.
  recessedScreen(g, -28 * s, -16 * s, 56 * s, 30 * s, 4 * s, col);
  // Equaliser bars along the base.
  g.fillStyle(col, edgeAlpha * 0.85);
  const bars = [8, 16, 11, 18, 13, 7];
  bars.forEach((h, i) => g.fillRect((-42 + i * 14) * s, (26 - h) * s, 8 * s, h * s));
}

function drawDoor(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number, state: PropState): void {
  g.fillStyle(BODY, 1);
  g.fillRoundedRect(-42 * s, -58 * s, 84 * s, 116 * s, 6 * s);
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-42 * s, -58 * s, 84 * s, 16 * s, 6 * s);
  g.fillRoundedRect(-42 * s, 42 * s, 84 * s, 16 * s, 6 * s);
  g.lineStyle(3 * s, col, edgeAlpha);
  g.strokeRoundedRect(-42 * s, -58 * s, 84 * s, 116 * s, 6 * s);
  // Central seam between the two leaves.
  g.lineStyle(2 * s, col, 0.3);
  g.lineBetween(0, -40 * s, 0, 40 * s);
  // Recessed lock plate (the hotspot lock glyph sits here).
  recessedScreen(g, -22 * s, -24 * s, 44 * s, 48 * s, 5 * s, col);
  // Hazard stripes on the top lintel.
  const hazard = state === "complete" ? col : WARM;
  g.lineStyle(3 * s, hazard, state === "locked" ? 0.3 : 0.55);
  for (let i = 0; i < 3; i += 1) {
    const hx = -22 * s + i * 16 * s;
    g.lineBetween(hx, -46 * s, hx + 8 * s, -54 * s);
  }
}

function drawRobotDock(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-48 * s, 30 * s, 96 * s, 16 * s, 4 * s);
  g.fillStyle(BODY, 1);
  g.fillRoundedRect(-44 * s, 24 * s, 88 * s, 9 * s, 3 * s);
  // Guide rails.
  g.fillStyle(BODY, 1);
  g.fillRoundedRect(-42 * s, -34 * s, 10 * s, 64 * s, 3 * s);
  g.fillRoundedRect(32 * s, -34 * s, 10 * s, 64 * s, 3 * s);
  g.lineStyle(2.5 * s, col, edgeAlpha);
  g.strokeRoundedRect(-42 * s, -34 * s, 10 * s, 64 * s, 3 * s);
  g.strokeRoundedRect(32 * s, -34 * s, 10 * s, 64 * s, 3 * s);
  // Charging arc that arches over the cradle.
  g.lineStyle(2.5 * s, col, edgeAlpha);
  g.beginPath();
  g.arc(0, -28 * s, 34 * s, Phaser.Math.DegToRad(200), Phaser.Math.DegToRad(340));
  g.strokePath();
  g.fillStyle(col, 0.9);
  g.fillCircle(-37 * s, -30 * s, 3 * s);
  g.fillCircle(37 * s, -30 * s, 3 * s);
}

function drawJournal(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY, 1);
  g.fillRoundedRect(-20 * s, 8 * s, 40 * s, 40 * s, 4 * s);
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-30 * s, 44 * s, 60 * s, 9 * s, 3 * s);
  // Angled data-slate on the lectern.
  g.fillStyle(BODY_HI, 1);
  g.beginPath();
  g.moveTo(-34 * s, 10 * s);
  g.lineTo(34 * s, 10 * s);
  g.lineTo(28 * s, -32 * s);
  g.lineTo(-28 * s, -32 * s);
  g.closePath();
  g.fillPath();
  g.lineStyle(2 * s, col, edgeAlpha);
  g.strokePath();
  g.lineBetween(0, -32 * s, 0, 10 * s);
}

function drawWindow(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY, 1);
  g.fillRoundedRect(-50 * s, -38 * s, 100 * s, 76 * s, 6 * s);
  g.fillStyle(0x123040, 0.6);
  g.fillRoundedRect(-42 * s, -30 * s, 84 * s, 60 * s, 4 * s);
  g.fillStyle(col, 0.07);
  g.fillRoundedRect(-42 * s, -30 * s, 84 * s, 30 * s, 4 * s);
  g.lineStyle(3 * s, col, edgeAlpha);
  g.strokeRoundedRect(-50 * s, -38 * s, 100 * s, 76 * s, 6 * s);
  g.lineStyle(2 * s, col, 0.4);
  g.lineBetween(0, -30 * s, 0, 30 * s);
  g.lineBetween(-42 * s, 0, 42 * s, 0);
}

function drawWorkbench(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  // Pegboard behind.
  g.fillStyle(BODY, 0.85);
  g.fillRoundedRect(-46 * s, -44 * s, 92 * s, 50 * s, 4 * s);
  g.lineStyle(1.5 * s, col, edgeAlpha * 0.7);
  g.strokeRoundedRect(-46 * s, -44 * s, 92 * s, 50 * s, 4 * s);
  g.fillStyle(EDGE, 0.6);
  for (let row = 0; row < 2; row += 1) {
    for (let cinx = 0; cinx < 5; cinx += 1) {
      g.fillCircle((-32 + cinx * 16) * s, (-32 + row * 18) * s, 2.5 * s);
    }
  }
  // Tabletop and legs.
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-52 * s, 2 * s, 104 * s, 12 * s, 3 * s);
  g.fillStyle(BODY, 1);
  g.fillRect(-44 * s, 14 * s, 8 * s, 30 * s);
  g.fillRect(36 * s, 14 * s, 8 * s, 30 * s);
}

function drawCore(g: Phaser.GameObjects.Graphics, s: number, col: number, edgeAlpha: number): void {
  g.fillStyle(BODY_HI, 1);
  g.fillRoundedRect(-30 * s, 26 * s, 60 * s, 14 * s, 4 * s);
  g.fillStyle(BODY, 1);
  g.fillRect(-8 * s, 12 * s, 16 * s, 16 * s);
  g.lineStyle(3 * s, col, edgeAlpha);
  g.strokeCircle(0, -6 * s, 38 * s);
  g.lineStyle(1.5 * s, col, 0.4);
  g.strokeCircle(0, -6 * s, 26 * s);
  g.fillStyle(col, 0.18);
  g.fillCircle(0, -6 * s, 16 * s);
}

function drawTrace(g: Phaser.GameObjects.Graphics, s: number, col: number, dim: boolean): void {
  const oy = 16 * s;
  const pts: Array<[number, number]> = [[-40, 12], [-14, -6], [12, 8], [40, -12]];
  g.lineStyle(3 * s, col, dim ? 0.25 : 0.5);
  for (let i = 0; i < pts.length - 1; i += 1) {
    g.lineBetween(pts[i][0] * s, pts[i][1] * s + oy, pts[i + 1][0] * s, pts[i + 1][1] * s + oy);
  }
  g.fillStyle(col, dim ? 0.3 : 0.7);
  pts.forEach(([px, py]) => g.fillCircle(px * s, py * s + oy, 3 * s));
  // Arrow head at the end of the path.
  const [ex, ey] = pts[pts.length - 1];
  g.fillTriangle(
    ex * s + 8 * s, ey * s + oy,
    ex * s - 4 * s, ey * s - 6 * s + oy,
    ex * s - 4 * s, ey * s + 6 * s + oy,
  );
}
