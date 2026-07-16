import Phaser from "phaser";
import type { Cosmetic } from "./RewardSystem";

function tint(item: Cosmetic | undefined, fallback: number): number {
  return item?.color ?? fallback;
}

function scaleContainer(scene: Phaser.Scene, parent: Phaser.GameObjects.Container, x: number, y: number, scale: number): Phaser.GameObjects.Container {
  const c = scene.add.container(x, y).setScale(scale);
  parent.add(c);
  return c;
}

export function drawOutfitBack(scene: Phaser.Scene, parent: Phaser.GameObjects.Container, outfit: Cosmetic | undefined, scale = 1, y = 0): void {
  if (!outfit) return;
  const color = tint(outfit, 0x6be7d6);
  const c = scaleContainer(scene, parent, 0, y, scale);
  const g = scene.add.graphics();
  c.add(g);

  if (["avatar-captain", "avatar-shadow", "avatar-astral", "avatar-aurora"].includes(outfit.id)) {
    const capeColor = outfit.id === "avatar-shadow" ? 0x11142b : outfit.id === "avatar-astral" ? 0x18255a : color;
    g.fillStyle(capeColor, outfit.id === "avatar-shadow" ? 0.72 : 0.42);
    g.fillTriangle(-22, -8, -54, 50, -8, 54);
    g.fillTriangle(22, -8, 54, 50, 8, 54);
    g.lineStyle(2, color, 0.52);
    g.strokeTriangle(-22, -8, -54, 50, -8, 54);
    g.strokeTriangle(22, -8, 54, 50, 8, 54);
  }

  if (outfit.id === "avatar-pilot") {
    g.fillStyle(0xdffcff, 0.18);
    g.fillRoundedRect(-34, -2, 14, 50, 7);
    g.fillRoundedRect(20, -2, 14, 50, 7);
    g.lineStyle(2, color, 0.8);
    g.strokeRoundedRect(-34, -2, 14, 50, 7);
    g.strokeRoundedRect(20, -2, 14, 50, 7);
  }
}

