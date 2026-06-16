import Phaser from "phaser";
import { competencyTracker } from "../core/CompetencyTracker";
import { formatDuration, proceduralScoring } from "../core/ProceduralScoring";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { DifficultyLevel, ProceduralRunSave } from "../procedural/ProceduralTypes";
import type { JournalEntry } from "../types/gameTypes";
import { Button } from "../ui/Button";
import { JournalPanel } from "../ui/JournalPanel";
import { VisualKit } from "../ui/VisualKit";

export class JournalScene extends Phaser.Scene {
  constructor() {
    super("JournalScene");
  }

  create(): void {
    this.cameras.main.setBackgroundColor("#071018");
    this.drawBackground();

    this.add.text(76, 50, "Diario di bordo", {
      fontFamily: "Inter, Arial",
      fontSize: "42px",
      color: "#f5fbff",
      fontStyle: "bold",
    });

    const entry = this.normalizeEntry(saveSystem.data.journalEntries.at(-1));
    if (entry) {
      new JournalPanel(this, 76, 122, entry);
    } else {
      this.add.rectangle(76, 122, 900, 320, 0x0c1821, 0.93).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.4);
      this.add.text(
        112,
        168,
        "Il diario è pronto, ma la prima missione non è ancora conclusa.\nRientra nel laboratorio e raccogli indizi.",
        {
          fontFamily: "Inter, Arial",
          fontSize: "24px",
          color: "#d9eaf1",
          wordWrap: { width: 780 },
          lineSpacing: 8,
        },
      );
    }

    this.drawCompetencySummary();

