import Phaser from "phaser";
import { theorySubjectLabels, theorySubjectOrder, theoryTopics, type TheorySubject, type TheoryTopic } from "../data/theoryCatalog";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import { difficultyModel } from "../procedural/DifficultyModel";
import { LanguageCorruptionGenerator } from "../procedural/generators/LanguageCorruptionGenerator";
import { MathPuzzleGenerator } from "../procedural/generators/MathPuzzleGenerator";
import { Random } from "../procedural/Random";
import { saveSystem } from "../core/SaveSystem";
import { exerciseDirector } from "../core/ExerciseDirector";
import { startScene } from "../core/SceneNavigator";
import type { DifficultyLevel, ProceduralPuzzleKind, ProceduralRunSave } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { drawTheoryVisual } from "../ui/TheoryVisual";
import { VisualKit } from "../ui/VisualKit";

const TRAINING_DIFFICULTY_KEY = "eliQuest.trainingDifficulty";
const studyPages = theoryTopics;
type TheoryFilter = TheorySubject | "tutte";

export class MathStudyScene extends Phaser.Scene {
  private pageIndex = 0;
  private listOffset = 0;
  private subjectFilter: TheoryFilter = "tutte";

  constructor() {
    super("MathStudyScene");
  }

  init(data?: { pageId?: string; listOffset?: number; subjectFilter?: TheoryFilter }): void {
    if (data?.subjectFilter) this.subjectFilter = data.subjectFilter;
    if (data?.pageId) {
      const index = studyPages.findIndex((page) => page.id === data.pageId);
      if (index >= 0) {
        this.pageIndex = index;
        this.subjectFilter = data?.subjectFilter ?? studyPages[index].subject;
        this.listOffset = Math.max(0, Math.min(data.listOffset ?? 0, this.maxListOffset()));
      }
    }
  }

  create(): void {
    this.normalizeSelection();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    this.drawHeader();
    this.drawPageList();
    this.drawStudyPage();
    this.drawFooter();
    VisualKit.vignette(this);
    placeHiddenAnomaly(this, "MathStudyScene");
  }

