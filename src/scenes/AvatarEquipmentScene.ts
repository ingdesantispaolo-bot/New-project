import Phaser from "phaser";
import { drawAccessoryVisual, drawOutfitBack, drawOutfitFront, drawPetVisual } from "../core/AvatarCosmeticVisuals";
import { audioManager } from "../core/AudioManager";
import { rewardSystem, type Cosmetic, type CosmeticSlot } from "../core/RewardSystem";
import { startScene } from "../core/SceneNavigator";
import { settingsSystem } from "../core/SettingsSystem";
import { Button } from "../ui/Button";

type EquipSlot = Exclude<CosmeticSlot, "upgrade" | "decor">;

const EQUIP_SLOTS: Array<{ slot: EquipSlot; label: string; hint: string }> = [
  { slot: "avatar", label: "Outfit", hint: "Tuta visibile nelle missioni" },
  { slot: "accessory", label: "Accessorio", hint: "Dettaglio sopra l'avatar" },
  { slot: "pet", label: "Pet", hint: "Compagno che fluttua vicino" },
  { slot: "bot", label: "Bit", hint: "Colore del nucleo NORA" },
  { slot: "emblem", label: "Emblema", hint: "Segno collezione profilo" },
];

export class AvatarEquipmentScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
  private selectedSlot: EquipSlot = "avatar";
  private pageBySlot: Partial<Record<EquipSlot, number>> = {};
  private previewLayer?: Phaser.GameObjects.Container;
  private inventoryLayer?: Phaser.GameObjects.Container;

  constructor() {
    super("AvatarEquipmentScene");
  }

  create(data?: { returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    this.drawBackground();
    this.drawHeader();
    this.drawStaticShell();
    audioManager.play("panelOpen");
    this.refresh();
  }

  private drawBackground(): void {
    if (this.textures.exists("reward-shop-bg")) {
      this.add.image(640, 360, "reward-shop-bg").setDisplaySize(1280, 720).setDepth(-10);
      this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.58).setDepth(-9);
      this.add.rectangle(410, 360, 560, 720, 0x041018, 0.42).setDepth(-8);
      this.add.rectangle(1000, 360, 560, 720, 0x02070b, 0.34).setDepth(-8);
      return;
    }
    this.add.rectangle(640, 360, 1280, 720, 0x05121a, 1);
  }

  private drawHeader(): void {
    this.add.rectangle(38, 38, 6, 48, 0xf6c85f, 0.96).setOrigin(0);
    this.add.text(58, 34, "Equipaggiamento Avatar", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(60, 72, "Combina outfit, accessorio, pet, Bit ed emblema. La preview mostra il set completo prima di tornare in missione.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9fb6c2",
      wordWrap: { width: 760 },
    });
    this.add.text(1016, 48, `${rewardSystem.energy()} ⚡`, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5);
    this.add.text(1016, 74, `Liv. ${rewardSystem.playerLevel()}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5);
    new Button(this, 1118, 56, "Bottega", () => {
      void startScene(this, "RewardShopScene", { returnScene: this.returnScene });
    }, { width: 112, height: 40, fontSize: 13, fill: 0x173b36, stroke: 0xf6c85f, soundKey: "panelOpen" });
    new Button(this, 1220, 56, "Indietro", () => this.scene.start(this.returnScene), {
      width: 104,
      height: 40,
      fontSize: 13,
      fill: 0x263743,
    });
  }

  private drawStaticShell(): void {
    this.add.rectangle(38, 126, 170, 548, 0x061019, 0.76).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8);
    this.add.text(62, 148, "Slot", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.rectangle(236, 126, 430, 548, 0x061019, 0.55).setOrigin(0).setStrokeStyle(1, 0x244451, 0.72);
    this.add.text(262, 148, "Preview set", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.rectangle(694, 126, 548, 548, 0x061019, 0.72).setOrigin(0).setStrokeStyle(1, 0x244451, 0.78);
    this.add.text(724, 148, "Inventario posseduto", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
  }

  private refresh(): void {
    this.previewLayer?.destroy(true);
    this.inventoryLayer?.destroy(true);
    this.previewLayer = this.add.container(0, 0);
    this.inventoryLayer = this.add.container(0, 0);
    this.drawSlotRail();
    this.drawPreview();
    this.drawInventory();
  }

  private drawSlotRail(): void {
    const layer = this.inventoryLayer!;
    EQUIP_SLOTS.forEach((entry, index) => {
      const y = 198 + index * 78;
      const active = this.selectedSlot === entry.slot;
      const equipped = rewardSystem.equipped(entry.slot);
      layer.add(new Button(this, 123, y, entry.label, () => {
        if (this.selectedSlot === entry.slot) return;
        this.selectedSlot = entry.slot;
        audioManager.play("click");
        this.refresh();
      }, {
        width: 132,
        height: 42,
        fontSize: 13,
        fill: active ? 0x1f5a51 : 0x122430,
        stroke: active ? 0xf6c85f : 0x6be7d6,
      }));
      layer.add(this.add.text(62, y + 28, equipped?.name ?? "Predefinito", {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: active ? "#f6c85f" : "#9fb6c2",
        wordWrap: { width: 124 },
      }));
    });
  }

  private drawPreview(): void {
    const layer = this.previewLayer!;
    const avatar = rewardSystem.equipped("avatar");
    const accessory = rewardSystem.equipped("accessory");
    const pet = rewardSystem.equipped("pet");
    const bit = rewardSystem.equipped("bot");
    const emblem = rewardSystem.equipped("emblem");
    const avatarColor = avatar?.color ?? 0x6be7d6;
    const botColor = bit?.color ?? 0x6be7d6;

    layer.add(this.add.ellipse(452, 574, 246, 46, 0x000000, 0.28));
    const ringOuter = this.add.ellipse(452, 394, 288, 288, 0x000000, 0).setStrokeStyle(2, avatarColor, 0.35);
    const ringInner = this.add.ellipse(452, 394, 210, 210, 0x000000, 0).setStrokeStyle(2, botColor, 0.22);
    layer.add([ringOuter, ringInner]);

    const figure = this.add.container(452, 418);
    drawOutfitBack(this, figure, avatar, 1.65, 10);
    if (this.textures.exists("eli-robot-girl")) {
      const sprite = this.add.sprite(0, 10, "eli-robot-girl", "down_idle").setOrigin(0.5, 0.58).setScale(1.65).setTint(avatarColor);
      figure.add(sprite);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({
          targets: sprite,
          y: 2,
          duration: 1450,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut",
        });
      }
    } else {
      figure.add(this.add.circle(0, -78, 36, 0x102c38, 1).setStrokeStyle(4, avatarColor, 1));
      figure.add(this.add.rectangle(0, 8, 86, 120, 0x102c38, 1).setStrokeStyle(5, avatarColor, 0.95));
      figure.add(this.add.circle(-16, -82, 6, 0x9ff5e9, 1));
      figure.add(this.add.circle(16, -82, 6, 0x9ff5e9, 1));
    }
    drawOutfitFront(this, figure, avatar, 1.65, 10);
    drawAccessoryVisual(this, figure, accessory, 1.65, 10);
    layer.add(figure);

    drawPetVisual(this, layer, pet, 330, 462, 1.55, !settingsSystem.effectsReduced());
    this.drawBit(layer, bit, 565, 506, botColor);
    this.drawEmblem(layer, emblem, 450, 632);

    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: ringOuter, angle: 360, duration: 9500, repeat: -1, ease: "Linear" });
      this.tweens.add({ targets: ringInner, angle: -360, duration: 7200, repeat: -1, ease: "Linear" });
      this.tweens.add({
        targets: figure,
        y: 410,
        duration: 1800,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
      });
    }

    layer.add(this.add.text(452, 196, this.setNameLine(), {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 330 },
    }).setOrigin(0.5));
    layer.add(this.add.text(452, 222, "outfit + accessorio + pet + Bit", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
      align: "center",
    }).setOrigin(0.5));
  }

  private drawInventory(): void {
    const layer = this.inventoryLayer!;
    const equippedId = rewardSystem.equippedId(this.selectedSlot);
    const ownedItems = rewardSystem.bySlot(this.selectedSlot).filter((item) => rewardSystem.owned(item.id));
    const pageSize = 8;
    const maxPage = Math.max(0, Math.ceil(ownedItems.length / pageSize) - 1);
    const page = Phaser.Math.Clamp(this.pageBySlot[this.selectedSlot] ?? 0, 0, maxPage);
    this.pageBySlot[this.selectedSlot] = page;
    const pageItems = ownedItems.slice(page * pageSize, page * pageSize + pageSize);
    const title = EQUIP_SLOTS.find((entry) => entry.slot === this.selectedSlot);
    layer.add(this.add.text(724, 174, title?.hint ?? "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9fb6c2",
    }));
    this.drawDefaultCard(layer, 724, 214, !equippedId);
    if (ownedItems.length === 0) {
      layer.add(this.add.text(994, 356, "Nessun oggetto posseduto in questo slot.\nApri la Bottega e sblocca nuove ricompense.", {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#cfe3ec",
        align: "center",
        wordWrap: { width: 340 },
      }).setOrigin(0.5));
      return;
    }
    if (maxPage > 0) {
      layer.add(this.add.text(1134, 174, `${page + 1}/${maxPage + 1}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9fb6c2",
        fontStyle: "bold",
      }).setOrigin(0.5));
      layer.add(new Button(this, 1090, 174, "<", () => {
        this.pageBySlot[this.selectedSlot] = Math.max(0, page - 1);
        this.refresh();
      }, { width: 34, height: 28, fontSize: 13, fill: page === 0 ? 0x1a252e : 0x263743 }));
      layer.add(new Button(this, 1178, 174, ">", () => {
        this.pageBySlot[this.selectedSlot] = Math.min(maxPage, page + 1);
        this.refresh();
      }, { width: 34, height: 28, fontSize: 13, fill: page === maxPage ? 0x1a252e : 0x263743 }));
    }
    pageItems.forEach((item, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      this.drawItemCard(layer, item, 724 + col * 258, 302 + row * 88, equippedId === item.id);
    });
  }

  private drawDefaultCard(layer: Phaser.GameObjects.Container, x: number, y: number, active: boolean): void {
    layer.add(this.add.rectangle(x, y, 500, 66, 0x07151d, 0.94).setOrigin(0).setStrokeStyle(2, active ? 0x2ed889 : 0x244451, active ? 0.96 : 0.72));
    layer.add(this.add.circle(x + 36, y + 33, 18, 0x122430, 1).setStrokeStyle(2, 0x6be7d6, 0.7));
    layer.add(this.add.text(x + 70, y + 16, "Predefinito", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    layer.add(this.add.text(x + 70, y + 39, "Rimuove l'oggetto equipaggiato nello slot selezionato.", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9fb6c2",
    }));
    if (active) {
      layer.add(this.add.text(x + 432, y + 33, "Attivo", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#8ff6c0",
        fontStyle: "bold",
      }).setOrigin(0.5));
      return;
    }
    layer.add(new Button(this, x + 432, y + 33, "Usa base", () => {
      rewardSystem.unequip(this.selectedSlot);
      this.drawEquipPulse(x + 432, y + 33, 0x6be7d6);
      this.time.delayedCall(120, () => this.refresh());
    }, { width: 108, height: 34, fontSize: 12, fill: 0x263743, soundKey: "shopEquip" }));
  }

  private drawItemCard(layer: Phaser.GameObjects.Container, item: Cosmetic, x: number, y: number, active: boolean): void {
    const accent = item.color ?? (active ? 0x2ed889 : 0x6be7d6);
    layer.add(this.add.rectangle(x, y, 240, 82, 0x07151d, 0.94).setOrigin(0).setStrokeStyle(2, active ? 0x2ed889 : accent, active ? 0.96 : 0.66));
    layer.add(this.add.rectangle(x, y, 4, 82, active ? 0x2ed889 : accent, 0.95).setOrigin(0));
    this.drawItemIcon(layer, item, x + 42, y + 40, 54);
    layer.add(this.add.text(x + 78, y + 14, item.name, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 138 },
    }));
    layer.add(this.add.text(x + 78, y + 36, item.description, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9fb6c2",
      wordWrap: { width: 138 },
    }));
    if (active) {
      layer.add(this.add.text(x + 196, y + 64, "Attivo", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#8ff6c0",
        fontStyle: "bold",
      }).setOrigin(0.5));
      return;
    }
    layer.add(new Button(this, x + 196, y + 64, "Equip", () => {
      rewardSystem.equip(item.id);
      this.drawEquipPulse(x + 196, y + 64, item.slot === "pet" ? 0x9ff5e9 : accent);
      this.time.delayedCall(120, () => this.refresh());
    }, { width: 72, height: 28, fontSize: 11, fill: 0x173b36, stroke: accent, soundKey: item.slot === "pet" ? "petEquip" : "shopEquip" }));
  }

  private drawItemIcon(layer: Phaser.GameObjects.Container, item: Cosmetic, x: number, y: number, size: number): void {
    if (this.textures.exists("reward-items") && this.textures.getFrame("reward-items", item.id)) {
      layer.add(this.add.image(x, y, "reward-items", item.id).setDisplaySize(size, size));
      return;
    }
    layer.add(this.add.circle(x, y, size * 0.38, 0x0c2130, 1).setStrokeStyle(2, item.color ?? 0x6be7d6, 0.95));
    layer.add(this.add.text(x, y - 2, item.glyph ?? "◇", {
      fontFamily: "Inter, Arial",
      fontSize: `${Math.round(size * 0.5)}px`,
      color: "#f5fbff",
    }).setOrigin(0.5));
  }

  private drawBit(layer: Phaser.GameObjects.Container, item: Cosmetic | undefined, x: number, y: number, color: number): void {
    const group = this.add.container(x, y);
    if (this.textures.exists("soft-glow")) {
      group.add(this.add.image(0, 0, "soft-glow").setTint(color).setAlpha(0.24).setScale(0.7));
    }
    group.add(this.add.circle(0, 0, 28, 0x07151d, 1).setStrokeStyle(3, color, 0.95));
    group.add(this.add.circle(0, 0, 9, color, 1));
    group.add(this.add.text(0, 42, item?.name ?? "Bit base", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9fb6c2",
    }).setOrigin(0.5));
    layer.add(group);
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: group, angle: 360, duration: 5600, repeat: -1, ease: "Linear" });
    }
  }

  private drawEmblem(layer: Phaser.GameObjects.Container, item: Cosmetic | undefined, x: number, y: number): void {
    if (!item) return;
    layer.add(this.add.rectangle(x, y, 174, 34, 0x07151d, 0.9).setStrokeStyle(1, item.color ?? 0xf6c85f, 0.75));
    layer.add(this.add.text(x - 74, y, item.glyph ?? "◇", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
    }).setOrigin(0.5));
    layer.add(this.add.text(x - 48, y, item.name, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f6c85f",
      fontStyle: "bold",
      wordWrap: { width: 122 },
    }).setOrigin(0, 0.5));
  }

  private drawEquipPulse(x: number, y: number, color: number): void {
    if (settingsSystem.effectsReduced()) return;
    const pulse = this.add.circle(x, y, 12, 0x000000, 0).setStrokeStyle(2, color, 0.88).setDepth(80);
    this.tweens.add({
      targets: pulse,
      scale: 4.4,
      alpha: 0,
      duration: 420,
      ease: "Cubic.easeOut",
      onComplete: () => pulse.destroy(),
    });
  }

  private setNameLine(): string {
    const avatar = rewardSystem.equipped("avatar")?.name ?? "Outfit base";
    const accessory = rewardSystem.equipped("accessory")?.name ?? "senza accessorio";
    const pet = rewardSystem.equipped("pet")?.name ?? "nessun pet";
    return `${avatar} · ${accessory} · ${pet}`;
  }
}
