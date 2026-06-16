import Phaser from "phaser";
import { mathStudyPages } from "../data/mathStudyPages";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import type { DifficultyLevel, ProceduralRunSave } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

const TRAINING_DIFFICULTY_KEY = "eliQuest.trainingDifficulty";

export class MathStudyScene extends Phaser.Scene {
  private pageIndex = 0;
  private listOffset = 0;

  constructor() {
    super("MathStudyScene");
  }

  init(data?: { pageId?: string; listOffset?: number }): void {
    if (data?.pageId) {
      const index = mathStudyPages.findIndex((page) => page.id === data.pageId);
      if (index >= 0) {
        this.pageIndex = index;
        this.listOffset = Math.max(0, Math.min(data.listOffset ?? index, mathStudyPages.length - 8));
      }
    }
  }

  create(): void {
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    this.drawHeader();
    this.drawPageList();
    this.drawStudyPage();
    this.drawFooter();
    VisualKit.vignette(this);
  }

  private drawHeader(): void {
    this.add.rectangle(640, 62, 1216, 86, 0x07151d, 0.82).setStrokeStyle(2, 0x6be7d6, 0.28);
    this.add.text(56, 28, "Atlante matematico", {
      fontFamily: "Inter, Arial",
      fontSize: "36px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(56, 74, "Pagine brevi da studiare: a cosa serve il concetto, come si calcola, esempio guidato e trappole tipiche.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#c7dce7",
      wordWrap: { width: 900 },
    });
    new Button(this, 1160, 58, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 132,
      height: 44,
      fill: 0x263743,
      fontSize: 15,
    });
  }

  private drawPageList(): void {
    this.add.rectangle(178, 388, 292, 520, 0x07151d, 0.86).setStrokeStyle(2, 0x6be7d6, 0.32);
    this.add.text(54, 148, "Concetti", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(54, 178, `${mathStudyPages.length} pagine | scegli e studia`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
    });

    const visiblePages = mathStudyPages.slice(this.listOffset, this.listOffset + 8);
    visiblePages.forEach((page, localIndex) => {
      const index = this.listOffset + localIndex;
      const selected = index === this.pageIndex;
      new Button(this, 178, 224 + localIndex * 48, page.title, () => {
        this.pageIndex = index;
        this.scene.restart({ pageId: page.id, listOffset: this.listOffset });
      }, {
        width: 248,
        height: 38,
        fill: selected ? 0x1f5a51 : 0x142736,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
        fontSize: 11,
        wordWrapWidth: 220,
      });
    });

    new Button(this, 112, 632, "Su", () => {
      this.listOffset = Math.max(0, this.listOffset - 4);
      this.scene.restart({ pageId: mathStudyPages[this.pageIndex].id, listOffset: this.listOffset });
    }, { width: 100, height: 36, fill: 0x263743, fontSize: 13 });
    new Button(this, 244, 632, "Giù", () => {
      this.listOffset = Math.min(Math.max(0, mathStudyPages.length - 8), this.listOffset + 4);
      this.scene.restart({ pageId: mathStudyPages[this.pageIndex].id, listOffset: this.listOffset });
    }, { width: 100, height: 36, fill: 0x263743, fontSize: 13 });
  }

  private drawStudyPage(): void {
    const page = mathStudyPages[this.pageIndex];
    this.add.rectangle(782, 388, 820, 520, 0x07151d, 0.88).setStrokeStyle(2, 0x6be7d6, 0.34);
    this.add.text(402, 136, page.title, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 620 },
    });
    this.add.text(404, 174, page.subtitle, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 630 },
    });
    this.add.text(1024, 142, `Livelli ${page.levelRange[0]}-${page.levelRange[1]}`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(1024, 168, page.competencies.map((item) => `#${item.replace("matematica.", "")}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c7dce7",
      wordWrap: { width: 180 },
      lineSpacing: 3,
    });

    this.addStudyBlock(404, 224, 360, 120, "A cosa serve", page.whatFor, "#9ff5e9");
    this.addStudyBlock(786, 224, 360, 120, "Come si calcola", page.howTo, "#9ff5e9");

    this.add.rectangle(584, 402, 360, 170, 0x0b1a24, 0.82).setStrokeStyle(1, 0x6be7d6, 0.22);
    this.add.text(422, 330, "Procedura", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
    this.add.text(422, 358, page.procedure.map((step, index) => `${index + 1}. ${step}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 320, useAdvancedWrap: true },
      lineSpacing: 5,
    });

    this.add.rectangle(966, 402, 360, 170, 0x0b1a24, 0.82).setStrokeStyle(1, 0xf6c85f, 0.28);
    this.add.text(804, 330, "Esempio guidato", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    });
    this.add.text(804, 358, page.example.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      wordWrap: { width: 322, useAdvancedWrap: true },
      lineSpacing: 3,
    });
    this.add.text(804, 420, [...page.example.steps, page.example.answer].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 322, useAdvancedWrap: true },
      lineSpacing: 4,
    });

    this.add.rectangle(584, 568, 360, 104, 0x07151d, 0.82).setStrokeStyle(1, 0xffb36b, 0.24);
    this.add.text(422, 524, "Attenzione", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#ffb36b",
      fontStyle: "bold",
    });
    this.add.text(422, 550, page.watchOut.map((item) => `- ${item}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#d9eaf1",
      wordWrap: { width: 320, useAdvancedWrap: true },
      lineSpacing: 4,
    });

    this.add.rectangle(966, 568, 360, 104, 0x07151d, 0.82).setStrokeStyle(1, 0x6be7d6, 0.24);
    this.add.text(804, 524, "Nel gioco", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(804, 550, page.missionUse, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 320, useAdvancedWrap: true },
      lineSpacing: 4,
    });
  }

  private drawFooter(): void {
    const prevIndex = (this.pageIndex - 1 + mathStudyPages.length) % mathStudyPages.length;
    const nextIndex = (this.pageIndex + 1) % mathStudyPages.length;
    new Button(this, 472, 672, "Pagina precedente", () => {
      this.pageIndex = prevIndex;
      this.scene.restart({ pageId: mathStudyPages[prevIndex].id, listOffset: this.listOffsetFor(prevIndex) });
    }, { width: 214, height: 42, fill: 0x263743, fontSize: 14 });
    new Button(this, 712, 672, "Pagina successiva", () => {
      this.pageIndex = nextIndex;
      this.scene.restart({ pageId: mathStudyPages[nextIndex].id, listOffset: this.listOffsetFor(nextIndex) });
    }, { width: 214, height: 42, fill: 0x263743, fontSize: 14 });
    new Button(this, 1018, 672, "Allenati su matematica", () => this.startMathTraining(), {
      width: 286,
      height: 42,
      fill: 0x173b36,
      fontSize: 14,
    });
  }

  private addStudyBlock(x: number, y: number, width: number, height: number, title: string, body: string, color: string): void {
    this.add.rectangle(x + width / 2, y + height / 2, width, height, 0x0b1a24, 0.82).setStrokeStyle(1, 0x6be7d6, 0.22);
    this.add.text(x + 18, y + 14, title, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color,
      fontStyle: "bold",
    });
    this.add.text(x + 18, y + 42, body, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 36, useAdvancedWrap: true },
      lineSpacing: 4,
    });
  }

  private startMathTraining(): void {
    const page = mathStudyPages[this.pageIndex];
    const level = this.studyLevelFor(page.levelRange);
    const mission = proceduralDirector.generateFreshMission(level, ["matematica"]);
    const startedAt = new Date().toISOString();
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["matematica"],
      mode: "training",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      startedAt,
    };
    saveSystem.setProceduralRun(run);
    void startScene(this, "ProceduralMissionScene");
  }

  private studyLevelFor(range: [number, number]): DifficultyLevel {
    const stored = Number(this.safeStorageGet(TRAINING_DIFFICULTY_KEY));
    const preferred = Number.isFinite(stored) && stored >= range[0] && stored <= range[1]
      ? stored
      : range[0];
    return Math.max(1, Math.min(8, Math.round(preferred))) as DifficultyLevel;
  }

  private safeStorageGet(key: string): string | null {
    try {
      return localStorage.getItem(key);
    } catch {
      return null;
    }
  }

  private listOffsetFor(index: number): number {
    if (index < this.listOffset) {
      return Math.max(0, index);
    }
    if (index >= this.listOffset + 8) {
      return Math.max(0, Math.min(index - 7, mathStudyPages.length - 8));
    }
    return this.listOffset;
  }
}