  private drawHeader(): void {
    this.add.rectangle(640, 62, 1216, 86, 0x07151d, 0.82).setStrokeStyle(2, 0x6be7d6, 0.28);
    this.add.text(56, 28, "Atlante", {
      fontFamily: "Inter, Arial",
      fontSize: "36px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(56, 74, "Teoria breve e densa per tutte le materie: definizioni, schemi, esempi guidati ed errori tipici.", {
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
    this.drawSubjectFilters();
    this.add.text(54, 226, "Concetti", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    const pages = this.filteredPages();
    this.add.text(54, 256, `${pages.length} pagine | scegli e studia`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
    });

    const visiblePages = pages.slice(this.listOffset, this.listOffset + 8);
    visiblePages.forEach((page, localIndex) => {
      const index = studyPages.indexOf(page);
      const selected = index === this.pageIndex;
      new Button(this, 178, 292 + localIndex * 42, page.title, () => {
        this.pageIndex = index;
        this.scene.restart({ pageId: page.id, listOffset: this.listOffset, subjectFilter: this.subjectFilter });
      }, {
        width: 248,
        height: 34,
        fill: selected ? 0x1f5a51 : 0x142736,
        stroke: selected ? 0xf6c85f : this.areaColor(page),
        fontSize: 11,
        wordWrapWidth: 220,
      });
    });

    new Button(this, 112, 632, "Su", () => {
      this.listOffset = Math.max(0, this.listOffset - 4);
      this.scene.restart({ pageId: studyPages[this.pageIndex].id, listOffset: this.listOffset, subjectFilter: this.subjectFilter });
    }, { width: 100, height: 36, fill: 0x263743, fontSize: 13 });
    new Button(this, 244, 632, "Giù", () => {
      this.listOffset = Math.min(this.maxListOffset(), this.listOffset + 4);
      this.scene.restart({ pageId: studyPages[this.pageIndex].id, listOffset: this.listOffset, subjectFilter: this.subjectFilter });
    }, { width: 100, height: 36, fill: 0x263743, fontSize: 13 });
  }

  private drawSubjectFilters(): void {
    const filters: Array<{ id: TheoryFilter; label: string }> = [
      { id: "tutte", label: "Tutte" },
      ...theorySubjectOrder.map((subject) => ({ id: subject, label: theorySubjectLabels[subject] })),
    ];
    filters.forEach((filter, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      const selected = this.subjectFilter === filter.id;
      new Button(this, 92 + col * 86, 142 + row * 28, filter.label, () => {
        this.subjectFilter = filter.id;
        const firstPage = this.filteredPages()[0] ?? studyPages[0];
        this.pageIndex = studyPages.indexOf(firstPage);
        this.listOffset = 0;
        this.scene.restart({ pageId: firstPage.id, listOffset: 0, subjectFilter: filter.id });
      }, {
        width: 78,
        height: 24,
        fill: selected ? 0x1f5a51 : 0x102632,
        stroke: selected ? 0xf6c85f : 0x2a4756,
        fontSize: 9,
      });
    });
  }

  private areaColor(page: TheoryTopic): number {
    if (page.subject === "matematica") {
      if (page.area === "Geometria") return 0xf6c85f;
      if (page.area === "Relazioni e funzioni") return 0x9f8cff;
      return 0x6be7d6;
    }
    if (page.subject === "italiano") return 0x70d68a;
    if (page.subject === "inglese") return 0x7ad7ff;
    if (page.subject === "elettronica") return 0xffd166;
    if (page.subject === "coding") return 0x9ff5e9;
    if (page.subject === "musica") return 0xcdbfff;
    if (page.subject === "fisica") return 0x8fd3ff;
    if (page.subject === "latino") return 0xf2b880;
    return 0x70d68a;
  }

  private drawStudyPage(): void {
    const page = studyPages[this.pageIndex];
    const accent = this.areaColor(page);
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
    this.add.text(1086, 178, `${theorySubjectLabels[page.subject]} · Profondità ${page.levelRange[0]}-${page.levelRange[1]}  ·  ${page.tags.join(" · ")}`, {
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

    // Core rules — each rule is displayed as a compact chip.
    this.add.rectangle(404, 264, 372, 212, 0x081722, 0.95).setOrigin(0).setStrokeStyle(2, 0xf6c85f, 0.5);
    this.add.text(420, 274, this.coreRulesTitle(page), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    page.coreRules.slice(0, 5).forEach((formula, index) => {
      const y = 306 + index * 31;
      this.add.rectangle(420, y, 340, 28, 0x12303a, 0.9).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.18);
      this.add.text(430, y + 3, formula, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#ffe6a0",
        wordWrap: { width: 322 },
        lineSpacing: 0,
      });
    });

    // Method — precise operating steps.
    this.add.rectangle(792, 264, 388, 212, 0x0b1a24, 0.9).setOrigin(0).setStrokeStyle(1, accent, 0.28);
    this.add.text(808, 274, this.methodTitle(page), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: String(accent === 0xf6c85f ? "#f7d37a" : "#9ff5e9"),
      fontStyle: "bold",
    });
    this.add.text(808, 306, page.method.map((rule, index) => `${index + 1}. ${rule}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 356, useAdvancedWrap: true },
      lineSpacing: 7,
    });

    // Schematic illustration for the topic's visualKind (shared renderer).
    this.add.text(724, 470, "SCHEMA", { fontFamily: "Inter, Arial", fontSize: "11px", color: "#9aaab0", fontStyle: "bold" });
    drawTheoryVisual(this, page, 724, 488, { width: 150, height: 158 });

    // ESEMPIO — guided example.
    this.add.rectangle(404, 488, 300, 158, 0x0b1a24, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.28);
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
      wordWrap: { width: 268 },
    });
    const visibleExampleSteps = page.example.steps.slice(0, 4);
    const hiddenExampleSteps = page.example.steps.length > visibleExampleSteps.length ? "\n..." : "";
    this.add.text(420, 550, `${visibleExampleSteps.map((step) => `→ ${step}`).join("\n")}${hiddenExampleSteps}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 268 },
      lineSpacing: 3,
    });
    this.add.text(420, 628, `= ${page.example.answer}`, {
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
    const page = studyPages[this.pageIndex];
    const pages = this.filteredPages();
    const filteredIndex = Math.max(0, pages.indexOf(page));
    const prevPage = pages[(filteredIndex - 1 + pages.length) % pages.length] ?? page;
    const nextPage = pages[(filteredIndex + 1) % pages.length] ?? page;
    const prevIndex = studyPages.indexOf(prevPage);
    const nextIndex = studyPages.indexOf(nextPage);
    new Button(this, 408, 672, "Pagina precedente", () => {
      this.pageIndex = prevIndex;
      this.scene.restart({ pageId: studyPages[prevIndex].id, listOffset: this.listOffsetFor(prevIndex), subjectFilter: this.subjectFilter });
    }, { width: 176, height: 42, fill: 0x263743, fontSize: 12 });
    new Button(this, 598, 672, "Pagina successiva", () => {
      this.pageIndex = nextIndex;
      this.scene.restart({ pageId: studyPages[nextIndex].id, listOffset: this.listOffsetFor(nextIndex), subjectFilter: this.subjectFilter });
    }, { width: 176, height: 42, fill: 0x263743, fontSize: 12 });
    new Button(this, 826, 672, this.primaryTrainingLabel(page), () => {
      if (page.subject === "italiano" && page.tags.includes("verbi")) this.startItalianVerbTraining();
      else if (page.subject === "matematica" && (page.tags.includes("funzioni") || page.tags.includes("punti"))) this.startGraphWorkshop();
      else this.startTopicTraining(page);
    }, {
      width: 244,
      height: 42,
      fill: 0x173b36,
      stroke: 0xf6c85f,
      fontSize: 13,
    });
    new Button(this, 1088, 672, `Percorso ${theorySubjectLabels[page.subject]}`, () => {
      this.startSubjectTraining(page.subject, page.levelRange);
    }, {
      width: 244,
      height: 42,
      fill: 0x173b36,
      fontSize: 13,
    });
  }

  private primaryTrainingLabel(page: TheoryTopic): string {
    if (page.subject === "italiano" && page.tags.includes("verbi")) return "Laboratorio Verbi";
    if (page.subject === "matematica" && (page.tags.includes("funzioni") || page.tags.includes("punti"))) return "Officina dei Grafici";
    return "Allenati su questa scheda";
  }

  private coreRulesTitle(page: TheoryTopic): string {
    if (page.subject === "matematica" || page.subject === "fisica") return "FORMULE / LEGGI";
    if (page.subject === "elettronica") return "PRINCIPI";
    if (page.subject === "coding") return "REGOLE DI STATO";
    if (page.subject === "musica") return "RIFERIMENTI";
    if (page.subject === "latino") return "DESINENZE / CASI";
    if (page.subject === "inglese") return "STRUTTURE";
    return "REGOLE CHIAVE";
  }

  private methodTitle(page: TheoryTopic): string {
    if (page.subject === "inglese") return "PROTOCOLLO";
    if (page.subject === "elettronica") return "DIAGNOSI";
    if (page.subject === "coding") return "TRACING";
    if (page.subject === "musica") return "LETTURA";
    if (page.subject === "latino") return "ANALISI";
    return "METODO";
  }

  private startTopicTraining(page: TheoryTopic): void {
    this.startSubjectTraining(page.subject, page.levelRange, page.linkedPuzzleKinds[0]);
  }

  private startSubjectTraining(subject: TheorySubject, range: [number, number], autoOpenPuzzle?: ProceduralPuzzleKind): void {
    const level = this.studyLevelFor(range);
    const mission = proceduralDirector.generateFreshMission(level, [subject]);
    const startedAt = new Date().toISOString();
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: [subject],
      mode: "training",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      startedAt,
    };
    saveSystem.setProceduralRun(run);
    void startScene(this, "ProceduralMissionScene", { autoOpenPuzzle: autoOpenPuzzle ?? this.defaultPuzzleForSubject(subject) });
  }

  private defaultPuzzleForSubject(subject: TheorySubject): ProceduralPuzzleKind {
    const defaultPuzzleBySubject: Record<TheorySubject, ProceduralPuzzleKind> = {
      matematica: "math",
      italiano: "language",
      inglese: "english",
      elettronica: "circuit",
      coding: "coding",
      musica: "music",
      fisica: "physics",
      latino: "latin",
    };
    return defaultPuzzleBySubject[subject];
  }

  private startMathTraining(): void {
    const page = studyPages[this.pageIndex];
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
    const page = studyPages[this.pageIndex];
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

  private startItalianTraining(): void {
    const page = studyPages[this.pageIndex];
    const level = this.studyLevelFor(page.levelRange);
    const mission = proceduralDirector.generateFreshMission(level, ["italiano"]);
    const startedAt = new Date().toISOString();
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["italiano"],
      mode: "training",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      startedAt,
    };
    saveSystem.setProceduralRun(run);
    void startScene(this, "ProceduralMissionScene", { autoOpenPuzzle: "language" });
  }

  private startItalianVerbTraining(): void {
    const page = studyPages[this.pageIndex];
    const level = this.studyLevelFor(page.levelRange);
    const mission = proceduralDirector.generateFreshMission(level, ["italiano"]);
    const generator = new LanguageCorruptionGenerator();
    const rewriteVerbPuzzle = (salt: string) => generator.generateMinigame(
      new Random(`${mission.seed}:verb-lab:${salt}:${Date.now()}`),
      level,
      ["verb-mastery"],
    );
    mission.puzzles.language = rewriteVerbPuzzle("base");
    if (mission.focusChallenges?.length) {
      mission.focusChallenges = mission.focusChallenges.map((challenge, index) => {
        if (challenge.kind !== "language") return challenge;
        const puzzle = rewriteVerbPuzzle(String(index));
        return {
          ...challenge,
          title: index === 0 ? "Modi e tempi dei verbi" : challenge.title,
          description: index === 0
            ? "Riconosci modo, tempo e persona; poi scegli o scrivi la forma corretta."
            : challenge.description,
          puzzle,
        };
      });
      const firstLanguage = mission.focusChallenges.find((challenge) => challenge.kind === "language");
      if (firstLanguage?.kind === "language") mission.puzzles.language = firstLanguage.puzzle;
      mission.objectives = mission.focusChallenges.map((challenge) => ({
        id: `procedural-${challenge.id}`,
        label: challenge.title,
        description: challenge.description,
        competencies: challenge.puzzle.competencies,
      }));
      mission.competencies = Array.from(new Set(mission.focusChallenges.flatMap((challenge) => challenge.puzzle.competencies)));
    }
    const startedAt = new Date().toISOString();
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["italiano", "italiano.verbi"],
      mode: "training",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      startedAt,
    };
    saveSystem.setProceduralRun(run);
    void startScene(this, "ProceduralMissionScene", { autoOpenPuzzle: "language" });
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
    const filteredIndex = this.filteredPages().findIndex((page) => studyPages.indexOf(page) === index);
    if (filteredIndex < 0) return 0;
    if (filteredIndex < this.listOffset) {
      return Math.max(0, filteredIndex);
    }
    if (filteredIndex >= this.listOffset + 8) {
      return Math.max(0, Math.min(filteredIndex - 7, this.maxListOffset()));
    }
    return this.listOffset;
  }

  private filteredPages(): TheoryTopic[] {
    return this.subjectFilter === "tutte"
      ? studyPages
      : studyPages.filter((page) => page.subject === this.subjectFilter);
  }

  private maxListOffset(): number {
    return Math.max(0, this.filteredPages().length - 8);
  }

  private normalizeSelection(): void {
    const current = studyPages[this.pageIndex] ?? studyPages[0];
    const pages = this.filteredPages();
    if (!current || pages.includes(current)) {
      this.listOffset = Math.min(this.listOffset, this.maxListOffset());
      return;
    }
    const firstPage = pages[0] ?? studyPages[0];
    this.pageIndex = studyPages.indexOf(firstPage);
    this.listOffset = 0;
  }
}
