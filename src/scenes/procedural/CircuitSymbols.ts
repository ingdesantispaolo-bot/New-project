import Phaser from "phaser";
import { settingsSystem } from "../../core/SettingsSystem";

// Pure schematic-symbol painters for the circuit console. Each draws onto the
// given overlay container using the scene's graphics factory and holds no
// state, so they live outside the mission scene to keep it focused on flow.

type Overlay = Phaser.GameObjects.Container;

function label(scene: Phaser.Scene, x: number, y: number, text: string, color: string, size = "10px"): Phaser.GameObjects.Text {
  return scene.add.text(x, y, text, {
    fontFamily: "Inter, Arial",
    fontSize: size,
    color,
  }).setOrigin(0.5);
}

function optionalColor(color: number): string {
  return color === 0xffb36b ? "#f7d37a" : "#9aaab0";
}

export function drawCapacitorSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.9);
  g.beginPath();
  g.moveTo(x - 46, y);
  g.lineTo(x - 14, y);
  g.moveTo(x - 14, y - 22);
  g.lineTo(x - 14, y + 22);
  g.moveTo(x + 14, y - 22);
  g.lineTo(x + 14, y + 22);
  g.moveTo(x + 14, y);
  g.lineTo(x + 46, y);
  g.strokePath();
  overlay.add(g);
  overlay.add(label(scene, x, y + 30, showLabel ? "condensatore: accumula carica" : "simbolo opzionale", optionalColor(color)));
}

export function drawSensorSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, showLabel = true): void {
  overlay.add(scene.add.rectangle(x, y, 150, 38, 0x0d2531, 0.92).setStrokeStyle(2, color, 0.78));
  const g = scene.add.graphics();
  g.lineStyle(2, color, 0.9);
  g.strokeCircle(x - 40, y, 10);
  g.beginPath();
  g.moveTo(x - 24, y);
  g.lineTo(x + 40, y);
  g.moveTo(x + 24, y - 8);
  g.lineTo(x + 40, y);
  g.lineTo(x + 24, y + 8);
  g.strokePath();
  overlay.add(g);
  overlay.add(label(scene, x, y + 30, showLabel ? "sensore: misura e invia dati" : "simbolo opzionale", optionalColor(color)));
}

export function drawBranchSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.88);
  g.beginPath();
  g.moveTo(x - 58, y - 20);
  g.lineTo(x - 22, y - 20);
  g.lineTo(x + 22, y + 20);
  g.lineTo(x + 58, y + 20);
  g.moveTo(x - 58, y + 20);
  g.lineTo(x - 22, y + 20);
  g.lineTo(x + 22, y - 20);
  g.lineTo(x + 58, y - 20);
  g.strokePath();
  g.strokeCircle(x, y, 10);
  overlay.add(g);
  overlay.add(label(scene, x, y + 34, showLabel ? "ramo parallelo: può guastarsi da solo" : "simbolo opzionale", optionalColor(color)));
}

export function drawRelaySymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.9);
  g.strokeRect(x - 50, y - 18, 44, 36);
  g.beginPath();
  g.moveTo(x - 2, y);
  g.lineTo(x + 46, y - 16);
  g.moveTo(x + 22, y + 18);
  g.lineTo(x + 52, y + 18);
  g.strokePath();
  overlay.add(g);
  overlay.add(label(scene, x, y + 32, showLabel ? "relè: comando + potenza" : "simbolo opzionale", optionalColor(color)));
}

export function drawMotorSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.9);
  g.strokeCircle(x, y, 22);
  g.beginPath();
  g.moveTo(x - 44, y);
  g.lineTo(x - 22, y);
  g.moveTo(x + 22, y);
  g.lineTo(x + 44, y);
  g.strokePath();
  overlay.add(g);
  overlay.add(scene.add.text(x, y - 8, "M", {
    fontFamily: "Inter, Arial",
    fontSize: "18px",
    color: color === 0xffb36b ? "#f7d37a" : "#9ff5e9",
    fontStyle: "bold",
  }).setOrigin(0.5));
  overlay.add(label(scene, x, y + 32, showLabel ? "motore: carico più esigente" : "simbolo opzionale", optionalColor(color)));
}

export function drawGroundSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.9);
  g.beginPath();
  g.moveTo(x, y - 30);
  g.lineTo(x, y);
  g.moveTo(x - 30, y);
  g.lineTo(x + 30, y);
  g.moveTo(x - 20, y + 10);
  g.lineTo(x + 20, y + 10);
  g.moveTo(x - 10, y + 20);
  g.lineTo(x + 10, y + 20);
  g.strokePath();
  overlay.add(g);
  overlay.add(label(scene, x, y + 34, showLabel ? "massa: ritorno stabile" : "simbolo opzionale", optionalColor(color)));
}

