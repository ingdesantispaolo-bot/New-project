import Phaser from "phaser";
import { formatDuration } from "../core/ProceduralScoring";
import { playerSystem, type ResultCategory } from "../core/PlayerSystem";
import { startScene } from "../core/SceneNavigator";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

type LeaderboardFilter = {
  category: ResultCategory;
  key?: string;
  label: string;
};

const exerciseFilters: LeaderboardFilter[] = [
  { category: "exercise", key: "math", label: "Matematica" },
  { category: "exercise", key: "language", label: "Italiano" },
  { category: "exercise", key: "english", label: "Inglese" },
  { category: "exercise", key: "circuit", label: "Elettronica" },
  { category: "exercise", key: "robot", label: "Coding" },
];

const focusFilters: LeaderboardFilter[] = [
  { category: "focus", key: "matematica", label: "Focus matematica" },
  { category: "focus", key: "italiano", label: "Focus italiano" },
  { category: "focus", key: "inglese", label: "Focus inglese" },
  { category: "focus", key: "elettronica", label: "Focus circuiti" },
  { category: "focus", key: "coding", label: "Focus coding" },
];

const missionFilter: LeaderboardFilter = {
  category: "mission",
  label: "Missioni",
};

export class LeaderboardScene extends Phaser.Scene {
  private activeFilter: LeaderboardFilter = missionFilter;

  constructor() {
    super("LeaderboardScene");
  }

  create(): void {
    playerSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    VisualKit.vignette(this);

    this.add.text(58, 42, "Classifiche locali", {
      fontFamily: "Inter, Arial",
      fontSize: "40px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(60, 94, "Top 20 salvata nel browser: utile per tablet, aula, famiglia o piccoli tornei senza backend.", {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#c7dce7",
      wordWrap: { width: 760 },
    });

    this.drawFilterPanel();
    this.drawLeaderboard();

    new Button(this, 136, 676, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 176,
      height: 46,
      fill: 0x263743,
    });
    new Button(this, 370, 676, "Report giocatore", () => {
      void startScene(this, "PlayerReportScene");
    }, {
      width: 240,
      height: 46,
      fill: 0x173b36,
    });
  }

  private drawFilterPanel(): void {
    const x = 52;
    const y = 138;
    this.add.rectangle(x, y, 310, 474, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.46);
    this.add.text(x + 24, y + 20, "Vista", {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    new Button(this, x + 154, y + 82, "Per missione", () => {
      this.activeFilter = missionFilter;
      this.scene.restart();
    }, {
      width: 246,
      height: 38,
      fill: this.activeFilter.category === "mission" ? 0x1f5a51 : 0x173244,
      stroke: this.activeFilter.category === "mission" ? 0xf6c85f : 0x6be7d6,
      fontSize: 14,
    });

    this.add.text(x + 24, y + 126, "Per esercizio", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    exerciseFilters.forEach((filter, index) => {
      this.drawFilterButton(x + 154, y + 164 + index * 40, filter);
    });

    this.add.text(x + 24, y + 350, "Per focus", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f6c85f",
      fontStyle: "bold",
    });
    focusFilters.forEach((filter, index) => {
      this.drawFilterButton(x + 154, y + 386 + index * 36, filter);
    });
  }

  private drawFilterButton(x: number, y: number, filter: LeaderboardFilter): void {
    const active = this.activeFilter.category === filter.category && this.activeFilter.key === filter.key;
    new Button(this, x, y, filter.label, () => {
      this.activeFilter = filter;
      this.scene.restart();
    }, {
      width: 246,
      height: 34,
      fill: active ? 0x1f5a51 : 0x173244,
      stroke: active ? 0xf6c85f : 0x6be7d6,
      fontSize: 12,
    });
  }

  private drawLeaderboard(): void {
    const x = 402;
    const y = 138;
    const width = 824;
    const height = 474;
    this.add.rectangle(x, y, width, height, 0x09151f, 0.92).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.46);
    this.add.text(x + 28, y + 22, `Top 20 - ${this.activeFilter.label}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });

    const results = playerSystem.topResults(this.activeFilter.category, this.activeFilter.key, 20);
    if (results.length === 0) {
      this.add.text(x + 32, y + 84, "Nessun risultato ancora registrato per questa classifica.\nCompleta una missione o un focus con almeno un giocatore.", {
        fontFamily: "Inter, Arial",
        fontSize: "19px",
        color: "#d9eaf1",
        wordWrap: { width: 700 },
        lineSpacing: 8,
      });
      return;
    }

    const headerY = y + 74;
    this.drawHeader(x + 28, headerY);
    results.forEach((result, index) => {
      const rowY = headerY + 34 + index * 18;
      const color = index < 3 ? "#f6c85f" : "#d9eaf1";
      this.add.text(x + 34, rowY, `${index + 1}`.padStart(2, "0"), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color,
        fontStyle: "bold",
      });
      this.add.text(x + 78, rowY, result.playerName, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
      });
      this.add.text(x + 248, rowY, result.label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#c7dce7",
        wordWrap: { width: 212 },
      });
      this.add.text(x + 492, rowY, `L${result.difficulty}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color,
      });
      this.add.text(x + 552, rowY, `${result.score}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color,
        fontStyle: "bold",
      });
      this.add.text(x + 632, rowY, formatDuration(result.elapsedMs), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
      });
      this.add.text(x + 724, rowY, `${result.hintsUsed}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
      });
    });
  }

  private drawHeader(x: number, y: number): void {
    this.add.rectangle(x, y - 7, 760, 24, 0x173244, 0.72).setOrigin(0);
    [
      { x: 6, text: "#" },
      { x: 50, text: "Giocatore" },
      { x: 220, text: "Prova" },
      { x: 464, text: "Liv." },
      { x: 524, text: "Punti" },
      { x: 604, text: "Tempo" },
      { x: 696, text: "Indizi" },
    ].forEach((item) => {
      this.add.text(x + item.x, y - 3, item.text, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9ff5e9",
        fontStyle: "bold",
      });
    });
  }
}
