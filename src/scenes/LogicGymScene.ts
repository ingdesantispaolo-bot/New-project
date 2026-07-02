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

type GymActivityKey = "simon" | "memory" | "code" | "seq" | "balance" | "flash" | "firewall";
type ActivityMeta = { key: GymActivityKey; title: string; glyph: string; theme: string; desc: string; color: number; start: () => void };
type MemoryCard = { pairId: string; label: string; rect: Phaser.GameObjects.Rectangle; text: Phaser.GameObjects.Text; matched: boolean; flipped: boolean };
type FirewallAction = "allow" | "block" | "quarantine" | "inspect";
type FirewallSignal = {
  id: string;
  color: "blu" | "verde" | "rosso" | "ambra" | "viola";
  origin: string;
  port: number;
  signature: "stabile" | "mancante" | "alterata" | "incerta";
  repeated: boolean;
  priority: boolean;
  correctAction: FirewallAction;
  reason: string;
};

const PAD_COLORS = [0xff5d7a, 0x6be7d6, 0xf6c85f, 0x70d68a, 0x9f8cff, 0xff9ad2];
const CODE_SYMBOLS = ["🔴", "🔵", "🟡", "🟢", "🟣", "🟠"];
const GYM_MIN_LEVEL = 1;
const GYM_MAX_LEVEL = 8;

/**
 * "Palestra della Mente" — a transversal logic & memory gym with four distinct,
 * challenging activities that feed the cross-cutting competencies (memoria di
 * lavoro, ragionamento logico) and therefore the Academy's mastery and Core.
 */
export class LogicGymScene extends Phaser.Scene {
  private tracked: Phaser.GameObjects.GameObject[] = [];
  private currentRestart: (() => void) | null = null;
  private gymLevel = 1;

  // Sequenza Luminosa
  private simonPads: Phaser.GameObjects.Rectangle[] = [];
  private simonSeq: number[] = [];
  private simonInput: number[] = [];
  private simonLocked = true;
  private simonStatus?: Phaser.GameObjects.Text;

  // Memory delle Coppie
  private memCards: MemoryCard[] = [];
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
  private flashTargetOrder: number[] = [];
  private flashPicked = new Set<number>();
  private flashRound = 0;
  private flashLocked = true;
  private flashStatus?: Phaser.GameObjects.Text;

  // Firewall NORA
  private firewallSignals: FirewallSignal[] = [];
  private firewallIndex = 0;
  private firewallCorrect = 0;
  private firewallErrors = 0;
  private firewallLocked = false;
  private firewallStatus?: Phaser.GameObjects.Text;
  private firewallPacket?: Phaser.GameObjects.Container;

