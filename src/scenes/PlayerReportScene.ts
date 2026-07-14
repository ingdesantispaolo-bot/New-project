import Phaser from "phaser";
import { formatDuration } from "../core/ProceduralScoring";
import { playerSystem, type PlayerReport, type PlayerResult } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

export class PlayerReportScene extends Phaser.Scene {
  constructor() {
    super("PlayerReportScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    VisualKit.vignette(this);

    const active = playerSystem.getActivePlayer();
    const report = playerSystem.playerReport(active.id);

    this.add.text(58, 42, "Registro studente", {
      fontFamily: "Inter, Arial",
      fontSize: "40px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(60, 94, `Giocatore attivo: ${active.name}  |  Voto globale: ${this.formatGrade(report.globalGrade)} (${report.globalGradeLabel})`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f6c85f",
    });

    this.drawPlayersPanel();
    this.drawReportPanel(report);
    this.drawTrainingPanel(report);

    new Button(this, 136, 676, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 176,
      height: 46,
      fill: 0x263743,
    });
    new Button(this, 360, 676, "Classifiche", () => {
      void startScene(this, "LeaderboardScene");
    }, {
      width: 218,
      height: 46,
      fill: 0x173b36,
    });
  }

  private drawPlayersPanel(): void {
    const x = 52;
    const y = 136;
    this.add.rectangle(x, y, 318, 474, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.48);
    this.add.text(x + 22, y + 18, "Profili locali", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(x + 22, y + 54, "Ogni risultato viene salvato sul tablet/browser del giocatore selezionato.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7dce7",
      wordWrap: { width: 266 },
      lineSpacing: 4,
    });

    const activeId = playerSystem.getActivePlayer().id;
    playerSystem.getPlayers().slice(0, 6).forEach((player, index) => {
      const selected = player.id === activeId;
      new Button(this, x + 158, y + 130 + index * 50, player.name, () => {
        playerSystem.setActivePlayer(player.id);
        saveSystem.load();
        this.scene.restart();
      }, {
        width: 252,
        height: 38,
        fill: selected ? 0x1f5a51 : 0x173244,
        stroke: selected ? 0xf6c85f : 0x6be7d6,
        fontSize: 14,
      });
    });

    new Button(this, x + 158, y + 408, "Nuovo giocatore", () => {
      const name = globalThis.prompt?.("Nome del nuovo giocatore");
      if (name !== undefined && name !== null) {
        playerSystem.createPlayer(name);
        saveSystem.newGame();
        this.scene.restart();
      }
    }, {
      width: 252,
      height: 42,
      fill: 0x173b36,
      fontSize: 15,
    });
  }

