import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { feedbackSystem } from "../core/FeedbackSystem";
import { rewardSystem, type CosmeticSlot } from "../core/RewardSystem";
import { Button } from "../ui/Button";

/**
 * Bottega dell'Energia — dove l'energia guadagnata rispondendo bene diventa
 * ricompense: colori per Bit, tute per l'avatar della stanza, emblemi-trofeo,
 * strumenti NORA e restauri d'area.
 * Dà una progressione tangibile e persistente al ciclo di allenamento.
 */
export class RewardShopScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
  private slot: CosmeticSlot = "bot";
  private headerLayer?: Phaser.GameObjects.Container;
  private bodyLayer?: Phaser.GameObjects.Container;

  constructor() {
    super("RewardShopScene");
  }

  create(data?: { returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    this.add.rectangle(640, 360, 1280, 720, 0x05121a, 1);
    audioManager.play("scan");
    this.refresh();
  }

  private refresh(): void {
    this.headerLayer?.destroy(true);
    this.bodyLayer?.destroy(true);
    this.headerLayer = this.add.container(0, 0);
    this.bodyLayer = this.add.container(0, 0);

    this.headerLayer.add(this.add.rectangle(40, 40, 6, 44, 0xf6c85f, 0.95).setOrigin(0));
    this.headerLayer.add(this.add.text(60, 36, "🛍️  Bottega dell'Energia", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }));
    this.headerLayer.add(this.add.text(62, 74, "Spendi l'energia guadagnata rispondendo bene: personalizza Bit, avatar, emblemi, strumenti NORA e restauri visivi delle aree.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2", wordWrap: { width: 820 },
    }));

    // energy balance chip
    const chip = this.add.container(1090, 52);
    chip.add(this.add.rectangle(0, 0, 180, 46, 0x061019, 0.95).setStrokeStyle(2, 0xf6c85f, 0.9));
    chip.add(this.add.text(-70, 0, "⚡", { fontFamily: "Inter, Arial", fontSize: "22px" }).setOrigin(0, 0.5));
    chip.add(this.add.text(-38, 0, String(rewardSystem.energy()), { fontFamily: "Inter, Arial", fontSize: "22px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0, 0.5));
    this.headerLayer.add(chip);
    this.headerLayer.add(new Button(this, 1210, 52, "Indietro", () => this.scene.start(this.returnScene), { width: 120, height: 40, fontSize: 14, fill: 0x263743 }));

    const tab = (x: number, id: CosmeticSlot, label: string): void => {
      const active = this.slot === id;
      this.headerLayer!.add(new Button(this, x, 132, label, () => {
        if (this.slot === id) return;
        this.slot = id;
        audioManager.play("click");
        this.refresh();
      }, { width: 220, height: 44, fontSize: 14, fill: active ? 0x1f5a51 : 0x122430, stroke: active ? 0xf6c85f : 0x6be7d6 }));
    };
    tab(140, "bot", "🤖 Bit");
    tab(350, "avatar", "🧑‍🚀 Avatar");
    tab(560, "emblem", "🏅 Emblemi");
    tab(770, "upgrade", "✦ NORA");
    tab(980, "decor", "◆ Aree");

    this.drawEquippedPreview();
    this.drawCards();
  }

  private drawEquippedPreview(): void {
    const layer = this.bodyLayer!;
    const equippedId = rewardSystem.equippedId(this.slot);
    const equipped = equippedId ? rewardSystem.find(equippedId) : undefined;
    layer.add(this.add.text(1142, 186, this.slot === "upgrade" ? "Strumenti attivi:" : this.slot === "decor" ? "Restauri attivi:" : "Equipaggiato ora:", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2" }).setOrigin(0.5));
    if (this.slot === "upgrade" || this.slot === "decor") {
      const active = rewardSystem.bySlot(this.slot).filter((item) => rewardSystem.owned(item.id));
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
    if (this.slot === "emblem") {
      layer.add(this.add.text(1142, 232, equipped?.glyph ?? "—", { fontFamily: "Inter, Arial", fontSize: "48px" }).setOrigin(0.5));
    } else {
      const color = equipped?.color ?? (this.slot === "bot" ? 0x6be7d6 : 0x6be7d6);
      layer.add(this.add.circle(1142, 236, 26, 0x143a48, 1).setStrokeStyle(3, color, 1));
      layer.add(this.add.circle(1142, 236, 8, color, 1));
    }
    layer.add(this.add.text(1142, 268, equipped?.name ?? "Predefinito", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#dce9f0" }).setOrigin(0.5));
  }

  private drawCards(): void {
    const layer = this.bodyLayer!;
    const items = rewardSystem.bySlot(this.slot);
    const cols = 2;
    const cardW = 460;
    const cardH = 150;
    const startX = 60;
    const startY = 210;
    items.forEach((cosmetic, i) => {
      const col = i % cols;
      const row = Math.floor(i / cols);
      const x = startX + col * (cardW + 24);
      const y = startY + row * (cardH + 20);
      const owned = rewardSystem.owned(cosmetic.id);
      const equipped = rewardSystem.isEquipped(cosmetic.id);
      const accent = equipped ? 0x2ed889 : owned ? 0x6be7d6 : 0xf6c85f;

      layer.add(this.add.rectangle(x, y, cardW, cardH, 0x07151d, 0.96).setOrigin(0).setStrokeStyle(2, accent, 0.8));
      // preview swatch / emblem
      if (cosmetic.slot === "emblem" || cosmetic.slot === "upgrade" || cosmetic.slot === "decor") {
        layer.add(this.add.text(x + 52, y + 56, cosmetic.glyph ?? "🏅", { fontFamily: "Inter, Arial", fontSize: "44px" }).setOrigin(0.5));
      } else {
        layer.add(this.add.circle(x + 52, y + 58, 26, 0x0c2130, 1).setStrokeStyle(3, cosmetic.color ?? 0x6be7d6, 1));
        layer.add(this.add.circle(x + 52, y + 58, 9, cosmetic.color ?? 0x6be7d6, 1));
      }
      layer.add(this.add.text(x + 96, y + 20, cosmetic.name, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f5fbff", fontStyle: "bold" }));
      layer.add(this.add.text(x + 96, y + 48, cosmetic.description, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2", wordWrap: { width: cardW - 120 } }));
      layer.add(this.add.text(x + 96, y + 92, `Costo: ${cosmetic.cost} ⚡`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f6c85f", fontStyle: "bold" }));

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
      layer.add(new Button(this, x, y, "Equipaggia", () => { rewardSystem.equip(id); audioManager.play("confirm"); this.refresh(); }, { width: 132, height: 34, fontSize: 13, fill: 0x173b36 }));
      return;
    }
    if (rewardSystem.canAfford(id)) {
      layer.add(new Button(this, x, y, "Acquista", () => {
        if (rewardSystem.purchase(id)) {
          audioManager.play("success");
          const slot = rewardSystem.find(id)?.slot;
          feedbackSystem.publish(slot === "upgrade" || slot === "decor" ? "Sbloccato e attivo!" : "Sbloccato ed equipaggiato!", "success");
          this.refresh();
        }
      }, { width: 132, height: 34, fontSize: 13, fill: 0x244a2e, stroke: 0xf6c85f }));
      return;
    }
    layer.add(this.add.rectangle(x, y, 132, 34, 0x25171a, 0.9).setStrokeStyle(1, 0x6a3a3a, 0.9));
    layer.add(this.add.text(x, y, "Energia insuff.", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#e0a0a0" }).setOrigin(0.5));
  }
}