  constructor() {
    super("LogicGymScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.gymLevel = Phaser.Math.Clamp(saveSystem.data.logicGym?.level ?? 1, GYM_MIN_LEVEL, GYM_MAX_LEVEL);
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
      { key: "firewall", title: "Firewall NORA", glyph: "FW", theme: "Cyber-logica", color: 0x5ec8ff, desc: "Classifica segnali: consenti, blocca, quarantena o ispeziona seguendo regole crescenti.", start: () => this.startFirewall() },
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
    return this.bestForLevel(key as GymActivityKey, this.gymLevel);
  }

  private bestForLevel(key: GymActivityKey, level: number): number {
    return saveSystem.data.logicGym?.bestByLevel?.[key]?.[String(level)] ?? 0;
  }

  private setGymLevel(delta: number): void {
    this.gymLevel = Phaser.Math.Clamp(this.gymLevel + delta, GYM_MIN_LEVEL, GYM_MAX_LEVEL);
    saveSystem.data.logicGym = {
      best: saveSystem.data.logicGym?.best ?? {},
      bestByLevel: saveSystem.data.logicGym?.bestByLevel ?? {},
      level: this.gymLevel,
    };
    saveSystem.persistData();
    this.showHub();
  }

  private levelSubtitle(): string {
    if (this.gymLevel <= 2) return "base guidata";
    if (this.gymLevel <= 4) return "attenzione stabile";
    if (this.gymLevel <= 6) return "deduzione rapida";
    return "sfida esperta";
  }

  // -- Hub ----------------------------------------------------------------

  private showHub(): void {
    this.clearScreen();
    this.currentRestart = null;
    this.t(this.add.text(56, 28, "Palestra della Mente", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 68, "Allenamento autonomo: scegli il livello, poi gioca. I record sono separati per difficoltà.", { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", wordWrap: { width: 760 } }));
    this.t(this.add.rectangle(1004, 54, 296, 54, 0x0c1d2a, 0.92).setStrokeStyle(2, 0xf6c85f, 0.48));
    this.t(this.add.text(1004, 40, `Livello ${this.gymLevel}/8`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(1004, 66, this.levelSubtitle(), { fontFamily: "Inter, Arial", fontSize: "11px", color: "#c7dce7" }).setOrigin(0.5));
    this.t(new Button(this, 870, 54, "−", () => this.setGymLevel(-1), { width: 42, height: 38, fontSize: 24, fill: 0x263743 }));
    this.t(new Button(this, 1138, 54, "+", () => this.setGymLevel(1), { width: 42, height: 38, fontSize: 22, fill: 0x263743 }));
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
      this.t(this.add.text(x + 20, y + 166, this.activityLevelLine(activity.key), { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9ff5e9", wordWrap: { width: w - 40 } }));
      this.t(this.add.text(x + 20, y + 188, `Record L${this.gymLevel}: ${this.best(activity.key)}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a" }));
      this.t(new Button(this, x + w - 100, y + 200, "Gioca", () => activity.start(), { width: 150, height: 44, fill: 0x1f5a51, stroke: activity.color }));
    });

    this.t(new Button(this, 132, 686, "Menu", () => this.scene.start("MainMenuScene"), { width: 170, height: 44, fill: 0x263743 }));
  }

  private backBar(restart: () => void): void {
    this.currentRestart = restart;
    this.t(this.add.text(640, 686, `Livello ${this.gymLevel}/8 · ${this.levelSubtitle()}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    this.t(new Button(this, 132, 686, "Palestra", () => this.showHub(), { width: 170, height: 44, fill: 0x263743 }));
  }

  private activityLevelLine(key: GymActivityKey): string {
    switch (key) {
      case "simon": return `${this.simonPadCount()} luci · ritmo ${this.gymLevel >= 6 ? "rapido" : "guidato"}`;
      case "memory": return `${this.memoryPairCount()} coppie · ${this.gymLevel >= 5 ? "associazioni miste" : "associazioni base"}`;
      case "code": return `${this.codeLengthForLevel()} simboli · ${this.codeMaxForLevel()} tentativi`;
      case "seq": return `${this.roundsForLevel()} schemi · regole fino a L${this.sequenceLevelForRound(this.roundsForLevel() - 1)}`;
      case "balance": return `${this.roundsForLevel()} deduzioni · ${this.gymLevel >= 8 ? "anche dati insufficienti" : "ordine logico"}`;
      case "flash": return `${this.flashGridSize()}x${this.flashGridSize()} · memoria ${this.gymLevel >= 7 ? "sequenziale" : "spaziale"}`;
    }
  }

  private simonPadCount(): number {
    return this.gymLevel <= 1 ? 3 : this.gymLevel <= 3 ? 4 : this.gymLevel <= 5 ? 5 : 6;
  }

  private simonStartLength(): number {
    return this.gymLevel >= 7 ? 2 : 1;
  }

  private simonTargetLength(): number {
    return 5 + this.gymLevel * 2;
  }

  private simonStepMs(): number {
    const base = settingsSystem.effectsReduced() ? 520 : 700 - this.gymLevel * 38;
    return Math.max(settingsSystem.effectsReduced() ? 430 : 360, base);
  }

  private memoryPairCount(): number {
    return this.gymLevel <= 1 ? 4 : this.gymLevel <= 3 ? 6 : this.gymLevel <= 6 ? 7 : 8;
  }

  private codeLengthForLevel(): number {
    return this.gymLevel <= 1 ? 3 : this.gymLevel >= 6 ? 5 : 4;
  }

  private codeMaxForLevel(): number {
    if (this.gymLevel <= 1) return 8;
    if (this.gymLevel <= 3) return 8;
    if (this.gymLevel <= 5) return 7;
    return 6;
  }

  private roundsForLevel(): number {
    return this.gymLevel >= 6 ? 8 : 6;
  }

  private sequenceLevelForRound(round: number): number {
    return Phaser.Math.Clamp(this.gymLevel - 1 + Math.floor(round / 2), 1, 8);
  }

  private flashGridSize(): number {
    return this.gymLevel >= 6 ? 5 : 4;
  }

  private flashBaseCount(): number {
    return this.gymLevel <= 2 ? 3 : this.gymLevel <= 4 ? 4 : this.gymLevel <= 6 ? 5 : 6;
  }

  private flashSequentialMode(): boolean {
    return this.gymLevel >= 7;
  }

  // -- Sequenza Luminosa (sequential working memory) ----------------------

  private startSimon(): void {
    this.clearScreen();
    this.simonSeq = [];
    this.simonInput = [];
    this.simonLocked = true;
    this.t(this.add.text(640, 40, `🧠 Sequenza Luminosa · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.simonStatus = this.t(this.add.text(640, 86, "Guarda bene…", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" }).setOrigin(0.5));

    const padCount = this.simonPadCount();
    const cols = padCount <= 4 ? 2 : 3;
    const padW = 168;
    const padH = 128;
    const gap = 26;
    const totalW = cols * padW + (cols - 1) * gap;
    const startX = 640 - totalW / 2 + padW / 2;
    const startY = padCount <= 4 ? 286 : 240;
    PAD_COLORS.slice(0, padCount).forEach((color, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = startX + col * (padW + gap);
      const y = startY + row * (padH + gap);
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
    const additions = this.simonSeq.length === 0 ? this.simonStartLength() : 1;
    for (let i = 0; i < additions; i += 1) {
      this.simonSeq.push(random.integer(0, this.simonPadCount() - 1));
    }
    this.simonStatus?.setText(`Turno ${this.simonSeq.length} · Guarda la sequenza…`);
    const step = this.simonStepMs();
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
      const expected = this.simonSeq[pos];
      this.finishActivity("simon", "Sequenza Luminosa", reached, ["trasversali.memoria"], Math.min(22, 4 + reached + this.gymLevel), `Errore al passo ${pos + 1}: hai premuto la luce ${index + 1}, ma la sequenza chiedeva la luce ${expected + 1}.`);
      return;
    }
    if (this.simonInput.length === this.simonSeq.length) {
      this.simonLocked = true;
      this.simonStatus?.setText("Perfetto! Sequenza più lunga…");
      audioManager.play("success");
      if (this.simonSeq.length >= this.simonTargetLength()) {
        this.finishActivity("simon", "Sequenza Luminosa", this.simonTargetLength(), ["trasversali.memoria"], 22, "Hai raggiunto la sequenza obiettivo del livello.");
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
    this.memPairs = this.memoryPairCount();
    const random = new Random(`memory-${Date.now()}`);
    const pairs: MemoryPair[] = buildMemoryPairs(random, this.memPairs);
    const deck = random.shuffle(pairs.flatMap((pair) => [
      { pairId: pair.id, label: pair.a },
      { pairId: pair.id, label: pair.b },
    ]));

    this.t(this.add.text(640, 36, `🃏 Memory delle Coppie · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.memStatus = this.t(this.add.text(640, 78, `Mosse: 0 · Coppie: 0/${this.memPairs}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9" }).setOrigin(0.5));

    const cols = 4;
    const cardW = this.memPairs >= 8 ? 206 : this.memPairs >= 7 ? 214 : 230;
    const cardH = this.memPairs >= 7 ? 94 : 116;
    const gap = this.memPairs >= 7 ? 14 : 18;
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
        const perfectMoves = this.memPairs;
        const efficiency = Math.max(0, Math.round((perfectMoves / Math.max(perfectMoves, this.memMoves)) * 100));
        const score = efficiency + this.gymLevel * 4;
        this.finishActivity("memory", "Memory delle Coppie", score, ["trasversali.memoria", "pensieroCritico"], Math.min(20, 6 + Math.round(efficiency / 12) + Math.floor(this.gymLevel / 3)), `Tutte le ${this.memPairs} coppie trovate in ${this.memMoves} mosse. Efficienza: ${efficiency}%.`);
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
    this.codeLen = this.codeLengthForLevel();
    this.codeMax = this.codeMaxForLevel();
    this.codeAttempts = 0;
    this.codeGuess = [];
    this.codeHistoryY = 150;
    const random = new Random(`code-${Date.now()}`);
    this.codeSecret = random.shuffle(CODE_SYMBOLS.map((_, i) => i)).slice(0, this.codeLen);

    this.t(this.add.text(56, 30, `🔐 Codice Segreto · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 70, `Indovina i ${this.codeLen} simboli (tutti diversi). ⚫ = giusto al posto giusto · ⚪ = c'è ma in un'altra posizione.`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#c7dce7", wordWrap: { width: 1160 } }));
    this.codeStatus = this.t(this.add.text(58, 100, `Tentativo 1 di ${this.codeMax}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f7d37a" }));

    // Current guess slots (right side).
    this.codeSlots = [];
    const slotStartX = this.codeLen >= 5 ? 786 : 820;
    for (let i = 0; i < this.codeLen; i += 1) {
      this.t(this.add.rectangle(slotStartX + i * 66, 560, 58, 60, 0x0c1d2a, 1).setStrokeStyle(2, 0x6be7d6, 0.6));
      this.codeSlots.push(this.t(this.add.text(slotStartX + i * 66, 560, "·", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#6be7d6" }).setOrigin(0.5)));
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
      this.codeStatus?.setText(`Completa il codice con ${this.codeLen} simboli diversi.`);
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
      const score = (this.codeMax - this.codeAttempts + 1) * (8 + this.gymLevel);
      this.finishActivity("code", "Codice Segreto", score, ["trasversali.logica", "pensieroCritico"], Math.min(24, 6 + (this.codeMax - this.codeAttempts) * 2 + Math.floor(this.gymLevel / 3)), `Codice da ${this.codeLen} simboli decifrato in ${this.codeAttempts} tentativi.`);
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
    this.seqTotal = this.roundsForLevel();
    this.nextSeq();
  }

  private nextSeq(): void {
    this.clearScreen();
    if (this.seqRound >= this.seqTotal) {
      const score = Math.round((this.seqCorrect / this.seqTotal) * 100) + this.gymLevel * 3;
      this.finishActivity("seq", "Sequenze Logiche", score, ["trasversali.logica", "pensieroCritico"], Math.min(22, 4 + this.seqCorrect * 2 + Math.floor(this.gymLevel / 2)), `Hai risolto ${this.seqCorrect} schemi su ${this.seqTotal}.`);
      return;
    }
    const level = this.sequenceLevelForRound(this.seqRound);
    const puzzle = new LogicSequenceGenerator().generate(new Random(`seq-${Date.now()}-${this.seqRound}`), level);

    this.t(this.add.text(640, 40, `🔢 Sequenze Logiche · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Schema ${this.seqRound + 1}/${this.seqTotal} · regola L${level} · corrette: ${this.seqCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

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
    this.balTotal = this.roundsForLevel();
    this.nextBalance();
  }

  private nextBalance(): void {
    this.clearScreen();
    if (this.balRound >= this.balTotal) {
      const score = Math.round((this.balCorrect / this.balTotal) * 100) + this.gymLevel * 3;
      this.finishActivity("balance", "Bilancia Logica", score, ["trasversali.logica", "pensieroCritico"], Math.min(22, 4 + this.balCorrect * 2 + Math.floor(this.gymLevel / 2)), `Hai risolto ${this.balCorrect} deduzioni su ${this.balTotal}.`);
      return;
    }
    const level = this.sequenceLevelForRound(this.balRound);
    const puzzle = generateBalance(new Random(`bal-${Date.now()}-${this.balRound}`), level);

    this.t(this.add.text(640, 40, `⚖️ Bilancia Logica · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Deduzione ${this.balRound + 1}/${this.balTotal} · regola L${level} · corrette: ${this.balCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

    this.t(this.add.text(640, 150, "Indizi:", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    puzzle.clues.forEach((clue, i) => {
      this.t(this.add.text(640, 188 + i * 34, clue, { fontFamily: "Inter, Arial", fontSize: "22px", color: "#f5fbff" }).setOrigin(0.5));
    });
    this.t(this.add.text(640, 188 + puzzle.clues.length * 34 + 14, puzzle.question, { fontFamily: "Inter, Arial", fontSize: "20px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));

    puzzle.options.forEach((option, index) => {
      const compact = option.length > 4;
      const x = 640 - ((puzzle.options.length - 1) * 180) / 2 + index * 180;
      this.t(new Button(this, x, 470, option, () => this.answerBalance(puzzle, index), { width: compact ? 176 : 130, height: 110, fontSize: compact ? 16 : 44, fill: 0x21162a, stroke: 0xf6c85f, wordWrapWidth: compact ? 142 : undefined }));
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
    this.t(this.add.text(640, 40, `⚡ Griglia Lampo · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.flashStatus = this.t(this.add.text(640, 84, this.flashSequentialMode() ? "Memorizza ordine e posizione…" : "Memorizza le caselle accese…", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" }).setOrigin(0.5));

    const size = this.flashGridSize();
    const cell = size >= 5 ? 74 : 96;
    const gap = size >= 5 ? 10 : 12;
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
    this.flashTargetOrder = [];
    const count = this.flashBaseCount() + this.flashRound;
    const random = new Random(`flash-${Date.now()}-${this.flashRound}`);
    while (this.flashTarget.size < Math.min(count, this.flashCells.length - 1)) {
      this.flashTarget.add(random.integer(0, this.flashCells.length - 1));
    }
    this.flashTargetOrder = [...this.flashTarget];
    this.flashStatus?.setText(this.flashSequentialMode()
      ? `Turno ${this.flashRound + 1} · memorizza ${this.flashTarget.size} caselle in ordine…`
      : `Turno ${this.flashRound + 1} · memorizza ${this.flashTarget.size} caselle…`);
    audioManager.play("scan");
    if (this.flashSequentialMode()) {
      const stepMs = settingsSystem.effectsReduced() ? 360 : 460 - this.gymLevel * 18;
      this.flashTargetOrder.forEach((index, i) => {
        this.time.delayedCall(420 + i * stepMs, () => {
          this.flashCells[index].setFillStyle(0xf6c85f, 1);
          this.time.delayedCall(Math.max(160, stepMs - 90), () => this.flashCells[index].setFillStyle(0x123247, 1));
        });
      });
      this.time.delayedCall(560 + this.flashTargetOrder.length * stepMs, () => {
        this.flashLocked = false;
        this.flashStatus?.setText("Ora ripeti lo stesso ordine!");
      });
      return;
    }
    this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0xf6c85f, 1));
    const showMs = settingsSystem.effectsReduced() ? 1600 : Math.max(720, 1250 + this.flashTarget.size * 110 - this.gymLevel * 80);
    this.time.delayedCall(showMs, () => {
      this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0x123247, 1));
      this.flashLocked = false;
      this.flashStatus?.setText("Ora tocca le caselle che erano accese!");
    });
  }

  private flashClick(index: number): void {
    if (this.flashLocked || this.flashPicked.has(index)) return;
    const expected = this.flashSequentialMode() ? this.flashTargetOrder[this.flashPicked.size] : undefined;
    if (!this.flashTarget.has(index) || (this.flashSequentialMode() && index !== expected)) {
      audioManager.play("error");
      this.flashCells[index].setFillStyle(0xff5d7a, 1);
      this.flashLocked = true;
      const message = this.flashSequentialMode() && expected !== undefined
        ? `Ordine interrotto: serviva la casella ${expected + 1}, non la ${index + 1}.`
        : `Hai ricostruito ${this.flashRound} griglie.`;
      this.finishActivity("flash", "Griglia Lampo", this.flashRound + this.gymLevel * 2, ["trasversali.memoria"], Math.min(22, 4 + this.flashRound * 2 + Math.floor(this.gymLevel / 2)), message);
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
      const targetRounds = this.gymLevel >= 6 ? 8 : 10;
      if (this.flashRound >= targetRounds) {
        this.finishActivity("flash", "Griglia Lampo", targetRounds + this.gymLevel * 3, ["trasversali.memoria"], 22, this.flashSequentialMode() ? "Hai ricostruito tutte le sequenze spaziali." : "Memoria spaziale eccezionale!");
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
    const activityKey = key as GymActivityKey;
    const previous = this.bestForLevel(activityKey, this.gymLevel);
    const record = score > previous;
    const best = saveSystem.data.logicGym?.best ?? {};
    const bestByLevel = saveSystem.data.logicGym?.bestByLevel ?? {};
    saveSystem.data.logicGym = {
      best: { ...best, [key]: Math.max(best[key] ?? 0, score) },
      bestByLevel: {
        ...bestByLevel,
        [key]: {
          ...(bestByLevel[key] ?? {}),
          [String(this.gymLevel)]: Math.max(previous, score),
        },
      },
      level: this.gymLevel,
    };
    if (award > 0) {
      competencyTracker.award(comps, award);
    }
    saveSystem.persistData();

    this.time.delayedCall(key === "simon" || key === "code" ? 600 : 50, () => {
      this.clearScreen();
      this.t(this.add.rectangle(640, 360, 880, 360, 0x0b1922, 0.97).setStrokeStyle(2, 0xf6c85f, 0.7));
      this.t(this.add.text(640, 250, `${label} · L${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "26px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
      this.t(this.add.text(640, 312, `Punteggio: ${score}${record ? "   ★ NUOVO RECORD DI LIVELLO!" : `   (record L${this.gymLevel}: ${Math.max(previous, score)})`}`, { fontFamily: "Inter, Arial", fontSize: "20px", color: record ? "#f6c85f" : "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
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
