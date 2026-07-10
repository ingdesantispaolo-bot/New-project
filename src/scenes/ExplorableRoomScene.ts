import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { getProceduralFocusPath } from "../data/procedural/focusPaths";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { DifficultyLevel, ProceduralRunSave, ProceduralSpecialization } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { RoomExplorer, type RoomConsole, type RoomWall } from "./procedural/RoomExplorer";

/**
 * Hub esplorabile della Palestra. La logica vive in {@link RoomExplorer}
 * (riusata anche dalla fase Esplora della missione); qui ogni console avvia un
 * allenamento procedurale reale sul focus scelto.
 */
const WORLD_W = 1760;
const WORLD_H = 1120;

type ConsolePayload = {
  focus: ProceduralSpecialization;
  summary: string;
};

export class ExplorableRoomScene extends Phaser.Scene {
  private returnScene = "MainMenuScene";
  private explorer?: RoomExplorer;
  private overlayOpen = false;
  private launching = false;

  constructor() {
    super("ExplorableRoomScene");
  }

  create(data?: { returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    this.cameras.main.setBackgroundColor(0x060f16);

    const walls: RoomWall[] = [
      { x: 0, y: 0, w: WORLD_W, h: 40 },
      { x: 0, y: WORLD_H - 40, w: WORLD_W, h: 40 },
      { x: 0, y: 0, w: 40, h: WORLD_H },
      { x: WORLD_W - 40, y: 0, w: 40, h: WORLD_H },
      { x: 520, y: 470, w: 70, h: 240 },
      { x: 1170, y: 470, w: 70, h: 240 },
    ];
    const consoles: RoomConsole[] = [
      {
        id: "math", assetId: "math", label: "Matematica", glyph: "➗", color: 0x6be7d6, x: 250, y: 250, w: 120, h: 150,
        ref: { focus: "matematica", summary: "Grafici, vincoli, calcolo e passaggi controllati." } satisfies ConsolePayload,
      },
      {
        id: "italian", assetId: "italian", label: "Italiano", glyph: "✒️", color: 0x9f8cff, x: 710, y: 210, w: 120, h: 150,
        ref: { focus: "italiano", summary: "Frasi, log, nessi logici e significato operativo." } satisfies ConsolePayload,
      },
      {
        id: "english", assetId: "english", label: "Inglese", glyph: "🌍", color: 0x7ad7ff, x: 1180, y: 250, w: 120, h: 150,
        ref: { focus: "inglese", summary: "Comandi autentici, lessico utile e comprensione reale." } satisfies ConsolePayload,
      },
      {
        id: "coding", assetId: "coding", label: "Coding", glyph: "💻", color: 0x7cf6a6, x: 320, y: 840, w: 120, h: 150,
        ref: { focus: "coding", summary: "Sequenze, debug, cicli, condizioni e robot." } satisfies ConsolePayload,
      },
      {
        id: "circuit", assetId: "electronics", label: "Circuiti", glyph: "⚡", color: 0xf6c85f, x: 1180, y: 840, w: 120, h: 150,
        ref: { focus: "elettronica", summary: "Componenti, corrente, protezione e diagnosi graduale." } satisfies ConsolePayload,
      },
      {
        id: "music", assetId: "music", label: "Musica", glyph: "🎵", color: 0xff9d5c, x: 760, y: 900, w: 120, h: 150,
        ref: { focus: "musica", summary: "Note, pentagramma, ritmo e lettura rapida." } satisfies ConsolePayload,
      },
      {
        id: "physics", label: "Fisica", glyph: "F", color: 0x9ff5e9, x: 1490, y: 250, w: 120, h: 150,
        ref: { focus: "fisica", summary: "Forze, grandezze, unità, relazioni e ragionamento." } satisfies ConsolePayload,
      },
      { id: "door", assetId: "exit", label: "Uscita", glyph: "🚪", color: 0xffd75e, x: 1560, y: 560, w: 120, h: 150 },
    ];

    this.explorer = new RoomExplorer(this, {
      worldW: WORLD_W,
      worldH: WORLD_H,
      bgTexture: "action-room-bg",
      walls,
      consoles,
      seedKey: "preview",
      onInteract: (console) => this.onInteract(console),
    });

    this.buildHud();
    audioManager.play("scan");
  }

  update(_time: number, delta: number): void {
    this.explorer?.update(delta, this.overlayOpen);
  }

  private buildHud(): void {
    this.add.text(24, 22, "Mappa Palestra: cammina con WASD/frecce o tocca il pavimento · E vicino a una console", {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#c7dce7", backgroundColor: "rgba(4,18,28,0.8)", padding: { x: 10, y: 6 },
    }).setScrollFactor(0).setDepth(50);
    new Button(this, 1180, 40, "Indietro", () => this.scene.start(this.returnScene), { width: 150, height: 40, fontSize: 15, fill: 0x263743 })
      .setScrollFactor(0).setDepth(50);
  }

  private onInteract(console: RoomConsole): void {
    if (this.overlayOpen) return;
    audioManager.play("panelOpen");
    if (console.id === "door") {
      this.scene.start(this.returnScene);
      return;
    }
    const payload = console.ref as ConsolePayload | undefined;
    if (!payload?.focus) return;
    this.openFocusPanel(console, payload);
  }

  private openFocusPanel(console: RoomConsole, payload: ConsolePayload): void {
    this.overlayOpen = true;
    this.explorer?.pauseForOverlay();
    const path = getProceduralFocusPath([payload.focus]);
    const panel = this.add.container(640, 360).setScrollFactor(0).setDepth(100);
    panel.add(this.add.rectangle(0, 0, 1280, 720, 0x02070b, 0.72).setInteractive());
    panel.add(this.add.rectangle(0, 0, 680, 380, 0x07151d, 0.99).setStrokeStyle(3, console.color, 0.9));
    panel.add(this.add.text(0, -138, `${console.glyph}  ${path.label}`, { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    panel.add(this.add.text(0, -88, path.title, {
      fontFamily: "Inter, Arial", fontSize: "17px", color: "#f7d37a", fontStyle: "bold", align: "center",
    }).setOrigin(0.5));
    panel.add(this.add.text(0, -20, `${payload.summary}\n\n${path.stageHint}`, {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", align: "center", lineSpacing: 6, wordWrap: { width: 570 },
    }).setOrigin(0.5));
    panel.add(this.add.text(0, 78, "Avvierò una stanza generata su questo focus, senza pressione: risolvi le console e registra il risultato.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", align: "center", wordWrap: { width: 540 },
    }).setOrigin(0.5));
    panel.add(new Button(this, -150, 142, "Resta nella mappa", () => {
      panel.destroy(true);
      this.overlayOpen = false;
      this.explorer?.resume();
    }, { width: 240, height: 46, fill: 0x263743 }));
    panel.add(new Button(this, 166, 142, "Avvia allenamento", () => {
      panel.destroy(true);
      this.startFocusTraining(payload.focus);
    }, { width: 268, height: 46, fill: 0x173b36, stroke: console.color }));
  }

  private startFocusTraining(focus: ProceduralSpecialization): void {
    if (this.launching) return;
    this.launching = true;
    try {
      saveSystem.load();
      saveSystem.pauseActiveProceduralRun();
      this.createProceduralRun(focus, this.mapDifficulty(), focus === "libera" ? "mission" : "training");
      void startScene(this, "ProceduralMissionScene").catch(() => {
        this.launching = false;
        this.overlayOpen = false;
        this.explorer?.resume();
        this.showError("Non sono riuscito ad aprire l'allenamento. Riprova tra un istante.");
      });
    } catch {
      this.launching = false;
      this.overlayOpen = false;
      this.explorer?.resume();
      this.showError("Non sono riuscito a generare l'allenamento. Riprova con un nuovo seed.");
    }
  }

  private mapDifficulty(): DifficultyLevel {
    const run = saveSystem.getProceduralTrainingRun() ?? saveSystem.getProceduralMissionRun() ?? saveSystem.data.proceduralRun;
    return Phaser.Math.Clamp(Math.round(run?.difficulty ?? 2), 1, 8) as DifficultyLevel;
  }

  private createProceduralRun(
    focus: ProceduralSpecialization = "libera",
    difficulty: DifficultyLevel = this.mapDifficulty(),
    mode: "mission" | "training" = focus === "libera" ? "mission" : "training",
  ): void {
    const focusList = focus === "libera" ? ["libera"] : [focus];
    const mission = proceduralDirector.generateFreshMission(difficulty, focusList);
    const createdAt = new Date().toISOString();
    const objectiveCount = Math.max(1, mission.objectives.length);
    const pressureEnabled = proceduralRunRules.pressureEnabledForMode(mode);
    const timeLimitMs = pressureEnabled ? proceduralRunRules.missionTimeLimitMs(mission.difficulty, objectiveCount) : undefined;
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: focusList,
      mode,
      mission,
      hintsUsed: 0,
      solvedPuzzleIds: [],
      score: { total: 0, byPuzzle: {}, byDomain: {} },
      puzzleStats: {},
      lives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      maxLives: pressureEnabled ? proceduralRunRules.maxLives : undefined,
      timeLimitMs,
      timerState: "preparing",
      createdAt,
      activeElapsedMs: 0,
      startedAt: createdAt,
    };
    saveSystem.setProceduralRun(run);
  }

  private showError(message: string): void {
    const panel = this.add.rectangle(640, 664, 620, 46, 0x1f1414, 0.94).setStrokeStyle(1, 0xff8f8f, 0.58).setScrollFactor(0).setDepth(120);
    const text = this.add.text(640, 664, message, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f5fbff",
    }).setOrigin(0.5).setScrollFactor(0).setDepth(121);
    this.time.delayedCall(2400, () => {
      panel.destroy();
      text.destroy();
    });
  }
}
