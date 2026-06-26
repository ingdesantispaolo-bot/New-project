import Phaser from "phaser";
import { mathStudyPages } from "../data/mathStudyPages";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { difficultyModel } from "../procedural/DifficultyModel";
import { MathPuzzleGenerator } from "../procedural/generators/MathPuzzleGenerator";
import { Random } from "../procedural/Random";
import { saveSystem } from "../core/SaveSystem";
import { exerciseDirector } from "../core/ExerciseDirector";
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
    this.add.text(56, 74, "Programma completo della scuola media: definizione, formule, regole ed esempio per ogni argomento.", {
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
        stroke: selected ? 0xf6c85f : this.areaColor(page.area),
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

  private areaColor(area: string): number {
    if (area === "Numeri") return 0x6be7d6;
    if (area === "Geometria") return 0xf6c85f;
    if (area === "Relazioni e funzioni") return 0x9f8cff;
    return 0x70d68a;
  }

  private drawStudyPage(): void {
    const page = mathStudyPages[this.pageIndex];
    const accent = this.areaColor(page.area);
    this.add.rectangle(782, 388, 820, 520, 0x07151d, 0.9).setOrigin(0.5).setStrokeStyle(2, accent, 0.42);

    this.add.text(402, 138, page.title, {
      fontFamily: "Inter, Arial",
      fontSize: "27px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 600 },
    });
    // Area badge + level range (top-right).
    this.add.rectangle(1086, 150, 168, 26, accent, 0.2).setStrokeStyle(1, accent, 0.8);
    this.add.text(1086, 150, page.area, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5);
    this.add.text(1086, 178, `Livelli ${page.levelRange[0]}-${page.levelRange[1]}  ·  ${page.tags.join(" · ")}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
    }).setOrigin(0.5);

    // Definition (full width, prominent).
    this.add.rectangle(404, 196, 760, 56, 0x0b1a24, 0.9).setOrigin(0).setStrokeStyle(1, accent, 0.3);
    this.add.text(420, 210, page.definition, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#eaf4f8",
      wordWrap: { width: 728 },
      lineSpacing: 4,
    });

    // FORMULE — the schematic core, each formula on its own chip.
    this.add.rectangle(404, 264, 372, 212, 0x081722, 0.95).setOrigin(0).setStrokeStyle(2, 0xf6c85f, 0.5);
    this.add.text(420, 274, "FORMULE", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    page.formulas.slice(0, 6).forEach((formula, index) => {
      const y = 306 + index * 27;
      this.add.rectangle(420, y, 340, 23, 0x12303a, 0.9).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.18);
      this.add.text(430, y + 3, formula, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#ffe6a0",
        wordWrap: { width: 322 },
      });
    });

    // REGOLE — precise steps.
    this.add.rectangle(792, 264, 388, 212, 0x0b1a24, 0.9).setOrigin(0).setStrokeStyle(1, accent, 0.28);
    this.add.text(808, 274, "REGOLE", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: String(accent === 0xf6c85f ? "#f7d37a" : "#9ff5e9"),
      fontStyle: "bold",
    });
    this.add.text(808, 306, page.rules.map((rule, index) => `${index + 1}. ${rule}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 356, useAdvancedWrap: true },
      lineSpacing: 7,
    });

    // ESEMPIO — guided example.
    this.add.rectangle(404, 488, 470, 158, 0x0b1a24, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.28);
    this.add.text(420, 498, "ESEMPIO", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#6be7d6",
      fontStyle: "bold",
    });
    this.add.text(420, 524, page.example.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 438 },
    });
    this.add.text(420, 552, page.example.steps.map((step) => `→ ${step}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 438 },
      lineSpacing: 4,
    });
    this.add.text(420, 620, `= ${page.example.answer}`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5a7",
      fontStyle: "bold",
    });

    // ATTENZIONE — common mistakes.
    this.add.rectangle(890, 488, 290, 158, 0x1a1410, 0.9).setOrigin(0).setStrokeStyle(1, 0xffb36b, 0.4);
    this.add.text(906, 498, "ATTENZIONE", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#ffb36b",
      fontStyle: "bold",
    });
    this.add.text(906, 528, page.watchOut.map((item) => `⚠ ${item}`).join("\n\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f3d9c4",
      wordWrap: { width: 258, useAdvancedWrap: true },
      lineSpacing: 4,
    });
  }

  private drawFooter(): void {
    const prevIndex = (this.pageIndex - 1 + mathStudyPages.length) % mathStudyPages.length;
    const nextIndex = (this.pageIndex + 1) % mathStudyPages.length;
    new Button(this, 408, 672, "Pagina precedente", () => {
      this.pageIndex = prevIndex;
      this.scene.restart({ pageId: mathStudyPages[prevIndex].id, listOffset: this.listOffsetFor(prevIndex) });
    }, { width: 176, height: 42, fill: 0x263743, fontSize: 12 });
    new Button(this, 598, 672, "Pagina successiva", () => {
      this.pageIndex = nextIndex;
      this.scene.restart({ pageId: mathStudyPages[nextIndex].id, listOffset: this.listOffsetFor(nextIndex) });
    }, { width: 176, height: 42, fill: 0x263743, fontSize: 12 });
    new Button(this, 826, 672, "Officina dei Grafici", () => this.startGraphWorkshop(), {
      width: 244,
      height: 42,
      fill: 0x173b36,
      stroke: 0xf6c85f,
      fontSize: 13,
    });
    new Button(this, 1088, 672, "Allenamento misto", () => this.startMathTraining(), {
      width: 244,
      height: 42,
      fill: 0x173b36,
      fontSize: 13,
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
    void startScene(this, "ProceduralMissionScene", { autoOpenPuzzle: "math" });
  }

  private startGraphWorkshop(): void {
    const page = mathStudyPages[this.pageIndex];
    const level = Math.max(3, this.studyLevelFor(page.levelRange)) as DifficultyLevel;
    const mission = proceduralDirector.generateFreshMission(level, ["matematica"]);
    const preset = difficultyModel.getPreset(level);
    const graphPuzzle = exerciseDirector.enrichMath(
      new MathPuzzleGenerator().generateGraphWorkshop(
        new Random(`${mission.seed}:direct-graph-workshop:${Date.now()}`),
        preset,
      ),
      level,
    );
    mission.puzzles.math = graphPuzzle;
    if (mission.focusChallenges?.length) {
      mission.focusChallenges = mission.focusChallenges.map((challenge, index) => {
        if (challenge.kind !== "math") return challenge;
        const puzzle = exerciseDirector.enrichMath(
          new MathPuzzleGenerator().generateGraphWorkshop(
            new Random(`${mission.seed}:graph-series:${index}:${Date.now()}`),
            preset,
          ),
          level,
        );
        return {
          ...challenge,
          title: `Officina grafica ${index + 1}`,
          description: puzzle.graphWorkshop?.objective ?? "Modifica i parametri e certifica il grafico.",
          puzzle,
        };
      });
      mission.objectives = mission.focusChallenges.map((challenge) => ({
        id: `procedural-${challenge.id}`,
        label: challenge.title,
        description: challenge.description,
        competencies: challenge.puzzle.competencies,
      }));
      const firstGraph = mission.focusChallenges.find((challenge) => challenge.kind === "math");
      if (firstGraph?.kind === "math") mission.puzzles.math = firstGraph.puzzle;
      mission.competencies = Array.from(new Set(mission.focusChallenges.flatMap((challenge) => challenge.puzzle.competencies)));
    }
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
    void startScene(this, "ProceduralMissionScene", { autoOpenPuzzle: "math" });
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