export function drawBatterySymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.95);
  g.beginPath();
  g.moveTo(x - 22, y - 24);
  g.lineTo(x - 22, y + 24);
  g.moveTo(x + 4, y - 15);
  g.lineTo(x + 4, y + 15);
  g.strokePath();
  overlay.add(g);
  overlay.add(scene.add.text(x - 38, y - 36, "+", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
  overlay.add(scene.add.text(x + 20, y - 36, "-", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
}

export function drawSwitchSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, closed: boolean, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.95);
  g.strokeCircle(x - 30, y, 4);
  g.strokeCircle(x + 30, y, 4);
  g.beginPath();
  g.moveTo(x - 26, y);
  g.lineTo(x + 24, closed ? y : y - 24);
  g.strokePath();
  overlay.add(g);
  if (showLabel) {
    overlay.add(label(scene, x, y + 28, closed ? "chiuso" : "aperto", closed ? "#9ff5e9" : "#f7d37a", "11px"));
  }
}

export function drawResistorSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, missing: boolean, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, missing ? 0.45 : 0.95);
  g.beginPath();
  g.moveTo(x - 42, y);
  g.lineTo(x - 30, y);
  for (let i = 0; i < 6; i += 1) {
    g.lineTo(x - 20 + i * 8, y + (i % 2 === 0 ? -12 : 12));
  }
  g.lineTo(x + 32, y);
  g.lineTo(x + 44, y);
  g.strokePath();
  overlay.add(g);
  if (showLabel) {
    overlay.add(label(scene, x, y + 30, missing ? "manca" : "220 ohm", missing ? "#f7d37a" : "#9ff5e9", "11px"));
  }
}

export function drawLedSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number, reversed: boolean, lit: boolean, showLabel = true): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.95);
  g.beginPath();
  if (reversed) {
    g.moveTo(x + 24, y - 22);
    g.lineTo(x - 18, y);
    g.lineTo(x + 24, y + 22);
    g.closePath();
    g.moveTo(x - 24, y - 22);
    g.lineTo(x - 24, y + 22);
  } else {
    g.moveTo(x - 24, y - 22);
    g.lineTo(x + 18, y);
    g.lineTo(x - 24, y + 22);
    g.closePath();
    g.moveTo(x + 24, y - 22);
    g.lineTo(x + 24, y + 22);
  }
  g.strokePath();
  g.beginPath();
  g.moveTo(x + 18, y - 34);
  g.lineTo(x + 34, y - 50);
  g.moveTo(x + 28, y - 26);
  g.lineTo(x + 44, y - 42);
  g.strokePath();
  overlay.add(g);
  if (lit) {
    // A steady, breathing halo communicates "power restored" (luce stabile).
    const halo = scene.add.image(x + 64, y, "soft-glow").setTint(0x8cffd7).setAlpha(0.5).setScale(1.4);
    overlay.add(halo);
    if (!settingsSystem.effectsReduced()) {
      scene.tweens.add({
        targets: halo,
        scale: 2.1,
        alpha: 0.78,
        duration: 1100,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
      });
    }
  }
  overlay.add(scene.add.circle(x + 64, y, 16, lit ? 0x8cffd7 : 0x243541, lit ? 0.95 : 0.78).setStrokeStyle(2, color, 0.7));
  if (showLabel) {
    overlay.add(label(scene, x, y + 30, reversed ? "invertito" : lit ? "acceso" : "spento", reversed ? "#f7d37a" : lit ? "#9ff5e9" : "#9aaab0", "11px"));
  }
}

export function drawReturnSymbol(scene: Phaser.Scene, overlay: Overlay, x: number, y: number, color: number): void {
  const g = scene.add.graphics();
  g.lineStyle(3, color, 0.9);
  g.beginPath();
  g.moveTo(x - 28, y);
  g.lineTo(x + 28, y);
  g.moveTo(x, y);
  g.lineTo(x, y + 36);
  g.moveTo(x - 22, y + 36);
  g.lineTo(x + 22, y + 36);
  g.moveTo(x - 14, y + 46);
  g.lineTo(x + 14, y + 46);
  g.moveTo(x - 6, y + 56);
  g.lineTo(x + 6, y + 56);
  g.strokePath();
  overlay.add(g);
}

export function drawCurrentArrows(
  scene: Phaser.Scene,
  overlay: Overlay,
  color: number,
  alpha: number,
  arrows: Array<{ x: number; y: number; rotation: number }>,
): void {
  arrows.forEach((arrow) => {
    const tri = scene.add.triangle(arrow.x, arrow.y, 0, -6, 14, 0, 0, 6, color, alpha)
      .setRotation(arrow.rotation)
      .setOrigin(0.5);
    overlay.add(tri);
  });
}
