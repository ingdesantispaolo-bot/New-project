import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { competencyTracker } from "../core/CompetencyTracker";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { settingsSystem } from "../core/SettingsSystem";
import { buildMemoryPairs, generateBalance, LogicSequenceGenerator, type BalancePuzzle, type LogicSequence, type MemoryPair } from "../procedural/generators/LogicGymContent";
import { Random } from "../procedural/Random";
import { Button } from "../ui/Button";
import { placeHiddenAnomaly } from "../ui/HiddenAnomaly";
import { VisualKit } from "../ui/VisualKit";

type ActivityMeta = { key: string; title: string; glyph: string; theme: string; desc: string; color: number; start: () => void };

const PAD_COLORS = [0xff5d7a, 0x6be7d6, 0xf6c85f, 0x70d68a, 0x9f8cff, 0xff9ad2];
const CODE_SYMBOLS = ["🔴", "🔵", "🟡", "🟢", "🟣", "🟠"];

/**
 * "Palestra della Mente" — a transversal logic & memory gym with four distinct,
 * challenging activities that feed the cross-cutting competencies (memoria di
 * lavoro, ragionamento logico) and therefore the Academy's mastery and Core.
 */
export class LogicGymScene extends Phaser.Scene {
  private tracked: Phaser.GameObjects.GameObject[] = [];
  private currentRestart: (() => void) | null = null;

  // Sequenza Luminosa
  private simonPads: Phaser.GameObjects.Rectangle[] = [];
  private simonSeq: number[] = [];
  private simonInput: number[] = [];
  private simonLocked = true;
  private simonStatus?: Phaser.GameObjects.Text;

  // Memory delle Coppie
  private memCards: Array<{ pairId: string; label: string; rect: Phaser.GameObjects.Rectangle; text: Phaser.GameObjects.Text; matched: boolean; flipped: boolean }> = [];
  private memFlipped: number[] = [];
  private memMoves = 0;
  private memMatched = 0;
  private memPairs = 6;
  private memLocked = false;
  private memStatus?: Phaser.GameObjects.Text;

  // Codice Segreto
  private codeSecret: number[] = [];
  private codeGuess: number[] = [];
  private codeAttempts = 0;
  private codeMax = 8;
  private codeLen = 4;
  private codeSlots: Phaser.GameObjects.Text[] = [];
  private codeStatus?: Phaser.GameObjects.Text;
  private codeHistoryY = 150;

  // Sequenze Logiche
  private seqRound = 0;
  private seqCorrect = 0;
  private seqTotal = 6;

  // Bilancia Logica
  private balRound = 0;
  private balCorrect = 0;
  private balTotal = 6;

  // Griglia Lampo
  private flashCells: Phaser.GameObjects.Rectangle[] = [];
  private flashTarget = new Set<number>();
  private flashPicked = new Set<number>();
  private flashRound = 0;
  private flashLocked = true;
  private flashStatus?: Phaser.GameObjects.Text;

  constructor() {
    super("LogicGymScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy");
    VisualKit.vignette(this);
    this.showHub();
  }

  private activities(): ActivityMeta[] {
    return [
      { key: "simon", title: "Sequenza Luminosa", glyph: "🧠", theme: "Memoria", color: 0x6be7d6, desc: "Guarda la sequenza di luci e ripetila. Si allunga a ogni turno!", start: () => this.startSimon() },
      { key: "memory", title: "Memory delle Coppie", glyph: "🃏", theme: "Memoria", color: 0xff9ad2, desc: "Trova le coppie equivalenti (1/2 = 0,5, dog = cane…) con meno mosse possibili.", start: () => this.startMemory() },
      { key: "code", title: "Codice Segreto", glyph: "🔐", theme: "Logica", color: 0xf6c85f, desc: "Indovina il codice nascosto deducendolo dagli indizi. Stile Mastermind.", start: () => this.startCode() },
      { key: "seq", title: "Sequenze Logiche", glyph: "🔢", theme: "Logica", color: 0x70d68a, desc: "Scopri la regola e trova il termine che continua la serie.", start: () => this.startSeq() },
      { key: "balance", title: "Bilancia Logica", glyph: "⚖️", theme: "Logica", color: 0xf6c85f, desc: "Deduci chi pesa di più (o di meno) mettendo in fila gli indizi.", start: () => this.startBalance() },
      { key: "flash", title: "Griglia Lampo", glyph: "⚡", theme: "Memoria", color: 0x6be7d6, desc: "Memorizza le caselle che lampeggiano e ricostruiscile. Aumentano ogni turno!", start: () => this.startFlash() },
    ];
  }

