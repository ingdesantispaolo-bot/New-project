import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { competencyTracker } from "../core/CompetencyTracker";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
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
type FirewallLens = "identity" | "content" | "route" | "priority";
type FirewallPayload = "pulito" | "rumoroso" | "criptato" | "esca";
type FirewallRoute = "interna" | "esterna" | "sconosciuta";
type FirewallSignal = {
  id: string;
  scenario: string;
  task: string;
  color: "blu" | "verde" | "rosso" | "ambra" | "viola";
  origin: string;
  port: number;
  signature: "stabile" | "mancante" | "alterata" | "incerta";
  payload: FirewallPayload;
  route: FirewallRoute;
  repeated: boolean;
  priority: boolean;
  threat: number;
  diagnosis: string;
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
  private firewallRoundObjects: Phaser.GameObjects.GameObject[] = [];
  private firewallStreak = 0;
  private firewallBestStreak = 0;
  private firewallStability = 100;
  private firewallRevealed = new Set<FirewallLens>();
  private firewallScansLeft = 0;

  constructor() {
    super("LogicGymScene");
  }

  preload(): void {
    queueSceneAssets(this, "academy", "logicGym");
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

  private ft<T extends Phaser.GameObjects.GameObject>(object: T): T {
    this.firewallRoundObjects.push(object);
    return this.t(object);
  }

  private clearFirewallRound(): void {
    const doomed = new Set(this.firewallRoundObjects);
    this.firewallRoundObjects.forEach((object) => object.destroy());
    this.tracked = this.tracked.filter((object) => !doomed.has(object));
    this.firewallRoundObjects = [];
    this.firewallPacket = undefined;
  }

  private clearScreen(): void {
    this.firewallRoundObjects = [];
    this.tracked.forEach((object) => object.destroy());
    this.tracked = [];
    this.simonPads = [];
    this.memCards = [];
    this.memFlipped = [];
    this.codeSlots = [];
    this.firewallPacket = undefined;
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
    this.t(this.add.text(58, 68, "Calibrazione autonoma: scegli la profondità, poi gioca. I record sono separati per settore.", { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9", wordWrap: { width: 760 } }));
    this.t(this.add.rectangle(1004, 54, 296, 54, 0x0c1d2a, 0.92).setStrokeStyle(2, 0xf6c85f, 0.48));
    this.t(this.add.text(1004, 40, `Profondità ${this.gymLevel}/8`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(1004, 66, this.levelSubtitle(), { fontFamily: "Inter, Arial", fontSize: "11px", color: "#c7dce7" }).setOrigin(0.5));
    this.t(new Button(this, 870, 54, "−", () => this.setGymLevel(-1), { width: 42, height: 38, fontSize: 24, fill: 0x263743 }));
    this.t(new Button(this, 1138, 54, "+", () => this.setGymLevel(1), { width: 42, height: 38, fontSize: 22, fill: 0x263743 }));
    placeHiddenAnomaly(this, "LogicGymScene");

    const cols = 4;
    const w = 288;
    const h = 248;
    const gap = 14;
    const startX = 40;
    const startY = 116;
    this.activities().forEach((activity, index) => {
      const x = startX + (index % cols) * (w + gap);
      const y = startY + Math.floor(index / cols) * (h + gap);
      this.t(this.add.rectangle(x, y, w, h, 0x0c1d2a, 0.94).setOrigin(0).setStrokeStyle(2, activity.color, 0.55));
      this.t(this.add.rectangle(x, y, w, 5, activity.color, 0.9).setOrigin(0));
      this.t(this.add.text(x + 18, y + 20, `${activity.glyph}  ${activity.title}`, { fontFamily: "Inter, Arial", fontSize: "17px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: w - 36 } }));
      this.t(this.add.text(x + 20, y + 58, activity.theme.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "12px", color: Phaser.Display.Color.IntegerToColor(activity.color).rgba, fontStyle: "bold" }));
      this.t(this.add.text(x + 20, y + 84, activity.desc, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: w - 40 }, lineSpacing: 3 }));
      this.t(this.add.text(x + 20, y + 166, this.activityLevelLine(activity.key), { fontFamily: "Inter, Arial", fontSize: "11px", color: "#9ff5e9", wordWrap: { width: w - 40 } }));
      this.t(this.add.text(x + 20, y + 188, `Record profondità ${this.gymLevel}: ${this.best(activity.key)}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a" }));
      this.t(new Button(this, x + w - 80, y + 200, "Gioca", () => activity.start(), { width: 124, height: 44, fill: 0x1f5a51, stroke: activity.color }));
    });

    this.t(new Button(this, 132, 686, "Menu", () => this.scene.start("MainMenuScene"), { width: 170, height: 44, fill: 0x263743 }));
  }

  private backBar(restart: () => void): void {
    this.currentRestart = restart;
    this.t(this.add.text(640, 686, `Profondità ${this.gymLevel}/8 · ${this.levelSubtitle()}`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    this.t(new Button(this, 132, 686, "Palestra", () => this.showHub(), { width: 170, height: 44, fill: 0x263743 }));
  }

  private activityLevelLine(key: GymActivityKey): string {
    switch (key) {
      case "simon": return `${this.simonPadCount()} luci · ritmo ${this.gymLevel >= 6 ? "rapido" : "guidato"}`;
      case "memory": return `${this.memoryPairCount()} coppie · ${this.gymLevel >= 5 ? "associazioni miste" : "associazioni base"}`;
      case "code": return `${this.codeLengthForLevel()} simboli · ${this.codeMaxForLevel()} tentativi`;
      case "seq": return `${this.roundsForLevel()} schemi · regole fino a profondità ${this.sequenceLevelForRound(this.roundsForLevel() - 1)}`;
      case "balance": return `${this.roundsForLevel()} deduzioni · ${this.gymLevel >= 8 ? "anche dati insufficienti" : "ordine logico"}`;
      case "flash": return `${this.flashGridSize()}x${this.flashGridSize()} · memoria ${this.gymLevel >= 7 ? "sequenziale" : "spaziale"}`;
      case "firewall": return `${this.firewallRoundCount()} segnali · ${this.firewallRuleCount()} regole`;
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

  private firewallRoundCount(): number {
    return this.gymLevel <= 2 ? 6 : this.gymLevel <= 5 ? 8 : 10;
  }

  private firewallRuleCount(): number {
    return this.gymLevel <= 1 ? 3 : this.gymLevel <= 2 ? 4 : this.gymLevel <= 4 ? 5 : this.gymLevel <= 6 ? 6 : 7;
  }

  private firewallAvailableActions(): FirewallAction[] {
    return ["allow", "block", "quarantine", "inspect"];
  }

  private firewallScanLimit(): number {
    if (this.gymLevel <= 2) return 3;
    if (this.gymLevel <= 5) return 2;
    return 2;
  }

  private firewallMinimumScans(): number {
    return this.gymLevel <= 2 ? 2 : 1;
  }

  // -- Sequenza Luminosa (sequential working memory) ----------------------

  private startSimon(): void {
    this.clearScreen();
    this.simonSeq = [];
    this.simonInput = [];
    this.simonLocked = true;
    this.t(this.add.text(640, 40, `🧠 Sequenza Luminosa · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
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
        this.finishActivity("simon", "Sequenza Luminosa", this.simonTargetLength(), ["trasversali.memoria"], 22, "Hai raggiunto la sequenza obiettivo della profondità.");
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

    this.t(this.add.text(640, 36, `🃏 Memory delle Coppie · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
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

    this.t(this.add.text(56, 30, `🔐 Codice Segreto · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }));
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

    this.t(this.add.text(640, 40, `🔢 Sequenze Logiche · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Schema ${this.seqRound + 1}/${this.seqTotal} · regola profondità ${level} · corrette: ${this.seqCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

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

    this.t(this.add.text(640, 40, `⚖️ Bilancia Logica · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Deduzione ${this.balRound + 1}/${this.balTotal} · regola profondità ${level} · corrette: ${this.balCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

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
    this.t(this.add.text(640, 40, `⚡ Griglia Lampo · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
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

  // -- Firewall NORA (rule switching + cyber-logic) ----------------------

  private startFirewall(): void {
    this.clearScreen();
    this.firewallIndex = 0;
    this.firewallCorrect = 0;
    this.firewallErrors = 0;
    this.firewallStreak = 0;
    this.firewallBestStreak = 0;
    this.firewallStability = 100;
    this.firewallRevealed = new Set();
    this.firewallScansLeft = this.firewallScanLimit();
    this.firewallLocked = false;
    this.firewallSignals = this.buildFirewallSignals(new Random(`firewall-${Date.now()}-${this.gymLevel}`));

    this.drawFirewallBackdrop();

    const bg = this.t(this.add.graphics());
    bg.fillStyle(0x06131c, 0.42);
    bg.fillRoundedRect(34, 92, 1212, 560, 10);
    bg.lineStyle(2, 0x5ec8ff, 0.34);
    bg.strokeRoundedRect(34, 92, 1212, 560, 10);
    for (let x = 90; x <= 1190; x += 74) {
      bg.lineStyle(1, 0x5ec8ff, 0.06);
      bg.lineBetween(x, 112, x, 626);
    }
    for (let y = 132; y <= 612; y += 48) {
      bg.lineStyle(1, 0x5ec8ff, 0.05);
      bg.lineBetween(54, y, 1226, y);
    }

    this.t(this.add.text(56, 32, `FW  Firewall NORA · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 70, "Indaga il segnale con gli strumenti, capisci il problema e applica il protocollo giusto. Meno scansioni usi, più NORA resta stabile.", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", wordWrap: { width: 920 } }));
    this.firewallStatus = this.t(this.add.text(1042, 54, "", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold", align: "right" }).setOrigin(0.5));

    this.drawFirewallRound();
    this.backBar(() => this.startFirewall());
  }

  private drawFirewallBackdrop(): void {
    if (this.textures.exists("logic-gym-firewall-bg")) {
      const backdrop = this.t(this.add.image(640, 360, "logic-gym-firewall-bg"));
      backdrop.setDisplaySize(1334, 750).setAlpha(0.9);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({
          targets: backdrop,
          scaleX: backdrop.scaleX * 1.018,
          scaleY: backdrop.scaleY * 1.018,
          duration: 14000,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut",
        });
      }
    }
    const shade = this.t(this.add.graphics());
    shade.fillStyle(0x02070b, 0.3);
    shade.fillRect(0, 0, 1280, 720);
    shade.fillGradientStyle(0x02070b, 0x02070b, 0x02070b, 0x02070b, 0.72, 0.22, 0.22, 0.72);
    shade.fillRect(0, 0, 1280, 720);
    shade.fillStyle(0x5ec8ff, 0.05);
    shade.fillCircle(640, 312, 210);
    shade.lineStyle(1, 0x5ec8ff, 0.1);
    for (let x = 58; x <= 1222; x += 84) {
      shade.lineBetween(x, 98, x + 130, 650);
    }
    const pulse = this.t(this.add.circle(640, 330, 112, 0x5ec8ff, 0.055).setStrokeStyle(2, 0x5ec8ff, 0.22));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: pulse, scale: 1.35, alpha: 0.01, duration: 1600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  private buildFirewallSignals(random: Random): FirewallSignal[] {
    const total = this.firewallRoundCount();
    const signals: FirewallSignal[] = [];
    const guardTypes = this.firewallAvailableActions();
    let attempts = 0;
    while (signals.length < total && attempts < total * 12) {
      attempts += 1;
      const signal = this.buildFirewallSignal(random, signals.length + attempts);
      if (!guardTypes.includes(signal.correctAction)) continue;
      signals.push(signal);
    }
    while (signals.length < total) {
      const fallback = this.buildFirewallSignal(random, signals.length + 100);
      fallback.color = signals.length % 2 === 0 ? "blu" : "rosso";
      fallback.signature = fallback.color === "rosso" ? "alterata" : "stabile";
      fallback.payload = fallback.color === "rosso" ? "esca" : "pulito";
      fallback.route = "interna";
      fallback.repeated = false;
      fallback.priority = false;
      const classified = this.classifyFirewallSignal(fallback);
      signals.push({ ...fallback, ...classified });
    }
    return random.shuffle(signals);
  }

  private buildFirewallSignal(random: Random, index: number): FirewallSignal {
    const colors = this.gymLevel <= 2
      ? (["blu", "verde", "rosso", "viola"] as const)
      : this.gymLevel <= 4
        ? (["blu", "verde", "rosso", "viola"] as const)
        : (["blu", "verde", "rosso", "ambra", "viola"] as const);
    const signatures = this.gymLevel <= 2
      ? (["stabile", "alterata", "mancante"] as const)
      : this.gymLevel <= 4
        ? (["stabile", "alterata", "mancante"] as const)
        : (["stabile", "alterata", "mancante", "incerta"] as const);
    const payloads = this.gymLevel <= 1
      ? (["pulito", "rumoroso", "esca"] as const)
      : this.gymLevel <= 4
        ? (["pulito", "rumoroso", "criptato", "esca"] as const)
        : (["pulito", "rumoroso", "criptato", "esca"] as const);
    const routes = this.gymLevel <= 1
      ? (["interna", "sconosciuta"] as const)
      : (["interna", "esterna", "sconosciuta"] as const);
    const origins = ["NORA-Core", "Archivio", "Serra", "Fabbrica", "Laboratorio", "Nodo Ombra", "Biblioteca", "Osservatorio"];
    const ports = [12, 24, 37, 48, 64, 81, 96, 108];
    const scenario = this.firewallScenario(random);
    const signal = {
      id: `N-${String(index).padStart(3, "0")}`,
      scenario: scenario.title,
      task: scenario.task,
      color: random.pick(colors),
      origin: random.pick(origins),
      port: random.pick(ports),
      signature: random.pick(signatures),
      payload: random.pick(payloads),
      route: random.pick(routes),
      repeated: this.gymLevel >= 1 && random.bool(this.gymLevel >= 6 ? 0.34 : 0.24),
      priority: this.gymLevel >= 7 && random.bool(0.22),
      threat: 0,
      diagnosis: "",
      correctAction: "allow" as FirewallAction,
      reason: "",
    };
    const classified = this.classifyFirewallSignal(signal);
    return { ...signal, ...classified };
  }

  private firewallScenario(random: Random): { title: string; task: string } {
    return random.pick([
      { title: "Archivio studenti", task: "Una richiesta vuole leggere un registro: proteggi i dati senza bloccare il lavoro." },
      { title: "Serra automatica", task: "Un modulo irrigazione chiede accesso: evita falsi allarmi, ma non fidarti dei segnali incompleti." },
      { title: "Porta laboratorio", task: "Una porta riceve un comando remoto: se il messaggio e' dubbio, non deve arrivare al motore." },
      { title: "Biblioteca NORA", task: "Un indice digitale sta sincronizzando: separa rumore, esche e traffico sicuro." },
      { title: "Nucleo energia", task: "Un canale ad alta priorita' chiede passaggio: controlla prima identita' e contenuto." },
      { title: "Banchi officina", task: "Una console segnala manutenzione: decidi se farla proseguire, isolarla o analizzarla." },
    ]);
  }

  private classifyFirewallSignal(signal: Pick<FirewallSignal, "color" | "signature" | "payload" | "route" | "repeated" | "priority">): Pick<FirewallSignal, "correctAction" | "reason" | "threat" | "diagnosis"> {
    const threat = this.firewallThreat(signal);
    if (this.gymLevel >= 7 && signal.priority && signal.signature === "stabile" && signal.color !== "rosso" && signal.payload !== "esca") {
      return { correctAction: "allow", threat, diagnosis: "Canale prioritario affidabile", reason: "La priorita' non basta da sola: qui funziona perche' firma e contenuto sono coerenti." };
    }
    if (signal.color === "rosso" || signal.signature === "alterata" || signal.payload === "esca") {
      return { correctAction: "block", threat, diagnosis: "Minaccia attiva", reason: "Una esca, una firma alterata o un segnale rosso non si isola soltanto: va fermato." };
    }
    if (this.gymLevel >= 2 && (signal.signature === "incerta" || signal.payload === "criptato" || signal.color === "ambra")) {
      return { correctAction: "inspect", threat, diagnosis: "Dato ambiguo", reason: "Quando il contenuto non e' leggibile o la firma e' incerta, la scelta didattica e' ispezionare." };
    }
    if (this.gymLevel >= 4 && signal.route === "esterna" && signal.repeated) {
      return { correctAction: "block", threat, diagnosis: "Pattern aggressivo", reason: "Rotta esterna ripetuta: non e' un dubbio isolato, e' un comportamento aggressivo." };
    }
    if (signal.signature === "mancante" || signal.repeated || signal.payload === "rumoroso" || signal.route === "sconosciuta" || signal.color === "viola" || threat >= 3) {
      return { correctAction: "quarantine", threat, diagnosis: "Rischio isolabile", reason: "Gli indizi sono incompleti o rumorosi: quarantena significa separare senza distruggere." };
    }
    return { correctAction: "allow", threat, diagnosis: "Traffico pulito", reason: "Identita', contenuto e percorso sono coerenti: lasciar passare e' la scelta efficiente." };
  }

  private firewallThreat(signal: Pick<FirewallSignal, "color" | "signature" | "payload" | "route" | "repeated" | "priority">): number {
    let threat = 0;
    if (signal.color === "rosso") threat += 4;
    if (signal.color === "ambra") threat += 2;
    if (signal.color === "viola") threat += 1;
    if (signal.signature === "alterata") threat += 4;
    if (signal.signature === "mancante") threat += 2;
    if (signal.signature === "incerta") threat += 2;
    if (signal.payload === "esca") threat += 4;
    if (signal.payload === "criptato") threat += 2;
    if (signal.payload === "rumoroso") threat += 1;
    if (signal.route === "sconosciuta") threat += 1;
    if (signal.route === "esterna") threat += 1;
    if (signal.repeated) threat += 2;
    if (signal.priority) threat -= 2;
    return Phaser.Math.Clamp(threat, 0, 9);
  }

  private drawFirewallInvestigation(signal: FirewallSignal): void {
    const x = 66;
    const y = 124;
    this.ft(this.add.rectangle(x, y, 318, 470, 0x0b1f2d, 0.94).setOrigin(0).setStrokeStyle(2, 0x5ec8ff, 0.42));
    this.ft(this.add.text(x + 22, y + 18, "1 · Indaga", { fontFamily: "Inter, Arial", fontSize: "20px", color: "#f5fbff", fontStyle: "bold" }));
    this.ft(this.add.text(x + 22, y + 48, `Scansioni: ${this.firewallScansLeft}/${this.firewallScanLimit()} · minime: ${this.firewallMinimumScans()}`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", fontStyle: "bold" }));
    this.ft(this.add.text(x + 22, y + 76, signal.scenario, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold", wordWrap: { width: 270 } }));
    this.ft(this.add.text(x + 22, y + 104, signal.task, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: 270 }, lineSpacing: 3 }));

    const lenses: FirewallLens[] = ["identity", "content", "route", "priority"];
    lenses.forEach((lens, index) => {
      const info = this.firewallLensInfo(signal, lens);
      const rowY = y + 188 + index * 58;
      const revealed = this.firewallRevealed.has(lens);
      this.ft(new Button(this, x + 92, rowY + 22, `${revealed ? "✓ " : ""}${info.label}`, () => this.scanFirewall(lens), {
        width: 136,
        height: 42,
        fontSize: 13,
        fill: revealed ? 0x173b36 : 0x143247,
        stroke: info.color,
        wordWrapWidth: 116,
      }));
      this.ft(this.add.text(x + 174, rowY + 8, revealed ? info.shortValue : info.lesson, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: revealed ? "#f5fbff" : "#8aa6b0",
        wordWrap: { width: 118 },
      }));
    });

    this.ft(this.add.text(x + 22, y + 426, "Obiettivo: scegli poche scansioni, poi applica il protocollo. Non ogni anomalia va bloccata.", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 270 },
    }));
  }

  private drawFirewallRound(): void {
    this.clearFirewallRound();
    if (this.firewallIndex >= this.firewallSignals.length) {
      this.finishFirewall();
      return;
    }
    this.firewallLocked = false;
    const signal = this.firewallSignals[this.firewallIndex];
    this.firewallStatus?.setText(`Segnale ${this.firewallIndex + 1}/${this.firewallSignals.length} · Scan ${this.firewallScansLeft} · Combo x${this.firewallStreak} · Stabilità ${this.firewallStability}%`);
    this.drawFirewallInvestigation(signal);
    this.drawFirewallGrid(signal);

    const actions = this.firewallAvailableActions();
    this.ft(this.add.text(1042, 382, "3 · Applica protocollo", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    actions.forEach((action, index) => {
      const x = 945 + (index % 2) * 168;
      const y = 410 + Math.floor(index / 2) * 82;
      this.ft(new Button(this, x, y, this.firewallActionLabel(action), () => this.answerFirewall(action), {
        width: 148,
        height: 58,
        fontSize: 15,
        fill: this.firewallActionFill(action),
        stroke: this.firewallActionColor(action),
        wordWrapWidth: 126,
      }));
    });
  }

  private firewallLensInfo(signal: FirewallSignal, lens: FirewallLens): { label: string; lesson: string; shortValue: string; color: number } {
    switch (lens) {
      case "identity":
        return {
          label: "Identità",
          lesson: "chi parla?",
          shortValue: `${signal.signature}, ${signal.color}`,
          color: this.firewallSignatureColor(signal.signature),
        };
      case "content":
        return {
          label: "Contenuto",
          lesson: "cosa porta?",
          shortValue: `${signal.payload}, rischio ${signal.threat}`,
          color: this.firewallPayloadColor(signal.payload),
        };
      case "route":
        return {
          label: "Percorso",
          lesson: "da dove passa?",
          shortValue: `${signal.route}${signal.repeated ? ", ripetuto" : ""}`,
          color: this.firewallRouteColor(signal.route),
        };
      case "priority":
        return {
          label: "Priorità",
          lesson: "ha permessi?",
          shortValue: signal.priority ? "prioritario" : "normale",
          color: signal.priority ? 0x9f8cff : 0x7d93a0,
        };
    }
  }

  private drawFirewallGrid(signal: FirewallSignal): void {
    const field = this.ft(this.add.graphics());
    field.lineStyle(2, 0x5ec8ff, 0.42);
    field.strokeRoundedRect(424, 136, 408, 344, 12);
    field.fillStyle(0x09202d, 0.82);
    field.fillRoundedRect(424, 136, 408, 344, 12);
    field.lineStyle(2, this.firewallSignalColor(signal.color), 0.72);
    field.strokeRoundedRect(454, 174, 348, 248, 10);
    const riskKnown = this.firewallRevealed.size >= 2 || this.firewallRevealed.has("content");
    field.fillStyle(0x071018, 0.82);
    field.fillRoundedRect(478, 438, 300, 18, 6);
    field.fillStyle(riskKnown ? (signal.threat >= 6 ? 0xff5d7a : signal.threat >= 3 ? 0xf6c85f : 0x70d68a) : 0x42515a, 0.9);
    field.fillRoundedRect(482, 442, riskKnown ? Math.max(14, (292 * signal.threat) / 9) : 24, 10, 5);
    field.lineStyle(3, 0x5ec8ff, 0.2);
    field.lineBetween(454, 300, 802, 300);
    field.lineBetween(628, 174, 628, 422);

    const nodes = [
      { x: 486, y: 226 }, { x: 486, y: 376 }, { x: 770, y: 226 }, { x: 770, y: 376 },
      { x: 628, y: 174 }, { x: 628, y: 422 },
    ];
    nodes.forEach((node, i) => {
      field.lineStyle(1, 0x9ff5e9, 0.18);
      field.lineBetween(628, 300, node.x, node.y);
      field.fillStyle(i % 2 === 0 ? 0x5ec8ff : 0xf6c85f, 0.72);
      field.fillCircle(node.x, node.y, 7);
    });

    const packetColor = this.firewallSignalColor(signal.color);
    const packet = this.ft(this.add.container(628, 300));
    const outer = this.add.circle(0, 0, 58, packetColor, 0.16).setStrokeStyle(3, packetColor, 0.9);
    const inner = this.add.rectangle(0, 0, 78, 46, 0x071018, 0.94).setStrokeStyle(2, packetColor, 0.9);
    const label = this.add.text(0, -5, signal.id, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5);
    const port = this.add.text(0, 17, `porta ${signal.port}`, { fontFamily: "Inter, Arial", fontSize: "11px", color: "#9ff5e9" }).setOrigin(0.5);
    packet.add([outer, inner, label, port]);
    this.firewallPacket = packet;
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: outer, scale: 1.18, alpha: 0.34, duration: 620, yoyo: true, repeat: -1 });
      this.tweens.add({ targets: packet, y: 292, duration: 900, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }

    const dataX = 874;
    const dataY = 128;
    this.ft(this.add.rectangle(dataX, dataY, 332, 276, 0x0b1f2d, 0.92).setOrigin(0).setStrokeStyle(2, 0x5ec8ff, 0.38));
    this.ft(this.add.text(dataX + 22, dataY + 18, "2 · Taccuino NORA", { fontFamily: "Inter, Arial", fontSize: "19px", color: "#f5fbff", fontStyle: "bold" }));
    const rows = this.firewallNotebookRows(signal);
    rows.forEach(([labelText, value, color], index) => {
      const rowY = dataY + 58 + index * 26;
      this.ft(this.add.text(dataX + 24, rowY, `${labelText}:`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0" }));
      this.ft(this.add.text(dataX + 116, rowY, String(value), { fontFamily: "Inter, Arial", fontSize: "13px", color: Phaser.Display.Color.IntegerToColor(color as number).rgba, fontStyle: "bold", wordWrap: { width: 170 } }));
    });

    this.ft(this.add.text(628, 512, riskKnown ? `Rischio stimato ${signal.threat}/9` : "Rischio non stimato: scansiona almeno due aspetti", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
    audioManager.play("scan");
  }

  private firewallNotebookRows(signal: FirewallSignal): Array<[string, string, number]> {
    const hidden: [string, string, number] = ["?", "non scansionato", 0x7d93a0];
    const rows: Array<[string, string, number]> = [];
    if (this.firewallRevealed.has("identity")) {
      rows.push(["Colore", signal.color.toUpperCase(), this.firewallSignalColor(signal.color)]);
      rows.push(["Origine", signal.origin, 0x9ff5e9]);
      rows.push(["Firma", signal.signature.toUpperCase(), this.firewallSignatureColor(signal.signature)]);
    } else {
      rows.push(["Identità", hidden[1], hidden[2]]);
    }
    if (this.firewallRevealed.has("content")) {
      rows.push(["Payload", signal.payload.toUpperCase(), this.firewallPayloadColor(signal.payload)]);
      rows.push(["Rischio", `${signal.threat}/9`, signal.threat >= 6 ? 0xff5d7a : signal.threat >= 3 ? 0xf6c85f : 0x70d68a]);
    } else {
      rows.push(["Contenuto", hidden[1], hidden[2]]);
    }
    if (this.firewallRevealed.has("route")) {
      rows.push(["Rotta", signal.route.toUpperCase(), this.firewallRouteColor(signal.route)]);
      rows.push(["Ripetuto", signal.repeated ? "SI" : "NO", signal.repeated ? 0xf6c85f : 0x70d68a]);
    } else {
      rows.push(["Percorso", hidden[1], hidden[2]]);
    }
    if (this.firewallRevealed.has("priority")) {
      rows.push(["Priorità", signal.priority ? "SI" : "NO", signal.priority ? 0x9f8cff : 0x7d93a0]);
    } else {
      rows.push(["Priorità", hidden[1], hidden[2]]);
    }
    return rows.slice(0, 8);
  }

  private scanFirewall(lens: FirewallLens): void {
    if (this.firewallLocked) return;
    const signal = this.firewallSignals[this.firewallIndex];
    if (!signal) return;
    if (this.firewallRevealed.has(lens)) {
      audioManager.play("hint");
      this.firewallStatus?.setText(`${this.firewallLensInfo(signal, lens).label} e' gia' nel taccuino.`);
      return;
    }
    if (this.firewallScansLeft <= 0) {
      audioManager.play("error");
      this.firewallStatus?.setText("Scanner scarichi: ora devi decidere con gli indizi raccolti.");
      return;
    }
    this.firewallRevealed.add(lens);
    this.firewallScansLeft -= 1;
    this.firewallStability = Phaser.Math.Clamp(this.firewallStability - (this.gymLevel >= 6 ? 3 : 1), 0, 100);
    audioManager.play("scan");
    this.drawFirewallRound();
  }

  private answerFirewall(action: FirewallAction): void {
    if (this.firewallLocked) return;
    const signal = this.firewallSignals[this.firewallIndex];
    if (!signal) return;
    if (this.firewallRevealed.size < this.firewallMinimumScans()) {
      audioManager.play("hint");
      this.firewallStatus?.setText(`Prima raccogli almeno ${this.firewallMinimumScans()} indizi: una decisione senza osservazione vale poco.`);
      return;
    }
    this.firewallLocked = true;
    const correct = action === signal.correctAction;
    const scanBonus = Math.max(0, this.firewallScansLeft);
    if (correct) {
      this.firewallCorrect += 1;
      this.firewallStreak += 1;
      this.firewallBestStreak = Math.max(this.firewallBestStreak, this.firewallStreak);
      this.firewallStability = Phaser.Math.Clamp(this.firewallStability + 4 + scanBonus * 2 + Math.min(5, this.firewallStreak), 0, 100);
      audioManager.play(this.firewallStreak > 0 && this.firewallStreak % 3 === 0 ? "circuitOn" : "success");
    } else {
      this.firewallErrors += 1;
      this.firewallStreak = 0;
      this.firewallStability = Phaser.Math.Clamp(this.firewallStability - 18, 0, 100);
      audioManager.play("error");
      this.cameras.main.shake(120, 0.003);
    }
    this.firewallPacket?.each((child: Phaser.GameObjects.GameObject) => {
      if (child instanceof Phaser.GameObjects.Shape) {
        child.setAlpha(correct ? 0.95 : 0.82);
      }
    });
    this.revealFirewallAnswer(signal);
    this.ft(this.add.rectangle(640, 590, 1060, 108, 0x071018, 0.98).setStrokeStyle(2, correct ? 0x70d68a : 0xff5d7a, 0.75));
    const text = correct
      ? `Corretto · combo x${this.firewallStreak} · diagnosi: ${signal.diagnosis}`
      : `Da correggere: serviva ${this.firewallActionLabel(signal.correctAction)} · diagnosi: ${signal.diagnosis}`;
    this.ft(this.add.text(640, 568, text, { fontFamily: "Inter, Arial", fontSize: "15px", color: correct ? "#9ff5c0" : "#ffd0da", align: "center", wordWrap: { width: 1000 } }).setOrigin(0.5));
    this.ft(this.add.text(640, 612, signal.reason, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#dbefff", align: "center", wordWrap: { width: 1000 } }).setOrigin(0.5));
    this.ft(this.add.text(640, 638, this.firewallReflection(signal), { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", align: "center", wordWrap: { width: 980 } }).setOrigin(0.5));
    const burst = this.ft(this.add.graphics());
    burst.lineStyle(4, correct ? 0x70d68a : 0xff5d7a, 0.82);
    burst.strokeCircle(correct ? 760 : 496, 300, 42);
    burst.lineStyle(2, correct ? 0x9ff5e9 : 0xffd0da, 0.58);
    burst.lineBetween(628, 300, correct ? 806 : 450, 300);
    this.ft(this.add.text(correct ? 838 : 416, 300, correct ? `+stabilità ${this.firewallStability}%` : `stabilità ${this.firewallStability}%`, { fontFamily: "Inter, Arial", fontSize: "13px", color: correct ? "#9ff5c0" : "#ffd0da", fontStyle: "bold" }).setOrigin(0.5));
    this.tracked.forEach((object) => {
      if (object instanceof Button) object.disableInteractive();
    });
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: this.firewallPacket, x: correct ? 760 : 496, duration: 260, yoyo: true, ease: "Cubic.easeOut" });
      this.tweens.add({ targets: burst, scale: 1.18, alpha: 0.22, duration: 520, ease: "Cubic.easeOut" });
    }
    this.time.delayedCall(2400, () => {
      this.firewallIndex += 1;
      this.firewallRevealed = new Set();
      this.firewallScansLeft = this.firewallScanLimit();
      this.drawFirewallRound();
    });
  }

  private revealFirewallAnswer(signal: FirewallSignal): void {
    this.firewallRevealed = new Set<FirewallLens>(["identity", "content", "route", "priority"]);
    this.firewallStatus?.setText(`Protocollo: ${this.firewallActionLabel(signal.correctAction)} · ${signal.diagnosis}`);
  }

  private firewallReflection(signal: FirewallSignal): string {
    switch (signal.correctAction) {
      case "allow":
        return "Idea chiave: sicurezza non significa bloccare tutto; significa riconoscere quando un segnale e' coerente.";
      case "block":
        return "Idea chiave: una minaccia attiva va fermata, non solo messa da parte.";
      case "quarantine":
        return "Idea chiave: quando il dato e' incompleto o rumoroso, isolare protegge senza perdere informazione utile.";
      case "inspect":
        return signal.payload === "criptato"
          ? "Idea chiave: se il contenuto non e' leggibile, prima si analizza e solo dopo si decide."
          : "Idea chiave: un dubbio tecnico non e' ancora una minaccia certa; richiede controllo.";
    }
  }

  private finishFirewall(): void {
    audioManager.play(this.firewallErrors === 0 ? "circuitOn" : "success");
    const total = Math.max(1, this.firewallSignals.length);
    const accuracy = Math.round((this.firewallCorrect / total) * 100);
    const score = Math.max(0, accuracy + this.gymLevel * 4 + this.firewallStability + this.firewallBestStreak * 3 - this.firewallErrors * 4);
    const award = Math.min(24, 6 + this.firewallCorrect * 2 + Math.floor(this.gymLevel / 2));
    const summary = `Rete stabilizzata: ${this.firewallCorrect}/${total} segnali corretti, precisione ${accuracy}%, stabilità ${this.firewallStability}%, combo migliore x${this.firewallBestStreak}.`;
    this.finishActivity("firewall", "Firewall NORA", score, ["trasversali.logica", "pensieroCritico"], award, summary);
  }

  private firewallActionLabel(action: FirewallAction): string {
    switch (action) {
      case "allow": return "Consenti";
      case "block": return "Blocca";
      case "quarantine": return "Quarantena";
      case "inspect": return "Ispeziona";
    }
  }

  private firewallActionColor(action: FirewallAction): number {
    switch (action) {
      case "allow": return 0x70d68a;
      case "block": return 0xff5d7a;
      case "quarantine": return 0xf6c85f;
      case "inspect": return 0x5ec8ff;
    }
  }

  private firewallActionFill(action: FirewallAction): number {
    switch (action) {
      case "allow": return 0x173b36;
      case "block": return 0x40202d;
      case "quarantine": return 0x3d3218;
      case "inspect": return 0x143247;
    }
  }

  private firewallSignalColor(color: FirewallSignal["color"]): number {
    switch (color) {
      case "blu": return 0x5ec8ff;
      case "verde": return 0x70d68a;
      case "rosso": return 0xff5d7a;
      case "ambra": return 0xf6c85f;
      case "viola": return 0x9f8cff;
    }
  }

  private firewallSignatureColor(signature: FirewallSignal["signature"]): number {
    switch (signature) {
      case "stabile": return 0x70d68a;
      case "mancante": return 0xf6c85f;
      case "alterata": return 0xff5d7a;
      case "incerta": return 0x5ec8ff;
    }
  }

  private firewallPayloadColor(payload: FirewallPayload): number {
    switch (payload) {
      case "pulito": return 0x70d68a;
      case "rumoroso": return 0xf6c85f;
      case "criptato": return 0x5ec8ff;
      case "esca": return 0xff5d7a;
    }
  }

  private firewallRouteColor(route: FirewallRoute): number {
    switch (route) {
      case "interna": return 0x70d68a;
      case "esterna": return 0xf6c85f;
      case "sconosciuta": return 0x9f8cff;
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
      this.t(this.add.text(640, 250, `${label} · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "26px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
      this.t(this.add.text(640, 312, `Punteggio: ${score}${record ? "   ★ NUOVO RECORD DI PROFONDITÀ!" : `   (record profondità ${this.gymLevel}: ${Math.max(previous, score)})`}`, { fontFamily: "Inter, Arial", fontSize: "20px", color: record ? "#f6c85f" : "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
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