    new Button(this, 166, 672, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 176,
      height: 48,
      fill: 0x263743,
    });
    new Button(this, 404, 672, "Nuova stanza", () => {
      if (!saveSystem.data.proceduralRun || saveSystem.data.proceduralRun.completedAt) {
        this.createProceduralRun();
      }
      void startScene(this, this.getContinueScene());
    }, { width: 260, height: 48, fill: 0x173b36 });
  }

  private drawBackground(): void {
    VisualKit.background(this, "archive");
    for (let index = 0; index < 28; index += 1) {
      const glow = this.add.image(Phaser.Math.Between(40, 1240), Phaser.Math.Between(40, 690), "soft-glow");
      glow.setTint(index % 3 === 0 ? 0xf6c85f : 0x6be7d6).setAlpha(0.04).setScale(Phaser.Math.FloatBetween(1.2, 3.4));
    }
    VisualKit.vignette(this);
  }

  private getContinueScene(): string {
    return "ProceduralMissionScene";
  }

  private createProceduralRun(): void {
    const previousDifficulty = saveSystem.data.proceduralRun?.difficulty ?? 1;
    const nextDifficulty = Math.min(8, previousDifficulty + 1) as DifficultyLevel;
    const focus = saveSystem.data.proceduralRun?.focus ?? ["libera"];
    const mission = proceduralDirector.generateFreshMission(nextDifficulty, focus);
    const previousMode = saveSystem.data.proceduralRun ? proceduralRunRules.modeFor(saveSystem.data.proceduralRun) : "mission";
    const mode = previousMode === "training" && proceduralRunRules.focusFor({ focus }) !== "libera" ? "training" : "mission";
    const startedAt = new Date().toISOString();
    const timeLimitMs = mode === "mission" ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length)) : undefined;
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus,
      mode,
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: mode === "mission" ? proceduralRunRules.maxLives : undefined,
      maxLives: mode === "mission" ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      deadlineAt: timeLimitMs ? proceduralRunRules.deadlineFrom(startedAt, timeLimitMs) : undefined,
      startedAt,
    };
    saveSystem.setProceduralRun(run);
  }

  private normalizeEntry(entry: JournalEntry | undefined): JournalEntry | undefined {
    if (!entry || !entry.id.startsWith("procedural-summary-")) {
      return entry;
    }
    const run = saveSystem.data.proceduralRun;
    const difficulty = run?.difficulty ?? this.extractDifficulty(entry);
    const nextDifficulty = Math.min(8, difficulty + 1);
    const solvedCount = run?.solvedPuzzleIds.length ?? this.extractSolvedCount(entry);
    const requiredCount = run?.mission.objectives.length ?? 5;
    const hints = run?.hintsUsed ?? this.extractHints(entry);
    const seed = run?.seed ?? entry.id.replace("procedural-summary-", "");
    const focus = run?.focus.find((item) => ["matematica", "italiano", "inglese", "elettronica", "coding", "musica"].includes(item)) ?? "libera";
    const elapsed = run?.completedAt ? new Date(run.completedAt).getTime() - new Date(run.startedAt).getTime() : 0;
    return {
      ...entry,
      title: "Missione completata",
      lines: [
        `Porta aperta: ${run?.mission.title ?? entry.title} stabilizzata.`,
        `Seed: ${seed}`,
        `Focus ${proceduralScoring.domainLabel(focus)}. Difficoltà completata ${difficulty}; prossima consigliata ${nextDifficulty}.`,
        `Sistemi risolti ${solvedCount}/${requiredCount}. Indizi ${hints}. Tempo ${elapsed > 0 ? formatDuration(elapsed) : "non registrato"}.`,
        `Punteggio formativo ${run?.score?.total ?? 0}: cresce con difficoltà, precisione e velocità ragionata.`,
        "NORA ha aperto un nuovo corridoio instabile: la prossima stanza usa regole simili, ma vincoli più stretti.",
      ],
    };
  }

  private extractDifficulty(entry: JournalEntry): number {
    const text = entry.lines.join(" ");
    return Number(text.match(/Difficoltà:\s*(\d+)/)?.[1] ?? 1);
  }

  private extractSolvedCount(entry: JournalEntry): number {
    const solvedLine = entry.lines.find((line) => line.startsWith("Puzzle risolti:"));
    return solvedLine ? solvedLine.split(",").length : 5;
  }

  private extractHints(entry: JournalEntry): number {
    const text = entry.lines.join(" ");
    return Number(text.match(/Indizi usati:\s*(\d+)/)?.[1] ?? 0);
  }

  private drawCompetencySummary(): void {
    const panelX = 952;
    const panelY = 122;
    this.add.rectangle(panelX, panelY, 286, 456, 0x0c1821, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.38);
    this.add.text(panelX + 22, panelY + 20, "Risultato", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const run = saveSystem.data.proceduralRun;
    const completed = Boolean(run?.completedAt);
    const mode = run ? proceduralRunRules.modeFor(run) : "mission";
    this.add.text(panelX + 22, panelY + 62, completed ? (mode === "training" ? "Allenamento completato" : "Missione completata") : "Run in corso", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: completed ? "#f7d37a" : "#d9eaf1",
      fontStyle: "bold",
    });
    const focus = run ? proceduralRunRules.focusFor(run) : "libera";
    const record = run ? saveSystem.data.trainingRecords?.[proceduralRunRules.trainingRecordKey(focus, run.difficulty)] : undefined;
    const resultLine = run && mode === "training"
      ? `Difficoltà ${run.difficulty}  |  Indizi ${run.hintsUsed}\nFocus ${proceduralScoring.domainLabel(focus)}\nVoto ${run.trainingResult?.grade ?? record?.lastGrade ?? "-"} /10\nRecord ${record ? formatDuration(record.bestTimeMs) : "non ancora"}\n${run.trainingResult?.nextGoal ?? "Obiettivo: ripeti con un nuovo seed e prova una strategia piu pulita."}`
      : run
        ? `Difficoltà ${run.difficulty}  |  Indizi ${run.hintsUsed}\nFocus ${proceduralScoring.domainLabel(focus)}\nPunti ${run.score?.total ?? 0}`
        : "Nessuna run registrata";
    this.add.text(panelX + 22, panelY + 94, resultLine, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#c9dce6",
      wordWrap: { width: 238 },
    });

    const competencyStartY = mode === "training" ? 218 : 184;
    this.add.text(panelX + 22, panelY + competencyStartY - 42, "Competenze allenate", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const activeCompetencyIds = new Set(run?.mission.competencies ?? []);
    const competencies = competencyTracker
      .getKnownCompetencies()
      .filter((competency) => competency.score > 0 && (activeCompetencyIds.size === 0 || activeCompetencyIds.has(competency.id)))
      .slice(0, 7);

    if (competencies.length === 0) {
      this.add.text(panelX + 22, panelY + competencyStartY, "Completa una run per vedere qui le competenze emerse.", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#c9dce6",
        wordWrap: { width: 238 },
        lineSpacing: 4,
      });
      return;
    }

    competencies.forEach((competency, index) => {
      const y = panelY + competencyStartY + index * 30;
      this.add.circle(panelX + 32, y + 9, 8, 0xf6c85f, 0.95);
      this.add.text(panelX + 50, y, `${competency.label}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        wordWrap: { width: 178 },
      });
      this.add.text(panelX + 226, y, `${competency.score}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
        fontStyle: "bold",
      });
    });

    this.add.text(panelX + 22, panelY + 426, "Prossimo passo: una nuova stanza con vincoli più stretti.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      wordWrap: { width: 238 },
    });
  }
}
