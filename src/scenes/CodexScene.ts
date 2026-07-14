import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { Button } from "../ui/Button";
import { pythonPrincipleSeeds, type PythonPrincipleSeed } from "../data/procedural/pythonPrinciples";
import { languageCards, type LanguageCard } from "../data/procedural/languageAtlas";

type CodexTab = "python" | "atlas";

/**
 * Codex del Programmatore — schermata di studio sfogliabile.
 *
 * Fuori dagli esercizi, lo studente può rivedere con calma i principi di Python
 * (codice vero + spiegazione + "approfondisci") e l'Atlante dei Linguaggi
 * (schede storiche e attuali). È una reference giocosa: nessun punteggio, solo
 * curiosità e voglia di approfondire.
 */
export class CodexScene extends Phaser.Scene {
  private tab: CodexTab = "python";
  private selected = 0;
  private page = 0;
  private returnScene = "MainMenuScene";
  private bodyLayer?: Phaser.GameObjects.Container;
  private tabLayer?: Phaser.GameObjects.Container;

  private static readonly PAGE_SIZE = 14;
  private readonly pythonEntries: PythonPrincipleSeed[] = [...pythonPrincipleSeeds]
    .sort((a, b) => a.minLevel - b.minLevel || a.principle.localeCompare(b.principle));
  private readonly atlasEntries: LanguageCard[] = [...languageCards].sort((a, b) => a.year - b.year);

  constructor() {
    super("CodexScene");
  }

  create(data?: { returnScene?: string; tab?: CodexTab }): void {
    if (data?.returnScene) this.returnScene = data.returnScene;
    if (data?.tab) this.tab = data.tab;
    audioManager.play("scan");
    this.drawChrome();
    this.refresh();
  }

  private drawChrome(): void {
    this.add.rectangle(640, 360, 1280, 720, 0x05121a, 1);
    // decorative code rain, very subtle
    for (let i = 0; i < 24; i += 1) {
      const glyph = this.add.text(
        Phaser.Math.Between(20, 1260),
        Phaser.Math.Between(90, 700),
        ["print()", "for", "if", "def", "0 1", "()", "#", "{ }", "01"][i % 9],
        { fontFamily: "Consolas, monospace", fontSize: `${Phaser.Math.Between(14, 26)}px`, color: "#6be7d6" },
      ).setAlpha(0.05);
      this.tweens.add({ targets: glyph, y: glyph.y - Phaser.Math.Between(10, 26), alpha: { from: 0.03, to: 0.12 }, duration: Phaser.Math.Between(2600, 5200), yoyo: true, repeat: -1 });
    }

    this.add.rectangle(40, 40, 6, 44, 0xf6c85f, 0.95).setOrigin(0);
    this.add.text(60, 36, "📖 Codex del Programmatore", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" });
    this.add.text(62, 74, "La tua enciclopedia del coding: principi di Python e storia dei linguaggi. Nessun punteggio, solo curiosità.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2", wordWrap: { width: 900 },
    });

    new Button(this, 1180, 52, "Indietro", () => this.scene.start(this.returnScene), {
      width: 150, height: 42, fontSize: 15, fill: 0x263743,
    });
  }

  private refresh(): void {
    this.tabLayer?.destroy(true);
    this.tabLayer = this.add.container(0, 0);
    const tab = (x: number, id: CodexTab, label: string): void => {
      const active = this.tab === id;
      this.tabLayer?.add(new Button(this, x, 128, label, () => {
        if (this.tab === id) return;
        this.tab = id;
        this.selected = 0;
        this.page = 0;
        audioManager.play("click");
        this.refresh();
      }, {
        width: 320, height: 44, fontSize: 16,
        fill: active ? 0x1f5a51 : 0x122430,
        stroke: active ? 0xf6c85f : 0x6be7d6,
      }));
    };
    tab(210, "python", "🐍 Principi di Python");
    tab(560, "atlas", "🌍 Atlante dei Linguaggi");
    const total = this.tab === "python" ? this.pythonEntries.length : this.atlasEntries.length;
    this.tabLayer.add(this.add.text(900, 118, `${total} schede · sezione ${this.tab === "python" ? "Python" : "Linguaggi"}`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2",
    }));