  private drawReportPanel(report: PlayerReport): void {
    const x = 406;
    const y = 136;
    this.add.rectangle(x, y, 402, 474, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.48);
    this.add.text(x + 24, y + 18, `Report di ${report.player.name}`, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    this.add.text(x + 26, y + 58, this.formatGrade(report.globalGrade), {
      fontFamily: "Inter, Arial",
      fontSize: "48px",
      color: report.globalGrade >= 8 ? "#f6c85f" : report.globalGrade >= 6.4 ? "#9ff5e9" : "#ff8f8f",
      fontStyle: "bold",
    });
    this.add.text(x + 152, y + 68, [
      `Globale: ${report.globalGradeLabel}`,
      `Missioni ${this.formatGrade(report.missionGrade)}`,
      `Calibrazione ${this.formatGrade(report.trainingGrade)}`,
      `Prove ${this.formatGrade(report.exerciseGrade)}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      lineSpacing: 4,
    });

    this.add.rectangle(x + 24, y + 138, 354, 68, 0x07151d, 0.78)
      .setOrigin(0)
      .setStrokeStyle(1, 0xf6c85f, 0.28);
    this.add.text(x + 40, y + 152, "Obiettivo personale", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.text(x + 40, y + 174, report.nextGoal, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#d9eaf1",
      wordWrap: { width: 324 },
      lineSpacing: 3,
    });

    const summary = [
      `Risultati registrati: ${report.resultCount}`,
      `Missioni completate: ${report.missionCount}`,
      `Focus completati: ${report.focusCount}`,
      `Prove risolte: ${report.exerciseCount}`,
      `Errori corretti: ${report.recoveredMistakes}`,
      `Soluzioni autonome: ${report.independentSolutions}`,
    ];
    this.add.text(x + 26, y + 224, summary.join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      lineSpacing: 5,
    });

    this.add.text(x + 206, y + 224, "Migliori risultati", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.drawBestLine(x + 206, y + 256, "Missione", report.bestMission);
    this.drawBestLine(x + 206, y + 308, "Focus", report.bestFocus);
    this.drawBestLine(x + 206, y + 360, "Prova", report.bestExercise);

    const strengths = report.strengths.length > 0
      ? report.strengths.map((item) => `${item.label}: ${item.score}`).join("\n")
      : "Completa alcune prove per vedere i punti forti.";
    this.add.text(x + 26, y + 372, "Aree forti", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.text(x + 26, y + 400, strengths, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 168 },
      lineSpacing: 4,
    });
  }

  private drawBestLine(x: number, y: number, label: string, result: PlayerResult | undefined): void {
    this.add.text(x, y, label, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(x, y + 18, result ? `${this.formatGrade(result.grade ?? 0)} | ${result.score} pt | profondità ${result.difficulty} | ${formatDuration(result.elapsedMs)}` : "Non ancora registrato", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
    });
  }

  private drawTrainingPanel(report: PlayerReport): void {
    const x = 844;
    const y = 136;
    this.add.rectangle(x, y, 382, 474, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.48);
    this.add.text(x + 24, y + 18, "Calibrazione per settore", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const trained = report.trainingStats.filter((item) => item.runs > 0);
    if (trained.length === 0) {
      this.add.text(x + 24, y + 62, "Completa un focus: qui appariranno voto medio, record, trend e obiettivo successivo.", {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#d9eaf1",
        wordWrap: { width: 320 },
        lineSpacing: 6,
      });
    } else {
      trained
        .sort((a, b) => b.averageGrade - a.averageGrade)
        .slice(0, 5)
        .forEach((item, index) => {
          const rowY = y + 62 + index * 48;
          const trend = item.trend === "up" ? "in crescita" : item.trend === "down" ? "da consolidare" : "stabile";
          this.add.text(x + 24, rowY, `${item.label}  ${this.formatGrade(item.averageGrade)}`, {
            fontFamily: "Inter, Arial",
            fontSize: "13px",
            color: item.averageGrade >= 8 ? "#f6c85f" : "#f5fbff",
            fontStyle: "bold",
          });
          this.add.text(x + 24, rowY + 19, `${item.runs} run | best ${this.formatGrade(item.bestGrade)} | ${formatDuration(item.bestTimeMs)} | ${trend}`, {
            fontFamily: "Inter, Arial",
            fontSize: "11px",
            color: "#c7dce7",
          });
        });
    }

    this.add.text(x + 24, y + 304, "Registro prove", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    report.subjectStats
      .filter((item) => item.exercises > 0)
      .sort((a, b) => a.averageGrade - b.averageGrade)
      .slice(0, 3)
      .forEach((item, index) => {
        const rowY = y + 334 + index * 30;
        this.add.text(x + 24, rowY, `${item.label}`, {
          fontFamily: "Inter, Arial",
          fontSize: "11px",
          color: "#d9eaf1",
          wordWrap: { width: 220 },
        });
        this.add.text(x + 278, rowY, `${this.formatGrade(item.averageGrade)}`, {
          fontFamily: "Inter, Arial",
          fontSize: "12px",
          color: item.averageGrade >= 8 ? "#f6c85f" : "#9ff5e9",
          fontStyle: "bold",
        });
      });

    this.add.text(x + 24, y + 432, "Ultimo risultato", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    report.recent.slice(0, 1).forEach((result, index) => {
      const rowY = y + 458 + index * 34;
      this.add.text(x + 24, rowY, `${result.label}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#f5fbff",
        fontStyle: "bold",
        wordWrap: { width: 242 },
      });
      this.add.text(x + 24, rowY + 17, `${this.formatGrade(result.grade ?? 0)} | profondità ${result.difficulty} | ${result.score} pt | ${formatDuration(result.elapsedMs)}`, {
        fontFamily: "Inter, Arial",
        fontSize: "10px",
        color: "#c7dce7",
      });
    });
  }

  private formatGrade(grade: number): string {
    return grade > 0 ? `${grade.toFixed(grade % 1 === 0 ? 0 : 1)}/10` : "-";
  }
}
