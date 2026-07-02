import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { noraCompanion, type NoraTone } from "../core/NoraCompanion";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { settingsSystem } from "../core/SettingsSystem";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { VisualKit } from "../ui/VisualKit";

/**
 * "NORA" — the companion screen. Shows the bond with NORA, her personalized
 * comments on the player's real progress, her recovered-memory subplot, and a
 * tone choice that gives the player a small narrative voice.
 */
export class NoraScene extends Phaser.Scene {
  constructor() {
    super("NoraScene");
  }

  preload(): void {
    queueSceneAssets(this, "archive", "story");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    VisualKit.vignette(this);
    placeHiddenAnomaly(this, "NoraScene");

    const player = playerSystem.getActivePlayer();
    const bond = noraCompanion.bond();
    const messages = noraCompanion.getProgressMessages();

    this.add.text(56, 30, "NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "36px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(58, 78, "La tua compagna di missione", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
    });

    this.drawPortraitPanel(bond);
    this.drawDialoguePanel(player.name, messages);
    this.drawMemories();
    this.drawToneChoice();

    new Button(this, 150, 686, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 180,
      height: 44,
      fill: 0x263743,
    });

    // Update the baseline so the next visit compares against now.
    noraCompanion.commitSnapshot();
  }

  private drawPortraitPanel(bond: { level: number; maxLevel: number; title: string }): void {
    const x = 52;
    const y = 118;
    this.add.rectangle(x, y, 360, 300, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.46);

    const cx = x + 180;
    const stages = noraCompanion.visualStages();
    const current = stages.find((stage) => stage.current) ?? stages[0];
    this.add.text(x + 22, y + 14, "Stato di NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const artY = y + 126;
    this.add.rectangle(cx, artY, 324, 178, 0x02070b, 0.86).setStrokeStyle(1, 0x6be7d6, 0.34);
    if (current && this.textures.exists(current.key)) {
      const portrait = this.add.image(cx, artY, current.key).setDisplaySize(324, 182);
      this.add.rectangle(cx, artY, 324, 182, 0x02070b, 0.08).setStrokeStyle(1, 0xf6c85f, 0.18);
      this.add.rectangle(cx, artY + 74, 324, 34, 0x02070b, 0.58);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({
          targets: portrait,
          scaleX: portrait.scaleX * 1.012,
          scaleY: portrait.scaleY * 1.012,
          duration: 5200,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut",
        });
      }
    } else {
      const core = this.add.circle(cx, artY, 30, 0x6be7d6, 0.95);
      this.add.circle(cx, artY, 11, 0xffffff, 0.9);
      const ring = this.add.image(cx, artY, "holo-ring").setTint(0x9ff5e9).setScale(2.2).setAlpha(0.5);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: core, scale: 1.25, alpha: 0.7, duration: 1100, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
        this.tweens.add({ targets: ring, rotation: Math.PI * 2, duration: 16000, repeat: -1 });
      }
    }

    this.add.text(x + 28, y + 207, current?.title ?? "NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(x + 28, y + 230, bond.title, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });

    stages.forEach((stage, index) => {
      const tx = x + 52 + index * 64;
      const ty = y + 266;
      this.add.rectangle(tx, ty, 56, 34, 0x02070b, 0.78).setStrokeStyle(2, stage.current ? 0xf6c85f : 0x6be7d6, stage.current ? 0.9 : stage.unlocked ? 0.4 : 0.14);
      if (stage.unlocked && this.textures.exists(stage.key)) {
        this.add.image(tx, ty, stage.key).setDisplaySize(52, 29).setAlpha(stage.current ? 0.98 : 0.72);
      } else {
        this.add.circle(tx, ty, 9, 0x304653, 0.8).setStrokeStyle(1, 0x6be7d6, 0.18);
      }
    });
    this.add.text(x + 22, y + 286, `Legame ${bond.level}/${bond.maxLevel} · cresce con capitoli e padronanza`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
    });
  }

  private drawDialoguePanel(playerName: string, messages: string[]): void {
    const x = 440;
    const y = 118;
    this.add.rectangle(x, y, 800, 196, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x9ff5e9, 0.4);
    this.add.rectangle(x, y, 800, 3, 0x9ff5e9, 0.8).setOrigin(0);
    this.add.text(x + 22, y + 14, "NORA ti parla", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    const body = [`Bentornata, ${playerName}.`, ...messages].join("\n");
    this.add.text(x + 22, y + 46, body, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#eaf4f8",
      wordWrap: { width: 756 },
      lineSpacing: 7,
    });
  }

  private drawMemories(): void {
    const x = 440;
    const y = 330;
    const memories = noraCompanion.memories();
    const recovered = memories.filter((memory) => memory.unlocked).length;
    this.add.rectangle(x, y, 800, 300, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.45);
    this.add.text(x + 22, y + 14, `Memorie di NORA  ·  ${recovered}/${memories.length} recuperate`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#cdbfff",
      fontStyle: "bold",
    });
    this.add.text(x + 22, y + 42, "La verità sul Blackout torna a galla man mano che riaccendi l'Accademia.", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
    });
    memories.forEach((memory, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const cardX = x + 22 + col * 378;
      const cardY = y + 72 + row * 68;
      const dot = memory.unlocked ? 0x9f8cff : 0x304653;
      this.add.rectangle(cardX, cardY, 354, 58, 0x071018, memory.unlocked ? 0.66 : 0.44).setOrigin(0).setStrokeStyle(1, 0x9f8cff, memory.unlocked ? 0.28 : 0.12);
      this.add.circle(cardX + 14, cardY + 18, 8, dot, memory.unlocked ? 0.95 : 0.5).setStrokeStyle(2, 0x9f8cff, memory.unlocked ? 0.8 : 0.2);
      this.add.text(cardX + 32, cardY + 8, memory.unlocked ? memory.title : "Ricordo bloccato", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: memory.unlocked ? "#cdbfff" : "#5d7782",
        fontStyle: "bold",
      });
      this.add.text(cardX + 32, cardY + 28, memory.unlocked ? this.memoryPreview(memory.text) : "Continua l'avventura per restituire questo ricordo a NORA.", {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: memory.unlocked ? "#d9eaf1" : "#5d7782",
        wordWrap: { width: 306 },
        lineSpacing: 1,
      });
    });
  }

  private memoryPreview(text: string): string {
    return text.length <= 104 ? text : `${text.slice(0, 101).trimEnd()}...`;
  }

  private drawToneChoice(): void {
    const x = 52;
    const y = 436;
    this.add.rectangle(x, y, 360, 194, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.4);
    this.add.text(x + 22, y + 14, "Come vuoi che NORA ti parli?", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(x + 22, y + 40, "Scegli il tono: cambia il suo modo di parlare, non gli esercizi.", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 320 },
    });
    const tones: Array<{ id: NoraTone; label: string }> = [
      { id: "gentile", label: "Gentile" },
      { id: "curiosa", label: "Curiosa" },
      { id: "coraggiosa", label: "Coraggiosa" },
    ];
    const current = noraCompanion.getTone();
    tones.forEach((tone, index) => {
      const selected = tone.id === current;
      new Button(this, x + 80 + index * 110, y + 110, tone.label, () => {
        noraCompanion.setTone(tone.id);
        audioManager.play("uiSelect");
        this.scene.restart();
      }, {
        width: 104,
        height: 44,
        fontSize: 14,
        fill: selected ? 0x1f5a51 : 0x263743,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
      });
    });
    this.add.text(x + 22, y + 152, `Tono attuale: ${noraCompanion.toneLabel()}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
  }
}