    this.drawBody();
  }

  private drawBody(): void {
    this.bodyLayer?.destroy(true);
    this.bodyLayer = this.add.container(0, 0);
    this.drawList();
    if (this.tab === "python") {
      this.drawPythonDetail(this.pythonEntries[this.selected]);
    } else {
      this.drawAtlasDetail(this.atlasEntries[this.selected]);
    }
  }

  private drawList(): void {
    const layer = this.bodyLayer!;
    const entries = this.tab === "python" ? this.pythonEntries : this.atlasEntries;
    const labels = this.tab === "python"
      ? this.pythonEntries.map((entry) => `Prof. ${entry.minLevel} · ${entry.principle}`)
      : this.atlasEntries.map((entry) => `${entry.year} · ${entry.name}`);

    // list frame
    layer.add(this.add.rectangle(40, 172, 300, 512, 0x081a25, 0.94).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.28));
    layer.add(this.add.text(58, 184, this.tab === "python" ? "Principi (per profondità)" : "Linguaggi (per anno)", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#f6c85f", fontStyle: "bold",
    }));

    const pageSize = CodexScene.PAGE_SIZE;
    const totalPages = Math.max(1, Math.ceil(entries.length / pageSize));
    this.page = Phaser.Math.Clamp(this.page, 0, totalPages - 1);
    const start = this.page * pageSize;
    const pageItems = entries.slice(start, start + pageSize);

    pageItems.forEach((_entry, i) => {
      const globalIndex = start + i;
      const active = globalIndex === this.selected;
      layer.add(new Button(this, 190, 224 + i * 32, labels[globalIndex], () => {
        this.selected = globalIndex;
        audioManager.play("click");
        this.drawBody();
      }, {
        width: 288, height: 28, fontSize: 12,
        fill: active ? 0x1f5a51 : 0x102632,
        stroke: active ? 0xf6c85f : 0x2a4756,
        wordWrapWidth: 276,
      }));
    });

    if (totalPages > 1) {
      layer.add(this.add.text(190, 664, `Pagina ${this.page + 1}/${totalPages}`, {
        fontFamily: "Inter, Arial", fontSize: "12px", color: "#9fb6c2",
      }).setOrigin(0.5, 0.5));
      layer.add(new Button(this, 74, 664, "◀", () => { if (this.page > 0) { this.page -= 1; audioManager.play("click"); this.drawBody(); } }, {
        width: 44, height: 30, fontSize: 16, fill: 0x173b36,
      }));
      layer.add(new Button(this, 306, 664, "▶", () => { if (this.page < totalPages - 1) { this.page += 1; audioManager.play("click"); this.drawBody(); } }, {
        width: 44, height: 30, fontSize: 16, fill: 0x173b36,
      }));
    }
  }

  /** Right-side detail panel frame + title, returns the code-box top Y. */
  private drawDetailFrame(title: string, subtitle: string, accent: number): void {
    const layer = this.bodyLayer!;
    layer.add(this.add.rectangle(360, 172, 880, 512, 0x07151d, 0.96).setOrigin(0).setStrokeStyle(2, accent, 0.5));
    layer.add(this.add.rectangle(360, 172, 880, 6, accent, 0.95).setOrigin(0));
    layer.add(this.add.text(384, 190, title, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: 820 } }));
    layer.add(this.add.text(384, 226, subtitle, { fontFamily: "Inter, Arial", fontSize: "14px", color: Phaser.Display.Color.IntegerToColor(accent).rgba, wordWrap: { width: 820 } }));
  }

  private drawCodeBox(y: number, lines: string[], height: number, caption: string): void {
    const layer = this.bodyLayer!;
    layer.add(this.add.text(384, y - 20, caption, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9fb6c2" }));
    layer.add(this.add.rectangle(384, y, 832, height, 0x02090e, 0.96).setOrigin(0).setStrokeStyle(1, 0x2a4756, 0.8));
    layer.add(this.add.text(400, y + 12, lines.join("\n"), {
      fontFamily: "Consolas, 'Courier New', monospace", fontSize: "16px", color: "#9ff5e9", lineSpacing: 6, wordWrap: { width: 800 },
    }));
  }

  private drawField(y: number, label: string, value: string, color = "#dce9f0"): number {
    const layer = this.bodyLayer!;
    layer.add(this.add.text(384, y, label, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#6be7d6", fontStyle: "bold" }));
    const text = this.add.text(384, y + 18, value, { fontFamily: "Inter, Arial", fontSize: "15px", color, wordWrap: { width: 828 }, lineSpacing: 3 });
    layer.add(text);
    return y + 18 + text.height + 12;
  }

  private drawPythonDetail(entry: PythonPrincipleSeed): void {
    this.drawDetailFrame(`Python · ${entry.principle}`, `Profondità consigliata: ${entry.minLevel} · principio di programmazione`, 0x6be7d6);
    this.drawCodeBox(288, entry.codeLines, 34 + entry.codeLines.length * 22, "Codice Python");
    let y = 288 + 34 + entry.codeLines.length * 22 + 22;
    y = this.drawField(y, "COME FUNZIONA", entry.explanation);
    if (entry.funFact) y = this.drawField(y, "🎈 CURIOSITÀ", entry.funFact, "#f7d37a");
    this.drawField(y, "💡 APPROFONDISCI", entry.explore, "#c9b8ff");
    this.drawEntryNav();
  }

  private drawAtlasDetail(entry: LanguageCard): void {
    const accent = entry.era === "storico" ? 0xf6c85f : 0x6be7d6;
    this.drawDetailFrame(`${entry.name}  ·  ${entry.year}`, `${entry.era === "storico" ? "Linguaggio storico" : "Linguaggio moderno"} · ${entry.personality}`, accent);
    this.drawCodeBox(286, entry.helloWorld, 24 + entry.helloWorld.length * 22, '«ciao mondo» in ' + entry.name);
    let y = 286 + 24 + entry.helloWorld.length * 22 + 22;
    y = this.drawField(y, "FAMOSO PER", entry.famousFor);
    y = this.drawField(y, "DOVE SI USA OGGI", entry.stillUsed);
    y = this.drawField(y, "🎈 CURIOSITÀ", entry.curiosity, "#f7d37a");
    this.drawField(y, "💡 APPROFONDISCI", entry.explore, "#c9b8ff");
    this.drawEntryNav();
  }

  private drawEntryNav(): void {
    const layer = this.bodyLayer!;
    const entries = this.tab === "python" ? this.pythonEntries : this.atlasEntries;
    const go = (delta: number): void => {
      this.selected = (this.selected + delta + entries.length) % entries.length;
      this.page = Math.floor(this.selected / CodexScene.PAGE_SIZE);
      audioManager.play("click");
      this.drawBody();
    };
    layer.add(new Button(this, 470, 700, "◀ Precedente", () => go(-1), { width: 180, height: 34, fontSize: 14, fill: 0x173b36 }));
    layer.add(new Button(this, 1130, 700, "Successiva ▶", () => go(1), { width: 180, height: 34, fontSize: 14, fill: 0x173b36 }));
    layer.add(this.add.text(800, 700, `${this.selected + 1} / ${entries.length}`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9fb6c2",
    }).setOrigin(0.5, 0.5));
  }
}
