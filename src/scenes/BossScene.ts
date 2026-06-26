import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { competencyTracker } from "../core/CompetencyTracker";
import { masterySystem } from "../core/MasterySystem";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { settingsSystem } from "../core/SettingsSystem";
import { CircuitFaultGenerator } from "../procedural/generators/CircuitFaultGenerator";
import { CodingPuzzleGenerator } from "../procedural/generators/CodingPuzzleGenerator";
import { EnglishInstructionGenerator } from "../procedural/generators/EnglishInstructionGenerator";
import { LanguageCorruptionGenerator } from "../procedural/generators/LanguageCorruptionGenerator";
import { MathPuzzleGenerator } from "../procedural/generators/MathPuzzleGenerator";
import { generateBalance, LogicSequenceGenerator } from "../procedural/generators/LogicGymContent";
import { difficultyModel } from "../procedural/DifficultyModel";
import { Random } from "../procedural/Random";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";

type BossTile = { label: string; correct: boolean; feedback: string };
type BossRound = {
  domain: string;
  color: number;
  question: string;
  context: string;
  tiles: BossTile[];
  explanation: string;
  competencies: string[];
};

type SelectChallenge = BossRound & { mode: "select" };
type SimonChallenge = { mode: "simon"; domain: string; color: number; competencies: string[]; question: string; length: number };
type FlashChallenge = { mode: "flash"; domain: string; color: number; competencies: string[]; question: string; count: number };
type BossChallenge = SelectChallenge | SimonChallenge | FlashChallenge;

const ECO_COLOR = 0xff5d7a;
const MEMORY_COLOR = 0xff9ad2;
const LOGIC_COLOR = 0xf6c85f;
const PAD_COLORS = [0xff5d7a, 0x6be7d6, 0xf6c85f, 0x70d68a, 0x9f8cff, 0xff9ad2];

/**
 * Pillar 4 — "Sfida dell'Eco": a multi-domain boss encounter. The Eco (a rebel
 * shard of NORA) challenges the player with a string of quick rounds drawn from
 * DIFFERENT subjects (maths, language, English, coding, circuits) AND from the
 * mind itself: logic (sequences, balance deduction) and memory (a Simon-style
 * sequence, a flash grid). Each success chips the Eco's integrity; three
 * mistakes end the run. Winning weakens the Eco, advances its story arc and
 * reinforces every competency faced — academic and transversal alike.
 */
export class BossScene extends Phaser.Scene {
  private level = 2;
  private integrity = 6;
  private integrityMax = 6;
  private lives = 3;
  private readonly livesMax = 3;
  private roundIndex = 0;
  private attemptSeed = "";
  private facedCompetencies = new Set<string>();
  private roundObjects: Phaser.GameObjects.GameObject[] = [];
  private overlayObjects: Phaser.GameObjects.GameObject[] = [];
  private integrityBar?: Phaser.GameObjects.Rectangle;
  private livesText?: Phaser.GameObjects.Text;
  private ecoCore?: Phaser.GameObjects.Arc;
  private busy = false;

  // Interactive mind-round state.
  private mindLock = true;
  private simonSeq: number[] = [];
  private simonInput: number[] = [];
  private simonPads: Phaser.GameObjects.Rectangle[] = [];
  private flashCells: Phaser.GameObjects.Rectangle[] = [];
  private flashTarget = new Set<number>();
  private flashPicked = new Set<number>();

