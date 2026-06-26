import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { campaignSystem, type CampaignChapter } from "../core/CampaignSystem";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { startScene } from "../core/SceneNavigator";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { VisualKit } from "../ui/VisualKit";

/**
 * "La Storia" — the campaign map. Re-surfaces the hand-crafted 4-chapter
 * adventure with an overarching frame, per-chapter "giornate" and a clear
 * multi-session progress so the player can resume the story across days.
 */
export class CampaignScene extends Phaser.Scene {
  constructor() {
    super("CampaignScene");
  }

  preload(): void {
    queueSceneAssets(this, "story", "storyBeats");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    const progress = campaignSystem.getProgress();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy", this.storyPhaseBackdropKey(progress.completed));
    VisualKit.vignette(this);
    placeHiddenAnomaly(this, "CampaignScene");

    const chapters = campaignSystem.getChapters();
    const active = campaignSystem.getActiveChapter();

    this.add.text(58, 36, "La Storia", {
      fontFamily: "Inter, Arial",
      fontSize: "40px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(60, 90, `Accademia delle Missioni · Capitoli ${progress.completed}/${progress.total}`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
    });

    // Synopsis + recap (left panel).
    this.panel(52, 128, 520, 300, "La missione");
    this.add.text(74, 172, campaignSystem.getSynopsis(), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 478 },
      lineSpacing: 6,
    });
    this.add.rectangle(74, 372, 476, 42, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.3);
    this.add.text(86, 380, campaignSystem.getRecap(), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 452 },
      lineSpacing: 3,
    });

    // Chapter rail (right panel).
    this.panel(592, 128, 634, 300, "I capitoli");
    chapters.forEach((chapter, index) => {
      const y = 178 + index * 58;
      const icon = chapter.status === "complete" ? "✓" : chapter.status === "active" ? "▶" : "🔒";
      const color = chapter.status === "complete" ? 0x2ed889 : chapter.status === "active" ? 0xf6c85f : 0x304653;
      const textColor = chapter.status === "locked" ? "#7d9098" : "#f5fbff";
      this.add.circle(626, y + 8, 16, color, chapter.status === "locked" ? 0.4 : 0.95).setStrokeStyle(2, color, 0.9);
      this.add.text(626, y + 8, icon, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#06131c", fontStyle: "bold" }).setOrigin(0.5);
      this.add.text(652, y - 4, `Capitolo ${chapter.number} · ${chapter.title}`, {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: textColor,
        fontStyle: chapter.status === "active" ? "bold" : "normal",
      });
      this.add.text(652, y + 18, `${chapter.location} — ${chapter.synopsis}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: chapter.status === "locked" ? "#5d7782" : "#9aaab0",
        wordWrap: { width: 540 },
      });
      if (index < chapters.length - 1) {
        this.add.rectangle(626, y + 32, 2, 18, color, 0.4);
      }
    });

    // Active chapter detail + giornate.
    this.drawActiveChapter(active);

    const pendingOutro = campaignSystem.consumePendingOutro();
    if (pendingOutro) {
      this.time.delayedCall(280, () => this.showChapterOutro(pendingOutro));
    }

    new Button(this, 150, 678, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 180,
      height: 46,
      fill: 0x263743,
    });
    if (progress.completed > 0 && !campaignSystem.isCampaignComplete()) {
      new Button(this, 372, 678, "Riepilogo nel Diario", () => this.scene.start("JournalScene"), {
        width: 240,
        height: 46,
        fill: 0x142736,
      });
    }
  }

  private drawActiveChapter(chapter: CampaignChapter): void {
    this.panel(52, 444, 1174, 206, campaignSystem.isCampaignComplete() ? "Storia completata" : `Capitolo attuale · ${chapter.title}`);

    if (campaignSystem.isCampaignComplete()) {
      this.add.text(74, 492, "Hai riacceso tutta l'Accademia e svelato la verità sul Blackout. NORA è viva grazie a te. Puoi rigiocare i capitoli o tornare al menu.", {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#9ff5e9",
        wordWrap: { width: 1080 },
        lineSpacing: 6,
      });
      new Button(this, 300, 600, "Rivivi un capitolo", () => this.enterChapter(chapter), {
        width: 280,
        height: 52,
        fill: 0x173b36,
        stroke: 0x6be7d6,
      });
      return;
    }

    this.add.text(74, 486, `${chapter.location} — ${chapter.synopsis}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7dce7",
      wordWrap: { width: 1080 },
    });

    // Giornate (mission objectives reframed as days).
    const days = campaignSystem.getChapterDays(chapter.missionId);
    this.add.text(74, 516, "Le giornate di questo capitolo:", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    days.slice(0, 6).forEach((day, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      const x = 74 + col * 290;
      const y = 542 + row * 36;
      const mark = day.status === "complete" ? "✓" : day.status === "active" ? "▶" : "·";
      const color = day.status === "complete" ? "#9ff5a7" : day.status === "active" ? "#f7d37a" : "#7d9098";
      this.add.text(x, y, `${mark} ${day.label}: ${day.task}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color,
        wordWrap: { width: 280 },
      });
    });

    new Button(this, 1040, 600, "Continua la storia", () => this.showChapterIntro(chapter), {
      width: 300,
      height: 56,
      fill: 0x1f5a51,
      stroke: 0xf6c85f,
      fontSize: 18,
      soundKey: "missionStart",
    });
  }

  private showChapterIntro(chapter: CampaignChapter): void {
    const modal = this.add.container(0, 0).setDepth(2000);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.82).setInteractive());
    modal.add(this.add.rectangle(640, 360, 980, 456, 0x07151d, 0.99).setStrokeStyle(2, 0x6be7d6, 0.8));
    this.addStoryBeatArt(modal, chapter, "intro", 366, 342);
    modal.add(this.add.text(552, 164, chapter.location.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(552, 190, chapter.title, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f6c85f",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(552, 244, chapter.intro, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#eaf4f8",
      wordWrap: { width: 506 },
      lineSpacing: 7,
    }));
    audioManager.play("panelOpen");
    new Button(this, 574, 524, "Indietro", () => modal.destroy(true), {
      width: 180,
      height: 50,
      fill: 0x263743,
    }).setDepth(2001);
    const enter = new Button(this, 822, 524, "Entra nel capitolo", () => this.enterChapter(chapter), {
      width: 280,
      height: 50,
      fill: 0x173b36,
      stroke: 0xf6c85f,
      fontSize: 17,
      soundKey: "missionStart",
    });
    enter.setDepth(2001);
    modal.add(enter);
  }

  private showChapterOutro(chapter: CampaignChapter): void {
    const modal = this.add.container(0, 0).setDepth(2000);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.84).setInteractive());
    modal.add(this.add.rectangle(640, 360, 980, 430, 0x07151d, 0.99).setStrokeStyle(2, 0x2ed889, 0.85));
    this.addStoryBeatArt(modal, chapter, "outro", 366, 340);
    modal.add(this.add.text(552, 178, `Capitolo ${chapter.number} completato`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5a7",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(552, 204, chapter.title, {
      fontFamily: "Inter, Arial",
      fontSize: "26px",
      color: "#6be7d6",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(552, 260, chapter.outro, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#eaf4f8",
      wordWrap: { width: 506 },
      lineSpacing: 7,
    }));
    audioManager.playOutcome("complete");
    VisualKit.particleBurst(this, 640, 250, "academy", "success");
    const close = new Button(this, 790, 506, campaignSystem.isCampaignComplete() ? "Fine della storia" : "Avanti", () => modal.destroy(true), {
      width: 260,
      height: 50,
      fill: 0x173b36,
      stroke: 0x6be7d6,
      soundKey: "confirm",
    });
    close.setDepth(2001);
    modal.add(close);
  }

  private addStoryBeatArt(
    modal: Phaser.GameObjects.Container,
    chapter: CampaignChapter,
    phase: "intro" | "outro",
    x: number,
    y: number,
  ): void {
    const key = `story-chapter-${String(chapter.number).padStart(2, "0")}-${phase}`;
    const frame = this.add.rectangle(x, y, 372, 236, 0x02070b, 0.72)
      .setStrokeStyle(2, phase === "intro" ? 0x6be7d6 : 0x2ed889, 0.55);
    modal.add(frame);
    if (!this.textures.exists(key)) {
      modal.add(this.add.rectangle(x, y, 344, 194, 0x0d1b26, 0.86).setStrokeStyle(1, 0x6be7d6, 0.24));
      return;
    }
    const image = this.add.image(x, y, key).setDisplaySize(356, 200);
    modal.add(image);
    modal.add(this.add.rectangle(x, y, 356, 200, 0x02070b, 0.08).setStrokeStyle(1, 0xf6c85f, 0.18));
    modal.add(this.add.rectangle(x, y + 112, 356, 24, 0x02070b, 0.48));
    modal.add(this.add.text(x - 164, y + 104, phase === "intro" ? "Ingresso nel capitolo" : "Esito del capitolo", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: phase === "intro" ? "#9ff5e9" : "#9ff5a7",
      fontStyle: "bold",
    }));
  }

  private enterChapter(chapter: CampaignChapter): void {
    audioManager.stopMusic();
    void startScene(this, chapter.sceneKey);
  }

  private panel(x: number, y: number, w: number, h: number, title: string): void {
    this.add.rectangle(x, y, w, h, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.46);
    this.add.rectangle(x, y, w, 3, 0x6be7d6, 0.75).setOrigin(0);
    this.add.text(x + 22, y + 14, title, {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
  }

  private storyPhaseBackdropKey(completedChapters: number): string {
    const phase = Phaser.Math.Clamp(completedChapters, 0, 4);
    return [
      "story-phase-00-blackout-bg",
      "story-phase-01-energy-bg",
      "story-phase-02-life-bg",
      "story-phase-03-production-bg",
      "story-phase-04-restored-bg",
    ][phase] ?? "story-academy-hub-bg";
  }
}