export function drawOutfitFront(scene: Phaser.Scene, parent: Phaser.GameObjects.Container, outfit: Cosmetic | undefined, scale = 1, y = 0): void {
  if (!outfit) return;
  const color = tint(outfit, 0x6be7d6);
  const c = scaleContainer(scene, parent, 0, y, scale);
  const g = scene.add.graphics();
  c.add(g);

  g.fillStyle(color, 0.28);
  g.fillRoundedRect(-25, -2, 50, 44, 10);
  g.lineStyle(2, color, 0.86);
  g.strokeRoundedRect(-25, -2, 50, 44, 10);

  if (outfit.id === "avatar-gold" || outfit.id === "avatar-violet" || outfit.id === "avatar-emerald" || outfit.id === "avatar-crimson") {
    g.lineStyle(3, 0xf6c85f, 0.78);
    g.lineBetween(-18, 11, 18, 11);
    g.lineBetween(-12, 27, 12, 27);
    c.add(scene.add.circle(-25, 7, 5, color, 0.92));
    c.add(scene.add.circle(25, 7, 5, color, 0.92));
    return;
  }

  if (outfit.id === "avatar-nebula") {
    g.fillStyle(0x111a46, 0.64);
    g.fillRoundedRect(-18, 7, 36, 29, 8);
    g.fillStyle(0xffffff, 0.9);
    [-10, 0, 12].forEach((sx, index) => g.fillCircle(sx, 15 + index * 7, index === 1 ? 1.6 : 1.2));
    return;
  }

  if (outfit.id === "avatar-aurora") {
    g.lineStyle(3, 0x9ff5e9, 0.82);
    g.lineBetween(-18, 4, 18, 35);
    g.lineBetween(18, 4, -18, 35);
    c.add(scene.add.circle(0, 21, 7, 0x74f0c5, 0.64));
    return;
  }

  if (outfit.id === "avatar-pilot") {
    g.fillStyle(0xf8fbff, 0.78);
    g.fillTriangle(-18, 2, 0, 20, 18, 2);
    g.lineStyle(3, color, 0.92);
    g.lineBetween(-25, 4, -8, 35);
    g.lineBetween(25, 4, 8, 35);
    c.add(scene.add.rectangle(0, 34, 42, 7, 0x07151d, 0.9).setStrokeStyle(1, color, 0.8));
    return;
  }

  if (outfit.id === "avatar-engineer") {
    g.fillStyle(0x061019, 0.9);
    g.fillRoundedRect(-28, 28, 56, 10, 3);
    [-16, 0, 16].forEach((px) => c.add(scene.add.rectangle(px, 32, 9, 12, 0x2b2010, 0.95).setStrokeStyle(1, 0xf6c85f, 0.8)));
    g.lineStyle(3, 0xf6c85f, 0.75);
    g.lineBetween(-16, 1, 16, 30);
    return;
  }

  if (outfit.id === "avatar-captain") {
    g.fillStyle(0xf6c85f, 0.92);
    g.fillRoundedRect(-19, 8, 38, 8, 4);
    g.fillStyle(color, 0.8);
    g.fillTriangle(-24, 2, -4, 39, 8, 39);
    c.add(scene.add.circle(19, 21, 5, 0xf6c85f, 0.95));
    return;
  }

  if (outfit.id === "avatar-shadow") {
    g.fillStyle(0x02070b, 0.72);
    g.fillRoundedRect(-23, -9, 46, 54, 12);
    g.lineStyle(2, color, 0.95);
    g.lineBetween(-14, 4, 14, 32);
    g.lineBetween(14, 4, -14, 32);
    return;
  }

  if (outfit.id === "avatar-astral") {
    g.fillStyle(0xffffff, 0.95);
    g.fillCircle(0, 16, 3);
    g.fillCircle(-11, 27, 2);
    g.fillCircle(13, 31, 2);
    g.lineStyle(2, 0xffd75e, 0.86);
    g.strokeCircle(0, -33, 19);
  }
}

