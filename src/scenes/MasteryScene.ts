import Phaser from "phaser";
import { masterySystem, type MasteryBranch } from "../core/MasterySystem";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { VisualKit } from "../ui/VisualKit";

/**
 * "Albero delle Competenze" — the mastery tree. Visualises growth across the
 * study branches; higher tiers (Esperto, Maestro) are earned through
 * autonomous, clean solving, not exposure alone.
 */
export class MasteryScene extends Phaser.Scene {
  constructor() {
    super("MasteryScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    VisualKit.vignette(this);
    placeHiddenAnomaly(this, "MasteryScene");

    const branches = masterySystem.getBranches();
    const rank = masterySystem.getAcademyRank();

    this.add.text(56, 30, "Albero delle Competenze", {
      fontFamily: "Inter, Arial",
      fontSize: "34px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(58, 76, `${playerSystem.getActivePlayer().name}  ·  Grado: ${rank.title}  ·  ${rank.stars}/${rank.maxStars} ★`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
    });
    this.add.text(58, 102, "La maestria si guadagna risolvendo da soli, al primo tentativo e senza aiuti: le profondità alte premiano l'autonomia, non i tentativi.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 1000 },
    });

    branches.forEach((branch, index) => {
      const col = index % 4;
      const row = Math.floor(index / 4);
      this.drawBranchCard(branch, 28 + col * 312, 150 + row * 256);
    });

    new Button(this, 150, 686, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 180,
      height: 44,
      fill: 0x263743,
    });
    new Button(this, 372, 686, "Calibrazione settore", () => this.scene.start("MainMenuScene"), {
      width: 240,
      height: 44,
      fill: 0x173b36,
      stroke: 0x6be7d6,
      fontSize: 14,
    });
  }

  private drawBranchCard(branch: MasteryBranch, x: number, y: number): void {
    const w = 296;
    const h = 246;
    this.add.rectangle(x, y, w, h, 0x09151f, 0.94).setOrigin(0).setStrokeStyle(2, branch.color, branch.tier > 0 ? 0.8 : 0.35);
    this.add.rectangle(x, y, w, 4, branch.color, branch.tier > 0 ? 0.95 : 0.4).setOrigin(0);

    this.add.text(x + 18, y + 16, branch.label, {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: branch.tier > 0 ? "#f5fbff" : "#7d9098",
      fontStyle: "bold",
    });
    // Tier stars (max 3).
    for (let i = 0; i < 3; i += 1) {
      this.add.text(x + w - 76 + i * 22, y + 16, i < branch.tier ? "★" : "☆", {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: i < branch.tier ? "#f6c85f" : "#3a4a54",
      });
    }
    this.add.text(x + 18, y + 46, `Profondità: ${branch.tierLabel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: branch.tier >= 2 ? "#9ff5a7" : "#c7dce7",
      fontStyle: "bold",
    });

    // Mastery score bar.
    this.add.text(x + 18, y + 72, `Padronanza ${branch.score}%`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#9aaab0",
    });
    this.add.rectangle(x + 18, y + 92, w - 36, 10, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8);
    this.add.rectangle(x + 18, y + 92, (w - 36) * branch.score / 100, 10, branch.color, 0.95).setOrigin(0);

    // Autonomy.
    this.add.text(x + 18, y + 108, `Soluzioni autonome: ${branch.autonomy}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
    });

    // Top concept nodes with mini bars.
    const topNodes = branch.nodes.slice(0, 3);
    if (topNodes.length === 0) {
      this.add.text(x + 18, y + 134, "Concetti non ancora calibrati.", {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#5d7782",
        wordWrap: { width: w - 36 },
      });
    } else {
      topNodes.forEach((node, index) => {
        const ny = y + 132 + index * 26;
        this.add.text(x + 18, ny, node.label, {
          fontFamily: "Inter, Arial",
          fontSize: "10px",
          color: "#d9eaf1",
          wordWrap: { width: w - 70 },
        }).setOrigin(0, 0);
        this.add.rectangle(x + 18, ny + 14, w - 36, 5, 0x0a1a24, 1).setOrigin(0);
        this.add.rectangle(x + 18, ny + 14, (w - 36) * node.score / 100, 5, branch.color, 0.9).setOrigin(0);
      });
    }

    // Next unlock.
    this.add.rectangle(x + 12, y + h - 44, w - 24, 36, 0x07151d, 0.8).setOrigin(0).setStrokeStyle(1, branch.color, 0.25);
    this.add.text(x + 20, y + h - 38, branch.nextUnlock, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#9ff5e9",
      wordWrap: { width: w - 36 },
      lineSpacing: 2,
    });
  }
}
