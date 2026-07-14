import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { campaignSystem } from "../core/CampaignSystem";
import { playerSystem } from "../core/PlayerSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { storySystem, type DiarioView } from "../core/StorySystem";
import { Button } from "../ui/Button";

/**
 * Diario di Bordo — the progressive-reveal story screen for "Il Relitto dei
 * Primi". Fragments unlock a ponte at a time (chapters + mastered subjects); the
 * player reads the recovered log at their own pace. Master–detail: the recovered
 * pages on the left, the selected page's text on the right; locked pages show
 * only where they will be found.
 */
export class DiarioScene extends Phaser.Scene {
  private returnScene = "ExplorableRoomScene";
  private selected = 0;
  private entries: DiarioView[] = [];
  private detailLayer?: Phaser.GameObjects.Container;

  constructor() {
    super("DiarioScene");
  }

  preload(): void {
    queueSceneAssets(this, "story");
  }

  create(data?: { returnScene?: string }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    playerSystem.load();
    saveSystem.load();
    storySystem.setPlayerIdProvider(() => playerSystem.getActivePlayer().id);
    this.syncFromProgress();
    this.entries = storySystem.diario();
    // Open on the most recent recovered page, or the first locked one.
    const lastUnlocked = this.entries.map((entry) => entry.unlocked).lastIndexOf(true);
    this.selected = lastUnlocked >= 0 ? lastUnlocked : 0;

    this.drawChrome();
    this.drawList();
    this.drawDetail();
    audioManager.play("scan");
  }

  /** Reveals the Diario pages earned so far (chapters completed + subjects trained). */
  private syncFromProgress(): void {
    const completedMissionIds = campaignSystem.getChapters()
      .filter((chapter) => chapter.status === "complete")
      .map((chapter) => chapter.missionId);
    const masteredFocuses = Array.from(
      new Set(
        Object.values(saveSystem.data.trainingRecords ?? {})
          .filter((record) => record.runs > 0)
          .map((record) => record.focus),
      ),
    );
    storySystem.syncProgress({ completedMissionIds, masteredFocuses });
  }

  private drawChrome(): void {
    this.cameras.main.setBackgroundColor("#05101a");
    if (this.textures.exists("story-primi-diario-bordo")) {
      const bg = this.add.image(640, 360, "story-primi-diario-bordo").setAlpha(0.28);
      const scale = Math.max(1280 / bg.width, 720 / bg.height);
      bg.setScale(scale);
    }
    this.add.rectangle(640, 360, 1280, 720, 0x040c14, 0.5);

    this.add.rectangle(56, 40, 5, 46, 0xf6c85f, 0.95).setOrigin(0);
    this.add.text(72, 34, "Diario di Bordo", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" });
    const found = storySystem.discoveredCount();
    const total = storySystem.total();
    this.add.text(74, 74, `Il Relitto dei Primi · ${found}/${total} pagine recuperate · si svelano riattivando i ponti`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9",
    });

    new Button(this, 1180, 44, "Indietro", () => { void startScene(this, this.returnScene); }, {
      width: 150, height: 40, fontSize: 15, fill: 0x263743,
    });
  }

  private actLabel(act: number): string {
    return act === 1 ? "Atto I · Il Relitto" : act === 2 ? "Atto II · I Primi" : "Atto III · Il Risveglio";
  }

