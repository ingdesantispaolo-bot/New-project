import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { backupSystem } from "../core/BackupSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

type SettingsSceneData = {
  returnTo?: string;
};

const PANEL_X = 360;
const PANEL_Y = 30;
const PANEL_W = 560;
const PANEL_H = 660;

/**
 * Lightweight overlay for audio + comfort preferences. Launched on top of the
 * calling scene, which it pauses while open.
 */
export class SettingsScene extends Phaser.Scene {
  private returnTo = "MainMenuScene";
  private volumeValueText?: Phaser.GameObjects.Text;
  private muteButton?: Button;
  private effectsButton?: Button;
  private qualityButton?: Button;
  private textButton?: Button;
  private pressureButton?: Button;
  private backupStatusText?: Phaser.GameObjects.Text;
  private effectsChanged = false;
  private qualityChanged = false;

  constructor() {
    super("SettingsScene");
  }

  create(data: SettingsSceneData): void {
    this.returnTo = data?.returnTo ?? "MainMenuScene";
    this.effectsChanged = false;

    const backdrop = this.add
      .rectangle(640, 360, 1280, 720, 0x02070b, 0.74)
      .setInteractive();
    backdrop.on("pointerdown", () => this.close());

    const panel = VisualKit.glassPanel(this, PANEL_X, PANEL_Y, PANEL_W, PANEL_H, "academy", 0.96);
    // Swallow clicks on the panel so they don't reach the backdrop.
    const panelGuard = this.add
      .rectangle(PANEL_X + PANEL_W / 2, PANEL_Y + PANEL_H / 2, PANEL_W, PANEL_H, 0x000000, 0.001)
      .setInteractive();
    panelGuard.on("pointerdown", (_p: unknown, _x: unknown, _y: unknown, event: { stopPropagation?: () => void }) => {
      event?.stopPropagation?.();
    });
    panel.setDepth(1);
    panelGuard.setDepth(2);

    this.add.text(PANEL_X + 32, PANEL_Y + 30, "Impostazioni", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setDepth(3);
    this.add.text(PANEL_X + 32, PANEL_Y + 74, "Audio e comfort di gioco. Le scelte restano salvate.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#c7dce7",
    }).setDepth(3);

    // --- Volume row ---
    this.add.text(PANEL_X + 32, PANEL_Y + 132, "Volume", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    new Button(this, PANEL_X + 300, PANEL_Y + 142, "−", () => this.changeVolume(-0.1), {
      width: 56,
      height: 46,
      fontSize: 24,
      soundKey: "uiSelect",
    }).setDepth(3);
    this.volumeValueText = this.add.text(PANEL_X + 366, PANEL_Y + 142, this.volumeLabel(), {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#f6c85f",
      fontStyle: "bold",
    }).setOrigin(0.5).setDepth(3);
    new Button(this, PANEL_X + 432, PANEL_Y + 142, "+", () => this.changeVolume(0.1), {
      width: 56,
      height: 46,
      fontSize: 24,
      soundKey: "uiSelect",
    }).setDepth(3);

    // --- Mute toggle ---
    this.add.text(PANEL_X + 32, PANEL_Y + 200, "Silenzia audio", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    this.muteButton = new Button(this, PANEL_X + 410, PANEL_Y + 210, this.muteLabel(), () => this.toggleMute(), {
      width: 156,
      height: 46,
      fontSize: 15,
      soundKey: "uiSelect",
    });
    this.muteButton.setDepth(3);

    // --- Reduced effects toggle ---
    this.add.text(PANEL_X + 32, PANEL_Y + 264, "Effetti ridotti", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    this.add.text(PANEL_X + 32, PANEL_Y + 290, "Meno particelle e movimento. Utile su tablet o per maggiore comfort.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 330 },
      lineSpacing: 3,
    }).setDepth(3);
    this.effectsButton = new Button(this, PANEL_X + 410, PANEL_Y + 274, this.effectsLabel(), () => this.toggleEffects(), {
      width: 156,
      height: 46,
      fontSize: 15,
      soundKey: "uiSelect",
    });
    this.effectsButton.setDepth(3);

    // --- Graphics quality ---
    this.add.text(PANEL_X + 32, PANEL_Y + 330, "Qualità grafica", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    this.add.text(PANEL_X + 32, PANEL_Y + 356, "Effetti cinematografici (bloom, grading). Comfort li disattiva sui dispositivi più lenti.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 330 },
      lineSpacing: 3,
    }).setDepth(3);
    this.qualityButton = new Button(this, PANEL_X + 410, PANEL_Y + 340, this.qualityLabel(), () => this.cycleQuality(), {
      width: 156,
      height: 46,
      fontSize: 15,
      soundKey: "uiSelect",
    });
    this.qualityButton.setDepth(3);

    // --- Text scale ---
    this.add.text(PANEL_X + 32, PANEL_Y + 396, "Dimensione testo", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    this.add.text(PANEL_X + 32, PANEL_Y + 422, "Aumenta tutti i testi; sui tablet viene applicato anche un piccolo incremento automatico.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 330 },
    }).setDepth(3);
    this.textButton = new Button(this, PANEL_X + 410, PANEL_Y + 406, this.textScaleLabel(), () => this.cycleTextScale(), {
      width: 156,
      height: 46,
      fontSize: 14,
      soundKey: "uiSelect",
    });
    this.textButton.setDepth(3);

    // --- Pressure mode ---
    this.add.text(PANEL_X + 32, PANEL_Y + 462, "Pressione missioni", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    this.add.text(PANEL_X + 32, PANEL_Y + 488, "Rilassata elimina timer e vite dalle missioni rapide. La Scalata resta una sfida a tempo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 330 },
    }).setDepth(3);
    this.pressureButton = new Button(this, PANEL_X + 410, PANEL_Y + 472, this.pressureLabel(), () => this.cyclePressure(), {
      width: 156,
      height: 46,
      fontSize: 13,
      soundKey: "uiSelect",
    });
    this.pressureButton.setDepth(3);

    // --- Backup dei salvataggi ---
    this.add.text(PANEL_X + 32, PANEL_Y + 528, "Salvataggi", {
      fontFamily: "Inter, Arial",
      fontSize: "19px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setDepth(3);
    this.add.text(PANEL_X + 32, PANEL_Y + 554, "Esporta profili e progressi su file, o ripristinali su questo o un altro dispositivo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: 330 },
    }).setDepth(3);
    new Button(this, PANEL_X + 410, PANEL_Y + 526, "Esporta", () => this.exportBackup(), {
      width: 156,
      height: 40,
      fontSize: 14,
      soundKey: "uiSelect",
    }).setDepth(3);
    new Button(this, PANEL_X + 410, PANEL_Y + 572, "Importa", () => this.importBackup(), {
      width: 156,
      height: 40,
      fontSize: 14,
      soundKey: "uiSelect",
    }).setDepth(3);
    this.backupStatusText = this.add.text(PANEL_X + PANEL_W / 2, PANEL_Y + 606, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      align: "center",
      wordWrap: { width: PANEL_W - 64 },
    }).setOrigin(0.5).setDepth(3);

    // --- Close ---
    new Button(this, PANEL_X + PANEL_W / 2, PANEL_Y + 636, "Chiudi", () => this.close(), {
      width: 200,
      height: 44,
      fill: 0x1f5a51,
      stroke: 0xf6c85f,
      soundKey: "confirm",
    }).setDepth(3);

    this.input.keyboard?.on("keydown-ESC", () => this.close());
  }

  private exportBackup(): void {
    try {
      const fileName = backupSystem.exportToFile();
      this.backupStatusText?.setColor("#9ff5e9");
      this.backupStatusText?.setText(`Backup scaricato: ${fileName}`);
      audioManager.play("confirm");
    } catch {
      this.backupStatusText?.setColor("#ff9ad2");
      this.backupStatusText?.setText("Esportazione non riuscita su questo browser.");
    }
  }

  private importBackup(): void {
    backupSystem.importFromFile()
      .then((count) => {
        this.backupStatusText?.setColor("#9ff5e9");
        this.backupStatusText?.setText(`Ripristinate ${count} voci. Ricarico il gioco...`);
        audioManager.play("confirm");
        // I sistemi in memoria (save, profili, impostazioni) vanno ricostruiti
        // dai nuovi dati: un reload pulito è il percorso più sicuro.
        this.time.delayedCall(900, () => window.location.reload());
      })
      .catch((error: Error) => {
        this.backupStatusText?.setColor("#ff9ad2");
        this.backupStatusText?.setText(error.message || "Importazione non riuscita.");
        audioManager.play("error");
      });
  }

  private volumeLabel(): string {
    return `${Math.round(settingsSystem.getVolume() * 100)}%`;
  }

  private muteLabel(): string {
    return settingsSystem.isMuted() ? "Audio: OFF" : "Audio: ON";
  }

  private effectsLabel(): string {
    return settingsSystem.get().reducedEffects ? "Ridotti: ON" : "Ridotti: OFF";
  }

  private changeVolume(delta: number): void {
    settingsSystem.setVolume(settingsSystem.getVolume() + delta);
    this.volumeValueText?.setText(this.volumeLabel());
    if (settingsSystem.isMuted() && settingsSystem.getVolume() > 0) {
      settingsSystem.setMuted(false);
      this.muteButton?.setLabel(this.muteLabel());
    }
    audioManager.play("uiSelect");
  }

  private toggleMute(): void {
    settingsSystem.toggleMuted();
    this.muteButton?.setLabel(this.muteLabel());
  }

  private toggleEffects(): void {
    settingsSystem.toggleReducedEffects();
    this.effectsChanged = true;
    this.effectsButton?.setLabel(this.effectsLabel());
  }

  private qualityLabel(): string {
    const labels = { high: "Qualità: Alta", medium: "Qualità: Media", comfort: "Qualità: Comfort" } as const;
    return labels[settingsSystem.getGraphicsQuality()];
  }

  private cycleQuality(): void {
    settingsSystem.cycleGraphicsQuality();
    this.qualityChanged = true;
    this.qualityButton?.setLabel(this.qualityLabel());
  }

  private textScaleLabel(): string {
    return `Testo: ${Math.round(settingsSystem.getTextScale() * 100)}%`;
  }

  private cycleTextScale(): void {
    settingsSystem.cycleTextScale();
    this.effectsChanged = true;
    this.textButton?.setLabel(this.textScaleLabel());
  }

  private pressureLabel(): string {
    return settingsSystem.pressureEnabled() ? "Modalità: Sfida" : "Modalità: Rilassata";
  }

  private cyclePressure(): void {
    settingsSystem.cyclePressureMode();
    this.pressureButton?.setLabel(this.pressureLabel());
  }

  private close(): void {
    const target = this.returnTo;
    const needsRebuild = this.effectsChanged || this.qualityChanged;
    if (target) {
      // Visual-setting changes only re-render cleanly on a fresh scene build.
      if (needsRebuild && target === "MainMenuScene") {
        this.scene.start(target);
        return;
      }
      this.scene.resume(target);
    }
    this.scene.stop();
  }
}
