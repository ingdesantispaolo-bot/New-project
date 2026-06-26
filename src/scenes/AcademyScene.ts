import Phaser from "phaser";
import { academySystem } from "../core/AcademySystem";
import { audioManager } from "../core/AudioManager";
import { masterySystem } from "../core/MasterySystem";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { settingsSystem } from "../core/SettingsSystem";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

/**
 * "La tua Accademia" — the persistent, personalised home base. It visibly grows
 * with the player: wings light up as chapters are restored, NORA's Core levels
 * up with mastery, trophies accumulate, and the player names it and picks an
 * emblem.
 */
export class AcademyScene extends Phaser.Scene {
  constructor() {
    super("AcademyScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    VisualKit.vignette(this);

    const emblem = academySystem.getEmblem();
    const rank = masterySystem.getAcademyRank();

    this.add.text(56, 28, `${emblem.glyph}  ${academySystem.getName()}`, {
      fontFamily: "Inter, Arial",
      fontSize: "32px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 900 },
    });
    this.add.text(58, 76, `Comandante: ${playerSystem.getActivePlayer().name}  ·  Grado: ${rank.title}  ·  ${rank.stars}/${rank.maxStars} ★`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
    });
    new Button(this, 1150, 52, "Rinomina", () => this.renameAcademy(), {
      width: 150,
      height: 40,
      fill: 0x263743,
      fontSize: 14,
    });

    this.drawCorePanel();
    this.drawWings();
    this.drawTrophies();

    this.add.text(58, 632, `Prossimo obiettivo: ${academySystem.getNextGoal()}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      wordWrap: { width: 900 },
    });
    new Button(this, 132, 686, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 150,
      height: 44,
      fill: 0x263743,
      fontSize: 14,
    });
    new Button(this, 332, 686, "Albero Competenze", () => { void startScene(this, "MasteryScene"); }, {
      width: 230,
      height: 44,
      fill: 0x173b36,
      stroke: 0x70d68a,
      fontSize: 13,
    });
    new Button(this, 576, 686, "NORA", () => { void startScene(this, "NoraScene"); }, {
      width: 180,
      height: 44,
      fill: 0x173b36,
      stroke: 0x9ff5e9,
      fontSize: 14,
    });
    new Button(this, 800, 686, "Continua la Storia", () => { void startScene(this, "CampaignScene"); }, {
      width: 240,
      height: 44,
      fill: 0x1f5a51,
      stroke: 0xf6c85f,
      fontSize: 13,
    });
  }

  private drawCorePanel(): void {
    const x = 52;
    const y = 116;
    this.add.rectangle(x, y, 380, 376, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.46);
    this.add.text(x + 22, y + 16, "Nucleo di NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const core = academySystem.getCore();
    const cx = x + 190;
    const cy = y + 150;
    const glow = this.add.image(cx, cy, "soft-glow").setTint(0x6be7d6).setAlpha(0.2 + core.brightness * 0.5).setScale(1.6 + core.brightness * 2.4);
    this.add.circle(cx, cy, 64, 0x0c2630, 1).setStrokeStyle(3, 0x6be7d6, 0.7);
    const orb = this.add.circle(cx, cy, 22 + core.level * 4, 0x6be7d6, 0.5 + core.brightness * 0.45);
    this.add.circle(cx, cy, 9, 0xffffff, 0.9);
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: [orb, glow], scale: "*=1.12", alpha: "*=0.85", duration: 1200, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
    this.add.text(cx, y + 256, `Livello Nucleo ${core.level}/${core.maxLevel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5);

    // Emblem chooser.
    this.add.text(x + 22, y + 286, "Emblema dell'Accademia:", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
    });
    const current = academySystem.getEmblem().id;
    academySystem.getEmblems().forEach((emblem, index) => {
      const selected = emblem.id === current;
      new Button(this, x + 50 + index * 64, y + 336, emblem.unlocked ? emblem.glyph : "🔒", () => {
        if (!emblem.unlocked) {
          audioManager.play("error");
          return;
        }
        academySystem.setEmblem(emblem.id);
        audioManager.play("uiSelect");
        this.scene.restart();
      }, {
        width: 56,
        height: 48,
        fontSize: 22,
        fill: selected ? 0x1f5a51 : 0x263743,
        stroke: selected ? 0xf6c85f : emblem.unlocked ? 0x6be7d6 : 0x3a4a54,
      });
    });
  }

  private drawWings(): void {
    const wings = academySystem.getWings();
    const positions = [
      { x: 452, y: 116 },
      { x: 846, y: 116 },
      { x: 452, y: 296 },
      { x: 846, y: 296 },
    ];
    wings.forEach((wing, index) => {
      const pos = positions[index];
      const w = 382;
      const h = 168;
      this.add.rectangle(pos.x, pos.y, w, h, wing.restored ? 0x0c2230 : 0x0a0f14, wing.restored ? 0.92 : 0.8)
        .setOrigin(0).setStrokeStyle(2, wing.restored ? wing.color : 0x2a3a44, wing.restored ? 0.85 : 0.4);
      this.add.rectangle(pos.x, pos.y, w, 4, wing.color, wing.restored ? 0.95 : 0.25).setOrigin(0);
      if (wing.restored) {
        this.add.image(pos.x + w - 40, pos.y + 36, "soft-glow").setTint(wing.color).setAlpha(0.4).setScale(1.2);
      }
      this.add.text(pos.x + 20, pos.y + 18, wing.label, {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: wing.restored ? "#f5fbff" : "#5d7782",
        fontStyle: "bold",
      });
      this.add.text(pos.x + 20, pos.y + 44, wing.restored ? `${wing.system} · attiva` : `${wing.system} · sigillata`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: wing.restored ? "#9ff5e9" : "#5d7782",
      });
      // Stability bar.
      this.add.text(pos.x + 20, pos.y + 96, `Stabilità ${wing.stability}%`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9aaab0",
      });
      this.add.rectangle(pos.x + 20, pos.y + 116, w - 40, 10, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8);
      this.add.rectangle(pos.x + 20, pos.y + 116, (w - 40) * wing.stability / 100, 10, wing.color, 0.9).setOrigin(0);
    });
  }

  private drawTrophies(): void {
    const x = 52;
    const y = 504;
    const trophies = academySystem.getTrophies();
    this.add.rectangle(x, y, 1188, 110, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0xf6c85f, 0.4);
    this.add.text(x + 22, y + 14, `Sala dei Trofei  ·  ${trophies.length}`, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    if (trophies.length === 0) {
      this.add.text(x + 22, y + 50, "Ancora nessun trofeo: completa capitoli e raggiungi la maestria per riempire la sala.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#9aaab0",
      });
      return;
    }
    trophies.slice(0, 10).forEach((trophy, index) => {
      const tx = x + 24 + (index % 5) * 232;
      const ty = y + 46 + Math.floor(index / 5) * 30;
      const icon = trophy.kind === "maestria" ? "🏆" : trophy.kind === "ala" ? "⬡" : "🎖";
      this.add.text(tx, ty, `${icon} ${trophy.label}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: trophy.kind === "maestria" ? "#ffe6a0" : "#d9eaf1",
        wordWrap: { width: 220 },
      });
    });
  }

  private renameAcademy(): void {
    const current = academySystem.getName();
    const name = globalThis.prompt?.("Come vuoi chiamare la tua Accademia?", current);
    if (name && name.trim().length > 0) {
      academySystem.setName(name);
      this.scene.restart();
    }
  }
}