  constructor() {
    super("BossScene");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    this.cameras.main.setBackgroundColor("#0a0710");
    VisualKit.background(this, "archive");
    VisualKit.vignette(this);

    const defeats = saveSystem.data.eco?.defeats ?? 0;
    const stars = masterySystem.getAcademyRank().stars;
    this.level = Math.max(1, Math.min(8, 2 + Math.floor(stars / 4) + defeats));
    this.integrityMax = 6 + Math.min(4, defeats);
    this.integrity = this.integrityMax;
    this.lives = this.livesMax;
    this.roundIndex = 0;
    this.attemptSeed = `eco-${defeats}-${Date.now()}`;
    this.facedCompetencies.clear();
    this.busy = false;

    this.add.text(56, 26, "⚠  Sfida dell'Eco", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#ff9fb2",
      fontStyle: "bold",
    });
    this.add.text(58, 66, `Frammento ribelle di NORA · Livello ${this.level}`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d6b4c2",
    });

    // Eco glitch core (top-right), contrasting NORA's clean cyan core.
    this.ecoCore = this.add.circle(1170, 64, 30, 0x2a0e1a, 1).setStrokeStyle(3, ECO_COLOR, 0.85);
    this.add.circle(1170, 64, 11, 0xffd0da, 0.9);
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: this.ecoCore, scaleX: 1.18, scaleY: 0.86, duration: 420, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }

    // Integrity bar.
    this.add.text(58, 98, "Integrità dell'Eco", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#d6b4c2" });
    this.add.rectangle(56, 120, 980, 16, 0x1a0a12, 1).setOrigin(0).setStrokeStyle(1, ECO_COLOR, 0.5);
    this.integrityBar = this.add.rectangle(56, 120, 980, 16, ECO_COLOR, 0.85).setOrigin(0);

    this.livesText = this.add.text(56, 146, "", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#ff9fb2" });
    this.refreshStatus();

    this.showIntro(defeats);
  }

  // -- Narrative ----------------------------------------------------------

  private taunt(defeats: number): string {
    const taunts = [
      "«Sono ciò che NORA ha dimenticato. Pensi davvero di rimettere ordine? Ogni materia che hai studiato — proviamole tutte, qui, ora.»",
      "«Di nuovo tu. L'ultima volta è stata fortuna. Stavolta mescolo numeri, parole e circuiti più in fretta.»",
      "«Mi stai indebolendo, lo ammetto. Ma più mi colpisci, più divento difficile da prevedere.»",
      "«I ricordi di NORA stanno tornando per colpa tua. Difenderò gli ultimi frammenti con tutto ciò che ho.»",
      "«Quasi non resta nulla di me. Ancora una sfida... e forse capirò che non ero un nemico, ma una parte di lei.»",
    ];
    return taunts[Math.min(taunts.length - 1, defeats)];
  }

  private showIntro(defeats: number): void {
    this.busy = true;
    const card = this.add.rectangle(640, 410, 1040, 360, 0x140811, 0.96).setStrokeStyle(2, ECO_COLOR, 0.6);
    const title = this.add.text(640, 270, "L'ECO TI SFIDA", {
      fontFamily: "Inter, Arial",
      fontSize: "26px",
      color: "#ff9fb2",
      fontStyle: "bold",
    }).setOrigin(0.5);
    const body = this.add.text(640, 380, this.taunt(defeats), {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f3dde4",
      align: "center",
      wordWrap: { width: 920 },
      lineSpacing: 6,
    }).setOrigin(0.5);
    const rule = this.add.text(640, 488, `Colpisci l'Eco con ${this.integrityMax} prove superate: materie diverse, ma anche logica e memoria. Hai ${this.livesMax} vite: tre errori e si rigenera.`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#c7a9b6",
      align: "center",
      wordWrap: { width: 900 },
    }).setOrigin(0.5);
    this.overlayObjects = [card, title, body, rule];
    const go = new Button(this, 640, 548, "Affronta l'Eco", () => {
      this.clearOverlay();
      this.busy = false;
      this.showRound();
    }, { width: 280, height: 52, fill: 0x7a1f3a, stroke: ECO_COLOR });
    this.overlayObjects.push(go as unknown as Phaser.GameObjects.GameObject);
  }

  // -- Round generation ---------------------------------------------------

  private buildRound(random: Random): BossRound {
    const preset = difficultyModel.getPreset(this.level);
    const logicComps = ["trasversali.logica", "pensieroCritico"];
    const domains: Array<() => BossRound> = [
      () => {
        const mini = new MathPuzzleGenerator().generateMinigame(random, preset, ["number-sequence"]).minigame!;
        const p = this.pickPrompt(mini.prompts);
        return { domain: "Matematica", color: 0xf6c85f, question: p.prompt, context: p.targetLabel, tiles: this.toTiles(p.tiles), explanation: p.explanation, competencies: mini.competencies };
      },
      () => {
        const mini = new LanguageCorruptionGenerator().generateMinigame(random, this.level, ["agreement-sprint", "connector-route", "intruder-hunt"]).minigame!;
        const p = this.pickPrompt(mini.prompts);
        return { domain: "Italiano", color: 0x9f8cff, question: p.prompt, context: p.context, tiles: this.toTiles(p.tiles), explanation: p.explanation, competencies: mini.competencies };
      },
      () => {
        const mini = new EnglishInstructionGenerator().generateMinigame(random, this.level, ["action-relay", "sequence-switchboard", "data-command-scan", "grammar-fix"]).minigame!;
        const p = this.pickPrompt(mini.prompts);
        return { domain: "Inglese", color: 0x5ec8ff, question: p.instruction, context: p.context, tiles: this.toTiles(p.tiles), explanation: p.explanation, competencies: mini.competencies };
      },
      () => {
        const mini = new CodingPuzzleGenerator().generateMinigame(random, preset, ["bug-hunt", "state-tracer", "binary-bits", "logic-gate", "loop-output", "conditional-path"]).minigame!;
        const p = this.pickPrompt(mini.prompts);
        return { domain: "Coding", color: 0x70d68a, question: p.question, context: p.codeLines.join("   |   "), tiles: this.toTiles(p.tiles), explanation: p.explanation, competencies: mini.competencies };
      },
      () => {
        const mini = new CircuitFaultGenerator().generateMinigame(random, preset).minigame!;
        const p = this.pickPrompt(mini.prompts);
        return { domain: "Circuiti", color: 0x6be7d6, question: p.question, context: p.diagramLines.join("   ·   "), tiles: this.toTiles(p.tiles), explanation: p.explanation, competencies: mini.competencies };
      },
      () => {
        const seq = new LogicSequenceGenerator().generate(random.fork("logic-seq"), this.level);
        return {
          domain: "Logica",
          color: LOGIC_COLOR,
          question: seq.question,
          context: `${seq.sequence.join("   ,   ")}   ,   ?`,
          tiles: seq.options.map((label, i) => ({ label, correct: i === seq.correctIndex, feedback: i === seq.correctIndex ? "Esatto!" : "Ragiona sulla regola della serie." })),
          explanation: seq.explanation,
          competencies: logicComps,
        };
      },
      () => {
        const bal = generateBalance(random.fork("logic-bal"), this.level);
        return {
          domain: "Logica",
          color: LOGIC_COLOR,
          question: bal.question,
          context: bal.clues.join("      "),
          tiles: bal.options.map((label, i) => ({ label, correct: i === bal.correctIndex, feedback: i === bal.correctIndex ? "Esatto!" : "Rimetti in fila gli indizi." })),
          explanation: bal.explanation,
          competencies: logicComps,
        };
      },
    ];
    return random.pick(domains)();
  }

  private buildChallenge(): BossChallenge {
    const random = new Random(`${this.attemptSeed}-r${this.roundIndex}`);
    // ~30% of rounds test the mind directly (sequential / spatial memory).
    if (random.integer(1, 100) <= 30) {
      const span = 3 + Math.min(4, Math.floor(this.level / 2));
      if (random.integer(0, 1) === 0) {
        return { mode: "simon", domain: "Memoria", color: MEMORY_COLOR, competencies: ["trasversali.memoria"], length: span, question: "L'Eco proietta una sequenza rubata ai ricordi di NORA. Guardala e ripetila." };
      }
      return { mode: "flash", domain: "Memoria", color: MEMORY_COLOR, competencies: ["trasversali.memoria"], count: span, question: "Frammenti di memoria lampeggiano nella griglia. Ricorda le loro posizioni." };
    }
    return { mode: "select", ...this.buildRound(random) };
  }

  private pickPrompt<T extends { tiles: Array<{ isCorrect: boolean }> }>(prompts: T[]): T {
    return prompts.find((p) => p.tiles.filter((t) => t.isCorrect).length === 1) ?? prompts[0];
  }

  private toTiles(tiles: Array<{ label: string; isCorrect: boolean; feedback: string }>): BossTile[] {
    return tiles.map((t) => ({ label: t.label, correct: t.isCorrect, feedback: t.feedback }));
  }

  // -- Round rendering ----------------------------------------------------

  private showRound(): void {
    this.clearRound();
    this.busy = false;
    this.mindLock = true;
    const challenge = this.buildChallenge();
    challenge.competencies.forEach((id) => this.facedCompetencies.add(id));
    this.renderHeader(challenge.domain, challenge.color);
    this.renderQuestion(challenge.question, challenge.color, challenge.mode === "select" ? challenge.context : "");
    if (challenge.mode === "select") {
      this.renderSelect(challenge);
    } else if (challenge.mode === "simon") {
      this.renderSimon(challenge);
    } else {
      this.renderFlash(challenge);
    }
  }

  private renderHeader(domain: string, color: number): void {
    const badge = this.add.rectangle(56, 184, 150, 30, color, 0.22).setOrigin(0).setStrokeStyle(1, color, 0.8);
    const badgeText = this.add.text(131, 199, domain.toUpperCase(), { fontFamily: "Inter, Arial", fontSize: "13px", color: "#ffffff", fontStyle: "bold" }).setOrigin(0.5);
    const colpo = this.add.text(1036, 199, `Colpo ${this.integrityMax - this.integrity + 1} · ${this.integrityMax} totali`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7a9b6" }).setOrigin(1, 0.5);
    this.roundObjects.push(badge, badgeText, colpo);
  }

  private renderQuestion(text: string, color: number, context: string): void {
    const question = this.add.text(56, 230, text, { fontFamily: "Inter, Arial", fontSize: "20px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: 1160 }, lineSpacing: 4 });
    this.roundObjects.push(question);
    if (context && context.trim().length > 0) {
      const ctxBox = this.add.rectangle(56, question.y + question.height + 12, 1160, 56, 0x140d16, 0.85).setOrigin(0).setStrokeStyle(1, color, 0.35);
      const ctx = this.add.text(72, ctxBox.y + 14, context, { fontFamily: "Consolas, monospace", fontSize: "14px", color: "#c9d6df", wordWrap: { width: 1130 } }).setOrigin(0);
      this.roundObjects.push(ctxBox, ctx);
    }
  }

  private renderSelect(round: SelectChallenge): void {
    const startY = 420;
    round.tiles.forEach((tile, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const bx = 320 + col * 600;
      const by = startY + row * 72;
      const button = new Button(this, bx, by, tile.label, () => this.resolveOutcome(tile.correct, tile.feedback || round.explanation), {
        width: 560, height: 60, fill: 0x21162a, stroke: round.color, fontSize: 16,
      });
      this.roundObjects.push(button as unknown as Phaser.GameObjects.GameObject);
    });
  }

  // Sequential working memory: watch the pad sequence, then repeat it.
  private renderSimon(challenge: SimonChallenge): void {
    this.simonInput = [];
    this.simonPads = [];
    const random = new Random(`${this.attemptSeed}-simon-${this.roundIndex}`);
    this.simonSeq = Array.from({ length: challenge.length }, () => random.integer(0, PAD_COLORS.length - 1));
    const cols = 3, padW = 150, padH = 96, gap = 22;
    const totalW = cols * padW + (cols - 1) * gap;
    const startX = 640 - totalW / 2 + padW / 2;
    PAD_COLORS.forEach((color, index) => {
      const col = index % cols, row = Math.floor(index / cols);
      const pad = this.add.rectangle(startX + col * (padW + gap), 400 + row * (padH + gap), padW, padH, color, 0.3).setStrokeStyle(3, color, 0.8);
      pad.setInteractive({ useHandCursor: true }).on("pointerdown", () => this.simonClick(index));
      this.roundObjects.push(pad);
      this.simonPads.push(pad);
    });
    const status = this.add.text(640, 624, "Guarda la sequenza…", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#ffd0ea" }).setOrigin(0.5);
    this.roundObjects.push(status);
    const step = settingsSystem.effectsReduced() ? 560 : 680;
    this.simonSeq.forEach((padIndex, i) => this.time.delayedCall(500 + i * step, () => this.flashPad(padIndex)));
    this.time.delayedCall(500 + this.simonSeq.length * step, () => { this.mindLock = false; status.setText("Ripeti la sequenza!"); });
  }

  private flashPad(index: number): void {
    const pad = this.simonPads[index];
    if (!pad) return;
    audioManager.play("levelSelect");
    pad.setFillStyle(PAD_COLORS[index], 1);
    this.tweens.add({ targets: pad, scale: 1.08, duration: 170, yoyo: true, onComplete: () => pad.setFillStyle(PAD_COLORS[index], 0.3) });
  }

  private simonClick(index: number): void {
    if (this.mindLock || this.busy) return;
    this.flashPad(index);
    this.simonInput.push(index);
    const pos = this.simonInput.length - 1;
    if (this.simonInput[pos] !== this.simonSeq[pos]) {
      this.mindLock = true;
      this.resolveOutcome(false, "Sequenza sbagliata: l'Eco trattiene il ricordo.");
      return;
    }
    if (this.simonInput.length === this.simonSeq.length) {
      this.mindLock = true;
      this.resolveOutcome(true, "Sequenza ricordata: un frammento torna a NORA!");
    }
  }

  // Spatial memory: memorise the lit cells, then reproduce them.
  private renderFlash(challenge: FlashChallenge): void {
    this.flashPicked = new Set();
    this.flashTarget = new Set();
    this.flashCells = [];
    const size = 4, cell = 80, gap = 10, startY = 326;
    const totalW = size * cell + (size - 1) * gap;
    const startX = 640 - totalW / 2 + cell / 2;
    for (let i = 0; i < size * size; i += 1) {
      const col = i % size, row = Math.floor(i / size);
      const rect = this.add.rectangle(startX + col * (cell + gap), startY + row * (cell + gap), cell, cell, 0x1a1020, 1).setStrokeStyle(2, MEMORY_COLOR, 0.5);
      rect.setInteractive({ useHandCursor: true }).on("pointerdown", () => this.flashClick(i));
      this.roundObjects.push(rect);
      this.flashCells.push(rect);
    }
    const random = new Random(`${this.attemptSeed}-flash-${this.roundIndex}`);
    while (this.flashTarget.size < Math.min(challenge.count, this.flashCells.length - 1)) {
      this.flashTarget.add(random.integer(0, this.flashCells.length - 1));
    }
    const status = this.add.text(640, 656, "Memorizza le caselle accese…", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#ffd0ea" }).setOrigin(0.5);
    this.roundObjects.push(status);
    this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(MEMORY_COLOR, 1));
    audioManager.play("scan");
    const showMs = settingsSystem.effectsReduced() ? 1700 : 1200 + this.flashTarget.size * 140;
    this.time.delayedCall(showMs, () => {
      this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0x1a1020, 1));
      this.mindLock = false;
      status.setText("Tocca le caselle che erano accese!");
    });
  }

  private flashClick(index: number): void {
    if (this.mindLock || this.busy || this.flashPicked.has(index)) return;
    if (!this.flashTarget.has(index)) {
      this.flashCells[index].setFillStyle(ECO_COLOR, 1);
      this.mindLock = true;
      this.resolveOutcome(false, "Posizione sbagliata: il ricordo sfuma.");
      return;
    }
    audioManager.play("uiSelect");
    this.flashPicked.add(index);
    this.flashCells[index].setFillStyle(0x70d68a, 1);
    if (this.flashPicked.size === this.flashTarget.size) {
      this.mindLock = true;
      this.resolveOutcome(true, "Tutte le posizioni esatte: memoria recuperata!");
    }
  }

  private resolveOutcome(success: boolean, feedbackText: string): void {
    if (this.busy) return;
    this.busy = true;
    const feedback = this.add.text(640, 692, feedbackText, { fontFamily: "Inter, Arial", fontSize: "14px", color: success ? "#9ff5c0" : "#ff9fb2", align: "center", wordWrap: { width: 1120 } }).setOrigin(0.5);
    this.roundObjects.push(feedback);
    if (success) {
      audioManager.play("success");
      this.integrity = Math.max(0, this.integrity - 1);
      this.cameras.main.flash(160, 255, 140, 170);
    } else {
      audioManager.play("error");
      this.lives = Math.max(0, this.lives - 1);
      this.cameras.main.shake(180, 0.006);
    }
    this.refreshStatus();
    this.time.delayedCall(success ? 900 : 1500, () => {
      if (this.integrity <= 0) this.victory();
      else if (this.lives <= 0) this.defeat();
      else { this.roundIndex += 1; this.showRound(); }
    });
  }

  // -- Outcomes -----------------------------------------------------------

  private victory(): void {
    const previous = saveSystem.data.eco?.defeats ?? 0;
    const defeats = previous + 1;
    saveSystem.data.eco = { defeats };
    competencyTracker.award(Array.from(this.facedCompetencies), 9);
    saveSystem.persistData();
    audioManager.play("success");
    this.clearRound();

    const finale = defeats >= 5;
    const lines = finale
      ? "L'Eco si dissolve in una luce calda e rientra in NORA. «Non ero un nemico... ero la parte di lei rimasta al buio. Grazie per avermi ritrovata.» L'arco dell'Eco è completo."
      : `Colpita! L'Eco arretra e un altro frammento di memoria torna a NORA. La prossima volta sarà più imprevedibile (sconfitte: ${defeats}/5).`;
    this.outcomeCard("L'ECO È STATA RESPINTA", lines, 0x123026, 0x9ff5c0, [
      { label: "Ancora", color: 0x7a1f3a, action: () => this.scene.restart() },
      { label: "La tua Accademia", color: 0x1f5a51, action: () => { void startScene(this, "AcademyScene"); } },
      { label: "Menu", color: 0x263743, action: () => this.scene.start("MainMenuScene") },
    ]);
  }

  private defeat(): void {
    audioManager.play("error");
    this.clearRound();
    this.outcomeCard(
      "L'ECO SI RIGENERA",
      "«Non ancora.» L'Eco si ricompone nell'ombra. Allenati nell'Albero delle Competenze e riprova: ogni materia che padroneggi è un colpo in più.",
      0x2a0e1a,
      0xff9fb2,
      [
        { label: "Riprova", color: 0x7a1f3a, action: () => this.scene.restart() },
        { label: "Albero Competenze", color: 0x173b36, action: () => { void startScene(this, "MasteryScene"); } },
        { label: "Menu", color: 0x263743, action: () => this.scene.start("MainMenuScene") },
      ],
    );
  }

  private outcomeCard(
    title: string,
    body: string,
    fill: number,
    accent: number,
    buttons: Array<{ label: string; color: number; action: () => void }>,
  ): void {
    this.clearOverlay();
    const card = this.add.rectangle(640, 400, 1040, 380, fill, 0.97).setStrokeStyle(2, accent, 0.7);
    const heading = this.add.text(640, 270, title, {
      fontFamily: "Inter, Arial",
      fontSize: "26px",
      color: Phaser.Display.Color.IntegerToColor(accent).rgba,
      fontStyle: "bold",
    }).setOrigin(0.5);
    const text = this.add.text(640, 390, body, {
      fontFamily: "Inter, Arial",
      fontSize: "17px",
      color: "#f3f7fb",
      align: "center",
      wordWrap: { width: 920 },
      lineSpacing: 6,
    }).setOrigin(0.5);
    this.overlayObjects = [card, heading, text];
    const total = buttons.length;
    const spacing = 300;
    const startX = 640 - ((total - 1) * spacing) / 2;
    buttons.forEach((spec, index) => {
      const button = new Button(this, startX + index * spacing, 520, spec.label, spec.action, {
        width: 270,
        height: 50,
        fill: spec.color,
        stroke: accent,
        fontSize: 15,
      });
      this.overlayObjects.push(button as unknown as Phaser.GameObjects.GameObject);
    });
  }

  // -- Helpers ------------------------------------------------------------

  private refreshStatus(): void {
    if (this.integrityBar) {
      this.integrityBar.width = 980 * (this.integrity / this.integrityMax);
    }
    if (this.livesText) {
      this.livesText.setText(`Vite: ${"❤".repeat(this.lives)}${"·".repeat(this.livesMax - this.lives)}`);
    }
    if (this.ecoCore) {
      this.ecoCore.setScale(0.7 + 0.5 * (this.integrity / this.integrityMax));
    }
  }

  private clearRound(): void {
    this.roundObjects.forEach((object) => object.destroy());
    this.roundObjects = [];
    this.simonPads = [];
    this.flashCells = [];
  }

  private clearOverlay(): void {
    this.overlayObjects.forEach((object) => object.destroy());
    this.overlayObjects = [];
  }
}
