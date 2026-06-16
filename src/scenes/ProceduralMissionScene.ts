import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { competencyTracker } from "../core/CompetencyTracker";
import { feedbackSystem, type FeedbackMessage } from "../core/FeedbackSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import { mistakeAnalyzer } from "../core/MistakeAnalyzer";
import { missionEngine } from "../core/MissionEngine";
import { formatDuration, proceduralScoring } from "../core/ProceduralScoring";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { circuitFaultTemplates } from "../data/procedural/circuitTemplates";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type {
  CircuitFaultType,
  DifficultyLevel,
  GeneratedFocusChallenge,
  GeneratedCircuitPuzzle,
  GeneratedEnglishPuzzle,
  GeneratedLanguagePuzzle,
  GeneratedMathPuzzle,
  GeneratedMusicPuzzle,
  GeneratedRobotPuzzle,
  GeneratedRoomHotspot,
  GridCommand,
  GridFacing,
  ProceduralRunSave,
} from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { outcomeFeedback, type OutcomeTone } from "../ui/OutcomeFeedback";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";
import { CircuitConsole, type CircuitConsoleModel } from "./procedural/components/CircuitConsole";
import { LanguageRepairConsole, type LanguageRepairModel } from "./procedural/components/LanguageRepairConsole";
import { MathTerminal, type MathTerminalModel } from "./procedural/components/MathTerminal";
import { MissionDependencyGraph } from "./procedural/components/MissionDependencyGraph";
import { RobotConsole } from "./procedural/components/RobotConsole";
import { isProceduralPuzzleSolved, proceduralPuzzleOrder, proceduralRequiredPuzzleIds, puzzleKindFromId, type ProceduralPuzzleId } from "./procedural/ProceduralMissionLayout";
import { ProceduralMissionView } from "./procedural/ProceduralMissionView";

const commandLabels: Record<GridCommand, string> = {
  MOVE_FORWARD: "Avanza",
  TURN_LEFT: "Gira SX",
  TURN_RIGHT: "Gira DX",
  PICK_UP: "Raccogli",
  EXIT: "Esci",
};

const faultLabels: Record<CircuitFaultType, string> = Object.fromEntries(
  circuitFaultTemplates.map((fault) => [fault.type, fault.label]),
) as Record<CircuitFaultType, string>;

const repairLabels: Record<CircuitFaultType, string> = {
  "missing-wire": "Collega filo",
  "open-switch": "Chiudi switch",
  "reversed-led": "Inverti LED",
  "missing-resistor": "Inserisci R",
  "disconnected-component": "Ricollega",
  "sensor-unpowered": "Alimenta sensore",
  "capacitor-discharged": "Carica condens.",
  "short-circuit": "Isola corto",
  "parallel-branch-open": "Chiudi ramo B",
  "wrong-resistor-value": "Cambia valore R",
  "relay-not-armed": "Arma relè",
  "loose-ground": "Fissa massa",
};

export class ProceduralMissionScene extends Phaser.Scene {
  private run!: ProceduralRunSave;
  private dependencies = new MissionDependencyGraph();
  private feedbackText?: Phaser.GameObjects.Text;
  private objectiveText?: Phaser.GameObjects.Text;
  private progressText?: Phaser.GameObjects.Text;
  private overlay?: Phaser.GameObjects.Container;
  private activePuzzleId?: string;
  private activePuzzleKind?: ProceduralPuzzleId;
  private activeChallenge?: GeneratedFocusChallenge;
  private mathEntry = "";
  private mathStepIndex = 0;
  private mathSupportMessage = "";
  private mathSupportText?: Phaser.GameObjects.Text;
  private languageAnalyzed = false;
  private englishAnalyzed = false;
  private circuitInspected = false;
  private selectedRepairs = new Set<CircuitFaultType>();
  private robotCommands: GridCommand[] = [];
  private robotExecuting = false;
  private robotSprite?: Phaser.GameObjects.Triangle;
  private robotKeyMarker?: Phaser.GameObjects.Star;
  private robotStatusText?: Phaser.GameObjects.Text;
  private robotOrigin = { x: 130, y: 118 };
  private robotCellSize = 48;
  private musicTimerEvent?: Phaser.Time.TimerEvent;
  private missionFailureInProgress = false;

  constructor() {
    super("ProceduralMissionScene");
  }

  create(): void {
    this.run = this.ensureRun();
    audioManager.playMusic("labAmbience");
    ProceduralMissionView.drawShell(this, this.run);
    const hud = ProceduralMissionView.createHud(
      this,
      this.run,
      () => this.regenerate(),
      () => this.scene.start("MainMenuScene"),
    );
    this.objectiveText = hud.objectiveText;
    this.progressText = hud.progressText;
    this.feedbackText = hud.feedbackText;
    ProceduralMissionView.createHotspots(this, this.run, this.allPuzzlesSolved(), (hotspot) => this.openHotspot(hotspot));
    this.refreshObjective();
    this.time.addEvent({ delay: 1000, loop: true, callback: () => this.refreshObjective() });

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    feedbackSystem.publish(`Stanza generata. Scegli una console da stabilizzare. Seed: ${this.run.seed}.`, "info");
  }