  private drawList(): void {
    const x = 56;
    let y = 118;
    let currentAct = 0;
    this.entries.forEach((entry, index) => {
      if (entry.act !== currentAct) {
        currentAct = entry.act;
        this.add.text(x, y, this.actLabel(entry.act).toUpperCase(), {
          fontFamily: "Inter, Arial", fontSize: "11px", color: "#f6c85f", fontStyle: "bold",
        });
        y += 22;
      }
      const isSel = index === this.selected;
      const row = this.add.container(x, y);
      const bg = this.add.rectangle(0, 0, 470, 34, isSel ? 0x143a2f : 0x0c1d2a, isSel ? 0.98 : 0.82)
        .setOrigin(0).setStrokeStyle(1, isSel ? 0x2ed889 : 0x27414d, 0.8).setInteractive({ useHandCursor: true });
      row.add(bg);
      row.add(this.add.text(12, 17, entry.unlocked ? "✦" : "🔒", { fontFamily: "Inter, Arial", fontSize: "15px", color: entry.unlocked ? "#7cf6a6" : "#5d7782" }).setOrigin(0, 0.5));
      row.add(this.add.text(36, 17, entry.unlocked ? entry.title : "Pagina non ancora recuperata", {
        fontFamily: "Inter, Arial", fontSize: "14px",
        color: entry.unlocked ? "#eaf4f7" : "#67808b", fontStyle: entry.unlocked ? "bold" : "normal",
      }).setOrigin(0, 0.5));
      bg.on("pointerdown", () => { this.selected = index; audioManager.play("uiSelect"); this.drawDetail(); this.refreshListHighlight(); });
      row.setData("bg", bg);
      row.setData("index", index);
      this.listRows.push(row);
      y += 38;
    });
  }

  private listRows: Phaser.GameObjects.Container[] = [];

  private refreshListHighlight(): void {
    this.listRows.forEach((row) => {
      const bg = row.getData("bg") as Phaser.GameObjects.Rectangle;
      const isSel = row.getData("index") === this.selected;
      bg.setFillStyle(isSel ? 0x143a2f : 0x0c1d2a, isSel ? 0.98 : 0.82);
      bg.setStrokeStyle(1, isSel ? 0x2ed889 : 0x27414d, 0.8);
    });
  }

  private drawDetail(): void {
    this.detailLayer?.destroy(true);
    const layer = this.add.container(0, 0);
    this.detailLayer = layer;
    const px = 560;
    const py = 118;
    const pw = 664;
    const ph = 512;
    layer.add(this.add.rectangle(px, py, pw, ph, 0x07151d, 0.96).setOrigin(0).setStrokeStyle(2, 0xf6c85f, 0.5));

    const entry = this.entries[this.selected];
    if (!entry) return;

    if (!entry.unlocked) {
      layer.add(this.add.text(px + pw / 2, py + ph / 2 - 30, "🔒", { fontFamily: "Inter, Arial", fontSize: "46px" }).setOrigin(0.5));
      layer.add(this.add.text(px + pw / 2, py + ph / 2 + 26, "Pagina non ancora recuperata", {
        fontFamily: "Inter, Arial", fontSize: "18px", color: "#9fb6c2", fontStyle: "bold",
      }).setOrigin(0.5));
      layer.add(this.add.text(px + pw / 2, py + ph / 2 + 58, entry.hint, {
        fontFamily: "Inter, Arial", fontSize: "14px", color: "#7d93a0", align: "center", wordWrap: { width: pw - 120 },
      }).setOrigin(0.5));
      return;
    }

    const kindLabel = entry.kind === "passato" ? "◐ Memoria dei Primi" : "◑ Segnale dal presente";
    const kindColor = entry.kind === "passato" ? "#d8a24a" : "#7ad7ff";
    layer.add(this.add.text(px + 34, py + 34, kindLabel.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "12px", color: kindColor, fontStyle: "bold" }));
    layer.add(this.add.text(px + 34, py + 58, entry.title, { fontFamily: "Inter, Arial", fontSize: "26px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: pw - 68 } }));
    layer.add(this.add.rectangle(px + 34, py + 104, 90, 3, 0xf6c85f, 0.9).setOrigin(0));
    layer.add(this.add.text(px + 34, py + 126, entry.text, {
      fontFamily: "Inter, Arial", fontSize: "16px", color: "#dce9ef", lineSpacing: 8, wordWrap: { width: pw - 68 },
    }));
  }
}
