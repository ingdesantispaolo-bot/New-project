import Phaser from "phaser";
import { competencyTracker } from "../core/CompetencyTracker";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";
import type { ProceduralRunSave } from "../procedural/ProceduralTypes";

type CompetencyGroup = {
  label: string;
  items: Array<{ label: string; score: number }>;
  average: number;
};

const GROUP_LABELS: Record<string, string> = {
  matematica: "Matematica",
  italiano: "Italiano",
  inglese: "Inglese",
  elettronica: "Elettronica",
  coding: "Coding",
  fisica: "Fisica",
  latino: "Latino",
  scienze: "Scienze",
};

const FALLBACK_GROUP = "Trasversali";

/**
 * Adult-facing overview: which competencies have been trained, which mistakes
 * recur, and the reproducible seeds — so a teacher or parent can read progress
 * and replay the exact same challenge.
 */
export class TeacherDashboardScene extends Phaser.Scene {
  private toast?: Phaser.GameObjects.Container;

  constructor() {
    super("TeacherDashboardScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "archive");
    VisualKit.vignette(this);

    const active = playerSystem.getActivePlayer();
    const report = playerSystem.playerReport(active.id);

    this.add.text(58, 36, "Quadro docente / genitore", {
      fontFamily: "Inter, Arial",
      fontSize: "38px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(60, 84, `Giocatore: ${active.name}  ·  Prove risolte: ${report.exerciseCount}  ·  Missioni: ${report.missionCount}  ·  Errori recuperati: ${report.recoveredMistakes}  ·  Soluzioni autonome: ${report.independentSolutions}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      wordWrap: { width: 1160 },
    });

    this.drawCompetencies(52, 130, 540, 470);
    this.drawMistakes(612, 130, 290, 470);
    this.drawSeeds(922, 130, 304, 470);

    new Button(this, 140, 678, "Menu", () => this.scene.start("MainMenuScene"), {
      width: 180,
      height: 46,
      fill: 0x263743,
    });
    new Button(this, 372, 678, "Registro studente", () => {
      void startScene(this, "PlayerReportScene");
    }, {
      width: 240,
      height: 46,
      fill: 0x173b36,
    });
  }

  // --- Competencies ---------------------------------------------------------

  private buildGroups(): CompetencyGroup[] {
    const known = competencyTracker.getKnownCompetencies().filter((item) => item.score > 0);
    const buckets = new Map<string, Array<{ label: string; score: number }>>();
    known.forEach((item) => {
      const prefix = item.id.includes(".") ? item.id.split(".")[0] : "";
      const groupLabel = GROUP_LABELS[prefix] ?? FALLBACK_GROUP;
      const list = buckets.get(groupLabel) ?? [];
      list.push({ label: item.label, score: item.score });
      buckets.set(groupLabel, list);
    });
    return [...buckets.entries()]
      .map(([label, items]) => ({
        label,
        items: items.sort((a, b) => b.score - a.score),
        average: Math.round(items.reduce((sum, i) => sum + i.score, 0) / items.length),
      }))
      .sort((a, b) => b.average - a.average);
  }

  private drawCompetencies(x: number, y: number, w: number, h: number): void {
    this.panel(x, y, w, h, "Competenze allenate");
    const groups = this.buildGroups();
    if (groups.length === 0) {
      this.add.text(x + 22, y + 64, "Nessuna competenza ancora registrata. Completa qualche prova per popolare questo quadro.", {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#c7dce7",
        wordWrap: { width: w - 44 },
        lineSpacing: 6,
      });
      return;
    }

    const colW = (w - 60) / 2;
    let col = 0;
    let rowY = y + 56;
    const topY = rowY;
    groups.slice(0, 6).forEach((group) => {
      const baseX = x + 22 + col * (colW + 16);
      this.add.text(baseX, rowY, `${group.label}  ·  media ${group.average}`, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#f6c85f",
        fontStyle: "bold",
      });
      group.items.slice(0, 3).forEach((item, index) => {
        const itemY = rowY + 26 + index * 38;
        this.add.text(baseX, itemY, item.label, {
          fontFamily: "Inter, Arial",
          fontSize: "12px",
          color: "#d9eaf1",
          wordWrap: { width: colW },
        });
        this.bar(baseX, itemY + 18, colW, item.score);
      });
      rowY += 26 + 3 * 38 + 14;
      if (rowY > y + h - 120) {
        col += 1;
        rowY = topY;
      }
    });
  }

  private bar(x: number, y: number, w: number, score: number): void {
    const clamped = Math.max(0, Math.min(100, score));
    this.add.rectangle(x, y, w, 8, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8);
    const color = clamped >= 70 ? 0x6be7d6 : clamped >= 40 ? 0xf6c85f : 0xc97f4b;
    this.add.rectangle(x, y, (w * clamped) / 100, 8, color, 0.95).setOrigin(0);
  }

  // --- Mistakes -------------------------------------------------------------

  private drawMistakes(x: number, y: number, w: number, h: number): void {
    this.panel(x, y, w, h, "Errori da rivedere");
    const memory = saveSystem.data.learningMemory ?? {};
    const entries = Object.entries(memory)
      .filter(([, value]) => value.count > 0)
      .sort((a, b) => b[1].count - a[1].count)
      .slice(0, 8);

    if (entries.length === 0) {
      this.add.text(x + 22, y + 64, "Nessun errore ricorrente registrato. Ottimo segnale di comprensione.", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#c7dce7",
        wordWrap: { width: w - 44 },
        lineSpacing: 6,
      });
      return;
    }