  // -- Tracking helpers ---------------------------------------------------

  private t<T extends Phaser.GameObjects.GameObject>(object: T): T {
    this.tracked.push(object);
    return object;
  }

  private clearScreen(): void {
    this.tracked.forEach((object) => object.destroy());
    this.tracked = [];
    this.simonPads = [];
    this.memCards = [];
    this.memFlipped = [];
    this.codeSlots = [];
  }

  private best(key: string): number {
    return saveSystem.data.logicGym?.best?.[key] ?? 0;
  }

  // -- Hub ----------------------------------------------------------------

  private showHub(): void {
    this.clearScreen();
    this.currentRestart = null;
    this.t(this.add.text(56, 28, "Palestra della Mente", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 68, "Qui NORA allenava sé stessa. Logica e memoria: ogni vittoria potenzia le Trasversali, il Nucleo dell'Accademia — e ti prepara alle prove di mente della Sfida dell'Eco.", { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", wordWrap: { width: 1180 } }));
    placeHiddenAnomaly(this, "LogicGymScene");

    const cols = 3;
    const w = 388;
    const h = 248;
    const gap = 14;
    const startX = 40;
    const startY = 116;
    this.activities().forEach((activity, index) => {
      const x = startX + (index % cols) * (w + gap);
      const y = startY + Math.floor(index / cols) * (h + gap);
      this.t(this.add.rectangle(x, y, w, h, 0x0c1d2a, 0.94).setOrigin(0).setStrokeStyle(2, activity.color, 0.55));
      this.t(this.add.rectangle(x, y, w, 5, activity.color, 0.9).setOrigin(0));
      this.t(this.add.text(x + 20, y + 20, `${activity.glyph}  ${activity.title}`, { fontFamily: "Inter, Arial", fontSize: "20px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: w - 40 } }));
      this.t(this.add.text(x + 20, y + 58, activity.theme.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "12px", color: Phaser.Display.Color.IntegerToColor(activity.color).rgba, fontStyle: "bold" }));
      this.t(this.add.text(x + 20, y + 84, activity.desc, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#c7dce7", wordWrap: { width: w - 40 }, lineSpacing: 3 }));
      this.t(this.add.text(x + 20, y + 180, `Record: ${this.best(activity.key)}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a" }));
      this.t(new Button(this, x + w - 100, y + 200, "Gioca", () => activity.start(), { width: 150, height: 44, fill: 0x1f5a51, stroke: activity.color }));
    });

    this.t(new Button(this, 132, 686, "Menu", () => this.scene.start("MainMenuScene"), { width: 170, height: 44, fill: 0x263743 }));
  }

  private backBar(restart: () => void): void {
    this.currentRestart = restart;
    this.t(new Button(this, 132, 686, "Palestra", () => this.showHub(), { width: 170, height: 44, fill: 0x263743 }));
  }

  // -- Sequenza Luminosa (sequential working memory) ----------------------

  private startSimon(): void {
    this.clearScreen();
    this.simonSeq = [];
    this.simonInput = [];
    this.simonLocked = true;
    this.t(this.add.text(640, 40, "🧠 Sequenza Luminosa", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.simonStatus = this.t(this.add.text(640, 86, "Guarda bene…", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" }).setOrigin(0.5));

    const cols = 3;
    const padW = 168;
    const padH = 128;
    const gap = 26;
    const totalW = cols * padW + (cols - 1) * gap;
    const startX = 640 - totalW / 2 + padW / 2;
    PAD_COLORS.forEach((color, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = startX + col * (padW + gap);
      const y = 240 + row * (padH + gap);
      const pad = this.t(this.add.rectangle(x, y, padW, padH, color, 0.32).setStrokeStyle(3, color, 0.8).setInteractive({ useHandCursor: true }));
      pad.on("pointerdown", () => this.simonClick(index));
      this.simonPads.push(pad);
    });
    this.backBar(() => this.startSimon());
    this.time.delayedCall(700, () => this.simonNextRound());
  }

  private simonNextRound(): void {
    this.simonInput = [];
    this.simonLocked = true;
    const random = new Random(`simon-${Date.now()}-${this.simonSeq.length}`);
    this.simonSeq.push(random.integer(0, PAD_COLORS.length - 1));
    this.simonStatus?.setText(`Turno ${this.simonSeq.length} · Guarda la sequenza…`);
    const step = settingsSystem.effectsReduced() ? 520 : 640;
    this.simonSeq.forEach((padIndex, i) => {
      this.time.delayedCall(400 + i * step, () => this.flashPad(padIndex));
    });
    this.time.delayedCall(400 + this.simonSeq.length * step, () => {
      this.simonLocked = false;
      this.simonStatus?.setText("Ripeti la sequenza!");
    });
  }

  private flashPad(index: number): void {
    const pad = this.simonPads[index];
    if (!pad) return;
    audioManager.play("levelSelect");
    pad.setFillStyle(PAD_COLORS[index], 1);
    this.tweens.add({ targets: pad, scale: 1.08, duration: 180, yoyo: true, onComplete: () => pad.setFillStyle(PAD_COLORS[index], 0.32) });
  }

  private simonClick(index: number): void {
    if (this.simonLocked) return;
    this.flashPad(index);
    this.simonInput.push(index);
    const pos = this.simonInput.length - 1;
    if (this.simonInput[pos] !== this.simonSeq[pos]) {
      audioManager.play("error");
      const reached = this.simonSeq.length - 1;
      this.finishActivity("simon", "Sequenza Luminosa", reached, ["trasversali.memoria"], Math.min(20, 4 + reached * 2), `Hai ripetuto correttamente ${reached} sequenze.`);
      return;
    }
    if (this.simonInput.length === this.simonSeq.length) {
      this.simonLocked = true;
      this.simonStatus?.setText("Perfetto! Sequenza più lunga…");
      audioManager.play("success");
      if (this.simonSeq.length >= 15) {
        this.finishActivity("simon", "Sequenza Luminosa", 15, ["trasversali.memoria"], 22, "Hai raggiunto la sequenza massima: memoria di ferro!");
        return;
      }
      this.time.delayedCall(750, () => this.simonNextRound());
    }
  }

  // -- Memory delle Coppie (visual memory + knowledge) --------------------

  private startMemory(): void {
    this.clearScreen();
    this.memFlipped = [];
    this.memMoves = 0;
    this.memMatched = 0;
    this.memLocked = false;
    this.memPairs = 6;
    const random = new Random(`memory-${Date.now()}`);
    const pairs: MemoryPair[] = buildMemoryPairs(random, this.memPairs);
    const deck = random.shuffle(pairs.flatMap((pair) => [
      { pairId: pair.id, label: pair.a },
      { pairId: pair.id, label: pair.b },
    ]));

    this.t(this.add.text(640, 36, "🃏 Memory delle Coppie", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.memStatus = this.t(this.add.text(640, 78, "Mosse: 0 · Coppie: 0/6", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9" }).setOrigin(0.5));

    const cols = 4;
    const cardW = 230;
    const cardH = 116;
    const gap = 18;
    const totalW = cols * cardW + (cols - 1) * gap;
    const startX = 640 - totalW / 2 + cardW / 2;
    const startY = 190;
    deck.forEach((card, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = startX + col * (cardW + gap);
      const y = startY + row * (cardH + gap);
      const rect = this.t(this.add.rectangle(x, y, cardW, cardH, 0x123247, 1).setStrokeStyle(2, 0x6be7d6, 0.6).setInteractive({ useHandCursor: true }));
      const text = this.t(this.add.text(x, y, "?", { fontFamily: "Inter, Arial", fontSize: "26px", color: "#6be7d6", fontStyle: "bold" }).setOrigin(0.5));
      const entry = { pairId: card.pairId, label: card.label, rect, text, matched: false, flipped: false };
      rect.on("pointerdown", () => this.memClick(this.memCards.indexOf(entry)));
      this.memCards.push(entry);
    });
    this.backBar(() => this.startMemory());
  }

  private memClick(index: number): void {
    if (this.memLocked) return;
    const card = this.memCards[index];
    if (!card || card.matched || card.flipped) return;
    card.flipped = true;
    card.text.setText(card.label).setColor("#ffffff");
    card.rect.setFillStyle(0x1f5a51, 1);
    this.memFlipped.push(index);
    if (this.memFlipped.length < 2) return;

    this.memMoves += 1;
    const [a, b] = this.memFlipped.map((i) => this.memCards[i]);
    if (a.pairId === b.pairId) {
      audioManager.play("success");
      a.matched = true;
      b.matched = true;
      [a, b].forEach((entry) => entry.rect.setFillStyle(0x173b36, 1).setStrokeStyle(2, 0x70d68a, 0.9));
      this.memFlipped = [];
      this.memMatched += 1;
      this.updateMemStatus();
      if (this.memMatched >= this.memPairs) {
        const score = Math.round((this.memPairs / this.memMoves) * 100);
        this.finishActivity("memory", "Memory delle Coppie", score, ["trasversali.memoria", "pensieroCritico"], Math.min(18, 6 + Math.round(score / 12)), `Tutte le coppie trovate in ${this.memMoves} mosse.`);
      }
    } else {
      audioManager.play("error");
      this.memLocked = true;
      this.updateMemStatus();
      this.time.delayedCall(850, () => {
        [a, b].forEach((entry) => {
          entry.flipped = false;
          entry.text.setText("?").setColor("#6be7d6");
          entry.rect.setFillStyle(0x123247, 1);
        });
        this.memFlipped = [];
        this.memLocked = false;
      });
    }
  }

  private updateMemStatus(): void {
    this.memStatus?.setText(`Mosse: ${this.memMoves} · Coppie: ${this.memMatched}/${this.memPairs}`);
  }

  // -- Codice Segreto (deductive logic, Mastermind) -----------------------

  private startCode(): void {
    this.clearScreen();
    this.codeLen = 4;
    this.codeMax = 8;
    this.codeAttempts = 0;
    this.codeGuess = [];
    this.codeHistoryY = 150;
    const random = new Random(`code-${Date.now()}`);
    this.codeSecret = random.shuffle(CODE_SYMBOLS.map((_, i) => i)).slice(0, this.codeLen);

    this.t(this.add.text(56, 30, "🔐 Codice Segreto", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 70, `Indovina i ${this.codeLen} simboli (tutti diversi). ⚫ = giusto al posto giusto · ⚪ = c'è ma in un'altra posizione.`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#c7dce7", wordWrap: { width: 1160 } }));
    this.codeStatus = this.t(this.add.text(58, 100, `Tentativo 1 di ${this.codeMax}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f7d37a" }));

    // Current guess slots (right side).
    this.codeSlots = [];
    for (let i = 0; i < this.codeLen; i += 1) {
      this.t(this.add.rectangle(820 + i * 70, 560, 60, 60, 0x0c1d2a, 1).setStrokeStyle(2, 0x6be7d6, 0.6));
      this.codeSlots.push(this.t(this.add.text(820 + i * 70, 560, "·", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#6be7d6" }).setOrigin(0.5)));
    }
    this.t(this.add.text(820, 516, "Il tuo tentativo (tocca uno slot per cancellare):", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0" }));
    this.codeSlots.forEach((slot, i) => {
      slot.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
        if (this.codeGuess.length > i) {
          this.codeGuess.splice(i, 1);
          this.renderCodeGuess();
        }
      });
    });

    // Palette.
    CODE_SYMBOLS.forEach((symbol, index) => {
      this.t(new Button(this, 540 + (index % 3) * 80, 540 + Math.floor(index / 3) * 70, symbol, () => this.codePick(index), { width: 64, height: 60, fontSize: 26, fill: 0x21162a, stroke: 0x6be7d6 }));
    });
    this.t(new Button(this, 1140, 560, "Prova", () => this.codeSubmit(), { width: 120, height: 60, fill: 0x1f5a51, stroke: 0xf6c85f }));
    this.backBar(() => this.startCode());
  }

  private codePick(symbolIndex: number): void {
    if (this.codeGuess.length >= this.codeLen) return;
    if (this.codeGuess.includes(symbolIndex)) return; // distinct symbols only
    this.codeGuess.push(symbolIndex);
    audioManager.play("uiSelect");
    this.renderCodeGuess();
  }

  private renderCodeGuess(): void {
    this.codeSlots.forEach((slot, i) => {
      slot.setText(this.codeGuess[i] !== undefined ? CODE_SYMBOLS[this.codeGuess[i]] : "·");
    });
  }

  private codeSubmit(): void {
    if (this.codeGuess.length < this.codeLen) {
      this.codeStatus?.setText("Completa il codice con 4 simboli diversi.");
      audioManager.play("error");
      return;
    }
    this.codeAttempts += 1;
    let exact = 0;
    let present = 0;
    this.codeGuess.forEach((symbol, i) => {
      if (this.codeSecret[i] === symbol) exact += 1;
      else if (this.codeSecret.includes(symbol)) present += 1;
    });

    const y = this.codeHistoryY;
    this.t(this.add.text(58, y, `${this.codeAttempts}.`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#7d93a0" }));
    this.codeGuess.forEach((symbol, i) => {
      this.t(this.add.text(96 + i * 44, y, CODE_SYMBOLS[symbol], { fontFamily: "Inter, Arial", fontSize: "24px" }));
    });
    this.t(this.add.text(300, y + 4, `${"⚫".repeat(exact)}${"⚪".repeat(present)}${"▫".repeat(this.codeLen - exact - present)}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#dbe6ee" }));
    this.codeHistoryY += 42;

    if (exact === this.codeLen) {
      audioManager.play("success");
      const score = (this.codeMax - this.codeAttempts + 1) * 12;
      this.finishActivity("code", "Codice Segreto", score, ["trasversali.logica", "pensieroCritico"], Math.min(22, 6 + (this.codeMax - this.codeAttempts) * 2), `Codice decifrato in ${this.codeAttempts} tentativi!`);
      return;
    }
    if (this.codeAttempts >= this.codeMax) {
      audioManager.play("error");
      this.finishActivity("code", "Codice Segreto", 0, ["trasversali.logica"], 4, `Codice non trovato. Era: ${this.codeSecret.map((s) => CODE_SYMBOLS[s]).join(" ")}`);
      return;
    }
    this.codeGuess = [];
    this.renderCodeGuess();
    this.codeStatus?.setText(`Tentativo ${this.codeAttempts + 1} di ${this.codeMax}`);
  }

  // -- Sequenze Logiche (inductive reasoning) -----------------------------

  private startSeq(): void {
    this.seqRound = 0;
    this.seqCorrect = 0;
    this.seqTotal = 6;
    this.nextSeq();
  }

  private nextSeq(): void {
    this.clearScreen();
    if (this.seqRound >= this.seqTotal) {
      const score = Math.round((this.seqCorrect / this.seqTotal) * 100);
      this.finishActivity("seq", "Sequenze Logiche", score, ["trasversali.logica", "pensieroCritico"], Math.min(20, 4 + this.seqCorrect * 3), `Hai risolto ${this.seqCorrect} schemi su ${this.seqTotal}.`);
      return;
    }
    const level = 1 + Math.floor(this.seqRound / 2);
    const puzzle = new LogicSequenceGenerator().generate(new Random(`seq-${Date.now()}-${this.seqRound}`), level);

    this.t(this.add.text(640, 40, "🔢 Sequenze Logiche", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Schema ${this.seqRound + 1}/${this.seqTotal} · corrette: ${this.seqCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

    this.t(this.add.text(640, 200, `${puzzle.sequence.join("   ,   ")}   ,   ?`, { fontFamily: "Inter, Arial", fontSize: "40px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 280, puzzle.question, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#c7dce7" }).setOrigin(0.5));

    puzzle.options.forEach((option, index) => {
      const x = 360 + (index % 2) * 560;
      const y = 380 + Math.floor(index / 2) * 90;
      this.t(new Button(this, x, y, option, () => this.answerSeq(puzzle, index), { width: 500, height: 70, fontSize: 24, fill: 0x21162a, stroke: 0x70d68a }));
    });
    this.backBar(() => this.startSeq());
  }

  private answerSeq(puzzle: LogicSequence, choice: number): void {
    const correct = choice === puzzle.correctIndex;
    if (correct) {
      this.seqCorrect += 1;
      audioManager.play("success");
    } else {
      audioManager.play("error");
    }
    this.t(this.add.rectangle(640, 600, 1100, 90, 0x0c1d2a, 0.96).setStrokeStyle(2, correct ? 0x70d68a : 0xff5d7a, 0.7));
    this.t(this.add.text(640, 600, `${correct ? "✓ Esatto! " : "✗ Quasi! "}${puzzle.explanation}`, { fontFamily: "Inter, Arial", fontSize: "15px", color: correct ? "#9ff5c0" : "#ffd0da", align: "center", wordWrap: { width: 1060 } }).setOrigin(0.5));
    this.tracked.forEach((object) => {
      if (object instanceof Button) object.disableInteractive();
    });
    this.time.delayedCall(1900, () => {
      this.seqRound += 1;
      this.nextSeq();
    });
  }

  // -- Bilancia Logica (deductive reasoning) ------------------------------

  private startBalance(): void {
    this.balRound = 0;
    this.balCorrect = 0;
    this.balTotal = 6;
    this.nextBalance();
  }

  private nextBalance(): void {
    this.clearScreen();
    if (this.balRound >= this.balTotal) {
      const score = Math.round((this.balCorrect / this.balTotal) * 100);
      this.finishActivity("balance", "Bilancia Logica", score, ["trasversali.logica", "pensieroCritico"], Math.min(20, 4 + this.balCorrect * 3), `Hai risolto ${this.balCorrect} deduzioni su ${this.balTotal}.`);
      return;
    }
    const level = 1 + Math.floor(this.balRound / 2);
    const puzzle = generateBalance(new Random(`bal-${Date.now()}-${this.balRound}`), level);

    this.t(this.add.text(640, 40, "⚖️ Bilancia Logica", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Deduzione ${this.balRound + 1}/${this.balTotal} · corrette: ${this.balCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

    this.t(this.add.text(640, 150, "Indizi:", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    puzzle.clues.forEach((clue, i) => {
      this.t(this.add.text(640, 188 + i * 34, clue, { fontFamily: "Inter, Arial", fontSize: "22px", color: "#f5fbff" }).setOrigin(0.5));
    });
    this.t(this.add.text(640, 188 + puzzle.clues.length * 34 + 14, puzzle.question, { fontFamily: "Inter, Arial", fontSize: "20px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));

    puzzle.options.forEach((option, index) => {
      const x = 640 - ((puzzle.options.length - 1) * 150) / 2 + index * 150;
      this.t(new Button(this, x, 470, option, () => this.answerBalance(puzzle, index), { width: 130, height: 110, fontSize: 44, fill: 0x21162a, stroke: 0xf6c85f }));
    });
    this.backBar(() => this.startBalance());
  }

  private answerBalance(puzzle: BalancePuzzle, choice: number): void {
    const correct = choice === puzzle.correctIndex;
    if (correct) {
      this.balCorrect += 1;
      audioManager.play("success");
    } else {
      audioManager.play("error");
    }
    this.t(this.add.rectangle(640, 600, 1100, 90, 0x0c1d2a, 0.96).setStrokeStyle(2, correct ? 0x70d68a : 0xff5d7a, 0.7));
    this.t(this.add.text(640, 600, `${correct ? "✓ Esatto! " : "✗ Quasi! "}${puzzle.explanation}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: correct ? "#9ff5c0" : "#ffd0da", align: "center", wordWrap: { width: 1060 } }).setOrigin(0.5));
    this.tracked.forEach((object) => {
      if (object instanceof Button) object.disableInteractive();
    });
    this.time.delayedCall(2000, () => {
      this.balRound += 1;
      this.nextBalance();
    });
  }

  // -- Griglia Lampo (spatial memory) -------------------------------------

  private startFlash(): void {
    this.clearScreen();
    this.flashRound = 0;
    this.t(this.add.text(640, 40, "⚡ Griglia Lampo", { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.flashStatus = this.t(this.add.text(640, 84, "Memorizza le caselle accese…", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" }).setOrigin(0.5));

    const size = 4;
    const cell = 96;
    const gap = 12;
    const total = size * cell + (size - 1) * gap;
    const startX = 640 - total / 2 + cell / 2;
    const startY = 200;
    this.flashCells = [];
    for (let i = 0; i < size * size; i += 1) {
      const col = i % size;
      const row = Math.floor(i / size);
      const x = startX + col * (cell + gap);
      const y = startY + row * (cell + gap);
      const rect = this.t(this.add.rectangle(x, y, cell, cell, 0x123247, 1).setStrokeStyle(2, 0x6be7d6, 0.5).setInteractive({ useHandCursor: true }));
      rect.on("pointerdown", () => this.flashClick(i));
      this.flashCells.push(rect);
    }
    this.backBar(() => this.startFlash());
    this.time.delayedCall(700, () => this.flashShow());
  }

  private flashShow(): void {
    this.flashLocked = true;
    this.flashPicked = new Set();
    this.flashTarget = new Set();
    const count = 3 + this.flashRound;
    const random = new Random(`flash-${Date.now()}-${this.flashRound}`);
    while (this.flashTarget.size < Math.min(count, this.flashCells.length - 1)) {
      this.flashTarget.add(random.integer(0, this.flashCells.length - 1));
    }
    this.flashStatus?.setText(`Turno ${this.flashRound + 1} · memorizza ${this.flashTarget.size} caselle…`);
    this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0xf6c85f, 1));
    audioManager.play("scan");
    const showMs = settingsSystem.effectsReduced() ? 1600 : 1100 + this.flashTarget.size * 120;
    this.time.delayedCall(showMs, () => {
      this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0x123247, 1));
      this.flashLocked = false;
      this.flashStatus?.setText("Ora tocca le caselle che erano accese!");
    });
  }

  private flashClick(index: number): void {
    if (this.flashLocked || this.flashPicked.has(index)) return;
    if (!this.flashTarget.has(index)) {
      audioManager.play("error");
      this.flashCells[index].setFillStyle(0xff5d7a, 1);
      this.flashLocked = true;
      this.finishActivity("flash", "Griglia Lampo", this.flashRound, ["trasversali.memoria"], Math.min(20, 4 + this.flashRound * 2), `Hai ricostruito ${this.flashRound} griglie.`);
      return;
    }
    audioManager.play("uiSelect");
    this.flashPicked.add(index);
    this.flashCells[index].setFillStyle(0x70d68a, 1);
    if (this.flashPicked.size === this.flashTarget.size) {
      audioManager.play("success");
      this.flashLocked = true;
      this.flashRound += 1;
      this.flashStatus?.setText("Perfetto! Griglia più grande…");
      if (this.flashRound >= 10) {
        this.finishActivity("flash", "Griglia Lampo", 10, ["trasversali.memoria"], 22, "Memoria spaziale eccezionale!");
        return;
      }
      this.time.delayedCall(800, () => {
        this.flashCells.forEach((rect) => rect.setFillStyle(0x123247, 1));
        this.flashShow();
      });
    }
  }

  // -- Shared outcome -----------------------------------------------------

  private finishActivity(key: string, label: string, score: number, comps: string[], award: number, summary: string): void {
    const previous = this.best(key);
    const record = score > previous;
    saveSystem.data.logicGym = { best: { ...(saveSystem.data.logicGym?.best ?? {}), [key]: Math.max(previous, score) } };
    if (award > 0) {
      competencyTracker.award(comps, award);
    }
    saveSystem.persistData();

    this.time.delayedCall(key === "simon" || key === "code" ? 600 : 50, () => {
      this.clearScreen();
      this.t(this.add.rectangle(640, 360, 880, 360, 0x0b1922, 0.97).setStrokeStyle(2, 0xf6c85f, 0.7));
      this.t(this.add.text(640, 250, label, { fontFamily: "Inter, Arial", fontSize: "26px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
      this.t(this.add.text(640, 312, `Punteggio: ${score}${record ? "   ★ NUOVO RECORD!" : `   (record: ${Math.max(previous, score)})`}`, { fontFamily: "Inter, Arial", fontSize: "20px", color: record ? "#f6c85f" : "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
      this.t(this.add.text(640, 360, summary, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", align: "center", wordWrap: { width: 760 } }).setOrigin(0.5));
      if (award > 0) {
        this.t(this.add.text(640, 408, `+${award} competenze Trasversali`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#70d68a" }).setOrigin(0.5));
      }
      const restart = this.currentRestart ?? (() => this.showHub());
      this.t(new Button(this, 440, 470, "Riprova", () => restart(), { width: 220, height: 50, fill: 0x1f5a51, stroke: 0xf6c85f }));
      this.t(new Button(this, 700, 470, "Palestra", () => this.showHub(), { width: 200, height: 50, fill: 0x263743 }));
      this.t(new Button(this, 920, 470, "Menu", () => this.scene.start("MainMenuScene"), { width: 160, height: 50, fill: 0x263743 }));
    });
  }
}
