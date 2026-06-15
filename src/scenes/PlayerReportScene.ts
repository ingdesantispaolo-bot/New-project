import Phaser from "phaser";
import { formatDuration } from "../core/ProceduralScoring";
import { playerSystem, type PlayerResult } from "../core/PlayerSystem";
import { startScene } from "../core/SceneNavigator";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

export class PlayerReportScene extends Phaser.Scene {
  constructor() {
    super("PlayerReportScene");
  }

  create(): void {
    playerSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    VisualKit.vignette(this);

    const active = playerSystem.getActivePlayer();
    const report = playerSystem.playerReport(active.id);

    this.add.text(58, 42, "Giocatori e report", {
      fontFamily: "Inter, Arial",
      fontSize: "40px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(60, 94, `Giocatore attivo: ${active.name}`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f6c85f",
    });

    this.drawPlayersPanel();
    this.drawReportPanel(report);
    this.drawRecentPanel(report.recent);

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
        this.scene.restart();
      }
    }, {
      width: 252,
      height: 42,
      fill: 0x173b36,
      fontSize: 15,
    });
  }

  private drawReportPanel(report: ReturnType<typeof playerSystem.playerReport>): void {
    const x = 406;
    const y = 136;
    this.add.rectangle(x, y, 402, 474, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.48);
    this.add.text(x + 24, y + 18, `Report di ${report.player.name}`, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const summary = [
      `Risultati registrati: ${report.resultCount}`,
      `Missioni completate: ${report.missionCount}`,
      `Focus completati: ${report.focusCount}`,
      `Esercizi risolti: ${report.exerciseCount}`,
      `Punti totali: ${report.totalScore}`,
      `Media per risultato: ${report.averageScore}`,
    ];
    this.add.text(x + 26, y + 64, summary.join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#d9eaf1",
      lineSpacing: 8,
    });

    this.add.text(x + 26, y + 224, "Migliori risultati", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.drawBestLine(x + 26, y + 262, "Missione", report.bestMission);
    this.drawBestLine(x + 26, y + 318, "Focus", report.bestFocus);
    this.drawBestLine(x + 26, y + 374, "Esercizio", report.bestExercise);

    const strengths = report.strengths.length > 0
      ? report.strengths.map((item) => `${item.label}: ${item.score}`).join("\n")
      : "Completa alcuni esercizi per vedere i punti forti.";
    this.add.text(x + 218, y + 224, "Aree forti", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    this.add.text(x + 218, y + 262, strengths, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 154 },
      lineSpacing: 5,
    });
  }

  private drawBestLine(x: number, y: number, label: string, result: PlayerResult | undefined): void {
    this.add.text(x, y, label, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
    this.add.text(x, y + 18, result ? `${result.score} pt | L${result.difficulty} | ${formatDuration(result.elapsedMs)}` : "Non ancora registrato", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
    });
  }

  private drawRecentPanel(results: PlayerResult[]): void {
    const x = 844;
    const y = 136;
    this.add.rectangle(x, y, 382, 474, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.48);
    this.add.text(x + 24, y + 18, "Ultimi risultati", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    if (results.length === 0) {
      this.add.text(x + 24, y + 66, "Completa una missione o un focus: qui appariranno tempo, punteggio e difficolta.", {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#d9eaf1",
        wordWrap: { width: 320 },
        lineSpacing: 6,
      });
      return;
    }

    results.forEach((result, index) => {
      const rowY = y + 68 + index * 48;
      this.add.text(x + 24, rowY, `${result.label}`, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f5fbff",
        fontStyle: "bold",
        wordWrap: { width: 242 },
      });
      this.add.text(x + 24, rowY + 19, `L${result.difficulty} | ${result.score} pt | ${formatDuration(result.elapsedMs)} | ${result.hintsUsed} indizi`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#c7dce7",
      });
    });
  }
}