export function drawAccessoryVisual(scene: Phaser.Scene, parent: Phaser.GameObjects.Container, accessory: Cosmetic | undefined, scale = 1, y = 0): void {
  if (!accessory) return;
  const color = tint(accessory, 0xf6c85f);
  const c = scaleContainer(scene, parent, 0, y, scale);
  const g = scene.add.graphics();
  c.add(g);

  if (accessory.id === "accessory-visor") {
    c.add(scene.add.rectangle(2, -30, 34, 10, color, 0.5).setStrokeStyle(2, 0xd9ffff, 0.78));
    return;
  }
  if (accessory.id === "accessory-scarf") {
    g.fillStyle(color, 0.82);
    g.fillRoundedRect(-24, -8, 45, 9, 4);
    g.fillTriangle(12, -5, 42, 8, 14, 10);
    return;
  }
  if (accessory.id === "accessory-compass") {
    c.add(scene.add.circle(25, -2, 10, 0x061019, 0.94).setStrokeStyle(2, color, 0.95));
    c.add(scene.add.text(25, -2, "N", { fontFamily: "Inter, Arial", fontSize: "9px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    return;
  }
  if (accessory.id === "accessory-pack") {
    c.add(scene.add.rectangle(-32, 13, 17, 34, 0x07151d, 0.94).setStrokeStyle(2, color, 0.88));
    c.add(scene.add.circle(-32, 1, 4, color, 0.9));
    return;
  }
  if (accessory.id === "accessory-crown") {
    g.fillStyle(color, 0.9);
    g.fillTriangle(-17, -43, -10, -60, -3, -43);
    g.fillTriangle(-4, -43, 4, -64, 12, -43);
    g.fillTriangle(9, -43, 18, -58, 23, -43);
    g.fillRoundedRect(-18, -45, 40, 8, 3);
    return;
  }
  if (accessory.id === "accessory-antenna") {
    g.lineStyle(2, color, 0.92);
    g.lineBetween(-16, -38, -30, -61);
    g.lineBetween(16, -38, 30, -61);
    c.add(scene.add.circle(-30, -61, 5, color, 0.92));
    c.add(scene.add.circle(30, -61, 5, color, 0.92));
    return;
  }
  if (accessory.id === "accessory-wings") {
    g.fillStyle(color, 0.32);
    g.fillTriangle(-27, -4, -62, 1, -32, 24);
    g.fillTriangle(27, -4, 62, 1, 32, 24);
    g.lineStyle(2, color, 0.8);
    g.strokeTriangle(-27, -4, -62, 1, -32, 24);
    g.strokeTriangle(27, -4, 62, 1, 32, 24);
    return;
  }
  if (accessory.id === "accessory-jetpack") {
    c.add(scene.add.rectangle(-34, 16, 13, 38, 0x061019, 0.94).setStrokeStyle(2, color, 0.88));
    c.add(scene.add.rectangle(34, 16, 13, 38, 0x061019, 0.94).setStrokeStyle(2, color, 0.88));
    g.fillStyle(0xf6c85f, 0.72);
    g.fillTriangle(-39, 36, -29, 36, -34, 52);
    g.fillTriangle(29, 36, 39, 36, 34, 52);
    return;
  }
  if (accessory.id === "accessory-halo") {
    g.lineStyle(3, color, 0.88);
    g.strokeEllipse(0, -58, 50, 15);
  }
}

export function drawPetVisual(scene: Phaser.Scene, parent: Phaser.GameObjects.Container, pet: Cosmetic | undefined, x: number, y: number, scale = 1, animate = true): Phaser.GameObjects.Container | undefined {
  if (!pet) return undefined;
  const color = tint(pet, 0x9ff5e9);
  const c = scaleContainer(scene, parent, x, y, scale);
  const g = scene.add.graphics();
  c.add(g);
  g.fillStyle(color, 0.16);
  g.fillCircle(0, 0, 18);
  g.lineStyle(2, color, 0.88);
  g.strokeCircle(0, 0, 11);

  if (pet.id === "pet-orbit" || pet.id === "pet-satellite") {
    g.strokeEllipse(0, 0, 42, 17);
    c.add(scene.add.circle(20, 1, 4, color, 0.96));
  } else if (pet.id === "pet-prisma") {
    g.fillStyle(color, 0.9);
    g.fillTriangle(0, -14, 13, 4, 0, 16);
    g.fillTriangle(0, -14, -13, 4, 0, 16);
  } else if (pet.id === "pet-guardiano") {
    g.lineStyle(3, color, 0.92);
    g.strokeRoundedRect(-14, -14, 28, 28, 8);
    g.fillStyle(0xffd75e, 0.86);
    g.fillCircle(0, 0, 5);
  } else if (pet.id === "pet-comet") {
    g.fillStyle(color, 0.76);
    g.fillTriangle(-2, -8, -35, -2, -2, 8);
    g.fillCircle(5, 0, 11);
  } else if (pet.id === "pet-luma") {
    g.fillStyle(color, 0.9);
    g.fillTriangle(0, -18, 6, -5, 20, 0);
    g.fillTriangle(20, 0, 6, 5, 0, 18);
    g.fillTriangle(0, 18, -6, 5, -20, 0);
    g.fillTriangle(-20, 0, -6, -5, 0, -18);
  } else if (pet.id === "pet-codex") {
    c.add(scene.add.rectangle(0, 0, 28, 22, 0x07151d, 0.96).setStrokeStyle(2, color, 0.95));
    c.add(scene.add.rectangle(-3, 0, 1, 21, color, 0.7));
    c.add(scene.add.circle(8, -4, 2, 0xffd75e, 0.9));
  } else {
    c.add(scene.add.text(0, -1, pet.glyph ?? "*", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
  }

  if (animate) {
    scene.tweens.add({
      targets: c,
      y: y - 7 * scale,
      duration: 1050,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }
  return c;
}