  private ensureRun(): ProceduralRunSave {
    if (saveSystem.data.proceduralRun && !saveSystem.data.proceduralRun.completedAt && !saveSystem.data.proceduralRun.failedAt) {
      const normalized = this.normalizeRunRules(saveSystem.data.proceduralRun);
      if (this.runNeedsContentMigration(normalized)) {
        return this.replaceLegacyRun(normalized);
      }
      return normalized;
    }
    const mission = proceduralDirector.generateFreshMission(2, ["libera"]);
    const startedAt = new Date().toISOString();
    const timeLimitMs = proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length));
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["libera"],
      mode: "mission",
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: proceduralRunRules.maxLives,
      maxLives: proceduralRunRules.maxLives,
      timeLimitMs,
      deadlineAt: proceduralRunRules.deadlineFrom(startedAt, timeLimitMs),
      startedAt,
    };
    saveSystem.setProceduralRun(run);
    return run;
  }

  private runNeedsContentMigration(run: ProceduralRunSave): boolean {
    const mode = proceduralRunRules.modeFor(run);
    const focus = proceduralRunRules.focusFor(run);
    const puzzles = run.mission.puzzles as Partial<ProceduralRunSave["mission"]["puzzles"]>;
    const hasMusicPuzzle = Boolean(puzzles.music);
    const hasMusicObjective = run.mission.objectives.some((objective) => puzzleKindFromId(objective.id.replace("procedural-", "")) === "music");
    const hasMusicHotspot = run.mission.map.hotspots.some((hotspot) => {
      const id = hotspot.puzzleId ?? hotspot.id;
      return hotspot.puzzleKind === "music" || id === "music" || id.startsWith("music-");
    });
    const hasMusicFocusSeries = Boolean(
      run.mission.focusChallenges?.length
      && run.mission.focusChallenges.every((challenge) => challenge.kind === "music"),
    );
    if (focus === "musica") {
      return !(hasMusicPuzzle && hasMusicObjective && hasMusicHotspot && hasMusicFocusSeries);
    }
    if (mode === "mission" || focus === "libera") {
      return !(hasMusicPuzzle && hasMusicObjective && hasMusicHotspot);
    }
    return false;
  }

  private replaceLegacyRun(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    const focus = run.focus.length > 0 ? run.focus : [mode === "training" ? proceduralRunRules.focusFor(run) : "libera"];
    const mission = proceduralDirector.generateFreshMission(run.difficulty, focus);
    const startedAt = new Date().toISOString();
    const timeLimitMs = mode === "mission" ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length)) : undefined;
    const replacement: ProceduralRunSave = {
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
    saveSystem.setProceduralRun(replacement);
    return replacement;
  }

  private normalizeRunRules(run: ProceduralRunSave): ProceduralRunSave {
    const mode = proceduralRunRules.modeFor(run);
    if (mode === "training") {
      if (run.mode !== mode) {
        saveSystem.updateProceduralRun({ mode });
        return saveSystem.data.proceduralRun ?? { ...run, mode };
      }
      return run;
    }
    const timeLimitMs = run.timeLimitMs ?? proceduralRunRules.missionTimeLimitMs(run.difficulty, Math.max(1, run.mission.objectives.length));
    const update: Partial<ProceduralRunSave> = {};
    if (run.mode !== "mission") update.mode = "mission";
    if (!run.maxLives) update.maxLives = proceduralRunRules.maxLives;
    if (!run.lives) update.lives = proceduralRunRules.maxLives;
    if (!run.timeLimitMs) update.timeLimitMs = timeLimitMs;
    if (!run.deadlineAt) update.deadlineAt = proceduralRunRules.deadlineFrom(run.startedAt, timeLimitMs);
    if (Object.keys(update).length > 0) {
      saveSystem.updateProceduralRun(update);
      return saveSystem.data.proceduralRun ?? { ...run, ...update };
    }
    return run;
  }

  private regenerate(): void {
    const nextDifficulty = Math.min(8, this.run.difficulty + (this.run.completedAt ? 1 : 0)) as DifficultyLevel;
    const mission = proceduralDirector.generateFreshMission(nextDifficulty, this.run.focus);
    const mode = proceduralRunRules.modeFor(this.run);
    const startedAt = new Date().toISOString();
    const timeLimitMs = mode === "mission" ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length)) : undefined;
    saveSystem.setProceduralRun({
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: this.run.focus,
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
    });
    this.scene.restart();
  }

  private openHotspot(hotspot: GeneratedRoomHotspot): void {
    audioManager.play("scan");
    if (hotspot.id === "door") {
      this.openDoor();
      return;
    }
    if (!hotspot.puzzleId) {
      feedbackSystem.publish(hotspot.description, "info");
      return;
    }
    if (this.isSolved(hotspot.puzzleId)) {
      feedbackSystem.publish(`${hotspot.label}: sistema già stabilizzato.`, "success");
      return;
    }
    this.openPuzzleConsole(hotspot.puzzleId);
  }

  private openPuzzleConsole(puzzleId: string): void {
    const challenge = this.findFocusChallenge(puzzleId);
    const systemId = challenge?.kind ?? puzzleKindFromId(puzzleId);
    const handlers: Record<ProceduralPuzzleId, () => void> = {
      language: () => this.openLanguage(),
      circuit: () => this.openCircuit(),
      math: () => this.openMath(),
      english: () => this.openEnglish(),
      robot: () => this.openRobot(),
      music: () => this.openMusic(),
    };
    if (proceduralPuzzleOrder.includes(systemId)) {
      if (this.activePuzzleId !== puzzleId) {
        this.resetTransientPuzzleState();
      }
      this.activePuzzleId = puzzleId;
      this.activePuzzleKind = systemId;
      this.activeChallenge = challenge;
      this.ensurePuzzleTimer(puzzleId);
      handlers[systemId]();
    }
  }

  private openLanguage(): void {
    const puzzle = this.currentLanguagePuzzle();
    const model = LanguageRepairConsole.fromPuzzle(puzzle, this.languageAnalyzed);
    const overlay = this.createOverlay(model.title, 660, { x: 40, y: 30, width: 1200 });
    LanguageRepairConsole.addHeader(this, overlay, model);
    this.addLanguageBrief(overlay, model);
    if (!this.languageAnalyzed) {
      overlay.add(new Button(this, 866, 586, "Analizza struttura", () => {
        this.languageAnalyzed = true;
        audioManager.playOutcome("neutral");
        outcomeFeedback.play(this, "info", "Analisi del segnale");
        feedbackSystem.publish(`Analisi avviata: ${model.method}`, "info");
        this.openLanguage();
      }, { width: 310, height: 52, fill: 0x173b36 }));
      return;
    }
    model.options.forEach((option, index) => {
      const y = 330 + index * 48;
      overlay.add(new Button(this, 866, y, option, () => {
        if (option === model.correctAnswer) {
          this.solvePuzzle(this.currentPuzzleId("language"), puzzle.competencies);
          return;
        }
        this.handleIncorrectAnswer(model.optionFeedback[option] ?? model.hints[Math.min(index, model.hints.length - 1)]);
      }, { width: 540, height: 40, fontSize: 11, wordWrapWidth: 506 }));
    });
    this.addMethodStrip(overlay, 56, 590, 520, "Metodo", [
      "soggetto reale",
      "accordi e connettivi",
      "significato operativo",
    ]);
    overlay.add(new Button(this, 866, 620, "Indizio mirato", () => {
      this.useHint(this.nextPedagogicHint(puzzle, model.hints[Math.min(this.run.hintsUsed, model.hints.length - 1)]));
      this.openLanguage();
    }, { width: 250, height: 40, fontSize: 13, fill: 0x263743 }));
  }

  private openCircuit(): void {
    const puzzle = this.currentCircuitPuzzle();
    const model = CircuitConsole.fromPuzzle(puzzle);
    const overlay = this.createOverlay(model.title, 660, { x: 40, y: 30, width: 1200 });
    overlay.add(this.add.text(48, 72, model.difficultyLabel.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(48, 100, model.symptom, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f7d37a",
      wordWrap: { width: 800 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(456, 158, 816, 58, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.text(64, 138, "Scopo della diagnosi", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(64, 158, `${model.learningPurpose} Domanda: ${model.diagnosticQuestion}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 760 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(1010, 132, 304, 112, 0x07151d, 0.78).setStrokeStyle(1, 0x6be7d6, 0.18));
    overlay.add(this.add.text(876, 90, "Concetti osservati", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(876, 116, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 260 },
      lineSpacing: 3,
    }));

    this.drawCircuitDiagnostic(overlay);
    this.drawCircuitSidePanel(overlay, model);

    if (!this.circuitInspected) {
      overlay.add(new Button(this, 1010, 588, "Leggi tester", () => {
        this.circuitInspected = true;
        audioManager.playOutcome("neutral");
        feedbackSystem.publish("Tester collegato: ora collega ogni misura a una causa, senza tentare riparazioni a caso.", "info");
        this.openCircuit();
      }, { width: 250, height: 52, fill: 0x173b36 }));
      return;
    }

    overlay.add(this.add.rectangle(452, 488, 816, 46, 0x07151d, 0.74).setStrokeStyle(1, 0xf6c85f, 0.2));
    overlay.add(this.add.text(64, 474, "Interventi disponibili", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(64, 496, "Seleziona solo le riparazioni dimostrate dal tester. Una riparazione inutile riduce qualita, tempo e affidabilita del log.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 760 },
    }));

    model.repairChoices.forEach((fault, index) => {
      const selected = this.selectedRepairs.has(fault);
      const col = index % 4;
      const row = Math.floor(index / 4);
      overlay.add(new Button(this, 142 + col * 200, 548 + row * 44, `${selected ? "[x] " : ""}${repairLabels[fault]}`, () => {
        if (selected) {
          this.selectedRepairs.delete(fault);
        } else {
          this.selectedRepairs.add(fault);
        }
        audioManager.play("click");
        this.openCircuit();
      }, { width: 176, height: 38, fontSize: 11, fill: selected ? 0x173b36 : 0x142736 }));
    });
    overlay.add(new Button(this, 1010, 604, "Testa circuito", () => {
      const required = new Set(puzzle.requiredRepairs);
      const exact = this.selectedRepairs.size === required.size && [...this.selectedRepairs].every((fault) => required.has(fault));
      if (exact) {
        const explanation = puzzle.requiredRepairs
          .map((fault) => model.explanations[fault] ?? faultLabels[fault])
          .join(" ");
        this.animateCircuitTest(true, () => {
          feedbackSystem.publish(`Circuito certificato. ${explanation}`, "success");
          this.solvePuzzle(this.currentPuzzleId("circuit"), puzzle.competencies);
        });
        return;
      }
      const missing = puzzle.requiredRepairs.filter((fault) => !this.selectedRepairs.has(fault));
      const extra = [...this.selectedRepairs].filter((fault) => !required.has(fault));
      const message = missing.length > 0
        ? `Manca ancora una causa: ${faultLabels[missing[0]]}.`
        : `Hai aggiunto un intervento non necessario: ${faultLabels[extra[0]]}.`;
      this.animateCircuitTest(false, () => this.handleIncorrectAnswer(`${message} ${this.nextPedagogicHint(puzzle, puzzle.hints[0] ?? "Rileggi il tester e collega sintomo a causa.")}`));
    }, { width: 250, height: 52, fill: 0x173b36 }));
  }

  private drawCircuitSidePanel(overlay: Phaser.GameObjects.Container, model: CircuitConsoleModel): void {
    const x = 856;
    const y = 188;
    overlay.add(this.add.rectangle(x, y, 330, 268, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(x + 18, y + 16, this.circuitInspected ? "Letture tester" : "Metodo tecnico", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    if (!this.circuitInspected) {
      overlay.add(this.add.text(x + 18, y + 48, "Prima misura, poi ripara. Il tester serve a distinguere una causa reale da una prova casuale.", {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: 288 },
        lineSpacing: 5,
      }));
      model.diagnosticPlan.slice(0, 4).forEach((step, index) => {
        const rowY = y + 122 + index * 34;
        overlay.add(this.add.circle(x + 28, rowY + 7, 9, 0xf6c85f, 0.18).setStrokeStyle(1, 0xf6c85f, 0.7));
        overlay.add(this.add.text(x + 25, rowY, String(index + 1), {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#f7d37a",
          fontStyle: "bold",
        }).setOrigin(0.5, 0));
        overlay.add(this.add.text(x + 48, rowY - 2, step, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#c7dce7",
          wordWrap: { width: 242 },
          lineSpacing: 2,
        }));
      });
      return;
    }

    const readingLabels: Record<NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]["reading"], string> = {
      continuita: "continuità",
      interrotto: "interrotto",
      "polarita-inversa": "polarità inversa",
      "non-stabile": "non stabile",
      corto: "corto",
      "tensione-bassa": "tensione bassa",
      "soglia-fuori-range": "soglia fuori range",
      "carica-bassa": "carica bassa",
    };
    model.testerReadings.slice(0, 5).forEach((reading, index) => {
      const rowY = y + 50 + index * 39;
      overlay.add(this.add.rectangle(x + 18, rowY - 4, 294, 34, 0x102533, 0.7).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.14));
      overlay.add(this.add.text(x + 30, rowY, `${reading.from} -> ${reading.to}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#f5fbff",
        fontStyle: "bold",
        wordWrap: { width: 130 },
      }));
      overlay.add(this.add.text(x + 162, rowY, readingLabels[reading.reading], {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: reading.reading === "continuita" ? "#9ff5e9" : "#f7d37a",
        fontStyle: "bold",
      }));
      overlay.add(this.add.text(x + 30, rowY + 15, reading.note, {
        fontFamily: "Inter, Arial",
        fontSize: "9px",
        color: "#9aaab0",
        wordWrap: { width: 270 },
      }));
    });

    const guide = model.componentGuide.slice(0, 2).map((component) => `${component.label}: ${component.check}`).join("\n");
    overlay.add(this.add.text(x + 18, y + 244, guide, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9aaab0",
      wordWrap: { width: 288 },
      lineSpacing: 2,
    }));
  }

  private formatTesterReadings(model: CircuitConsoleModel): string {
    const readingLabels: Record<NonNullable<GeneratedCircuitPuzzle["testerReadings"]>[number]["reading"], string> = {
      continuita: "continuità",
      interrotto: "interrotto",
      "polarita-inversa": "polarità inversa",
      "non-stabile": "non stabile",
      corto: "corto",
      "tensione-bassa": "tensione bassa",
      "soglia-fuori-range": "soglia fuori range",
      "carica-bassa": "carica bassa",
    };
    const readings = model.testerReadings
      .slice(0, 5)
      .map((reading, index) => `${index + 1}. ${reading.from} -> ${reading.to}: ${readingLabels[reading.reading]}. ${reading.note}`)
      .join("\n");
    const plan = model.diagnosticPlan.map((step, index) => `${index + 1}) ${step}`).join("  ");
    const components = model.componentGuide
      .slice(0, 4)
      .map((component) => `${component.label}: ${component.check}`)
      .join(" | ");
    return `Letture tester\n${readings}\n\nPiano: ${plan}\nComponenti chiave: ${components}`;
  }

  private drawCircuitDiagnostic(overlay: Phaser.GameObjects.Container): void {
    const puzzle = this.currentCircuitPuzzle();
    const activeFaults = new Set(puzzle.requiredRepairs.filter((fault) => !this.selectedRepairs.has(fault)));
    const lit = this.circuitWouldLight();
    const wireColor = lit ? 0x6be7d6 : 0x425865;
    const y = 248;
    const bottomY = 330;
    const positions = {
      battery: 94,
      switch: 226,
      resistor: 370,
      led: 522,
      return: 668,
    };

    overlay.add(this.add.rectangle(400, 276, 704, 214, 0x081823, 0.9).setStrokeStyle(1, 0x6be7d6, 0.26));
    overlay.add(this.add.text(58, 184, "Schema del giro della corrente", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));

    const path = this.add.graphics();
    path.lineStyle(5, wireColor, lit ? 0.9 : 0.45);
    path.beginPath();
    path.moveTo(positions.battery + 24, y);
    path.lineTo(positions.switch - 38, y);
    path.moveTo(positions.switch + 42, y);
    path.lineTo(positions.resistor - 48, y);
    path.moveTo(positions.resistor + 52, y);
    path.lineTo(positions.led - 46, y);
    path.moveTo(positions.led + 46, y);
    path.lineTo(positions.return - 36, y);
    path.moveTo(positions.return + 28, y);
    path.lineTo(positions.return + 28, bottomY);
    path.lineTo(positions.battery - 28, bottomY);
    path.lineTo(positions.battery - 28, y);
    path.strokePath();
    overlay.add(path);

    if (activeFaults.has("missing-wire")) {
      const broken = this.add.graphics();
      broken.lineStyle(6, 0xffb36b, 0.9);
      broken.beginPath();
      broken.moveTo(positions.led + 58, y);
      broken.lineTo(positions.return - 46, y);
      broken.strokePath();
      broken.lineStyle(2, 0x07151d, 1);
      broken.beginPath();
      broken.moveTo(positions.return - 88, y - 16);
      broken.lineTo(positions.return - 70, y + 16);
      broken.moveTo(positions.return - 68, y - 16);
      broken.lineTo(positions.return - 50, y + 16);
      broken.strokePath();
      overlay.add(broken);
    }

    this.drawBatterySymbol(overlay, positions.battery, y, 0xf6c85f);
    this.drawSwitchSymbol(overlay, positions.switch, y, activeFaults.has("open-switch") ? 0xffb36b : 0x9ff5e9, !activeFaults.has("open-switch"));
    this.drawResistorSymbol(overlay, positions.resistor, y, activeFaults.has("missing-resistor") || activeFaults.has("wrong-resistor-value") ? 0xffb36b : 0x9ff5e9, activeFaults.has("missing-resistor"));
    this.drawLedSymbol(overlay, positions.led, y, activeFaults.has("reversed-led") ? 0xffb36b : 0x9ff5e9, activeFaults.has("reversed-led"), lit);
    this.drawReturnSymbol(overlay, positions.return, y, activeFaults.has("missing-wire") || activeFaults.has("loose-ground") || activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9);

    [
      { x: positions.battery, label: "Batteria", text: "spinge la corrente dal + al -" },
      { x: positions.switch, label: "Interruttore", text: "chiude o apre il percorso" },
      { x: positions.resistor, label: "Resistenza", text: "protegge il LED limitando la corrente" },
      { x: positions.led, label: "LED", text: "si accende solo nel verso giusto" },
      { x: positions.return, label: "Ritorno", text: "riporta la corrente al -" },
    ].forEach((item) => {
      overlay.add(this.add.text(item.x, 292, item.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      overlay.add(this.add.text(item.x, 312, item.text, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#9aaab0",
        align: "center",
        wordWrap: { width: 116 },
      }).setOrigin(0.5, 0));
    });

    this.drawCurrentArrows(overlay, lit ? 0x8cffd7 : 0x5c7480, lit ? 0.85 : 0.35, [
      { x: 160, y, rotation: 0 },
      { x: 450, y, rotation: 0 },
      { x: 696, y: 292, rotation: Math.PI / 2 },
      { x: 330, y: bottomY, rotation: Math.PI },
    ]);

    if (puzzle.nodes.includes("capacitor")) {
      this.drawCapacitorSymbol(overlay, 226, 366, activeFaults.has("capacitor-discharged") ? 0xffb36b : 0x9ff5e9);
    }
    if (puzzle.nodes.includes("sensor")) {
      this.drawSensorSymbol(overlay, 590, 366, activeFaults.has("sensor-unpowered") || activeFaults.has("disconnected-component") ? 0xffb36b : 0x9ff5e9);
    }
    if (puzzle.nodes.includes("branchLed")) {
      this.drawBranchSymbol(overlay, 404, 366, activeFaults.has("parallel-branch-open") ? 0xffb36b : 0x9ff5e9);
    }
    if (puzzle.nodes.includes("relay")) {
      this.drawRelaySymbol(overlay, 190, 386, activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9);
    }
    if (puzzle.nodes.includes("motor")) {
      this.drawMotorSymbol(overlay, 350, 386, activeFaults.has("relay-not-armed") ? 0xffb36b : 0x9ff5e9);
    }
    if (puzzle.nodes.includes("ground")) {
      this.drawGroundSymbol(overlay, 590, 386, activeFaults.has("loose-ground") || activeFaults.has("short-circuit") ? 0xffb36b : 0x9ff5e9);
    }
  }

  private drawCapacitorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.beginPath();
    g.moveTo(x - 46, y);
    g.lineTo(x - 14, y);
    g.moveTo(x - 14, y - 22);
    g.lineTo(x - 14, y + 22);
    g.moveTo(x + 14, y - 22);
    g.lineTo(x + 14, y + 22);
    g.moveTo(x + 14, y);
    g.lineTo(x + 46, y);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 30, "condensatore: accumula carica", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawSensorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    overlay.add(this.add.rectangle(x, y, 150, 38, 0x0d2531, 0.92).setStrokeStyle(2, color, 0.78));
    const g = this.add.graphics();
    g.lineStyle(2, color, 0.9);
    g.strokeCircle(x - 40, y, 10);
    g.beginPath();
    g.moveTo(x - 24, y);
    g.lineTo(x + 40, y);
    g.moveTo(x + 24, y - 8);
    g.lineTo(x + 40, y);
    g.lineTo(x + 24, y + 8);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 30, "sensore: misura e invia dati", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawBranchSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.88);
    g.beginPath();
    g.moveTo(x - 58, y - 20);
    g.lineTo(x - 22, y - 20);
    g.lineTo(x + 22, y + 20);
    g.lineTo(x + 58, y + 20);
    g.moveTo(x - 58, y + 20);
    g.lineTo(x - 22, y + 20);
    g.lineTo(x + 22, y - 20);
    g.lineTo(x + 58, y - 20);
    g.strokePath();
    g.strokeCircle(x, y, 10);
    overlay.add(g);
    overlay.add(this.add.text(x, y + 34, "ramo parallelo: può guastarsi da solo", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawRelaySymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.strokeRect(x - 50, y - 18, 44, 36);
    g.beginPath();
    g.moveTo(x - 2, y);
    g.lineTo(x + 46, y - 16);
    g.moveTo(x + 22, y + 18);
    g.lineTo(x + 52, y + 18);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 32, "relè: comando + potenza", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawMotorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.strokeCircle(x, y, 22);
    g.beginPath();
    g.moveTo(x - 44, y);
    g.lineTo(x - 22, y);
    g.moveTo(x + 22, y);
    g.lineTo(x + 44, y);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y - 8, "M", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: color === 0xffb36b ? "#f7d37a" : "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(this.add.text(x, y + 32, "motore: carico più esigente", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawGroundSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.beginPath();
    g.moveTo(x, y - 30);
    g.lineTo(x, y);
    g.moveTo(x - 30, y);
    g.lineTo(x + 30, y);
    g.moveTo(x - 20, y + 10);
    g.lineTo(x + 20, y + 10);
    g.moveTo(x - 10, y + 20);
    g.lineTo(x + 10, y + 20);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 34, "massa: ritorno stabile", {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: color === 0xffb36b ? "#f7d37a" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawBatterySymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.95);
    g.beginPath();
    g.moveTo(x - 22, y - 24);
    g.lineTo(x - 22, y + 24);
    g.moveTo(x + 4, y - 15);
    g.lineTo(x + 4, y + 15);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x - 38, y - 36, "+", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    overlay.add(this.add.text(x + 20, y - 36, "-", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
  }

  private drawSwitchSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, closed: boolean): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.95);
    g.strokeCircle(x - 30, y, 4);
    g.strokeCircle(x + 30, y, 4);
    g.beginPath();
    g.moveTo(x - 26, y);
    g.lineTo(x + 24, closed ? y : y - 24);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 28, closed ? "chiuso" : "aperto", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: closed ? "#9ff5e9" : "#f7d37a",
    }).setOrigin(0.5));
  }

  private drawResistorSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, missing: boolean): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, missing ? 0.45 : 0.95);
    g.beginPath();
    g.moveTo(x - 42, y);
    g.lineTo(x - 30, y);
    for (let i = 0; i < 6; i += 1) {
      g.lineTo(x - 20 + i * 8, y + (i % 2 === 0 ? -12 : 12));
    }
    g.lineTo(x + 32, y);
    g.lineTo(x + 44, y);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.text(x, y + 30, missing ? "manca" : "220 ohm", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: missing ? "#f7d37a" : "#9ff5e9",
    }).setOrigin(0.5));
  }

  private drawLedSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number, reversed: boolean, lit: boolean): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.95);
    g.beginPath();
    if (reversed) {
      g.moveTo(x + 24, y - 22);
      g.lineTo(x - 18, y);
      g.lineTo(x + 24, y + 22);
      g.closePath();
      g.moveTo(x - 24, y - 22);
      g.lineTo(x - 24, y + 22);
    } else {
      g.moveTo(x - 24, y - 22);
      g.lineTo(x + 18, y);
      g.lineTo(x - 24, y + 22);
      g.closePath();
      g.moveTo(x + 24, y - 22);
      g.lineTo(x + 24, y + 22);
    }
    g.strokePath();
    g.beginPath();
    g.moveTo(x + 18, y - 34);
    g.lineTo(x + 34, y - 50);
    g.moveTo(x + 28, y - 26);
    g.lineTo(x + 44, y - 42);
    g.strokePath();
    overlay.add(g);
    overlay.add(this.add.circle(x + 64, y, 16, lit ? 0x8cffd7 : 0x243541, lit ? 0.95 : 0.78).setStrokeStyle(2, color, 0.7));
    overlay.add(this.add.text(x, y + 30, reversed ? "invertito" : lit ? "acceso" : "spento", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: reversed ? "#f7d37a" : lit ? "#9ff5e9" : "#9aaab0",
    }).setOrigin(0.5));
  }

  private drawReturnSymbol(overlay: Phaser.GameObjects.Container, x: number, y: number, color: number): void {
    const g = this.add.graphics();
    g.lineStyle(3, color, 0.9);
    g.beginPath();
    g.moveTo(x - 28, y);
    g.lineTo(x + 28, y);
    g.moveTo(x, y);
    g.lineTo(x, y + 36);
    g.moveTo(x - 22, y + 36);
    g.lineTo(x + 22, y + 36);
    g.moveTo(x - 14, y + 46);
    g.lineTo(x + 14, y + 46);
    g.moveTo(x - 6, y + 56);
    g.lineTo(x + 6, y + 56);
    g.strokePath();
    overlay.add(g);
  }

  private drawCurrentArrows(
    overlay: Phaser.GameObjects.Container,
    color: number,
    alpha: number,
    arrows: Array<{ x: number; y: number; rotation: number }>,
  ): void {
    arrows.forEach((arrow) => {
      const tri = this.add.triangle(arrow.x, arrow.y, 0, -6, 14, 0, 0, 6, color, alpha)
        .setRotation(arrow.rotation)
        .setOrigin(0.5);
      overlay.add(tri);
    });
  }

  private circuitWouldLight(): boolean {
    const puzzle = this.currentCircuitPuzzle();
    const lightBlockingFaults = new Set<CircuitFaultType>([
      "missing-wire",
      "open-switch",
      "reversed-led",
      "short-circuit",
      "loose-ground",
    ]);
    return puzzle.requiredRepairs
      .filter((fault) => lightBlockingFaults.has(fault))
      .every((fault) => this.selectedRepairs.has(fault));
  }

  private animateCircuitTest(success: boolean, onComplete: () => void): void {
    const flash = this.add.rectangle(400, 302, 706, 238, success ? 0x6be7d6 : 0xc94b55, success ? 0.18 : 0.22);
    this.overlay?.add(flash);
    audioManager.play(success ? "circuitOn" : "error");
    this.tweens.add({
      targets: flash,
      alpha: 0,
      scale: 1.04,
      duration: 520,
      onComplete: () => {
        flash.destroy();
        onComplete();
      },
    });
  }

  private openMath(): void {
    const puzzle = this.currentMathPuzzle();
    const model = MathTerminal.fromPuzzle(puzzle);
    const overlay = this.createMathOverlay(model.title);

    this.addMathPanel(overlay, 28, 102, 378, 438, "Briefing matematico");
    overlay.add(this.add.text(54, 146, model.difficultyLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(54, 172, `Ambito: ${model.domainLabel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    if (model.curriculumTags.length > 0) {
      overlay.add(this.add.text(54, 196, `Concetti: ${model.curriculumTags.slice(0, 4).join(" · ")}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 326 },
      }));
    }
    overlay.add(this.add.text(54, 236, model.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 320, useAdvancedWrap: true },
      lineSpacing: 4,
    }));

    this.drawMathLogicVisualizer(overlay, puzzle, model, 430, 102, 500, 438);

    this.addMathPanel(overlay, 954, 102, 298, 438, "Console di risposta");
    overlay.add(this.add.text(982, 148, "Inserisci solo il valore finale quando hai una strategia chiara.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 242 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(1016, 216, "Risultato", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      fontStyle: "bold",
    }));
    overlay.add(this.add.rectangle(1102, 270, 156, 70, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.56));
    overlay.add(this.add.text(1040, 248, this.mathEntry.padEnd(4, "-"), {
      fontFamily: "Inter, Arial",
      fontSize: "42px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const keypadY = 348;
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"].forEach((key, index) => {
      overlay.add(new Button(this, 1024 + (index % 3) * 76, keypadY + Math.floor(index / 3) * 42, key, () => this.pressMathKey(key), {
        width: 58,
        height: 34,
        fontSize: 17,
        fill: key === "OK" ? 0x173b36 : 0x142736,
      }));
    });

    this.addMathPanel(overlay, 28, 556, 1224, 132, "Supporti intelligenti");
    overlay.add(this.add.text(54, 596, [
      `Scopo didattico: ${model.learningPurpose}`,
      `Metodo consigliato: ${model.strategy}`,
      model.mentalMathNote,
      `Appunti: ${model.scratchpadPrompt}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 620 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.rectangle(990, 596, 478, 44, 0x07151d, 0.82).setStrokeStyle(1, 0xf6c85f, 0.28));
    this.mathSupportText = this.add.text(760, 580, this.mathSupportMessage || "Scegli un aiuto solo quando serve: ogni supporto guida il ragionamento e viene conteggiato nel punteggio.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.mathSupportMessage ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 460, useAdvancedWrap: true },
      lineSpacing: 3,
    });
    overlay.add(this.mathSupportText);
    overlay.add(new Button(this, 812, 660, "Indizio", () => this.showMathSupport(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])), {
      width: 150,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1000, 660, "Passo guidato", () => this.revealMathStep(puzzle), {
      width: 180,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(this, 1180, 660, "Teoria breve", () => this.revealMathTheory(model), {
      width: 170,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
  }

  private createMathOverlay(title: string): Phaser.GameObjects.Container {
    this.clearOverlay();
    const overlay = this.add.container(0, 0).setDepth(1000);
    overlay.add(this.add.rectangle(640, 360, 1280, 720, 0x02080d, 0.96));
    if (this.textures.exists("bg-lab-painted")) {
      overlay.add(this.add.image(640, 360, "bg-lab-painted").setDisplaySize(1320, 742).setAlpha(0.32));
    }
    const grid = this.add.graphics();
    grid.lineStyle(1, 0x6be7d6, 0.06);
    for (let x = -100; x < 1380; x += 72) {
      grid.lineBetween(x, 0, x - 128, 720);
    }
    for (let y = 86; y < 720; y += 58) {
      grid.lineBetween(0, y, 1280, y + 10);
    }
    overlay.add(grid);
    overlay.add(this.add.rectangle(640, 52, 1280, 104, 0x06131c, 0.86));
    overlay.add(this.add.rectangle(640, 103, 1280, 2, 0x6be7d6, 0.34));
    overlay.add(this.add.text(36, 24, title, {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    overlay.add(this.add.text(38, 68, "Laboratorio matematico - mappa visiva del ragionamento", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
    }));
    overlay.add(new Button(this, 1224, 48, "X", () => this.clearOverlay(), {
      width: 56,
      height: 42,
      fontSize: 18,
      fill: 0x263743,
    }));
    this.overlay = overlay;
    return overlay;
  }

  private addMathPanel(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    height: number,
    title: string,
  ): void {
    overlay.add(VisualKit.glassPanel(this, x, y, width, height, "lab", 0.84));
    overlay.add(this.add.text(x + 24, y + 20, title, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
  }

  private drawMathLogicVisualizer(
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    model: MathTerminalModel,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    this.addMathPanel(overlay, x, y, width, height, "Mappa visiva");
    overlay.add(this.add.text(x + 24, y + 58, "Leggi il problema come un sistema: dati -> regola -> trasformazione -> controllo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: width - 48 },
    }));

    const archetype = puzzle.archetype ?? "calcolo-diretto";
    if (archetype === "frazioni" || archetype === "percentuali" || archetype === "proporzione") {
      this.drawShareVisualizer(overlay, x, y, width, archetype);
    } else if (archetype === "geometria") {
      this.drawGeometryVisualizer(overlay, x, y, width, model.curriculumTags);
    } else if (archetype === "coordinate") {
      this.drawCoordinateVisualizer(overlay, x, y);
    } else if (archetype === "statistica" || archetype === "probabilita" || archetype === "lettura-dati") {
      this.drawDataVisualizer(overlay, x, y, archetype);
    } else if (
      archetype === "funzione-lineare"
      || archetype === "sistemi-lineari"
      || archetype === "pre-algebra"
      || archetype === "ragionamento-inverso"
      || archetype === "equazione-primo-grado"
    ) {
      this.drawAlgebraVisualizer(overlay, x, y, width, archetype);
    } else if (archetype === "sequenza" || archetype === "potenze-radici") {
      this.drawSequenceVisualizer(overlay, x, y, archetype);
    } else {
      this.drawOperationVisualizer(overlay, x, y, width);
    }

    this.drawMathReasoningRail(overlay, x + 42, y + height - 82, width - 84, [
      "Dati",
      "Regola",
      "Passaggi",
      "Verifica",
    ]);
  }

  private drawShareVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const barX = x + 68;
    const barY = y + 178;
    const segmentW = (width - 136) / 6;
    g.fillStyle(0x07151d, 0.9);
    g.fillRoundedRect(barX - 10, barY - 18, width - 116, 96, 10);
    for (let index = 0; index < 6; index += 1) {
      const color = index < 3 ? 0x6be7d6 : index < 5 ? 0xf6c85f : 0x315766;
      g.fillStyle(color, index < 5 ? 0.58 : 0.22);
      g.fillRoundedRect(barX + index * segmentW, barY, segmentW - 5, 34, 6);
      g.lineStyle(1, 0xffffff, 0.1);
      g.strokeRoundedRect(barX + index * segmentW, barY, segmentW - 5, 34, 6);
    }
    overlay.add(g);
    const label = archetype === "percentuali"
      ? "100% = intero, poi calcola la quota richiesta"
      : archetype === "proporzione"
        ? "Stesso rapporto, scala diversa"
        : "Quote dello stesso intero, poi resto";
    overlay.add(this.add.text(x + 72, y + 138, label, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 74, y + 232, "Non dividere il resto per errore: identifica prima l'intero iniziale.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 140 },
    }));
  }

  private drawGeometryVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    tags: string[],
  ): void {
    const g = this.add.graphics();
    const isPythagoras = tags.some((tag) => tag.toLowerCase().includes("pitagora"));
    g.lineStyle(3, 0x6be7d6, 0.85);
    g.fillStyle(0x07151d, 0.62);
    if (isPythagoras) {
      const ax = x + 126;
      const ay = y + 284;
      const bx = x + 126;
      const by = y + 148;
      const cx = x + 348;
      const cy = y + 284;
      g.fillTriangle(ax, ay, bx, by, cx, cy);
      g.strokeTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(2, 0xf6c85f, 0.78);
      g.lineBetween(bx, by, cx, cy);
      overlay.add(g);
      overlay.add(this.add.text(x + 164, y + 116, "Triangolo rettangolo: i due lati perpendicolari determinano la diagonale.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f7d37a",
        wordWrap: { width: width - 120 },
      }));
    } else {
      g.fillRoundedRect(x + 116, y + 146, 258, 146, 8);
      g.strokeRoundedRect(x + 116, y + 146, 258, 146, 8);
      g.lineStyle(2, 0xf6c85f, 0.7);
      g.strokeRoundedRect(x + 106, y + 136, 278, 166, 10);
      overlay.add(g);
      overlay.add(this.add.text(x + 144, y + 116, "Area = spazio interno. Perimetro = bordo esterno.", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f7d37a",
        fontStyle: "bold",
      }));
    }
    overlay.add(this.add.text(x + 88, y + 324, "Prima scegli la grandezza giusta, poi applica la formula. Area, perimetro e distanza non misurano la stessa cosa.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 116 },
    }));
  }

  private drawCoordinateVisualizer(overlay: Phaser.GameObjects.Container, x: number, y: number): void {
    const g = this.add.graphics();
    const originX = x + 142;
    const originY = y + 304;
    const cell = 32;
    g.lineStyle(1, 0x6be7d6, 0.16);
    for (let i = 0; i <= 7; i += 1) {
      g.lineBetween(originX, originY - i * cell, originX + 7 * cell, originY - i * cell);
      g.lineBetween(originX + i * cell, originY, originX + i * cell, originY - 7 * cell);
    }
    g.lineStyle(4, 0xf6c85f, 0.82);
    g.lineBetween(originX + cell, originY - cell, originX + 5 * cell, originY - cell);
    g.lineBetween(originX + 5 * cell, originY - cell, originX + 5 * cell, originY - 5 * cell);
    overlay.add(g);
    overlay.add(this.add.circle(originX + cell, originY - cell, 8, 0x6be7d6, 1));
    overlay.add(this.add.star(originX + 5 * cell, originY - 5 * cell, 5, 7, 16, 0xf6c85f, 1));
    overlay.add(this.add.text(x + 84, y + 124, "Conta spostamento orizzontale e verticale: niente diagonali.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
  }

  private drawDataVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const values = [54, 86, 128, 102, 168];
    values.forEach((value, index) => {
      g.fillStyle(index === 2 ? 0xf6c85f : 0x6be7d6, index === 2 ? 0.78 : 0.42);
      g.fillRoundedRect(x + 116 + index * 58, y + 304 - value, 34, value, 6);
    });
    g.lineStyle(2, 0x9aaab0, 0.42);
    g.lineBetween(x + 94, y + 304, x + 414, y + 304);
    overlay.add(g);
    const label = archetype === "probabilita"
      ? "Rapporto -> frequenza attesa"
      : "Dati -> misura stabile -> codice";
    overlay.add(this.add.text(x + 112, y + 126, label, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 98, y + 330, "Non scegliere il numero piu vistoso: controlla quale misura chiede il terminale.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 330 },
    }));
  }

  private drawAlgebraVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const cy = y + 224;
    const boxes = [
      {
        x: x + 90,
        label: archetype === "ragionamento-inverso"
          ? "Uscita"
          : archetype === "equazione-primo-grado"
            ? "Equilibrio"
            : "Ingresso x",
      },
      {
        x: x + 242,
        label: archetype === "sistemi-lineari"
          ? "Relazioni"
          : archetype === "equazione-primo-grado"
            ? "Operazioni inverse"
            : "Regola",
      },
      {
        x: x + 394,
        label: archetype === "ragionamento-inverso"
          ? "Ingresso"
          : archetype === "equazione-primo-grado"
            ? "x isolata"
            : "Uscita y",
      },
    ];
    g.lineStyle(3, 0x6be7d6, 0.6);
    g.lineBetween(boxes[0].x + 54, cy, boxes[1].x - 54, cy);
    g.lineBetween(boxes[1].x + 54, cy, boxes[2].x - 54, cy);
    overlay.add(g);
    boxes.forEach((box, index) => {
      overlay.add(this.add.rectangle(box.x, cy, 108, 72, index === 1 ? 0x173b36 : 0x07151d, 0.92).setStrokeStyle(2, index === 1 ? 0xf6c85f : 0x6be7d6, 0.68));
      overlay.add(this.add.text(box.x, cy, box.label, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f5fbff",
        align: "center",
        wordWrap: { width: 86 },
      }).setOrigin(0.5));
    });
    const caption = archetype === "sistemi-lineari"
      ? "Due informazioni insieme isolano le incognite."
      : archetype === "equazione-primo-grado"
        ? "Una bilancia resta vera solo se fai la stessa operazione su entrambi i lati."
        : "Una regola trasforma, l'operazione inversa ricostruisce.";
    overlay.add(this.add.text(x + 78, y + 126, caption, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 120 },
    }));
  }

  private drawSequenceVisualizer(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = this.add.graphics();
    const startX = x + 96;
    const startY = y + 286;
    const nodes = archetype === "potenze-radici" ? [0, 34, 82, 154] : [0, 42, 92, 156];
    g.lineStyle(3, 0x6be7d6, 0.48);
    nodes.forEach((rise, index) => {
      const px = startX + index * 94;
      const py = startY - rise;
      if (index > 0) {
        const prevX = startX + (index - 1) * 94;
        const prevY = startY - nodes[index - 1];
        g.lineBetween(prevX, prevY, px, py);
      }
    });
    overlay.add(g);
    nodes.forEach((rise, index) => {
      overlay.add(this.add.circle(startX + index * 94, startY - rise, 16, index === nodes.length - 1 ? 0xf6c85f : 0x6be7d6, 0.82));
    });
    overlay.add(this.add.text(x + 82, y + 126, archetype === "potenze-radici" ? "Crescita ripetuta: controlla quante volte applichi la stessa regola." : "Osserva i salti: il prossimo valore nasce dalla regola, non dal caso.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 360 },
    }));
  }

  private drawOperationVisualizer(overlay: Phaser.GameObjects.Container, x: number, y: number, width: number): void {
    const labels = ["Valore", "Operazione", "Intermedio", "Codice"];
    labels.forEach((label, index) => {
      const cx = x + 86 + index * 110;
      overlay.add(this.add.rectangle(cx, y + 224, 92, 62, index === labels.length - 1 ? 0x173b36 : 0x07151d, 0.92).setStrokeStyle(2, index === labels.length - 1 ? 0xf6c85f : 0x6be7d6, 0.56));
      overlay.add(this.add.text(cx, y + 224, label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        align: "center",
      }).setOrigin(0.5));
      if (index < labels.length - 1) {
        overlay.add(this.add.triangle(cx + 60, y + 224, 0, -7, 14, 0, 0, 7, 0x6be7d6, 0.72));
      }
    });
    overlay.add(this.add.text(x + 82, y + 126, "Trasforma un valore alla volta e conserva i risultati intermedi.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 120 },
    }));
  }

  private drawMathReasoningRail(
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    labels: string[],
  ): void {
    const g = this.add.graphics();
    const gap = width / (labels.length - 1);
    g.lineStyle(2, 0x6be7d6, 0.32);
    g.lineBetween(x, y, x + width, y);
    overlay.add(g);
    labels.forEach((label, index) => {
      const cx = x + index * gap;
      overlay.add(this.add.circle(cx, y, 12, index === 0 ? 0xf6c85f : 0x6be7d6, 0.82));
      overlay.add(this.add.text(cx, y + 24, label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
      }).setOrigin(0.5));
    });
  }

  private revealMathStep(puzzle: GeneratedMathPuzzle): void {
    const steps = puzzle.solutionSteps ?? [];
    if (steps.length === 0) {
      this.showMathSupport("Scomponi il problema in dati, operazione richiesta e controllo finale.");
      return;
    }
    const index = Math.min(this.mathStepIndex, steps.length - 1);
    this.mathStepIndex = Math.min(index + 1, steps.length - 1);
    this.showMathSupport(`Passo guidato ${index + 1}/${steps.length}: ${steps[index]}`);
  }

  private revealMathTheory(model: MathTerminalModel): void {
    this.showMathSupport(`Teoria breve: ${model.theoryPrinciple} Strategia: ${model.strategy}`);
  }

  private showMathSupport(text: string): void {
    this.mathSupportMessage = text;
    this.useHint(text);
    this.mathSupportText?.setText(text).setColor("#f7d37a");
    if (this.mathSupportText) {
      this.tweens.add({
        targets: this.mathSupportText,
        alpha: { from: 0.35, to: 1 },
        duration: 180,
        ease: "Sine.easeOut",
      });
    }
  }

  private pressMathKey(key: string): void {
    const puzzle = this.currentMathPuzzle();
    if (key === "C") {
      this.mathEntry = "";
      this.openMath();
      return;
    }
    if (key === "OK") {
      const enteredValue = Number(this.mathEntry);
      if (enteredValue === puzzle.answer) {
        this.solvePuzzle(this.currentPuzzleId("math"), puzzle.competencies);
        return;
      }
      this.mathEntry = "";
      this.mathSupportMessage = `Il valore ${Number.isFinite(enteredValue) ? enteredValue : "inserito"} non chiude il terminale. Controlla un passaggio intermedio, non provare numeri a caso. ${this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)])}`;
      if (this.handleIncorrectAnswer(this.mathSupportMessage)) {
        return;
      }
      this.openMath();
      return;
    }
    if (this.mathEntry.length < 4) {
      this.mathEntry += key;
      this.openMath();
    }
  }

  private openEnglish(): void {
    const puzzle = this.currentEnglishPuzzle();
    const overlay = this.createOverlay(puzzle.title, 660, { x: 40, y: 30, width: 1200 });
    const instructionSize = puzzle.instruction.length > 122 ? 16 : puzzle.instruction.length > 96 ? 18 : puzzle.instruction.length > 72 ? 20 : 22;
    overlay.add(this.add.text(56, 78, (puzzle.difficultyLabel ?? "Livello 1 - comandi e divieti").toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(56, 104, `${this.englishChallengeLabel(puzzle.challengeType)}${puzzle.scenario ? ` | ${puzzle.scenario}` : ""}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 1030 },
    }));
    overlay.add(this.add.text(56, 136, puzzle.instruction, {
      fontFamily: "Inter, Arial",
      fontSize: `${instructionSize}px`,
      color: "#f5fbff",
      wordWrap: { width: 1040 },
      lineSpacing: 4,
    }));
    this.drawEnglishChallengePanel(overlay, puzzle);
    this.drawEnglishSupportPanel(overlay, puzzle);
    this.drawEnglishReasoningPanel(overlay, puzzle);

    if (!this.englishAnalyzed) {
      overlay.add(new Button(this, 866, 574, "Decodifica comando", () => {
        this.englishAnalyzed = true;
        audioManager.playOutcome("neutral");
        outcomeFeedback.play(this, "info", "Comando decodificato");
        feedbackSystem.publish(`Decodifica avviata: ${puzzle.method ?? "cerca verbo, oggetto, condizione e divieto."}`, "info");
        this.openEnglish();
      }, { width: 310, height: 52, fill: 0x173b36 }));
      return;
    }
    puzzle.choices.forEach((choice, index) => {
      overlay.add(new Button(this, 866, 402 + index * 50, choice.label, () => {
        if (choice.isCorrect) {
          this.solvePuzzle(this.currentPuzzleId("english"), puzzle.competencies);
          return;
        }
        this.handleIncorrectAnswer(choice.feedback);
      }, { width: 540, height: 42, fontSize: 13, fill: 0x263743 }));
    });
    this.addMethodStrip(overlay, 56, 596, 520, "Metodo", puzzle.methodSteps ?? [
      "verbo d'azione",
      "oggetto e quantità",
      "condizione, limite o divieto",
    ]);
    overlay.add(new Button(this, 866, 620, "Indizio mirato", () => {
      this.useHint(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)]));
      this.openEnglish();
    }, { width: 250, height: 40, fontSize: 13, fill: 0x263743 }));
  }

  private drawEnglishChallengePanel(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(316, 288, 520, 170, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(76, 218, "Sfida", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 242, puzzle.taskPrompt ?? puzzle.commandGoal ?? "Trasforma l'istruzione inglese in una procedura sicura.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 462 },
      lineSpacing: 3,
    }));
    const source = puzzle.sourceText ? (puzzle.sourceText.length > 124 ? `${puzzle.sourceText.slice(0, 121)}...` : puzzle.sourceText) : undefined;
    if (source) {
      overlay.add(this.add.text(76, 296, source, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        wordWrap: { width: 462 },
        lineSpacing: 3,
      }));
    }
    overlay.add(this.add.text(76, source ? 348 : 328, `Scopo: ${puzzle.learningPurpose ?? "Allena inglese operativo dentro una decisione tecnica."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 462 },
      lineSpacing: 2,
    }));
  }

  private drawEnglishSupportPanel(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(866, 288, 540, 170, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(614, 218, "Parole chiave e dati", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(614, 242, (puzzle.conceptTags ?? []).slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 500 },
      lineSpacing: 3,
    }));

    const dataPoints = (puzzle.dataPoints ?? []).slice(0, 3);
    if (dataPoints.length > 0) {
      dataPoints.forEach((point, index) => {
        const y = 284 + index * 28;
        overlay.add(this.add.rectangle(618, y - 4, 494, 24, 0x132835, 0.9).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
        overlay.add(this.add.text(630, y, `${point.label}: ${point.value}${point.note ? ` | ${point.note}` : ""}`, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#d9eaf1",
          wordWrap: { width: 470 },
        }));
      });
      return;
    }

    const glossary = (puzzle.glossary ?? []).slice(0, 5);
    glossary.forEach((item, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      overlay.add(this.add.text(626 + col * 236, 288 + row * 34, `${item.term}: ${item.meaning}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        wordWrap: { width: 216 },
        lineSpacing: 2,
      }));
    });
  }

  private drawEnglishReasoningPanel(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(316, 478, 520, 150, 0x07151d, 0.82).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(this.add.text(76, 414, this.englishAnalyzed ? "Ragionamento" : "Prima della risposta", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const text = this.englishAnalyzed
      ? puzzle.diagnosticSteps.slice(0, 4).map((step, index) => `${index + 1}. ${step}`).join("\n")
      : `Decodifica il comando: cerca verbo, oggetto, condizione e parole che limitano l'azione.\nMetodo: ${puzzle.method ?? "leggi prima l'azione, poi divieti e condizioni."}`;
    overlay.add(this.add.text(76, 440, text, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: this.englishAnalyzed ? "#9ff5e9" : "#d9eaf1",
      wordWrap: { width: 470 },
      lineSpacing: 5,
    }));
  }

  private openMusic(): void {
    const puzzle = this.currentMusicPuzzle();
    const puzzleId = this.currentPuzzleId("music");
    const overlay = this.createOverlay(puzzle.title, 660, { x: 40, y: 30, width: 1200 });
    overlay.add(this.add.text(56, 76, `${puzzle.difficultyLabel.toUpperCase()} | Tempo obiettivo: ${formatDuration(puzzle.timeLimitMs)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(56, 104, "Obiettivo: riconosci la nota scritta sul pentagramma. Guarda prima la chiave, poi conta linee, spazi e linee addizionali.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 1040 },
      lineSpacing: 4,
    }));
    this.drawMusicStaff(overlay, puzzle, 320, 310);
    this.drawMusicSupport(overlay, puzzle);
    const timerText = this.add.text(868, 146, "", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5);
    overlay.add(timerText);
    this.startMusicCountdown(puzzleId, puzzle, timerText);

    puzzle.choices.forEach((choice, index) => {
      const x = 756 + (index % 2) * 260;
      const y = 390 + Math.floor(index / 2) * 74;
      overlay.add(new Button(this, x, y, choice.label, () => {
        if (this.musicTimeExpired(puzzleId, puzzle)) {
          this.handleIncorrectAnswer("Tempo scaduto: la nota va riconosciuta entro il tempo del livello. Usa la chiave come ancora, poi conta linee e spazi.");
          return;
        }
        if (choice.isCorrect) {
          this.solvePuzzle(puzzleId, puzzle.competencies);
          return;
        }
        this.handleIncorrectAnswer(choice.feedback);
      }, { width: 220, height: 56, fontSize: 20, fill: choice.isCorrect ? 0x173b36 : 0x263743 }));
    });

    this.addMethodStrip(overlay, 56, 590, 520, "Metodo", puzzle.methodSteps);
    overlay.add(new Button(this, 866, 586, "Indizio di lettura", () => {
      this.useHint(this.nextPedagogicHint(puzzle, puzzle.hints[Math.min(this.run.hintsUsed, puzzle.hints.length - 1)]));
      this.openMusic();
    }, { width: 280, height: 44, fontSize: 14, fill: 0x263743 }));
  }

  private drawMusicStaff(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number): void {
    overlay.add(this.add.rectangle(centerX, centerY, 560, 320, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(centerX - 244, centerY - 140, puzzle.clef === "treble" ? "Chiave di violino" : "Chiave di basso", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const lineSpacing = 28;
    const staffLeft = centerX - 210;
    const staffRight = centerX + 226;
    const topY = centerY - 72;
    for (let index = 0; index < 5; index += 1) {
      const y = topY + index * lineSpacing;
      overlay.add(this.add.rectangle((staffLeft + staffRight) / 2, y, staffRight - staffLeft, 2, 0x9ff5e9, 0.78));
    }
    overlay.add(this.add.text(staffLeft - 64, topY - 42, puzzle.clef === "treble" ? "𝄞" : "𝄢", {
      fontFamily: "Georgia, 'Times New Roman', serif",
      fontSize: puzzle.clef === "treble" ? "86px" : "76px",
      color: "#f7d37a",
    }).setOrigin(0.5, 0));
    const noteX = centerX + 46;
    const noteY = topY + puzzle.staffPosition * (lineSpacing / 2);
    puzzle.ledgerLines.forEach((position) => {
      const y = topY + position * (lineSpacing / 2);
      overlay.add(this.add.rectangle(noteX, y, 96, 2, 0xf7d37a, 0.88));
    });
    const note = this.add.ellipse(noteX, noteY, 34, 24, 0xf5fbff, 1).setRotation(-0.42).setStrokeStyle(2, 0xf7d37a, 0.9);
    overlay.add(note);
    overlay.add(this.add.rectangle(noteX + 18, noteY - 42, 3, 86, 0xf5fbff, 0.94));
    overlay.add(this.add.text(centerX - 244, centerY + 112, [
      `Posizione: ${puzzle.staffPosition % 2 === 0 ? "linea" : "spazio"}`,
      puzzle.ledgerLines.length > 0 ? `Linee addizionali: ${puzzle.ledgerLines.length}` : "Nessuna linea addizionale",
      "Risposta completa: nome + ottava",
    ].join("  |  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 500 },
    }));
  }

  private drawMusicSupport(overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle): void {
    overlay.add(this.add.rectangle(866, 266, 540, 196, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(614, 184, "Come ragionare", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(614, 212, puzzle.method, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 500 },
      lineSpacing: 4,
    }));
    overlay.add(this.add.text(614, 306, `Scopo didattico: ${puzzle.learningPurpose}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 500 },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(614, 352, puzzle.conceptTags.map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 500 },
    }));
  }

  private startMusicCountdown(puzzleId: string, puzzle: GeneratedMusicPuzzle, text: Phaser.GameObjects.Text): void {
    this.musicTimerEvent?.remove(false);
    const update = (): void => {
      if (!text.active) return;
      const remaining = Math.max(0, puzzle.timeLimitMs - this.puzzleElapsedMs(puzzleId));
      text.setText(`Tempo nota: ${formatDuration(remaining)}`);
      text.setColor(remaining < 3_000 ? "#ff8a8a" : "#f7d37a");
    };
    update();
    this.musicTimerEvent = this.time.addEvent({ delay: 160, loop: true, callback: update });
  }

  private puzzleElapsedMs(puzzleId: string): number {
    const startedAt = (saveSystem.data.proceduralRun ?? this.run).puzzleStats?.[puzzleId]?.startedAt;
    if (!startedAt) return 0;
    return Math.max(0, Date.now() - new Date(startedAt).getTime());
  }

  private musicTimeExpired(puzzleId: string, puzzle: GeneratedMusicPuzzle): boolean {
    return this.puzzleElapsedMs(puzzleId) > puzzle.timeLimitMs;
  }

  private openRobot(): void {
    const puzzle = this.currentRobotPuzzle();
    const model = RobotConsole.fromPuzzle(puzzle);
    const overlay = this.createOverlay(model.title, 620);
    this.robotExecuting = false;
    this.robotCellSize = Math.min(42, Math.floor(270 / Math.max(puzzle.cols, puzzle.rows)));
    this.robotOrigin = { x: 118, y: 178 };
    overlay.add(this.add.text(48, 74, (model.instructions ?? [
      "Obiettivo: raggiungi la stella, usa Raccogli, poi raggiungi il quadrato e usa Esci.",
      "La punta del robot indica la direzione iniziale.",
    ]).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 700 },
      lineSpacing: 4,
    }));
    for (let row = 0; row < puzzle.rows; row += 1) {
      for (let col = 0; col < puzzle.cols; col += 1) {
        const blocked = puzzle.obstacles.some((cell) => cell.col === col && cell.row === row);
        overlay.add(this.add.rectangle(this.robotCellX(col), this.robotCellY(row), this.robotCellSize - 4, this.robotCellSize - 4, blocked ? 0x4c2b38 : 0x132835, 1).setStrokeStyle(1, blocked ? 0xc94b55 : 0x315766, 0.7));
      }
    }
    [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order).forEach((checkpoint) => {
      overlay.add(this.add.circle(this.robotCellX(checkpoint.col), this.robotCellY(checkpoint.row), Math.max(9, this.robotCellSize * 0.28), 0x8a7cff, 0.72).setStrokeStyle(2, 0xf5fbff, 0.58));
      overlay.add(this.add.text(this.robotCellX(checkpoint.col), this.robotCellY(checkpoint.row), checkpoint.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
    });
    this.robotSprite = this.add.triangle(
      this.robotCellX(puzzle.start.col),
      this.robotCellY(puzzle.start.row),
      0,
      -16,
      14,
      14,
      -14,
      14,
      0x6be7d6,
      1,
    );
    this.robotSprite.setStrokeStyle(2, 0xf5fbff, 0.8).setRotation(this.robotRotationFor(puzzle.start.facing));
    this.robotKeyMarker = this.add.star(this.robotCellX(puzzle.key.col), this.robotCellY(puzzle.key.row), 5, 7, 16, 0xf6c85f, 1);
    const exitMarker = this.add.rectangle(this.robotCellX(puzzle.exit.col), this.robotCellY(puzzle.exit.row), 24, 24, 0x9ff5e9, 0.45);
    overlay.add(this.robotSprite);
    overlay.add(this.robotKeyMarker);
    overlay.add(exitMarker);
    overlay.add(this.add.text(48, 374, `Legenda: triangolo = robot (${this.facingLabel(puzzle.start.facing)}), stella = chiave, quadrato = uscita, viola = checkpoint, rosso = ostacolo.`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 330 },
    }));
    this.addMethodStrip(overlay, 48, 404, 330, "Metodo", [
      "simula con il dito",
      "segna svolte",
      "esegui quando il piano e completo",
    ]);
    overlay.add(this.add.text(430, 146, `Sequenza:\n${this.robotCommands.length ? this.robotCommands.map((command, i) => `${i + 1}. ${commandLabels[command]}`).join("\n") : "(vuota)"}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 300 },
      lineSpacing: 4,
    }));
    const debugLine = model.buggedCommands
      ? `\n\nLog guasto:\n${this.formatRobotCommands(model.buggedCommands, 7)}`
      : "";
    overlay.add(this.add.text(430, 52, [
      `Concetti: ${model.conceptTags.slice(0, 4).join(", ") || "sequenza, direzione"}`,
      model.debugBrief ?? "Progetta la rotta prima di eseguire: la console premia programmi spiegabili.",
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      wordWrap: { width: 300 },
      lineSpacing: 4,
    }));
    this.robotStatusText = this.add.text(430, 318, `Condizioni:\n${model.successConditions.map((condition) => `- ${condition}`).join("\n")}${debugLine}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c9dce6",
      wordWrap: { width: 300 },
      lineSpacing: 4,
    });
    overlay.add(this.robotStatusText);
    (["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "PICK_UP", "EXIT"] satisfies GridCommand[]).forEach((command, index) => {
      overlay.add(new Button(this, 144 + index * 132, 474, commandLabels[command], () => {
        if (!this.robotExecuting && this.robotCommands.length < (puzzle.maxCommands ?? puzzle.solutionCommands.length + 4)) {
          this.robotCommands.push(command);
          this.openRobot();
        } else if (!this.robotExecuting) {
          this.useHint("Il buffer e pieno: non aggiungere tentativi. Simula il percorso e togli i comandi che non cambiano obiettivo.");
        }
      }, { width: 116, height: 40, fontSize: 13 }));
    });
    overlay.add(new Button(this, 282, 564, "Esegui", () => this.executeRobot(), { width: 180, height: 44, fill: 0x173b36 }));
    overlay.add(new Button(this, 506, 564, "Pulisci", () => {
      if (this.robotExecuting) {
        return;
      }
      this.robotCommands = [];
      this.openRobot();
    }, { width: 180, height: 44, fill: 0x263743 }));
  }

  private executeRobot(): void {
    if (this.robotExecuting || this.robotCommands.length === 0) {
      return;
    }
    const puzzle = this.currentRobotPuzzle();
    this.robotExecuting = true;
    let state = { ...puzzle.start };
    let hasKey = false;
    const checkpoints = [...(puzzle.checkpoints ?? [])].sort((a, b) => a.order - b.order);
    let checkpointIndex = 0;
    const turn = (facing: GridFacing, direction: "L" | "R"): GridFacing => {
      const order: GridFacing[] = ["N", "E", "S", "W"];
      const offset = direction === "R" ? 1 : -1;
      return order[(order.indexOf(facing) + offset + order.length) % order.length];
    };

    const fail = (message: string, col = state.col, row = state.row): void => {
      this.robotExecuting = false;
      this.robotStatusText?.setColor("#f7d37a").setText(message);
      this.flashRobotCell(col, row, 0xc94b55);
      this.shakeRobot();
      this.handleIncorrectAnswer(message);
    };

    const runAt = (index: number): void => {
      if (index >= this.robotCommands.length) {
        if (checkpointIndex < checkpoints.length) {
          fail(`Il programma si ferma prima del checkpoint ${checkpoints[checkpointIndex].label}: dividi la rotta in tappe e completa la prossima tappa.`);
          return;
        }
        fail(hasKey ? mistakeAnalyzer.robotFailureMessage({ kind: "not-exited" }, this.robotCommands) : mistakeAnalyzer.robotFailureMessage({ kind: "missing-key" }, this.robotCommands));
        return;
      }
      const command = this.robotCommands[index];
      this.robotStatusText?.setColor("#d9eaf1").setText(`Passo ${index + 1}: ${commandLabels[command]}`);
      if (command === "TURN_LEFT") {
        state.facing = turn(state.facing, "L");
        this.tweens.add({
          targets: this.robotSprite,
          rotation: this.robotRotationFor(state.facing),
          duration: 180,
          onComplete: () => this.time.delayedCall(90, () => runAt(index + 1)),
        });
        return;
      } else if (command === "TURN_RIGHT") {
        state.facing = turn(state.facing, "R");
        this.tweens.add({
          targets: this.robotSprite,
          rotation: this.robotRotationFor(state.facing),
          duration: 180,
          onComplete: () => this.time.delayedCall(90, () => runAt(index + 1)),
        });
        return;
      } else if (command === "MOVE_FORWARD") {
        const delta = { N: [0, -1], E: [1, 0], S: [0, 1], W: [-1, 0] }[state.facing];
        const next = { col: state.col + delta[0], row: state.row + delta[1], facing: state.facing };
        const blocked = next.col < 0 || next.row < 0 || next.col >= puzzle.cols || next.row >= puzzle.rows || puzzle.obstacles.some((cell) => cell.col === next.col && cell.row === next.row);
        if (blocked) {
          fail(mistakeAnalyzer.robotFailureMessage({ kind: "wall", commandIndex: index }, this.robotCommands), next.col, next.row);
          return;
        }
        state = next;
        const checkpoint = checkpoints[checkpointIndex];
        if (checkpoint && state.col === checkpoint.col && state.row === checkpoint.row) {
          checkpointIndex += 1;
          this.flashRobotCell(state.col, state.row, 0x8a7cff);
          this.robotStatusText?.setColor("#9ff5e9").setText(`Checkpoint ${checkpoint.label} validato. Prossimo sotto-obiettivo: ${checkpointIndex < checkpoints.length ? `checkpoint ${checkpoints[checkpointIndex].label}` : "chiave"}.`);
        }
        audioManager.play("footstep");
        this.tweens.add({
          targets: this.robotSprite,
          x: this.robotCellX(state.col),
          y: this.robotCellY(state.row),
          duration: 260,
          ease: "Sine.easeInOut",
          onComplete: () => this.time.delayedCall(80, () => runAt(index + 1)),
        });
        return;
      } else if (command === "PICK_UP") {
        if (checkpointIndex < checkpoints.length) {
          fail(`Hai provato a raccogliere prima di validare il checkpoint ${checkpoints[checkpointIndex].label}. Il programma deve rispettare l'ordine dei sotto-obiettivi.`, state.col, state.row);
          return;
        }
        hasKey = state.col === puzzle.key.col && state.row === puzzle.key.row;
        if (!hasKey) {
          fail(mistakeAnalyzer.robotFailureMessage({ kind: "premature-pickup", commandIndex: index }, this.robotCommands));
          return;
        }
        audioManager.play("success");
        this.robotKeyMarker?.setAlpha(0.2).setScale(0.7);
        this.tweens.add({
          targets: this.robotSprite,
          scale: 1.24,
          duration: 130,
          yoyo: true,
          onComplete: () => this.time.delayedCall(100, () => runAt(index + 1)),
        });
        return;
      } else if (command === "EXIT") {
        if (hasKey && checkpointIndex === checkpoints.length && state.col === puzzle.exit.col && state.row === puzzle.exit.row) {
          this.robotStatusText?.setColor("#9ff5e9").setText("Percorso confermato: chiave recuperata e uscita raggiunta.");
          this.flashRobotCell(state.col, state.row, 0x9ff5e9);
          audioManager.play("success");
          this.tweens.add({
            targets: this.robotSprite,
            scale: 1.35,
            alpha: 0.25,
            duration: 420,
            yoyo: true,
            onComplete: () => this.solvePuzzle(this.currentPuzzleId("robot"), puzzle.competencies),
          });
          return;
        }
        if (checkpointIndex < checkpoints.length) {
          fail(`La porta robot rifiuta il programma: manca il checkpoint ${checkpoints[checkpointIndex].label}.`);
          return;
        }
        fail(mistakeAnalyzer.robotFailureMessage(hasKey ? { kind: "not-exited" } : { kind: "missing-key" }, this.robotCommands));
        return;
      }
    };

    runAt(0);
  }

  private robotCellX(col: number): number {
    return this.robotOrigin.x + col * this.robotCellSize;
  }

  private robotCellY(row: number): number {
    return this.robotOrigin.y + row * this.robotCellSize;
  }

  private robotRotationFor(facing: GridFacing): number {
    return {
      N: 0,
      E: Math.PI / 2,
      S: Math.PI,
      W: -Math.PI / 2,
    }[facing];
  }

  private flashRobotCell(col: number, row: number, color: number): void {
    const puzzle = this.currentRobotPuzzle();
    const safeCol = Phaser.Math.Clamp(col, 0, puzzle.cols - 1);
    const safeRow = Phaser.Math.Clamp(row, 0, puzzle.rows - 1);
    const flash = this.add.rectangle(this.robotCellX(safeCol), this.robotCellY(safeRow), this.robotCellSize - 6, this.robotCellSize - 6, color, 0.32);
    this.overlay?.add(flash);
    this.tweens.add({
      targets: flash,
      alpha: 0,
      scale: 1.2,
      duration: 520,
      onComplete: () => flash.destroy(),
    });
  }

  private shakeRobot(): void {
    if (!this.robotSprite) {
      return;
    }
    const startX = this.robotSprite.x;
    this.tweens.add({
      targets: this.robotSprite,
      x: { from: startX - 8, to: startX + 8 },
      duration: 45,
      yoyo: true,
      repeat: 4,
      onComplete: () => {
        this.robotSprite?.setX(startX);
      },
    });
    audioManager.play("error");
  }

  private facingLabel(facing: GridFacing): string {
    return {
      N: "punta verso nord",
      E: "punta verso est",
      S: "punta verso sud",
      W: "punta verso ovest",
    }[facing];
  }

  private formatRobotCommands(commands: GridCommand[], limit = commands.length): string {
    const visible = commands.slice(0, limit).map((command, index) => `${index + 1}. ${commandLabels[command]}`);
    if (commands.length > limit) {
      visible.push(`... altri ${commands.length - limit}`);
    }
    return visible.join("\n");
  }

  private openDoor(): void {
    const missing = this.requiredPuzzleIds().filter((id) => !this.isSolved(id));
    if (missing.length > 0) {
      feedbackSystem.publish(`La porta resta in attesa: manca ancora ${missing.map((id) => this.puzzleLabel(id)).join(", ")}.`, "hint");
      audioManager.playOutcome("wrong");
      return;
    }
    audioManager.playOutcome("complete");
    outcomeFeedback.play(this, "complete", proceduralRunRules.modeFor(this.run) === "training" ? "Allenamento registrato" : "Porta aperta");
    missionEngine.completeProceduralMission();
    feedbackSystem.publish(
      proceduralRunRules.modeFor(this.run) === "training"
        ? "Allenamento completato. Il diario registra voto, miglior tempo e competenze del focus."
        : "Missione completata. Il diario registra seed, competenze, tempo e vite rimaste.",
      "success",
    );
    this.time.delayedCall(900, () => this.scene.start("JournalScene"));
  }

  private solvePuzzle(puzzleId: string, competencies: string[]): void {
    const score = this.finalizePuzzleScore(puzzleId);
    saveSystem.markProceduralPuzzleSolved(puzzleId);
    competencyTracker.award(competencies, 10 + this.run.difficulty * 2 + (score.focusBonus > 0 ? 4 : 0));
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("correct");
    this.clearOverlay();
    const solvedNode = puzzleKindFromId(puzzleId);
    const remaining = this.requiredPuzzleIds().filter((id) => !this.isSolved(id) && id !== solvedNode);
    const nextLine = remaining.length > 0
      ? `Restano: ${remaining.map((id) => this.puzzleLabel(id)).join(", ")}.`
      : "Percorso disciplinare completo: la porta finale è pronta.";
    feedbackSystem.publish(`${this.dependencies.effectLine(solvedNode)} +${score.total} punti (${formatDuration(score.elapsedMs)}). ${score.feedback} ${nextLine}`, "success");
    this.time.delayedCall(640, () => this.scene.restart());
  }

  private nextPedagogicHint(puzzle: { hints: string[]; pedagogy?: { hintLadder: Array<{ text: string }> } }, fallback: string): string {
    const ladder = puzzle.pedagogy?.hintLadder;
    if (ladder && ladder.length > 0) {
      return ladder[Math.min(this.run.hintsUsed, ladder.length - 1)].text;
    }
    return fallback;
  }

  private useHint(text: string): void {
    this.recordPuzzleSupport();
    saveSystem.incrementProceduralHints();
    this.run = saveSystem.data.proceduralRun ?? this.run;
    audioManager.playOutcome("hint");
    feedbackSystem.publish(`Indizio: ${text}`, "hint");
  }

  private handleIncorrectAnswer(message: string): boolean {
    this.recordPuzzleMistake();
    if (proceduralRunRules.modeFor(this.run) === "mission") {
      this.loseMissionLife(message);
      return true;
    }
    audioManager.playOutcome("wrong");
    outcomeFeedback.play(this, "warning", "Risposta da rivedere");
    this.useHint(message);
    return false;
  }

  private loseMissionLife(reason: string): void {
    if (this.missionFailureInProgress) {
      return;
    }
    this.missionFailureInProgress = true;
    const lives = this.run.lives ?? proceduralRunRules.maxLives;
    const nextLives = Math.max(0, lives - 1);
    const now = new Date().toISOString();
    audioManager.playOutcome("wrong");
    this.clearOverlay();

    if (nextLives > 0) {
      const timeLimitMs = this.run.timeLimitMs ?? proceduralRunRules.missionTimeLimitMs(this.run.difficulty, Math.max(1, this.run.mission.objectives.length));
      saveSystem.updateProceduralRun({
        lives: nextLives,
        hintsUsed: 0,
        solvedPuzzleIds: [],
        score: { total: 0, byPuzzle: {}, byDomain: {} },
        puzzleStats: {},
        startedAt: now,
        timeLimitMs,
        deadlineAt: proceduralRunRules.deadlineFrom(now, timeLimitMs),
      });
      feedbackSystem.publish(`Vita persa: ${reason} Restano ${nextLives}/${this.run.maxLives ?? proceduralRunRules.maxLives}. La stanza riparte dallo stesso addestramento narrativo.`, "warning");
      this.time.delayedCall(1300, () => this.scene.restart());
      return;
    }

    saveSystem.updateProceduralRun({
      lives: 0,
      failedAt: now,
    });
    feedbackSystem.publish(`Missione fallita: ${reason} Le 3 vite sono terminate. Ricomincia dal menu con una nuova missione.`, "warning");
    this.time.delayedCall(1800, () => this.scene.start("MainMenuScene"));
  }

  private isSolved(puzzleId: string): boolean {
    return isProceduralPuzzleSolved(puzzleId, this.run.solvedPuzzleIds);
  }

  private allPuzzlesSolved(): boolean {
    return this.requiredPuzzleIds().every((id) => this.isSolved(id));
  }

  private refreshObjective(): void {
    if (this.checkMissionTimeout()) {
      return;
    }
    const pendingObjectives = this.run.mission.objectives.filter((objective) => !this.isSolved(objective.id.replace("procedural-", "")));
    const requiredCount = this.requiredPuzzleIds().length;
    const elapsed = this.run.completedAt
      ? new Date(this.run.completedAt).getTime() - new Date(this.run.startedAt).getTime()
      : Date.now() - new Date(this.run.startedAt).getTime();
    const mode = proceduralRunRules.modeFor(this.run);
    const focus = proceduralRunRules.focusFor(this.run);
    const recordKey = proceduralRunRules.trainingRecordKey(focus, this.run.difficulty);
    const record = saveSystem.data.trainingRecords?.[recordKey];
    const remainingMs = proceduralRunRules.remainingMs(this.run);
    const checklist = this.run.mission.objectives.map((objective) => {
      const puzzleId = objective.id.replace("procedural-", "");
      return `${this.isSolved(puzzleId) ? "[OK]" : "[ ]"} ${objective.label}`;
    }).join("\n");
    this.objectiveText?.setText(
      pendingObjectives.length > 0
        ? mode === "mission"
          ? `Console da sistemare\n${checklist}\n\nOrdine libero. Ogni errore o tempo scaduto consuma una vita.`
          : `Allenamento ${proceduralScoring.domainLabel(focus)}\n${checklist}\n\nIl voto pesa tempo, precisione e aiuti usati.`
        : mode === "mission"
          ? `Tutti i sistemi sono coerenti.\n[OK] Apri la porta finale.\n\nSeed: ${this.run.seed}`
          : `Allenamento completato.\n[OK] Apri la porta per registrare voto e miglior tempo.\n\nSeed: ${this.run.seed}`,
    );
    this.progressText?.setText(
      mode === "mission"
        ? `${this.requiredPuzzleIds().filter((id) => this.isSolved(id)).length}/${requiredCount} esercizi completati\nVite: ${this.run.lives ?? proceduralRunRules.maxLives}/${this.run.maxLives ?? proceduralRunRules.maxLives}\nTempo restante: ${formatDuration(Math.max(0, remainingMs))}\nPunti: ${this.run.score?.total ?? 0}`
        : `${this.requiredPuzzleIds().filter((id) => this.isSolved(id)).length}/${requiredCount} esercizi completati\nIndizi: ${this.run.hintsUsed}\nTempo: ${formatDuration(elapsed)}\nRecord: ${record ? formatDuration(record.bestTimeMs) : "non ancora"}\nPunti: ${this.run.score?.total ?? 0}`,
    );
  }

  private checkMissionTimeout(): boolean {
    if (proceduralRunRules.modeFor(this.run) !== "mission" || this.run.completedAt || this.run.failedAt) {
      return false;
    }
    if (proceduralRunRules.remainingMs(this.run) > 0) {
      return false;
    }
    this.loseMissionLife("tempo esaurito.");
    return true;
  }

  private requiredPuzzleIds(): string[] {
    return proceduralRequiredPuzzleIds(this.run.mission.objectives);
  }

  private puzzleLabel(id: string): string {
    return {
      language: "italiano",
      circuit: "circuiti",
      math: "matematica",
      english: "inglese",
      robot: "coding",
      music: "musica",
    }[puzzleKindFromId(id)];
  }

  private findFocusChallenge(id: string): GeneratedFocusChallenge | undefined {
    return this.run.mission.focusChallenges?.find((challenge) => challenge.id === id);
  }

  private currentPuzzleId(kind: ProceduralPuzzleId): string {
    return this.activePuzzleKind === kind ? this.activePuzzleId ?? kind : kind;
  }

  private currentLanguagePuzzle(): GeneratedLanguagePuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "language" ? challenge.puzzle : this.run.mission.puzzles.language;
  }

  private currentCircuitPuzzle(): GeneratedCircuitPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "circuit" ? challenge.puzzle : this.run.mission.puzzles.circuit;
  }

  private currentMathPuzzle(): GeneratedMathPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "math" ? challenge.puzzle : this.run.mission.puzzles.math;
  }

  private currentEnglishPuzzle(): GeneratedEnglishPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "english" ? challenge.puzzle : this.run.mission.puzzles.english;
  }

  private currentMusicPuzzle(): GeneratedMusicPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "music" ? challenge.puzzle : this.run.mission.puzzles.music;
  }

  private currentRobotPuzzle(): GeneratedRobotPuzzle {
    const challenge = this.activeChallenge;
    return challenge?.kind === "robot" ? challenge.puzzle : this.run.mission.puzzles.robot;
  }

  private resetTransientPuzzleState(): void {
    this.mathEntry = "";
    this.mathStepIndex = 0;
    this.mathSupportMessage = "";
    this.mathSupportText = undefined;
    this.languageAnalyzed = false;
    this.englishAnalyzed = false;
    this.circuitInspected = false;
    this.selectedRepairs.clear();
    this.robotCommands = [];
    this.robotExecuting = false;
    this.musicTimerEvent?.remove(false);
    this.musicTimerEvent = undefined;
  }

  private ensurePuzzleTimer(puzzleId: string): void {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const current = run.puzzleStats?.[puzzleId];
    if (current?.startedAt) {
      return;
    }
    const startedAt = new Date().toISOString();
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [puzzleId]: {
          puzzleId,
          domain: proceduralScoring.puzzleDomain(puzzleId),
          startedAt,
          elapsedMs: 0,
          hintsUsed: 0,
          attempts: 0,
          basePoints: 0,
          difficultyBonus: 0,
          speedBonus: 0,
          focusBonus: 0,
          supportPenalty: 0,
          total: 0,
          feedback: "Timer avviato.",
        },
      },
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private recordPuzzleSupport(): void {
    const puzzleId = this.activePuzzleId;
    const run = saveSystem.data.proceduralRun ?? this.run;
    if (!puzzleId || this.isSolved(puzzleId)) {
      return;
    }
    const current = run.puzzleStats?.[puzzleId];
    if (!current) {
      this.ensurePuzzleTimer(puzzleId);
    }
    const refreshed = saveSystem.data.proceduralRun ?? this.run;
    const stats = refreshed.puzzleStats?.[puzzleId];
    if (!stats) {
      return;
    }
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(refreshed.puzzleStats ?? {}),
        [puzzleId]: {
          ...stats,
          hintsUsed: stats.hintsUsed + 1,
        },
      },
    });
  }

  private recordPuzzleMistake(): void {
    const puzzleId = this.activePuzzleId;
    const run = saveSystem.data.proceduralRun ?? this.run;
    if (!puzzleId || this.isSolved(puzzleId)) {
      return;
    }
    const current = run.puzzleStats?.[puzzleId];
    if (!current) {
      this.ensurePuzzleTimer(puzzleId);
    }
    const refreshed = saveSystem.data.proceduralRun ?? this.run;
    const stats = refreshed.puzzleStats?.[puzzleId];
    if (!stats) {
      return;
    }
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(refreshed.puzzleStats ?? {}),
        [puzzleId]: {
          ...stats,
          attempts: stats.attempts + 1,
        },
      },
    });
    this.run = saveSystem.data.proceduralRun ?? this.run;
  }

  private finalizePuzzleScore(puzzleId: string) {
    const run = saveSystem.data.proceduralRun ?? this.run;
    const startedAt = run.puzzleStats?.[puzzleId]?.startedAt ?? new Date().toISOString();
    const existing = run.puzzleStats?.[puzzleId];
    const completedAt = new Date().toISOString();
    const score = proceduralScoring.calculate({
      puzzleId,
      difficulty: run.difficulty,
      focus: run.focus,
      startedAt,
      completedAt,
      hintsUsed: existing?.hintsUsed ?? 0,
      attempts: (existing?.attempts ?? 0) + 1,
    });
    saveSystem.updateProceduralRun({
      puzzleStats: {
        ...(run.puzzleStats ?? {}),
        [puzzleId]: score,
      },
      score: proceduralScoring.addToSummary(run.score, score),
    });
    this.activePuzzleId = undefined;
    this.activePuzzleKind = undefined;
    this.activeChallenge = undefined;
    this.resetTransientPuzzleState();
    return score;
  }

  private createOverlay(
    title: string,
    height: number,
    layout: { x?: number; y?: number; width?: number } = {},
  ): Phaser.GameObjects.Container {
    this.clearOverlay();
    const width = layout.width ?? 800;
    const defaultY = height > 660 ? 10 : 68;
    const overlay = this.add.container(layout.x ?? 240, layout.y ?? defaultY);
    overlay.add(SceneChrome.consolePanel(this, 0, 0, width, height, title, "lab"));
    overlay.add(new Button(this, width - 84, 40, "X", () => this.clearOverlay(), {
      width: 48,
      height: 40,
      fontSize: 18,
      fill: 0x263743,
    }));
    this.overlay = overlay;
    return overlay;
  }

  private addLanguageBrief(overlay: Phaser.GameObjects.Container, model: LanguageRepairModel): void {
    overlay.add(this.add.rectangle(316, 326, 520, 188, 0x07151d, 0.84).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(76, 246, "Obiettivo di riparazione", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 270, model.repairGoal, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 3,
    }));
    overlay.add(this.add.text(76, 342, `Scopo: ${model.learningPurpose}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 2,
    }));

    overlay.add(this.add.rectangle(866, 256, 540, 66, 0x07151d, 0.78).setStrokeStyle(1, 0x6be7d6, 0.2));
    overlay.add(this.add.text(614, 232, "Concetti allenati", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(614, 254, model.conceptTags.slice(0, 5).map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 500, useAdvancedWrap: true },
      lineSpacing: 3,
    }));

    overlay.add(this.add.rectangle(316, 498, 520, 134, 0x07151d, 0.78).setStrokeStyle(1, 0xf6c85f, 0.24));
    overlay.add(this.add.text(76, 444, "Controllo di qualità", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(76, 468, model.method, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 456, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
  }

  private addEnglishBrief(overlay: Phaser.GameObjects.Container, puzzle: GeneratedEnglishPuzzle): void {
    overlay.add(this.add.rectangle(400, 256, 704, 164, 0x07151d, 0.86).setStrokeStyle(1, 0x6be7d6, 0.24));
    overlay.add(this.add.text(62, 184, "Sfida", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(62, 204, puzzle.taskPrompt ?? puzzle.commandGoal ?? "Trasforma l'istruzione inglese in una procedura sicura e non ambigua.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 410 },
      lineSpacing: 3,
    }));
    if (puzzle.sourceText) {
      const sourceText = /^(log|broken log|source|fonte):/i.test(puzzle.sourceText)
        ? puzzle.sourceText
        : `Fonte: ${puzzle.sourceText}`;
      overlay.add(this.add.text(62, 254, sourceText, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        wordWrap: { width: 410 },
        lineSpacing: 3,
      }));
    }
    overlay.add(this.add.text(62, 318, `Scopo: ${puzzle.learningPurpose ?? "Allena inglese operativo dentro una decisione tecnica."}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
      wordWrap: { width: 642 },
    }));
    overlay.add(this.add.text(500, 184, (puzzle.conceptTags ?? ["action", "condition", "safety"]).slice(0, 3).map((tag) => `#${tag}`).join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 226 },
      lineSpacing: 4,
    }));
    const dataPoints = (puzzle.dataPoints ?? []).slice(0, 3);
    dataPoints.forEach((point, index) => {
      const y = 232 + index * 30;
      overlay.add(this.add.rectangle(610, y, 250, 24, 0x132835, 0.9).setStrokeStyle(1, 0x6be7d6, 0.25));
      overlay.add(this.add.text(492, y - 8, `${point.label}: ${point.value}${point.note ? ` (${point.note})` : ""}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#d9eaf1",
        wordWrap: { width: 236 },
      }));
    });
    const glossary = (puzzle.glossary ?? []).slice(0, 4);
    if (glossary.length > 0 && dataPoints.length === 0) {
      overlay.add(this.add.text(500, 244, glossary.map((item) => `${item.term}: ${item.meaning}`).join("\n"), {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
        wordWrap: { width: 238 },
        lineSpacing: 2,
      }));
    }
  }

  private englishChallengeLabel(type: GeneratedEnglishPuzzle["challengeType"]): string {
    return {
      command: "Comando",
      safety: "Sicurezza",
      sequence: "Sequenza",
      condition: "Condizione",
      "data-reading": "Dati",
      "procedure-debug": "Debug procedura",
      "vocabulary-in-context": "Lessico in contesto",
      inference: "Inferenza",
    }[type ?? "command"];
  }

  private addMethodStrip(overlay: Phaser.GameObjects.Container, x: number, y: number, width: number, title: string, steps: string[]): void {
    overlay.add(this.add.rectangle(x, y, width, 52, 0x07151d, 0.82).setOrigin(0).setStrokeStyle(1, 0xf6c85f, 0.32));
    overlay.add(this.add.text(x + 12, y + 8, title, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(this.add.text(x + 12, y + 27, steps.join("  ->  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 24 },
    }));
  }

  private clearOverlay(): void {
    this.musicTimerEvent?.remove(false);
    this.musicTimerEvent = undefined;
    this.overlay?.destroy(true);
    this.overlay = undefined;
    this.mathSupportText = undefined;
  }

  private handleFeedback(message: FeedbackMessage): void {
    const colors = {
      info: "#d9eaf1",
      hint: "#f7d37a",
      success: "#9ff5e9",
      warning: "#ffb36b",
    };
    this.feedbackText?.setColor(colors[message.tone]).setText(message.text);
    if (message.tone !== "info") {
      outcomeFeedback.play(this, message.tone as OutcomeTone);
    }
  }
}
