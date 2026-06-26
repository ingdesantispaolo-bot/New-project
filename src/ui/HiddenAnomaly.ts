import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { collectionSystem, type MemoryFragment } from "../core/CollectionSystem";
import { settingsSystem } from "../core/SettingsSystem";

// Discreet corners where a faint anomaly is unlikely to collide with UI.
const ANCHORS = [
  { x: 26, y: 694 },
  { x: 1254, y: 694 },
  { x: 1254, y: 26 },
  { x: 26, y: 150 },
];

function anchorFor(sceneKey: string): { x: number; y: number } {
  let hash = 0;
  for (let i = 0; i < sceneKey.length; i += 1) {
    hash = (hash * 31 + sceneKey.charCodeAt(i)) >>> 0;
  }
  return ANCHORS[hash % ANCHORS.length];
}

/**
 * Drops a subtle, pulsing "anomaly" into a room if that room still hides an
 * undiscovered memory fragment. Clicking it reveals the fragment for the
 * Galleria dei Frammenti. The keen explorer is rewarded; nothing clutters a
 * room that has already been searched.
 */
export function placeHiddenAnomaly(scene: Phaser.Scene, sceneKey: string): void {
  if (!collectionSystem.roomHasSecret(sceneKey)) {
    return;
  }
  const { x, y } = anchorFor(sceneKey);
  const tint = (anchorFor(sceneKey).x + anchorFor(sceneKey).y) % 2 === 0 ? 0xff5d7a : 0x6be7d6;

  const halo = scene.add.circle(x, y, 12, tint, 0.18).setDepth(900);
  const dot = scene.add.circle(x, y, 4, tint, 0.5).setDepth(901);
  const zone = scene.add.zone(x, y, 40, 40).setInteractive({ useHandCursor: true }).setDepth(902);

  if (!settingsSystem.effectsReduced()) {
    scene.tweens.add({ targets: halo, scale: 1.8, alpha: 0.05, duration: 1400, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  zone.on("pointerdown", () => {
    const fragment = collectionSystem.discoverRoom(sceneKey);
    halo.destroy();
    dot.destroy();
    zone.destroy();
    if (fragment) {
      audioManager.play("hint");
      revealToast(scene, fragment);
    }
  });
}

function revealToast(scene: Phaser.Scene, fragment: MemoryFragment): void {
  const cx = 640;
  const cy = 120;
  const card = scene.add.rectangle(cx, cy, 560, 92, 0x10131c, 0.96).setStrokeStyle(2, 0xf6c85f, 0.8).setDepth(1000).setAlpha(0);
  const heading = scene.add.text(cx, cy - 24, `${fragment.glyph}  Frammento di memoria ritrovato!`, {
    fontFamily: "Inter, Arial",
    fontSize: "16px",
    color: "#f6c85f",
    fontStyle: "bold",
  }).setOrigin(0.5).setDepth(1001).setAlpha(0);
  const title = scene.add.text(cx, cy + 4, `«${fragment.title}» — aprilo nella Galleria dei Frammenti`, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#dbe6ee",
  }).setOrigin(0.5).setDepth(1001).setAlpha(0);

  const group = [card, heading, title];
  scene.tweens.add({ targets: group, alpha: 1, y: "+=10", duration: 280, ease: "Back.easeOut" });
  scene.time.delayedCall(3400, () => {
    scene.tweens.add({
      targets: group,
      alpha: 0,
      duration: 360,
      onComplete: () => group.forEach((object) => object.destroy()),
    });
  });
}
