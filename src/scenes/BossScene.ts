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

const ECO_COLOR = 0xff5d7a;

/**
 * Pillar 4 — "Sfida dell'Eco": a multi-domain boss encounter. The Eco (a rebel
 * shard of NORA) challenges the player with a string of quick questions drawn
 * from DIFFERENT subjects (maths, language, English, coding, circuits). Each
 * correct answer chips the Eco's integrity; three mistakes end the run. Winning
 * weakens the Eco, advances its story arc and reinforces the competencies faced.
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
    const rule = this.add.text(640, 488, `Colpisci l'Eco con ${this.integrityMax} risposte corrette di materie diverse. Hai ${this.livesMax} vite: tre errori e si rigenera.`, {
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

  private buildRound(): BossRound {
    const random = new Random(`${this.attemptSeed}-r${this.roundIndex}`);
    const preset = difficultyModel.getPreset(this.level);
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
    ];
    return random.pick(domains)();
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
    const round = this.buildRound();
    round.competencies.forEach((id) => this.facedCompetencies.add(id));

    const badge = this.add.rectangle(56, 184, 150, 30, round.color, 0.22).setOrigin(0).setStrokeStyle(1, round.color, 0.8);
    const badgeText = this.add.text(131, 199, round.domain.toUpperCase(), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#ffffff",
      fontStyle: "bold",
    }).setOrigin(0.5);
    const colpo = this.add.text(1036, 199, `Colpo ${this.integrityMax - this.integrity + 1} · ${this.integrityMax} totali`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7a9b6",
    }).setOrigin(1, 0.5);

    const question = this.add.text(56, 230, round.question, {
      fontFamily: "Inter, Arial",
      fontSize: "20px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 1160 },
      lineSpacing: 4,
    });
    this.roundObjects.push(badge, badgeText, colpo, question);

    if (round.context && round.context.trim().length > 0) {
      const ctxBox = this.add.rectangle(56, question.y + question.height + 12, 1160, 56, 0x140d16, 0.85).setOrigin(0).setStrokeStyle(1, round.color, 0.35);
      const ctx = this.add.text(72, ctxBox.y + 14, round.context, {
        fontFamily: "Consolas, monospace",
        fontSize: "14px",
        color: "#c9d6df",
        wordWrap: { width: 1130 },
      }).setOrigin(0);
      this.roundObjects.push(ctxBox, ctx);
    }

    // Option tiles in a 2-column grid.
    const tiles = round.tiles;
    const startY = 420;
    tiles.forEach((tile, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const bx = 320 + col * 600;
      const by = startY + row * 72;
      const button = new Button(this, bx, by, tile.label, () => this.answer(round, tile, button), {
        width: 560,
        height: 60,
        fill: 0x21162a,
        stroke: round.color,
        fontSize: 16,
      });
      this.roundObjects.push(button as unknown as Phaser.GameObjects.GameObject);
    });
  }

  private answer(round: BossRound, tile: BossTile, _button: Button): void {
    if (this.busy) {
      return;
    }
    this.busy = true;

    const feedback = this.add.text(640, 660, tile.feedback || round.explanation, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: tile.correct ? "#9ff5c0" : "#ff9fb2",
      align: "center",
      wordWrap: { width: 1120 },
    }).setOrigin(0.5);
    this.roundObjects.push(feedback);

    if (tile.correct) {
      audioManager.play("success");
      this.integrity = Math.max(0, this.integrity - 1);
      this.cameras.main.flash(160, 255, 140, 170);
    } else {
      audioManager.play("error");
      this.lives = Math.max(0, this.lives - 1);
      this.cameras.main.shake(180, 0.006);
    }
    this.refreshStatus();

    this.time.delayedCall(tile.correct ? 850 : 1500, () => {
      if (this.integrity <= 0) {
        this.victory();
      } else if (this.lives <= 0) {
        this.defeat();
      } else {
        this.roundIndex += 1;
        this.busy = false;
        this.showRound();
      }
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
  }

  private clearOverlay(): void {
    this.overlayObjects.forEach((object) => object.destroy());
    this.overlayObjects = [];
  }
}
