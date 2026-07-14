import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { playerSystem } from "../core/PlayerSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { settingsSystem } from "../core/SettingsSystem";
import { storySystem, type EndingChoice } from "../core/StorySystem";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

type FinaleStyle = { name: string; art: string; accent: number; hex: string };

const FINALES: Record<EndingChoice, FinaleStyle> = {
  silence: { name: "Il Silenzio", art: "story-primi-finale-dormiente", accent: 0x7ad7ff, hex: "#7ad7ff" },
  fire: { name: "Il Fuoco", art: "story-primi-finale-accesa", accent: 0xf6c85f, hex: "#f6c85f" },
  wonder: { name: "La Meraviglia", art: "story-primi-finale-eli", accent: 0x6be7d6, hex: "#6be7d6" },
};

/** A short epilogue after the ending text — the door left open for the sequel. */
const EPILOGUE: Record<EndingChoice, string> = {
  silence: "La nave torna al buio, al sicuro. Ma nel sonno del Relitto resta una domanda: quante altre navi dormono sotto le città del mondo?",
  fire: "La città è salva e la nave brilla. Eppure, sotto la potenza, Eli sente lo stesso peso che spezzò i Primi — e sa che il rivale, sconfitto, non ha detto l'ultima parola.",
  wonder: "«Non eravamo l'unica nave», sussurra NORA. «E tu sei la prima Chiave che sceglie di aspettare.» All'orizzonte del Diario compare una rotta nuova, verso un secondo relitto.",
};

/**
 * FinaleScene — the full-screen cutscene of the chosen ending. Shows the
 * ending's painted art, its canonical text and a closing epilogue that opens
 * the sequel. Reached from the "Scelta della Chiave" bivio.
 */
export class FinaleScene extends Phaser.Scene {
  private returnScene = "ExplorableRoomScene";

  constructor() {
    super("FinaleScene");
  }

  preload(): void {
    queueSceneAssets(this, "story");
  }

  create(data?: { ending?: EndingChoice; returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    playerSystem.load();
    saveSystem.load();

    const summary = storySystem.endingSummary();
    const ending = data?.ending ?? summary?.id;
    this.cameras.main.setBackgroundColor("#03080d");

    if (!ending || !summary) {
      this.add.text(640, 340, "Il finale non è ancora stato scelto.", {
        fontFamily: "Inter, Arial", fontSize: "18px", color: "#c7dce7",
      }).setOrigin(0.5);
      new Button(this, 640, 420, "Torna al Relitto", () => { void startScene(this, this.returnScene); }, {
        width: 240, height: 46, fill: 0x263743,
      });
      return;
    }

    const style = FINALES[ending];

    // Full-screen painted art, gently drifting, under a legibility gradient.
    if (this.textures.exists(style.art)) {
      const art = this.add.image(640, 330, style.art);
      const scale = Math.max(1280 / art.width, 620 / art.height);
      art.setScale(scale).setAlpha(0.92);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: art, scale: scale * 1.05, duration: 12000, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    }
    this.add.rectangle(640, 360, 1280, 720, 0x03080d, 0.36);
    this.add.rectangle(640, 620, 1280, 260, 0x03080d, 0.7);
    this.cameras.main.fadeIn(600, 3, 8, 13);

    this.add.text(640, 92, "IL FINALE · IL RELITTO DEI PRIMI", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: style.hex, fontStyle: "bold",
    }).setOrigin(0.5).setShadow(0, 2, "#000000", 6);
    this.add.text(640, 140, style.name, {
      fontFamily: "Inter, Arial", fontSize: "52px", color: "#f5fbff", fontStyle: "bold",
    }).setOrigin(0.5).setShadow(0, 4, "#000000", 12);
    this.add.rectangle(640, 186, 120, 3, style.accent, 0.95);

    // Ending text + epilogue in a readable slab near the bottom.
    this.add.text(640, 520, summary.text, {
      fontFamily: "Inter, Arial", fontSize: "17px", color: "#eef6fa", align: "center",
      wordWrap: { width: 900 }, lineSpacing: 7,
    }).setOrigin(0.5).setShadow(0, 2, "#000000", 8);
    this.add.text(640, 616, EPILOGUE[ending], {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#b9cfd9", align: "center", fontStyle: "italic",
      wordWrap: { width: 820 }, lineSpacing: 5,
    }).setOrigin(0.5).setShadow(0, 2, "#000000", 8);

    if (!settingsSystem.effectsReduced()) {
      VisualKit.particleBurst(this, 640, 170, "academy", ending === "fire" ? "success" : "success");
    }
    audioManager.playOutcome("complete");

    new Button(this, 640, 686, "Torna al Relitto", () => { void startScene(this, this.returnScene); }, {
      width: 260, height: 46, fill: 0x1f5a51, stroke: style.accent, fontSize: 15, soundKey: "confirm",
    });
  }
}
