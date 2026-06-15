import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { mapLayoutSystem, type MapLayoutRect } from "../core/MapLayoutSystem";
import { missionEngine } from "../core/MissionEngine";
import { proceduralRunRules } from "../core/ProceduralRunRules";
import { progressionSystem } from "../core/ProgressionSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { proceduralDirector } from "../procedural/ProceduralDirector";
import type { ProceduralRunSave } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { MissionCard } from "../ui/MissionCard";
import { VisualKit } from "../ui/VisualKit";

export class HubScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getHubLayout();

  constructor() {
    super("HubScene");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.drawHub();

    const mission = missionEngine.getActiveMission();
    const missionCard = this.rect("hub:missionCard", { x: 74, y: 98 });
    new MissionCard(this, missionCard.x, missionCard.y, mission);
    this.drawProgressionPanel();

    const title = this.rect("hub:title", { x: 74, y: 346 });
    this.add.text(title.x, title.y, "Hub Accademia", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(
      this.rect("hub:copy", { x: 74, y: 384, width: 440 }).x,
      this.rect("hub:copy", { x: 74, y: 384, width: 440 }).y,
      this.getHubCopy(),
      {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: "#c9dce6",
        wordWrap: { width: this.rect("hub:copy", { x: 74, y: 384, width: 440 }).width ?? 440 },
        lineSpacing: 5,
      },
    );

    const destination = this.getActiveDestination();
    const primary = this.rect("hub:primary", { x: 250, y: 552, width: 320 });
    new Button(this, primary.x, primary.y, destination.label, () => {
      void startScene(this, destination.scene);
    }, {
      width: primary.width,
    });
    if (saveSystem.data.flags.mission1Complete) {
      const review = this.rect("hub:reviewLab", { x: 610, y: 626, width: 260 });
      new Button(this, review.x, review.y, "Rivedi Laboratorio", () => {
        void startScene(this, "LaboratoryScene");
      }, {
        width: review.width,
        fill: 0x142736,
      });
    }
    const procedural = this.rect("hub:procedural", { x: 610, y: 552, width: 300 });
    new Button(this, procedural.x, procedural.y, "Missione Procedurale", () => this.startProceduralMission(), {
      width: procedural.width,
      fill: 0x173b36,
      fontSize: 18,
    });
    const journal = this.rect("hub:journal", { x: 250, y: 626, width: 320 });
    new Button(this, journal.x, journal.y, "Diario", () => this.scene.start("JournalScene"), {
      width: journal.width,
      fill: 0x142736,
    });
    VisualKit.vignette(this);
  }

  private drawHub(): void {
    this.cameras.main.setBackgroundColor("#061019");
    VisualKit.background(this, "academy");
    this.add.rectangle(640, 660, 1200, 96, 0x061019, 0.74).setStrokeStyle(1, 0x294958, 0.7);

    const corridor = this.add.graphics();
    corridor.fillStyle(0x0e222e, 0.2);
    corridor.fillRoundedRect(560, 70, 360, 590, 8);
    corridor.lineStyle(2, 0x6be7d6, 0.18);
    corridor.strokeRoundedRect(560, 70, 360, 590, 8);
    corridor.lineStyle(1, 0x6be7d6, 0.16);
    for (let y = 130; y < 630; y += 58) {
      corridor.lineBetween(560, y, 920, y);
    }

    VisualKit.glowFrame(this, 548, 58, 384, 614, "academy");
    const portal = this.rect("hub:portal", { x: 740, y: 302, width: 360, height: 590 });
    const portalGlow = this.add.image(portal.x, portal.y + 24, "holo-ring").setTint(0x6be7d6).setAlpha(0.42).setScale(3.3);
    this.tweens.add({ targets: portalGlow, rotation: Math.PI * 2, duration: 18000, repeat: -1 });
    this.add.rectangle(portal.x, portal.y, 146, 238, 0x071018, 0.34).setStrokeStyle(2, 0xf6c85f, 0.48);
    this.add.rectangle(portal.x, portal.y, 210, 330, 0x142d3a, 0.18).setStrokeStyle(3, 0x6be7d6, 0.38);
    this.add.text(portal.x - 86, portal.y - 180, "LAB 01", {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f6c85f",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 0, color: "#f6c85f", blur: 12, fill: true },
    });

    ["NUM", "BIO", "ARC"].forEach((label, index) => {
      const wingId = label === "NUM" ? "hub:wing:num" : label === "BIO" ? "hub:wing:bio" : "hub:wing:arc";
      const wing = this.rect(wingId, { x: 1010, y: 170 + index * 145, width: 210, height: 88 });
      const x = wing.x;
      const y = wing.y;
      const unlockedBio = label === "BIO" && saveSystem.data.flags.mission1Complete;
      const unlockedNumbers = label === "NUM" && saveSystem.data.flags.mission2Complete;
      const unlockedArchive = label === "ARC" && saveSystem.data.flags.mission3Complete;
      const unlocked = unlockedBio || unlockedNumbers || unlockedArchive;
      this.add
        .rectangle(
          x,
          y,
          210,
          88,
          unlocked ? (unlockedArchive ? 0x241f36 : unlockedNumbers ? 0x2f2512 : 0x123027) : 0x071018,
          unlocked ? 0.76 : 0.56,
        )
        .setStrokeStyle(1, unlockedArchive ? 0x9f8cff : unlockedNumbers ? 0xf6c85f : unlockedBio ? 0x70d68a : 0x3a5460, 0.7);
      this.add.rectangle(x - 84, y - 34, 4, 58, unlocked ? 0x6be7d6 : 0x53636a, unlocked ? 0.8 : 0.32);
      this.add.text(x - 54, y - 14, label, {
        fontFamily: "Inter, Arial",
        fontSize: "22px",
        color: unlockedArchive ? "#cdbfff" : unlockedNumbers ? "#f7d37a" : unlockedBio ? "#9ff5a7" : "#55717c",
        shadow: unlocked ? { offsetX: 0, offsetY: 0, color: "#6be7d6", blur: 8, fill: true } : undefined,
      });
      this.add.text(x - 76, y + 18, unlockedArchive ? "archivio attivo" : unlockedNumbers ? "fabbrica attiva" : unlockedBio ? "serra attiva" : "sigillato", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: unlockedArchive ? "#e3d9ff" : unlockedNumbers ? "#ffe0a3" : unlockedBio ? "#c9f7c9" : "#7d9098",
      });
    });
  }

  private drawProgressionPanel(): void {
    const progression = progressionSystem.getProgression();
    const x = 1036;
    const y = 590;
    this.add.rectangle(x, y, 316, 126, 0x071018, 0.76).setStrokeStyle(1, 0x6be7d6, 0.36);
    this.add.text(x - 140, y - 48, progression.rankTitle, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(x - 140, y - 22, progression.rankDescription, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c9dce6",
      wordWrap: { width: 274 },
      lineSpacing: 3,
    });
    progression.chapters.forEach((chapter, index) => {
      const dotX = x - 122 + index * 74;
      const complete = chapter.status === "complete";
      const active = chapter.status === "active";
      this.add.circle(dotX, y + 30, active ? 12 : 9, complete ? 0x9ff5e9 : active ? 0xf7d37a : 0x304653, complete || active ? 0.95 : 0.7);
      this.add.text(dotX - 18, y + 46, chapter.chapter.act.replace("Atto ", "A"), {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: active ? "#f7d37a" : complete ? "#9ff5e9" : "#7d9098",
      });
    });
    this.add.text(x - 140, y + 72, `Procedurale: diff. ${progression.recommendedProceduralDifficulty} (${progression.proceduralDifficultyLabel})`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 276 },
    });
  }

  private rect(id: string, fallback: MapLayoutRect): MapLayoutRect {
    return { ...fallback, ...this.layout[id] };
  }

  private getActiveDestination(): { label: string; scene: string } {
    const activeMission = missionEngine.getActiveMission();
    if (activeMission.id === "mission-04-archivio-parole") {
      return { label: "Entra nell'Archivio", scene: "WordArchiveScene" };
    }
    if (activeMission.id === "mission-03-fabbrica-numeri") {
      return { label: "Entra nella Fabbrica", scene: "NumberFactoryScene" };
    }
    if (activeMission.id === "mission-02-serra-biologica") {
      return { label: "Entra nella Serra", scene: "GreenhouseScene" };
    }
    return { label: "Entra nel Laboratorio", scene: "LaboratoryScene" };
  }

  private getHubCopy(): string {
    const activeMission = missionEngine.getActiveMission();
    if (activeMission.id === "mission-04-archivio-parole") {
      return "La fabbrica ha riattivato l'ala archivio. I messaggi corrotti aprono cassetti sbagliati e NORA chiede un rapporto verificabile.";
    }
    if (activeMission.id === "mission-03-fabbrica-numeri") {
      return "La serra ha stabilizzato il corridoio industriale. La Fabbrica dei Numeri produce energia sbagliata e chiede una configurazione precisa.";
    }
    if (activeMission.id === "mission-02-serra-biologica") {
      return "Il corridoio biologico ha ricevuto energia dal primo laboratorio. La serra automatizzata manda un segnale debole.";
    }
    return "I laboratori laterali sono ancora sigillati. Il nucleo centrale ha energia sufficiente per una sola missione.";
  }

  private startProceduralMission(): void {
    const baseDifficulty = progressionSystem.getProgression().recommendedProceduralDifficulty;
    const mission = proceduralDirector.generateFreshMission(baseDifficulty, ["problemSolving", "pensieroCritico"]);
    const startedAt = new Date().toISOString();
    const timeLimitMs = proceduralRunRules.missionTimeLimitMs(mission.difficulty, Math.max(1, mission.objectives.length));
    const run: ProceduralRunSave = {
      seed: mission.seed,
      difficulty: mission.difficulty,
      focus: ["problemSolving", "pensieroCritico"],
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
    void startScene(this, "ProceduralMissionScene");
  }
}