    this.add.text(x + 22, y + 50, "Concetti su cui tornare, ordinati per frequenza:", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: w - 44 },
    });
    entries.forEach(([key, value], index) => {
      const rowY = y + 88 + index * 44;
      this.add.circle(x + 32, rowY + 8, 13, 0xc94b55, 0.18).setStrokeStyle(2, 0xc94b55, 0.9);
      this.add.text(x + 32, rowY + 8, String(value.count), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#ffb0a8",
        fontStyle: "bold",
      }).setOrigin(0.5);
      this.add.text(x + 54, rowY, this.humanizeMistake(key), {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f5fbff",
        wordWrap: { width: w - 80 },
        lineSpacing: 2,
      });
    });
  }

  private humanizeMistake(key: string): string {
    const labels: Record<string, string> = {
      "circuit": "Circuiti: continuità e polarità",
      "math": "Matematica: ordine dei passaggi",
      "robot": "Coding: sequenza del robot",
      "language": "Italiano: coerenza del messaggio",
      "english": "Inglese: lettura della procedura",
      "music": "Musica: lettura delle note",
      "progressive": "Sintesi: ordine della catena",
    };
    const head = key.split(":")[0];
    if (labels[head]) {
      return labels[head];
    }
    // Generic prettifier for unknown keys.
    return key
      .replace(/[:_-]+/g, " · ")
      .replace(/([a-z])([A-Z])/g, "$1 $2")
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }

  // --- Seeds ----------------------------------------------------------------

  private drawSeeds(x: number, y: number, w: number, h: number): void {
    this.panel(x, y, w, h, "Seed riproducibili");
    this.add.text(x + 22, y + 50, "Copia un seed per rigiocare la stessa identica sfida.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: w - 44 },
      lineSpacing: 3,
    });

    const runs: Array<{ title: string; run?: ProceduralRunSave }> = [
      { title: "Missione", run: saveSystem.getProceduralMissionRun() },
      { title: "Calibrazione", run: saveSystem.getProceduralTrainingRun() },
      { title: "Scalata", run: saveSystem.getProceduralProgressiveRun() },
    ];

    let rowY = y + 96;
    let any = false;
    runs.forEach(({ title, run }) => {
      if (!run?.seed) {
        return;
      }
      any = true;
      const focus = run.focus.length > 0 ? run.focus.join(", ") : "misto";
      this.add.text(x + 22, rowY, `${title} · Profondità ${run.difficulty}`, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f6c85f",
        fontStyle: "bold",
      });
      this.add.text(x + 22, rowY + 20, `seed: ${run.seed}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        wordWrap: { width: w - 124 },
      });
      this.add.text(x + 22, rowY + 38, `focus: ${focus}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9aaab0",
        wordWrap: { width: w - 44 },
      });
      new Button(this, x + w - 58, rowY + 22, "Copia", () => this.copySeed(run.seed), {
        width: 84,
        height: 38,
        fill: 0x173b36,
        fontSize: 13,
        soundKey: "confirm",
      });
      rowY += 84;
    });

    if (!any) {
      this.add.text(x + 22, rowY, "Nessun seed salvato. Avvia una missione o una calibrazione per generarne uno.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#c7dce7",
        wordWrap: { width: w - 44 },
        lineSpacing: 5,
      });
    }
  }

  private copySeed(seed: string): void {
    const done = () => this.showToast(`Seed copiato: ${seed}`);
    try {
      const clipboard = (navigator as Navigator | undefined)?.clipboard;
      if (clipboard?.writeText) {
        void clipboard.writeText(seed).then(done).catch(() => this.fallbackCopy(seed));
        return;
      }
    } catch {
      // Fall through to prompt-based copy.
    }
    this.fallbackCopy(seed);
  }

  private fallbackCopy(seed: string): void {
    globalThis.prompt?.("Copia il seed (Ctrl/Cmd + C):", seed);
    this.showToast(`Seed: ${seed}`);
  }

  // --- Shared UI ------------------------------------------------------------

  private panel(x: number, y: number, w: number, h: number, title: string): void {
    this.add.rectangle(x, y, w, h, 0x09151f, 0.9).setOrigin(0).setStrokeStyle(2, 0x6be7d6, 0.48);
    this.add.rectangle(x, y, w, 3, 0x6be7d6, 0.75).setOrigin(0);
    this.add.text(x + 22, y + 16, title, {
      fontFamily: "Inter, Arial",
      fontSize: "21px",
      color: "#9ff5e9",
      fontStyle: "bold",
    });
  }

  private showToast(message: string): void {
    this.toast?.destroy(true);
    const container = this.add.container(640, 650).setDepth(9800);
    container.add(this.add.rectangle(0, 0, 520, 48, 0x06231d, 0.97).setStrokeStyle(2, 0x6be7d6, 0.9));
    container.add(this.add.text(0, 0, message, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    container.setAlpha(0);
    this.toast = container;
    this.tweens.add({
      targets: container,
      alpha: 1,
      duration: 160,
      yoyo: true,
      hold: 1500,
      completeDelay: 120,
      onComplete: () => {
        if (this.toast === container) this.toast = undefined;
        container.destroy(true);
      },
    });
  }
}
