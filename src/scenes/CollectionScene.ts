import Phaser from "phaser";
import { collectionSystem } from "../core/CollectionSystem";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

/**
 * "Galleria dei Frammenti" — the discovery codex. Shows the 12 memory fragments
 * of the Academy's backstory: discovered ones reveal their story, locked ones
 * show only a silhouette plus a hint on where/how to find them.
 */
export class CollectionScene extends Phaser.Scene {
  constructor() {
    super("CollectionScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    VisualKit.vignette(this);

    const fragments = collectionSystem.getAll();
    const found = collectionSystem.discoveredCount();
    const total = collectionSystem.total();

    this.add.text(56, 26, "Galleria dei Frammenti", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(58, 66, `La storia dell'Accademia, di NORA e dell'Eco · ${found}/${total} frammenti ritrovati`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
    });
    if (found >= total) {
      this.add.text(640, 66, "★ Backstory completa!", { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0, 0);
    }

    const cols = 4;
    const cardW = 282;
    const cardH = 150;
    const gapX = 16;
    const gapY = 14;
    const startX = 56;
    const startY = 100;

    fragments.forEach((fragment, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = startX + col * (cardW + gapX);
      const y = startY + row * (cardH + gapY);
      this.drawCard(fragment, x, y, cardW, cardH);
    });

    new Button(this, 132, 686, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 160,
      height: 44,
      fill: 0x263743,
    });
    new Button(this, 340, 686, "La tua Accademia", () => { void startScene(this, "AcademyScene"); }, {
      width: 240,
      height: 44,
      fill: 0x1f5a51,
      stroke: 0x70d68a,
      fontSize: 14,
    });
    this.add.text(700, 686, "Suggerimento: tocca le anomalie luminose nascoste negli angoli delle stanze.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#8aa0ab",
      wordWrap: { width: 520 },
    }).setOrigin(0, 0.5);
  }

  private drawCard(
    fragment: ReturnType<typeof collectionSystem.getAll>[number],
    x: number,
    y: number,
    w: number,
    h: number,
  ): void {
    const discovered = fragment.discovered;
    this.add.rectangle(x, y, w, h, discovered ? 0x102230 : 0x0c1016, 0.94)
      .setOrigin(0)
      .setStrokeStyle(2, discovered ? 0xf6c85f : 0x2a3a44, discovered ? 0.7 : 0.4);

    this.add.text(x + 14, y + 12, discovered ? fragment.glyph : "❔", {
      fontFamily: "Inter, Arial",
      fontSize: "26px",
    });
    this.add.text(x + 52, y + 14, `${fragment.index}.`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#7d93a0",
    });
    this.add.text(x + 52, y + 30, discovered ? fragment.title : "Frammento sconosciuto", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: discovered ? "#ffe6a0" : "#5d7782",
      fontStyle: "bold",
      wordWrap: { width: w - 64 },
    });

    if (discovered) {
      this.add.text(x + 14, y + 64, fragment.story, {
        fontFamily: "Inter, Arial",
        fontSize: "11.5px",
        color: "#cddbe4",
        wordWrap: { width: w - 28 },
        lineSpacing: 2,
      });
    } else {
      this.add.text(x + 14, y + 72, fragment.hint, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#7d93a0",
        fontStyle: "italic",
        wordWrap: { width: w - 28 },
        lineSpacing: 3,
      });
    }
  }
}
