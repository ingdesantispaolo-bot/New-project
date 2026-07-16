import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { feedbackSystem } from "../core/FeedbackSystem";
import { rewardSystem, type Cosmetic, type CosmeticSlot } from "../core/RewardSystem";
import { startScene } from "../core/SceneNavigator";
import { settingsSystem } from "../core/SettingsSystem";
import { Button } from "../ui/Button";

type RewardRarity = {
  label: string;
  color: number;
  text: string;
};

/**
 * Bottega dell'Energia — dove l'energia guadagnata rispondendo bene diventa
 * ricompense: colori per Bit, tute per l'avatar della stanza, accessori, pet,
 * emblemi-trofeo, strumenti NORA e restauri d'area.
 * Dà una progressione tangibile e persistente al ciclo di allenamento.
 */
export class RewardShopScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
  private slot: CosmeticSlot = "bot";
  private pageBySlot: Partial<Record<CosmeticSlot, number>> = {};
  private headerLayer?: Phaser.GameObjects.Container;
  private bodyLayer?: Phaser.GameObjects.Container;

  constructor() {
    super("RewardShopScene");
  }

  create(data?: { returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    this.drawBackground();
    this.drawAmbientMotes();
    audioManager.play("shopOpen");
    this.refresh();
  }

  private drawBackground(): void {
    if (this.textures.exists("reward-shop-bg")) {
      this.add.image(640, 360, "reward-shop-bg").setDisplaySize(1280, 720).setDepth(-10);
      this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.46).setDepth(-9);
      this.add.rectangle(640, 640, 1280, 160, 0x02070b, 0.44).setDepth(-8);
      return;
    }
    this.add.rectangle(640, 360, 1280, 720, 0x05121a, 1);
  }

  private drawAmbientMotes(): void {
    if (settingsSystem.effectsReduced() || !this.textures.exists("soft-glow")) return;
    for (let i = 0; i < 18; i += 1) {
      const mote = this.add.image(Phaser.Math.Between(70, 1210), Phaser.Math.Between(110, 650), "soft-glow")
        .setDepth(-6)
        .setAlpha(Phaser.Math.FloatBetween(0.025, 0.075))
        .setTint(i % 3 === 0 ? 0xf6c85f : i % 3 === 1 ? 0x6be7d6 : 0x9f8cff)
        .setScale(Phaser.Math.FloatBetween(0.22, 0.72));
      this.tweens.add({
        targets: mote,
        x: mote.x + Phaser.Math.Between(-24, 24),
        y: mote.y - Phaser.Math.Between(18, 52),
        alpha: { from: mote.alpha, to: mote.alpha * 1.8 },
        duration: Phaser.Math.Between(2400, 5200),
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
      });
    }
  }

  private refresh(): void {
    this.headerLayer?.destroy(true);
    this.bodyLayer?.destroy(true);
    this.headerLayer = this.add.container(0, 0);
    this.bodyLayer = this.add.container(0, 0);

    this.headerLayer.add(this.add.rectangle(40, 40, 6, 44, 0xf6c85f, 0.95).setOrigin(0));
    this.headerLayer.add(this.add.text(60, 36, "🛍️  Bottega dell'Energia", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }));
    this.headerLayer.add(this.add.text(62, 74, "Spendi l'energia guadagnata rispondendo bene: personalizza Bit, avatar, accessori, pet, emblemi, strumenti NORA e restauri visivi.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2", wordWrap: { width: 740 },
    }));

    // energy balance chip
    const chip = this.add.container(1046, 52);
    chip.add(this.add.rectangle(0, 0, 156, 46, 0x061019, 0.95).setStrokeStyle(2, 0xf6c85f, 0.9));
    chip.add(this.add.text(-58, 0, "⚡", { fontFamily: "Inter, Arial", fontSize: "22px" }).setOrigin(0, 0.5));
    chip.add(this.add.text(-28, -7, String(rewardSystem.energy()), { fontFamily: "Inter, Arial", fontSize: "20px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0, 0.5));
    chip.add(this.add.text(-28, 13, `Liv. ${rewardSystem.playerLevel()}`, { fontFamily: "Inter, Arial", fontSize: "10px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0, 0.5));
    this.headerLayer.add(chip);
    this.headerLayer.add(new Button(this, 902, 52, "Armadio", () => {
      void startScene(this, "AvatarEquipmentScene", { returnScene: this.returnScene });
    }, { width: 118, height: 40, fontSize: 13, fill: 0x173b36, stroke: 0xf6c85f, soundKey: "panelOpen" }));
    this.headerLayer.add(new Button(this, 1210, 52, "Indietro", () => this.scene.start(this.returnScene), { width: 120, height: 40, fontSize: 14, fill: 0x263743 }));

    const tab = (x: number, id: CosmeticSlot, label: string): void => {
      const active = this.slot === id;
      this.headerLayer!.add(new Button(this, x, 132, label, () => {
        if (this.slot === id) return;
        this.slot = id;
        audioManager.play("click");
        this.refresh();
      }, { width: 144, height: 44, fontSize: 12, fill: active ? 0x1f5a51 : 0x122430, stroke: active ? 0xf6c85f : 0x6be7d6 }));
    };
    tab(104, "bot", "Bit");
    tab(256, "avatar", "Outfit");
    tab(408, "accessory", "Accessori");
    tab(560, "pet", "Pet");
    tab(712, "emblem", "Emblemi");
    tab(864, "upgrade", "NORA");
    tab(1016, "decor", "Aree");

    this.drawEquippedPreview();
    this.drawCards();
  }

  private drawEquippedPreview(): void {
    const layer = this.bodyLayer!;
    const equippedId = rewardSystem.equippedId(this.slot);
    const equipped = equippedId ? rewardSystem.find(equippedId) : undefined;
    const active = rewardSystem.bySlot(this.slot).filter((item) => rewardSystem.owned(item.id));
    const total = rewardSystem.bySlot(this.slot).length;
    this.drawPreviewPedestal(layer, equipped, active.length, total);
    layer.add(this.add.text(1142, 186, this.slot === "upgrade" ? "Potenziamenti attivi:" : this.slot === "decor" ? "Restauri attivi:" : "Equipaggiato ora:", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2" }).setOrigin(0.5));
    if (this.slot === "upgrade" || this.slot === "decor") {
      layer.add(this.add.text(1142, 232, `${active.length}/${rewardSystem.bySlot(this.slot).length}`, { fontFamily: "Inter, Arial", fontSize: "42px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
      layer.add(this.add.text(1142, 274, active.length > 0 ? active.map((item) => item.name).join("\n") : "Nessuno", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#dce9f0",
        align: "center",
        wordWrap: { width: 190 },
      }).setOrigin(0.5, 0));
      return;
    }
    if (equipped && this.textures.exists("reward-items") && this.textures.getFrame("reward-items", equipped.id)) {
      layer.add(this.add.image(1142, 238, "reward-items", equipped.id).setDisplaySize(82, 82));
    } else if (this.slot === "emblem" || this.slot === "accessory" || this.slot === "pet") {
      layer.add(this.add.text(1142, 232, equipped?.glyph ?? "-", { fontFamily: "Inter, Arial", fontSize: "48px" }).setOrigin(0.5));
    } else {
      const color = equipped?.color ?? (this.slot === "bot" ? 0x6be7d6 : 0x6be7d6);
      layer.add(this.add.circle(1142, 236, 26, 0x143a48, 1).setStrokeStyle(3, color, 1));
      layer.add(this.add.circle(1142, 236, 8, color, 1));
    }
    layer.add(this.add.text(1142, 292, equipped?.name ?? "Predefinito", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#dce9f0", wordWrap: { width: 190 } }).setOrigin(0.5));
  }

  private drawPreviewPedestal(layer: Phaser.GameObjects.Container, equipped: Cosmetic | undefined, owned: number, total: number): void {
    const accent = equipped?.color ?? this.rarityFor(equipped).color;
    layer.add(this.add.rectangle(1142, 252, 214, 214, 0x061019, 0.78).setStrokeStyle(1, 0x244451, 0.75));
    layer.add(this.add.ellipse(1142, 290, 132, 32, 0x000000, 0.24));
    const ring = this.add.ellipse(1142, 238, 112, 112, 0x000000, 0).setStrokeStyle(2, accent, 0.35);
    layer.add(ring);
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: ring, angle: 360, duration: 9000, repeat: -1, ease: "Linear" });
    }
    layer.add(this.add.text(1142, 344, `Collezione ${owned}/${total}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
  }

  private drawCards(): void {
    const layer = this.bodyLayer!;
    const items = rewardSystem.bySlot(this.slot);
    const pageSize = 6;
    const maxPage = Math.max(0, Math.ceil(items.length / pageSize) - 1);
    const page = Phaser.Math.Clamp(this.pageBySlot[this.slot] ?? 0, 0, maxPage);
    this.pageBySlot[this.slot] = page;
    const pageItems = items.slice(page * pageSize, page * pageSize + pageSize);
    const cols = 2;
    const cardW = 460;
    const cardH = 150;
    const startX = 60;
    const startY = 210;
    if (maxPage > 0) {
      layer.add(this.add.text(888, 168, `Pagina ${page + 1}/${maxPage + 1}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9fb6c2",
        fontStyle: "bold",
      }).setOrigin(0.5));
      layer.add(new Button(this, 826, 168, "‹", () => {
        this.pageBySlot[this.slot] = Math.max(0, page - 1);
        audioManager.play("click");
        this.refresh();
      }, { width: 40, height: 30, fontSize: 18, fill: page === 0 ? 0x1a252e : 0x263743 }));
      layer.add(new Button(this, 950, 168, "›", () => {
        this.pageBySlot[this.slot] = Math.min(maxPage, page + 1);
        audioManager.play("click");
        this.refresh();
      }, { width: 40, height: 30, fontSize: 18, fill: page === maxPage ? 0x1a252e : 0x263743 }));
    }
    pageItems.forEach((cosmetic, i) => {
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x = startX + col * (cardW + 24);
      const y = startY + row * (cardH + 20);
      const owned = rewardSystem.owned(cosmetic.id);
      const equipped = rewardSystem.isEquipped(cosmetic.id);
      const accent = equipped ? 0x2ed889 : owned ? 0x6be7d6 : 0xf6c85f;
      const rarity = this.rarityFor(cosmetic);
      const locked = !owned && !rewardSystem.canUnlock(cosmetic.id);

      layer.add(this.add.rectangle(x, y, cardW, cardH, 0x07151d, locked ? 0.78 : 0.92).setOrigin(0).setStrokeStyle(2, equipped ? 0x2ed889 : rarity.color, equipped ? 0.95 : 0.74));
      layer.add(this.add.rectangle(x, y, cardW, 4, equipped ? 0x2ed889 : rarity.color, equipped ? 0.95 : 0.82).setOrigin(0));
      layer.add(this.add.rectangle(x + 2, y + 2, 82, cardH - 4, 0x02070b, 0.32).setOrigin(0));
      this.drawRewardIcon(layer, cosmetic, x + 52, y + 60, 74);
      if (locked) {
        layer.add(this.add.rectangle(x + 52, y + 60, 74, 74, 0x02070b, 0.46));
        layer.add(this.add.text(x + 52, y + 60, "LOCK", {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#c7b8ff",
          fontStyle: "bold",
        }).setOrigin(0.5));
      }
      layer.add(this.add.text(x + 96, y + 20, cosmetic.name, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f5fbff", fontStyle: "bold" }));
      layer.add(this.add.text(x + cardW - 24, y + 24, rarity.label.toUpperCase(), {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: rarity.text,
        fontStyle: "bold",
      }).setOrigin(1, 0.5));
      layer.add(this.add.text(x + 96, y + 48, cosmetic.description, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2", wordWrap: { width: cardW - 120 } }));
      const req = cosmetic.minLevel ? ` · Liv. ${cosmetic.minLevel}` : "";
      layer.add(this.add.text(x + 96, y + 92, `Costo: ${cosmetic.cost} ⚡${req}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f6c85f", fontStyle: "bold" }));

      this.drawCardAction(layer, cosmetic.id, x + cardW - 150, y + cardH - 38);
    });
  }

  private drawCardAction(layer: Phaser.GameObjects.Container, id: string, x: number, y: number): void {
    if (rewardSystem.isEquipped(id)) {
      layer.add(this.add.rectangle(x, y, 132, 34, 0x123a2e, 0.9).setStrokeStyle(1, 0x2ed889, 0.9));
      const slot = rewardSystem.find(id)?.slot;
      const label = slot === "upgrade" || slot === "decor" ? "✓ Attivo" : "✓ Equipaggiato";
      layer.add(this.add.text(x, y, label, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#8ff6c0", fontStyle: "bold" }).setOrigin(0.5));
      return;
    }
    if (rewardSystem.owned(id)) {
      const slot = rewardSystem.find(id)?.slot;
      layer.add(new Button(this, x, y, "Equipaggia", () => {
        rewardSystem.equip(id);
        this.showRewardBurst(x, y, slot === "pet" ? 0x9ff5e9 : 0x6be7d6);
        this.time.delayedCall(180, () => this.refresh());
      }, { width: 132, height: 34, fontSize: 13, fill: 0x173b36, soundKey: slot === "pet" ? "petEquip" : "shopEquip" }));
      return;
    }
    const reason = rewardSystem.unavailableReason(id);
    if (reason && reason !== "Energia insuff.") {
      layer.add(new Button(this, x, y, `Richiede ${reason}`, () => {
        feedbackSystem.publish(`Oggetto bloccato: raggiungi ${reason} Accademia.`, "warning");
      }, { width: 132, height: 34, fontSize: 11, fill: 0x171f2b, stroke: 0x6a638d, soundKey: "shopLocked" }));
      return;
    }
    if (rewardSystem.canAfford(id)) {
      const cosmetic = rewardSystem.find(id);
      const slot = cosmetic?.slot;
      layer.add(new Button(this, x, y, "Acquista", () => {
        if (rewardSystem.purchase(id)) {
          feedbackSystem.publish(slot === "upgrade" || slot === "decor" ? "Sbloccato e attivo!" : "Sbloccato ed equipaggiato!", "success");
          if (cosmetic && this.rarityFor(cosmetic).label === "leggendario") {
            this.showLegendaryReveal(cosmetic);
            return;
          }
          this.showRewardBurst(x, y, slot === "pet" ? 0x9ff5e9 : 0xf6c85f);
          this.time.delayedCall(240, () => this.refresh());
        }
      }, { width: 132, height: 34, fontSize: 13, fill: 0x244a2e, stroke: 0xf6c85f, soundKey: slot === "pet" ? "petEquip" : "shopPurchase" }));
      return;
    }
    layer.add(new Button(this, x, y, "Energia insuff.", () => {
      feedbackSystem.publish("Energia insufficiente: completa esercizi, missioni o bonus palestra.", "warning");
    }, { width: 132, height: 34, fontSize: 12, fill: 0x25171a, stroke: 0x6a3a3a, soundKey: "shopLocked" }));
  }

  private drawRewardIcon(layer: Phaser.GameObjects.Container, cosmetic: Cosmetic, x: number, y: number, size: number): void {
    if (this.textures.exists("reward-items") && this.textures.getFrame("reward-items", cosmetic.id)) {
      layer.add(this.add.image(x, y, "reward-items", cosmetic.id).setDisplaySize(size, size));
      return;
    }
    if (cosmetic.slot === "emblem" || cosmetic.slot === "upgrade" || cosmetic.slot === "decor" || cosmetic.slot === "accessory" || cosmetic.slot === "pet") {
      layer.add(this.add.text(x, y - 2, cosmetic.glyph ?? "◇", { fontFamily: "Inter, Arial", fontSize: `${Math.round(size * 0.58)}px` }).setOrigin(0.5));
      return;
    }
    layer.add(this.add.circle(x, y, size * 0.35, 0x0c2130, 1).setStrokeStyle(3, cosmetic.color ?? 0x6be7d6, 1));
    layer.add(this.add.circle(x, y, size * 0.12, cosmetic.color ?? 0x6be7d6, 1));
  }

  private rarityFor(cosmetic: Cosmetic | undefined): RewardRarity {
    if (!cosmetic) return { label: "base", color: 0x6be7d6, text: "#9ff5e9" };
    if ((cosmetic.minLevel ?? 0) >= 8 || cosmetic.cost >= 3000) return { label: "leggendario", color: 0xffd75e, text: "#ffd75e" };
    if ((cosmetic.minLevel ?? 0) >= 6 || cosmetic.cost >= 1200) return { label: "epico", color: 0x9f8cff, text: "#c7b8ff" };
    if ((cosmetic.minLevel ?? 0) >= 4 || cosmetic.cost >= 500) return { label: "raro", color: 0x6be7d6, text: "#9ff5e9" };
    return { label: "comune", color: 0x7da2af, text: "#b9cbd3" };
  }

  private showLegendaryReveal(cosmetic: Cosmetic): void {
    const overlay = this.add.container(0, 0).setDepth(400);
    const blocker = this.add.rectangle(640, 360, 1280, 720, 0x010407, 0.9).setInteractive();
    const rarity = this.rarityFor(cosmetic);
    overlay.add(blocker);
    overlay.add(this.add.rectangle(640, 360, 570, 500, 0x071018, 0.96).setStrokeStyle(3, rarity.color, 0.95));
    overlay.add(this.add.rectangle(640, 142, 570, 5, rarity.color, 0.98));
    overlay.add(this.add.text(640, 176, "RICOMPENSA LEGGENDARIA", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: rarity.text,
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(640, 208, cosmetic.name, {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    const halo = this.add.circle(640, 338, 128, 0x000000, 0).setStrokeStyle(4, rarity.color, 0.42);
    const innerHalo = this.add.circle(640, 338, 88, 0x000000, 0).setStrokeStyle(2, 0xffffff, 0.24);
    overlay.add([halo, innerHalo]);
    if (this.textures.exists("soft-glow")) {
      overlay.add(this.add.image(640, 338, "soft-glow").setTint(rarity.color).setAlpha(0.28).setScale(2.2));
    }
    this.drawRewardIcon(overlay, cosmetic, 640, 338, 136);
    overlay.add(this.add.text(640, 446, cosmetic.description, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#cfe3ec",
      align: "center",
      wordWrap: { width: 440 },
    }).setOrigin(0.5));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: halo, angle: 360, duration: 5200, repeat: -1, ease: "Linear" });
      this.tweens.add({ targets: innerHalo, angle: -360, duration: 4200, repeat: -1, ease: "Linear" });
      for (let i = 0; i < 18; i += 1) {
        const angle = (Math.PI * 2 * i) / 18;
        const spark = this.add.circle(640 + Math.cos(angle) * 78, 338 + Math.sin(angle) * 78, i % 4 === 0 ? 4 : 3, i % 2 === 0 ? rarity.color : 0xffffff, 0.92);
        overlay.add(spark);
        this.tweens.add({
          targets: spark,
          x: 640 + Math.cos(angle) * Phaser.Math.Between(154, 214),
          y: 338 + Math.sin(angle) * Phaser.Math.Between(118, 172),
          alpha: { from: 0.95, to: 0.12 },
          scale: { from: 1, to: 0.35 },
          duration: Phaser.Math.Between(900, 1450),
          repeat: -1,
          yoyo: true,
          ease: "Sine.easeInOut",
        });
      }
    }
    const continueButton = new Button(this, 552, 566, "Continua", () => {
      overlay.destroy(true);
      this.refresh();
    }, { width: 150, height: 42, fontSize: 14, fill: 0x263743 });
    const equipButton = new Button(this, 730, 566, "Equipaggiamento", () => {
      void startScene(this, "AvatarEquipmentScene", { returnScene: this.returnScene });
    }, { width: 178, height: 42, fontSize: 13, fill: 0x173b36, stroke: rarity.color, soundKey: "panelOpen" });
    overlay.add([continueButton, equipButton]);
  }

  private showRewardBurst(x: number, y: number, color: number): void {
    if (settingsSystem.effectsReduced() || !this.bodyLayer) return;
    const burst = this.add.container(x, y).setDepth(40);
    this.bodyLayer.add(burst);
    for (let i = 0; i < 12; i += 1) {
      const angle = (Math.PI * 2 * i) / 12;
      const spark = this.add.circle(0, 0, i % 3 === 0 ? 4 : 3, i % 2 === 0 ? color : 0xf6c85f, 0.95);
      burst.add(spark);
      this.tweens.add({
        targets: spark,
        x: Math.cos(angle) * Phaser.Math.Between(28, 58),
        y: Math.sin(angle) * Phaser.Math.Between(20, 46),
        alpha: 0,
        scale: 0.2,
        duration: 360,
        ease: "Cubic.easeOut",
      });
    }
    const ring = this.add.circle(0, 0, 10, 0x000000, 0).setStrokeStyle(2, color, 0.8);
    burst.add(ring);
    this.tweens.add({
      targets: ring,
      scale: 4,
      alpha: 0,
      duration: 420,
      ease: "Cubic.easeOut",
      onComplete: () => burst.destroy(true),
    });
  }
}
