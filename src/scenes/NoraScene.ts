import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { noraContextEngine } from "../core/NoraContextEngine";
import { noraCompanion, type NoraTalkChoice, type NoraTone } from "../core/NoraCompanion";
import { noraKnowledge } from "../core/NoraKnowledge";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { settingsSystem } from "../core/SettingsSystem";
import type { ProceduralPuzzleKind } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { VisualKit } from "../ui/VisualKit";

/**
 * "NORA" — the companion screen. Shows the bond with NORA, her personalized
 * comments on the player's real progress, her recovered-memory subplot, and a
 * tone choice that gives the player a small narrative voice.
 */
export class NoraScene extends Phaser.Scene {
  private talkText?: Phaser.GameObjects.Text;

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
    this.drawRoomAtmosphere();

    const player = playerSystem.getActivePlayer();
    const bond = noraCompanion.bond();
    const messages = noraCompanion.getProgressMessages();
    const observations = noraContextEngine.observations();
    const roomLine = noraCompanion.roomPresenceLine(player.name);

    this.add.text(56, 30, "Stanza di NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(58, 76, "Qui non si consulta un pannello: ci si siede vicino al nucleo e si parla con lei.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      wordWrap: { width: 840 },
    });

    this.drawPortraitPanel(bond);
    this.drawDialoguePanel(roomLine, messages, observations);
    this.drawMemories();
    this.drawToneChoice();

    new Button(this, 150, 686, "Torna all'avventura", () => this.scene.start("MainMenuScene"), {
      width: 180,
      height: 44,
      fill: 0x263743,
    });

    // Update the baseline so the next visit compares against now.
    noraCompanion.commitSnapshot();
    noraCompanion.markRoomVisit();
  }

  private drawRoomAtmosphere(): void {
    const stage = noraCompanion.currentVisualStage();
    const accent = this.stageAccent(stage.id);
    this.add.rectangle(0, 612, 1280, 108, 0x041019, 0.68).setOrigin(0);
    this.add.ellipse(300, 620, 430, 82, 0x173b36, 0.34).setStrokeStyle(2, accent, 0.22);
    this.add.rectangle(106, 602, 218, 20, 0x263743, 0.78).setStrokeStyle(1, 0x9ff5e9, 0.18);
    this.add.rectangle(98, 622, 16, 44, 0x102533, 0.82);
    this.add.rectangle(316, 622, 16, 44, 0x102533, 0.82);
    this.add.circle(1054, 118, 38, accent, 0.08).setStrokeStyle(2, accent, 0.2);
    this.add.circle(1054, 118, 12, 0xf5fbff, 0.18);

    if (settingsSystem.effectsReduced()) return;
    Array.from({ length: 14 }).forEach((_, index) => {
      const mote = this.add.circle(110 + index * 78, 142 + ((index * 47) % 360), 2 + (index % 3), accent, 0.18 + (index % 4) * 0.04);
      this.tweens.add({
        targets: mote,
        y: mote.y - 24 - (index % 5) * 8,
        alpha: 0.05,
        duration: 2600 + index * 180,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut",
      });
    });
  }

  private drawPortraitPanel(bond: { level: number; maxLevel: number; title: string }): void {
    const x = 52;
    const y = 112;
    const w = 500;
    const h = 520;
    this.add.rectangle(x, y, w, h, 0x071018, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.46);

    const cx = x + w / 2;
    const stages = noraCompanion.visualStages();
    const current = stages.find((stage) => stage.current) ?? stages[0];
    const accent = this.stageAccent(current?.id ?? "dormant");
    this.add.text(x + 24, y + 18, current?.title ?? "NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const artY = y + 174;
    this.add.rectangle(cx, artY, 450, 260, 0x02070b, 0.78).setStrokeStyle(1, accent, 0.38);
    if (current && this.textures.exists(current.key)) {
      this.drawStageAura(cx, artY, current.id, accent);
      const portrait = this.add.image(cx, artY, current.key).setDisplaySize(450, 260);
      this.add.rectangle(cx, artY, 450, 260, 0x02070b, 0.08).setStrokeStyle(1, 0xf6c85f, 0.18);
      this.add.rectangle(cx, artY + 106, 450, 44, 0x02070b, 0.48);
      this.animateStagePortrait(portrait, current.id);
    } else {
      const core = this.add.circle(cx, artY, 64, 0x6be7d6, 0.95);
      this.add.circle(cx, artY, 22, 0xffffff, 0.9);
      const ring = this.add.image(cx, artY, "holo-ring").setTint(0x9ff5e9).setScale(4.2).setAlpha(0.5);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: core, scale: 1.25, alpha: 0.7, duration: 1100, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
        this.tweens.add({ targets: ring, rotation: Math.PI * 2, duration: 16000, repeat: -1 });
      }
    }

    this.add.text(x + 28, y + 324, bond.title, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.text(x + 28, y + 354, noraCompanion.moodSummary(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: w - 56 },
      lineSpacing: 4,
    });

    stages.forEach((stage, index) => {
      const tx = x + 62 + index * 88;
      const ty = y + 438;
      this.add.rectangle(tx, ty, 72, 44, 0x02070b, 0.78).setStrokeStyle(2, stage.current ? 0xf6c85f : 0x6be7d6, stage.current ? 0.9 : stage.unlocked ? 0.4 : 0.14);
      if (stage.unlocked && this.textures.exists(stage.key)) {
        this.add.image(tx, ty, stage.key).setDisplaySize(68, 39).setAlpha(stage.current ? 0.98 : 0.72);
      } else {
        this.add.circle(tx, ty, 9, 0x304653, 0.8).setStrokeStyle(1, 0x6be7d6, 0.18);
      }
    });
    this.add.text(x + 28, y + 480, `Legame ${bond.level}/${bond.maxLevel} · cresce con capitoli e padronanza`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
    });
  }

  private stageAccent(stageId: string): number {
    if (stageId === "guardian") return 0xcdbfff;
    if (stageId === "restored") return 0x6be7d6;
    if (stageId === "memory") return 0x9f8cff;
    if (stageId === "awakening") return 0xf6c85f;
    return 0x7ad7ff;
  }

  private drawStageAura(x: number, y: number, stageId: string, accent: number): void {
    const alpha = stageId === "dormant" ? 0.08 : stageId === "guardian" ? 0.16 : 0.12;
    this.add.circle(x, y, 144, accent, alpha);
    this.add.circle(x, y, 94, accent, alpha * 0.72).setStrokeStyle(2, accent, 0.22);
    if (stageId === "memory" || stageId === "guardian") {
      this.add.rectangle(x, y - 86, 376, 2, accent, 0.22);
      this.add.rectangle(x, y + 86, 376, 2, accent, 0.18);
    }
  }

  private animateStagePortrait(portrait: Phaser.GameObjects.Image, stageId: string): void {
    if (settingsSystem.effectsReduced()) return;
    const baseScaleX = portrait.scaleX;
    const baseScaleY = portrait.scaleY;
    const pulse = stageId === "dormant" ? 1.006 : stageId === "guardian" ? 1.018 : 1.012;
    const duration = stageId === "awakening" ? 3200 : stageId === "memory" ? 4300 : stageId === "guardian" ? 3600 : 5200;
    this.tweens.add({
      targets: portrait,
      scaleX: baseScaleX * pulse,
      scaleY: baseScaleY * pulse,
      y: portrait.y + (stageId === "dormant" ? 2 : -3),
      duration,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }

  private drawDialoguePanel(roomLine: string, messages: string[], observations: string[]): void {
    const x = 584;
    const y = 112;
    this.add.rectangle(x, y, 640, 246, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x9ff5e9, 0.4);
    this.add.rectangle(x, y, 640, 3, 0x9ff5e9, 0.8).setOrigin(0);
    this.add.text(x + 22, y + 16, "Parla con NORA", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    new Button(this, x + 546, y + 28, "Ripasso", () => this.showRecommendedTheory(), {
      width: 120,
      height: 30,
      fontSize: 11,
      fill: 0x173b36,
      stroke: 0xf6c85f,
    });
    const body = [roomLine, ...messages.slice(0, 2)].join("\n");
    this.talkText = this.add.text(x + 22, y + 50, body, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#eaf4f8",
      wordWrap: { width: 580 },
      lineSpacing: 5,
    });
    this.add.text(x + 22, y + 144, observations.slice(0, 2).map((line) => `- ${line}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 588, useAdvancedWrap: true },
      lineSpacing: 3,
    });
    this.drawTalkChoices(x + 28, y + 204);
  }

  private showRecommendedTheory(): void {
    const topic = this.recommendedTheoryTopic();
    if (!topic) return;
    this.talkText?.setText(`«${noraKnowledge.noraBrief(topic)}»`);
    audioManager.play("uiSelect");
  }

  private recommendedTheoryTopic() {
    const weakCompetencyTopic = noraKnowledge.weakestCompetencyTopic(saveSystem.data.competencies ?? {});
    if (weakCompetencyTopic) return weakCompetencyTopic;

    const validKinds = new Set<ProceduralPuzzleKind>(["language", "latin", "circuit", "math", "english", "robot", "coding", "music", "physics"]);
    const topMemory = Object.entries(saveSystem.data.learningMemory ?? {})
      .filter(([key]) => validKinds.has(key.split(":")[0] as ProceduralPuzzleKind))
      .sort((a, b) => b[1].count - a[1].count)[0];
    if (topMemory) {
      const kind = topMemory[0].split(":")[0] as ProceduralPuzzleKind;
      const topic = noraKnowledge.topicForPuzzle(kind);
      if (topic) return topic;
    }
    return noraKnowledge.topics()[0];
  }

  private drawMemories(): void {
    const x = 584;
    const y = 384;
    const memories = noraCompanion.memories();
    const recovered = memories.filter((memory) => memory.unlocked).length;
    this.add.rectangle(x, y, 640, 248, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x9f8cff, 0.45);
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
      const cardX = x + 22 + col * 300;
      const cardY = y + 70 + row * 54;
      const dot = memory.unlocked ? 0x9f8cff : 0x304653;
      this.add.rectangle(cardX, cardY, 284, 46, 0x071018, memory.unlocked ? 0.66 : 0.44).setOrigin(0).setStrokeStyle(1, 0x9f8cff, memory.unlocked ? 0.28 : 0.12);
      this.add.circle(cardX + 14, cardY + 18, 8, dot, memory.unlocked ? 0.95 : 0.5).setStrokeStyle(2, 0x9f8cff, memory.unlocked ? 0.8 : 0.2);
      this.add.text(cardX + 32, cardY + 8, memory.unlocked ? memory.title : "Ricordo bloccato", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: memory.unlocked ? "#cdbfff" : "#5d7782",
        fontStyle: "bold",
      });
      this.add.text(cardX + 32, cardY + 28, memory.unlocked ? this.memoryPreview(memory.text) : "Continua l'avventura per restituire questo ricordo a NORA.", {
        fontFamily: "Inter, Arial",
        fontSize: "9px",
        color: memory.unlocked ? "#d9eaf1" : "#5d7782",
        wordWrap: { width: 238 },
        lineSpacing: 1,
      });
    });
  }

  private drawTalkChoices(x: number, y: number): void {
    const choices: Array<{ id: NoraTalkChoice; label: string }> = [
      { id: "stay", label: "Resta con me" },
      { id: "notice", label: "Cosa vedi?" },
      { id: "memory", label: "Un ricordo" },
      { id: "courage", label: "Mi serve coraggio" },
    ];
    choices.forEach((choice, index) => {
      new Button(this, x + 70 + index * 142, y, choice.label, () => {
        const line = noraCompanion.talk(choice.id);
        this.talkText?.setText(`«${line}»`);
        audioManager.play("uiSelect");
      }, {
        width: 132,
        height: 34,
        fontSize: 11,
        fill: choice.id === "courage" ? 0x2a1f3a : 0x173b36,
        stroke: choice.id === "memory" ? 0x9f8cff : 0x6be7d6,
      });
    });
  }

  private memoryPreview(text: string): string {
    return text.length <= 68 ? text : `${text.slice(0, 65).trimEnd()}...`;
  }

  private drawToneChoice(): void {
    const x = 72;
    const y = 548;
    this.add.text(x, y, "Tono della voce", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    const tones: Array<{ id: NoraTone; label: string }> = [
      { id: "gentile", label: "Gentile" },
      { id: "curiosa", label: "Curiosa" },
      { id: "coraggiosa", label: "Coraggiosa" },
    ];
    const current = noraCompanion.getTone();
    tones.forEach((tone, index) => {
      const selected = tone.id === current;
      new Button(this, x + 58 + index * 112, y + 56, tone.label, () => {
        noraCompanion.setTone(tone.id);
        audioManager.play("uiSelect");
        this.scene.restart();
      }, {
        width: 104,
        height: 36,
        fontSize: 12,
        fill: selected ? 0x1f5a51 : 0x263743,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
      });
    });
    this.add.text(x, y + 20, `Attuale: ${noraCompanion.toneLabel()}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
  }
}
