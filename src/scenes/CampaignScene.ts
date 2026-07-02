import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { campaignSystem, type CampaignChapter } from "../core/CampaignSystem";
import { buildChapterExploreRun, buildChapterTrialRun, chapterExploreLevel, chapterTrialLevel, chapterTrialTimeMs, CHAPTER_TRIAL_ERROR_BUDGET } from "../core/ChapterTrial";
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

    this.add.rectangle(46, 34, 5, 56, 0xf6c85f, 0.9).setOrigin(0);
    this.add.text(58, 36, "La Storia", {
      fontFamily: "Inter, Arial",
      fontSize: "40px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.rectangle(1226, 44, 200, 30, 0x07151d, 0.85).setOrigin(1, 0).setStrokeStyle(2, 0xf6c85f, 0.8);
    this.add.text(1126, 59, "📖 PERCORSO STORIA", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5);
    this.add.text(60, 90, `Accademia delle Missioni · Capitoli ${progress.completed}/${progress.total}`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
    });

    // Synopsis + recap (left panel).
    this.panel(52, 128, 520, 300, "La missione");
    this.add.text(74, 172, campaignSystem.getSynopsis(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 478 },
      lineSpacing: 4,
    }).setFixedSize(478, 96);
    this.drawStoryClues(progress.completed, 74, 292);
    this.add.rectangle(74, 376, 476, 36, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.3);
    this.add.text(86, 383, campaignSystem.getRecap(), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 452 },
      lineSpacing: 2,
    });

    // Chapter rail (right panel).
    this.panel(592, 128, 634, 300, "I capitoli");
    const dense = chapters.length > 5;
    const railStep = dense ? 44 : 58;
    const railRadius = dense ? 13 : 16;
    chapters.forEach((chapter, index) => {
      const y = (dense ? 168 : 178) + index * railStep;
      const icon = chapter.status === "complete" ? "✓" : chapter.status === "active" ? "▶" : "🔒";
      const color = chapter.status === "complete" ? 0x2ed889 : chapter.status === "active" ? 0xf6c85f : 0x304653;
      const textColor = chapter.status === "locked" ? "#7d9098" : "#f5fbff";
      this.add.circle(626, y + 8, railRadius, color, chapter.status === "locked" ? 0.4 : 0.95).setStrokeStyle(2, color, 0.9);
      this.add.text(626, y + 8, icon, { fontFamily: "Inter, Arial", fontSize: dense ? "12px" : "14px", color: "#06131c", fontStyle: "bold" }).setOrigin(0.5);
      const seasonTag = chapter.season >= 2 && (index === 0 || chapters[index - 1].season !== chapter.season) ? " · STAGIONE 2" : "";
      this.add.text(652, y - 4, `Capitolo ${chapter.number} · ${chapter.title}${seasonTag}`, {
        fontFamily: "Inter, Arial",
        fontSize: dense ? "15px" : "16px",
        color: textColor,
        fontStyle: chapter.status === "active" || seasonTag ? "bold" : "normal",
      });
      this.add.text(652, y + (dense ? 15 : 18), `${chapter.location} — ${chapter.synopsis}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: chapter.status === "locked" ? "#5d7782" : "#9aaab0",
        wordWrap: { width: 540 },
      });
      if (index < chapters.length - 1) {
        this.add.rectangle(626, y + railStep - 12, 2, dense ? 10 : 18, color, 0.4);
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

    // Briefing in due fasi: prima comprensione, poi valutazione.
    const explored = campaignSystem.isChapterExplored(chapter.missionId);
    const exploreLevel = chapterExploreLevel(chapter.missionId);
    const level = chapterTrialLevel(chapter.missionId);
    const minutes = Math.round(chapterTrialTimeMs(chapter.missionId) / 60_000);
    this.add.text(74, 516, "Percorso del Capitolo: prima capisci il metodo, poi lo dimostri.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    const phases = [
      {
        title: explored ? "1. Esplora completata" : "1. Esplora",
        body: `Livello ${exploreLevel}/8. Nessun timer o vite: feedback e indizi preparano il metodo.`,
        color: explored ? "#9ff5a7" : "#9ff5e9",
        imageKey: "story-transition-explore",
      },
      {
        title: explored ? "2. Prova disponibile" : "2. Prova bloccata",
        body: `Livello ${level}/8. Max ${CHAPTER_TRIAL_ERROR_BUDGET} errori, circa ${minutes} min: supera per sbloccare.`,
        color: explored ? "#f7d37a" : "#8aa0a8",
        imageKey: "story-transition-trial",
      },
    ];
    phases.forEach((phase, index) => {
      const cardW = 386;
      const x = 74 + index * 408;
      this.add.rectangle(x, 542, cardW, 70, 0x07151d, 0.72).setOrigin(0).setStrokeStyle(1, index === 0 ? 0x6be7d6 : 0xf6c85f, explored || index === 0 ? 0.45 : 0.22);
      if (this.textures.exists(phase.imageKey)) {
        this.add.image(x + 54, 577, phase.imageKey)
          .setDisplaySize(84, 48)
          .setAlpha(explored || index === 0 ? 0.86 : 0.34);
        this.add.rectangle(x + 12, 553, 84, 48, 0x02070b, 0.08)
          .setOrigin(0)
          .setStrokeStyle(1, index === 0 ? 0x6be7d6 : 0xf6c85f, explored || index === 0 ? 0.22 : 0.12);
      }
      this.add.text(x + 112, 552, phase.title, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: phase.color,
        fontStyle: "bold",
      });
      this.add.text(x + 112, 576, phase.body, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#c7dce7",
        wordWrap: { width: cardW - 128 },
        lineSpacing: 2,
      });
    });

    if (!explored) {
      new Button(this, 1040, 560, "Esplora il Capitolo ▸", () => this.showChapterIntro(chapter, "explore"), {
        width: 300,
        height: 52,
        fill: 0x173b36,
        stroke: 0x6be7d6,
        fontSize: 17,
        soundKey: "missionStart",
      });
      new Button(this, 1040, 620, "Prova dopo Esplora", () => undefined, {
        width: 300,
        height: 38,
        fill: 0x263743,
        stroke: 0xf6c85f,
        fontSize: 12,
      }).setEnabled(false);
      return;
    }

    new Button(this, 1040, 560, "Affronta la Prova ▸", () => this.showChapterIntro(chapter, "trial"), {
      width: 300,
      height: 52,
      fill: 0x1f5a51,
      stroke: 0xf6c85f,
      fontSize: 17,
      soundKey: "missionStart",
    });
    new Button(this, 1040, 620, "Riesplora senza pressione", () => this.showChapterIntro(chapter, "explore"), {
      width: 300,
      height: 38,
      fill: 0x142736,
      stroke: 0x6be7d6,
      fontSize: 12,
    });
  }

  private showChapterIntro(chapter: CampaignChapter, phase: "explore" | "trial"): void {
    const explore = phase === "explore";
    const modal = this.add.container(0, 0).setDepth(2000);
    modal.add(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.82).setInteractive());
    modal.add(this.add.rectangle(640, 360, 980, 456, 0x07151d, 0.99).setStrokeStyle(2, explore ? 0x6be7d6 : 0xf6c85f, 0.8));
    this.addStoryBeatArt(modal, chapter, "intro", 366, 342);
    modal.add(this.add.text(552, 164, chapter.location.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    modal.add(this.add.text(552, 190, explore ? `${chapter.title} · Esplora` : `${chapter.title} · Prova`, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: explore ? "#9ff5e9" : "#f6c85f",
      fontStyle: "bold",
    }));
    this.addPhaseTransitionBadge(modal, phase, 1064, 196);
    const body = explore
      ? `${chapter.intro}\n\nFase Esplora: niente timer e niente vite. Completa la stanza per preparare la Prova del Capitolo.`
      : `${chapter.intro}\n\nFase Prova: ora conta la precisione. Supera timer ed errori per sbloccare il capitolo successivo.`;
    modal.add(this.add.text(552, 244, body, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#eaf4f8",
      wordWrap: { width: 506 },
      lineSpacing: 7,
    }));
    audioManager.play("panelOpen");
    const back = new Button(this, 574, 524, "Indietro", () => modal.destroy(true), {
      width: 180,
      height: 50,
      fill: 0x263743,
    });
    back.setDepth(2001);
    modal.add(back);
    const enter = new Button(this, 822, 524, explore ? "Inizia Esplora ▸" : "Inizia la Prova ▸", () => {
      if (explore) {
        this.startChapterExplore(chapter);
      } else {
        this.startChapterTrial(chapter);
      }
    }, {
      width: 280,
      height: 50,
      fill: explore ? 0x173b36 : 0x1f5a51,
      stroke: explore ? 0x6be7d6 : 0xf6c85f,
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

  private drawStoryClues(completedChapters: number, x: number, y: number): void {
    const clues = [
      { key: "story-clue-blackout-signal", label: "Firma blackout", unlockAt: 1 },
      { key: "story-clue-archive-record", label: "Archivio ferito", unlockAt: 4 },
      { key: "story-clue-sabotage-route", label: "Rotta esterna", unlockAt: 5 },
    ];

    this.add.text(x, y, "Indizi", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    clues.forEach((clue, index) => {
      const cardW = 152;
      const cardH = 54;
      const cardX = x + index * 162;
      const cardY = y + 18;
      const unlocked = completedChapters >= clue.unlockAt;
      const stroke = unlocked ? 0x6be7d6 : 0x304653;
      this.add.rectangle(cardX, cardY, cardW, cardH, 0x07151d, unlocked ? 0.78 : 0.48)
        .setOrigin(0)
        .setStrokeStyle(1, stroke, unlocked ? 0.42 : 0.5);

      if (unlocked && this.textures.exists(clue.key)) {
        this.add.image(cardX + cardW / 2, cardY + cardH / 2, clue.key)
          .setDisplaySize(cardW - 4, cardH - 4)
          .setAlpha(0.78);
        this.add.rectangle(cardX + 2, cardY + cardH - 19, cardW - 4, 17, 0x02070b, 0.72).setOrigin(0);
        this.add.text(cardX + 8, cardY + cardH - 17, clue.label, {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#f5fbff",
          fontStyle: "bold",
        });
        return;
      }

      this.add.circle(cardX + cardW / 2, cardY + 22, 9, 0x1d3441, 0.75).setStrokeStyle(1, 0x6be7d6, 0.22);
      this.add.text(cardX + cardW / 2, cardY + 38, "Da scoprire", {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#7d9098",
        fontStyle: "bold",
      }).setOrigin(0.5);
    });
  }

  private addPhaseTransitionBadge(modal: Phaser.GameObjects.Container, phase: "explore" | "trial", x: number, y: number): void {
    const explore = phase === "explore";
    const key = explore ? "story-transition-explore" : "story-transition-trial";
    const stroke = explore ? 0x6be7d6 : 0xf6c85f;
    modal.add(this.add.rectangle(x, y, 126, 70, 0x02070b, 0.72).setStrokeStyle(1, stroke, 0.42));

    if (this.textures.exists(key)) {
      modal.add(this.add.image(x, y, key).setDisplaySize(120, 64).setAlpha(0.86));
    }

    modal.add(this.add.rectangle(x, y + 22, 120, 20, 0x02070b, 0.68));
    modal.add(this.add.text(x, y + 14, explore ? "ESPLORA" : "PROVA", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: explore ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
  }

  /** Launches the low-pressure chapter exploration that unlocks the trial. */
  private startChapterExplore(chapter: CampaignChapter): void {
    audioManager.stopMusic();
    saveSystem.load();
    saveSystem.pauseActiveProceduralRun();
    saveSystem.setProceduralRun(buildChapterExploreRun(chapter.missionId));
    void startScene(this, "ProceduralMissionScene");
  }

  /**
   * Launches the graded "Prova del Capitolo": a mixed-subject trial at the
   * chapter's fixed level with the 3-error budget and time limit. Passing it
   * (handled in ProceduralMissionScene) sets the chapter flag and unlocks the
   * next chapter; failing sends the player back here.
   */
  private startChapterTrial(chapter: CampaignChapter): void {
    audioManager.stopMusic();
    saveSystem.load();
    saveSystem.pauseActiveProceduralRun();
    saveSystem.setProceduralRun(buildChapterTrialRun(chapter.missionId));
    void startScene(this, "ProceduralMissionScene");
  }

  /** Optional: replay the hand-crafted themed episode (does not gate progress). */
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
    const phase = Phaser.Math.Clamp(completedChapters, 0, 6);
    return [
      "story-phase-00-blackout-bg",
      "story-phase-01-energy-bg",
      "story-phase-02-life-bg",
      "story-phase-03-production-bg",
      "story-phase-04-restored-bg",
      "story-phase-05-signal-bg",
      "story-phase-06-city-restored-bg",
    ][phase] ?? "story-academy-hub-bg";
  }
}
