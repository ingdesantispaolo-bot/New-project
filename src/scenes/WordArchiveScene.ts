import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { dialogueSystem } from "../core/DialogueSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import { exerciseVariantSystem } from "../core/ExerciseVariantSystem";
import type { FeedbackMessage } from "../core/FeedbackSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { mapLayoutSystem, type MapLayoutRect } from "../core/MapLayoutSystem";
import { missionEngine } from "../core/MissionEngine";
import { saveSystem } from "../core/SaveSystem";
import { tiledSceneRenderer } from "../core/TiledSceneRenderer";
import {
  type ArchiveEvidence,
  type ArchiveMessage,
  type BilingualInstruction,
} from "../data/wordArchive";
import { ArchiveInvestigationSimulator, type ArchiveRepairCase } from "../procedural/simulators/ArchiveInvestigationSimulator";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type ArchiveMode = "repair" | "evidence" | "instruction" | "report";

export class WordArchiveScene extends Phaser.Scene {
  private readonly layout = mapLayoutSystem.getArchiveLayout();
  private readonly simulator = new ArchiveInvestigationSimulator();
  private archiveVariant = exerciseVariantSystem.getArchiveVariant();
  private archiveMessages: ArchiveMessage[] = this.archiveVariant.messages;
  private archiveEvidence: ArchiveEvidence[] = this.archiveVariant.evidence;
  private archiveInstruction: BilingualInstruction = this.archiveVariant.instruction;
  private reportKeywords: string[] = this.archiveVariant.reportKeywords;
  private reportPrompt = this.archiveVariant.reportPrompt;
  private mode: ArchiveMode = "repair";
  private selectedMessageId = this.archiveMessages[0].id;
  private repairedMessageIds = new Set<string>();
  private analyzedMessageIds = new Set<string>();
  private selectedEvidenceIds = new Set<string>();
  private repairAttempts: Record<string, number> = {};
  private archiveLayer?: Phaser.GameObjects.Container;
  private panelLayer?: Phaser.GameObjects.Container;
  private feedbackText?: Phaser.GameObjects.Text;
  private objectiveText?: Phaser.GameObjects.Text;
  private reportDom?: Phaser.GameObjects.DOMElement;

  constructor() {
    super("WordArchiveScene");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.restoreFlags();
    this.mode = this.resolveMode();
    this.drawArchive();
    this.createHud();
    this.refreshScene();

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    if (!saveSystem.data.flags.mission4IntroSeen) {
      saveSystem.setFlag("mission4IntroSeen", true);
      new DialogueBox(this, dialogueSystem.format("mission4Opening"), () => {
        feedbackSystem.publish("Le frasi non sono esercizi: sono comandi rotti dell'archivio.", "info");
      });
    }
  }

  private restoreFlags(): void {
    this.archiveMessages.forEach((message) => {
      if (saveSystem.data.flags[`archiveMessage:${message.id}`]) {
        this.repairedMessageIds.add(message.id);
      }
    });
  }

  private resolveMode(): ArchiveMode {
    if (!saveSystem.data.flags.archiveMessagesRepaired) {
      return "repair";
    }
    if (!saveSystem.data.flags.archiveEvidenceSelected) {
      return "evidence";
    }
    if (!saveSystem.data.flags.archiveInstructionDecoded) {
      return "instruction";
    }
    return "report";
  }

  private drawArchive(): void {
    SceneChrome.drawTwoColumnMissionChrome(
      this,
      "archive",
      "Archivio delle Parole",
      "Ripara messaggi, scegli indizi utili e consegna un rapporto operativo.",
      "Archivio instabile",
    );
    VisualKit.cinematicDepth(this, "archive", 0.9);
    tiledSceneRenderer.renderBackdrop(this, "archive");

    const shelves = this.add.graphics();
    const shelfLayout = this.rect("archive:shelves", { x: 48, y: 136, width: 744, height: 486 });
    const shelfWidth = shelfLayout.width ?? 744;
    const shelfHeight = shelfLayout.height ?? 486;
    const shelfTexture = this.textureKey("painted-archive-shelf", "prop-archive-shelf");
    if (shelfTexture) {
      this.add.image(shelfLayout.x + shelfWidth / 2, shelfLayout.y + shelfHeight / 2, shelfTexture).setDisplaySize(shelfWidth, shelfHeight).setAlpha(0.88);
    } else {
      shelves.fillStyle(0x101521, 0.18);
      shelves.fillRect(shelfLayout.x, shelfLayout.y, shelfWidth, shelfHeight);
      shelves.lineStyle(2, 0x9f8cff, 0.2);
      shelves.strokeRect(shelfLayout.x, shelfLayout.y, shelfWidth, shelfHeight);
    }
    VisualKit.glowFrame(this, shelfLayout.x - 10, shelfLayout.y - 10, shelfWidth + 20, shelfHeight + 20, "archive");
    VisualKit.scanLine(this, 420, 372, 730, 456, "archive");
    for (let y = 196; y < 586; y += 86) {
      if (!shelfTexture) {
        shelves.fillStyle(0x1b2030, 0.16);
        shelves.fillRect(shelfLayout.x + 24, y, shelfWidth - 48, 20);
        shelves.lineStyle(1, 0x9f8cff, 0.22);
        shelves.lineBetween(shelfLayout.x + 24, y, shelfLayout.x + shelfWidth - 24, y);
      }
    }
    if (!shelfTexture) {
      for (let index = 0; index < 58; index += 1) {
        const x = 86 + (index % 15) * 44;
        const y = 160 + Math.floor(index / 15) * 90;
        const colors = [0x355c7d, 0x6c5b7b, 0xc06c84, 0x4f6f52, 0x8a6f3d];
        shelves.fillStyle(colors[index % colors.length], 0.24);
        shelves.fillRect(x, y, 24, 56 + (index % 3) * 8);
      }
    }

    for (let index = 0; index < 16; index += 1) {
      const glyph = this.add.text(Phaser.Math.Between(70, 760), Phaser.Math.Between(150, 590), index % 2 === 0 ? "?" : "a", {
        fontFamily: "Georgia, serif",
        fontSize: `${Phaser.Math.Between(18, 34)}px`,
        color: "#9f8cff",
      });
      glyph.setAlpha(0.06);
      this.tweens.add({
        targets: glyph,
        y: glyph.y - Phaser.Math.Between(12, 28),
        alpha: { from: 0.04, to: 0.16 },
        duration: Phaser.Math.Between(2200, 4800),
        yoyo: true,
        repeat: -1,
      });
    }
    this.drawFloatingDocuments();
  }

  private drawFloatingDocuments(): void {
    [
      { x: 116, y: 208, w: 64, h: 84 },
      { x: 686, y: 188, w: 78, h: 96 },
      { x: 318, y: 548, w: 84, h: 64 },
    ].forEach((doc) => {
      const shard = VisualKit.hologramShard(this, doc.x, doc.y, doc.w, doc.h, "archive");
      shard.setRotation(Phaser.Math.FloatBetween(-0.08, 0.08));
    });
  }

  private createHud(): void {
    SceneChrome.consolePanel(this, 820, 130, 420, 126, "Sistema archivio", "archive");
    this.objectiveText = this.add.text(842, 164, "", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#d9eaf1",
      wordWrap: { width: 370 },
      lineSpacing: 5,
    });

    this.feedbackText = SceneChrome.bottomLog(this, SceneChrome.twoColumnLayout.bottom, "");

    new Button(this, 1110, 58, "Diario", () => this.scene.start("JournalScene"), {
      width: 150,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
    new Button(this, 930, 58, "Hub", () => this.scene.start("HubScene"), {
      width: 132,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
  }

  private refreshScene(): void {
    this.archiveLayer?.destroy(true);
    this.panelLayer?.destroy(true);
    this.reportDom = undefined;
    this.archiveLayer = this.add.container(0, 0);
    this.panelLayer = this.add.container(0, 0);
    this.drawArchiveObjects();

    if (this.mode === "repair") {
      this.drawRepairPanel();
    } else if (this.mode === "evidence") {
      this.drawEvidencePanel();
    } else if (this.mode === "instruction") {
      this.drawInstructionPanel();
    } else {
      this.drawReportPanel();
    }
    this.updateObjective();
  }

  private drawArchiveObjects(): void {
    this.archiveMessages.forEach((message, index) => {
      const cardLayout = this.rect(`archive:message:${index}`, { x: 170 + index * 240, y: 306, width: 190, height: 142 });
      const x = cardLayout.x;
      const y = cardLayout.y;
      const repaired = this.repairedMessageIds.has(message.id);
      const card = this.add.container(x, y);
      if (this.textures.exists("prop-archive-card")) {
        card.add(this.add.image(0, 0, "prop-archive-card").setDisplaySize(200, 158).setTint(repaired ? 0xdfffee : 0xffffff).setAlpha(0.94));
      } else {
        card.add(this.add.rectangle(8, 8, 190, 142, 0x000000, 0.28));
        card.add(this.add.rectangle(0, 0, 190, 142, repaired ? 0x182e25 : 0x241b2a, 0.86).setStrokeStyle(2, repaired ? 0x9ff5e9 : 0x9f8cff, 0.62));
        card.add(this.add.rectangle(-68, -62, 36, 3, repaired ? 0x9ff5e9 : 0xf7d37a, 0.72));
        card.add(this.add.rectangle(66, 60, 42, 2, repaired ? 0x9ff5e9 : 0x9f8cff, 0.48));
      }
      card.add(this.add.text(-78, -52, message.title, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: repaired ? "#9ff5e9" : "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: 156 },
      }));
      card.add(this.add.text(-78, -8, repaired ? message.repaired : message.corrupted, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f5fbff",
        wordWrap: { width: 158 },
        lineSpacing: 4,
      }));
      card.setSize(190, 142);
      card.setInteractive(new Phaser.Geom.Rectangle(-95, -71, 190, 142), Phaser.Geom.Rectangle.Contains);
      card.on("pointerdown", () => {
        this.selectedMessageId = message.id;
        this.mode = "repair";
        audioManager.play("scan");
        this.refreshScene();
      });
      this.archiveLayer?.add(card);
    });

    const terminalColor = this.mode === "report" ? 0x9ff5e9 : 0x9f8cff;
    const terminal = this.rect("archive:terminal", { x: 420, y: 518, width: 476, height: 76 });
    const terminalTexture = this.textureKey(this.mode === "report" ? "painted-archive-desk" : "painted-archive-terminal", "prop-archive-terminal");
    this.archiveLayer?.add(terminalTexture
      ? this.add.image(terminal.x, terminal.y, terminalTexture).setDisplaySize(terminal.width ?? 476, (terminal.height ?? 76) * 1.72).setTint(terminalColor === 0x9ff5e9 ? 0xdfffee : 0xffffff).setAlpha(0.92)
      : this.add.rectangle(terminal.x, terminal.y, terminal.width, terminal.height, 0x0d1b26, 0.95).setStrokeStyle(2, terminalColor, 0.44));
    this.archiveLayer?.add(this.add.text(terminal.x - 202, terminal.y - 22, "Terminale rapporto", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: terminalColor === 0x9ff5e9 ? "#9ff5e9" : "#cdbfff",
      fontStyle: "bold",
    }));
    this.archiveLayer?.add(this.add.text(terminal.x - 202, terminal.y + 10, this.statusLine(), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 400 },
    }));
  }

  private drawRepairPanel(): void {
    const message = this.getSelectedMessage();
    const repaired = this.repairedMessageIds.has(message.id);
    const analyzed = this.analyzedMessageIds.has(message.id);
    const panel = this.rect("archive:repairPanel", { x: 820, y: 226, width: 420, height: 420 });
    this.panelLayer?.add(SceneChrome.consolePanel(this, panel.x, panel.y, panel.width ?? 420, panel.height ?? 420, "Banco di restauro", "archive"));
    this.panelLayer?.add(this.add.text(842, 284, `Segnale: "${message.corrupted}"`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
      lineSpacing: 5,
    }));
    this.panelLayer?.add(this.add.text(842, 386, message.systemMeaning, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));

    if (repaired) {
      this.panelLayer?.add(this.add.text(842, 488, "Messaggio stabilizzato. Puoi selezionare un altro frammento o passare agli indizi.", {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#9ff5e9",
        wordWrap: { width: 350 },
      }));
      this.panelLayer?.add(new Button(this, 1012, 590, "Continua archivio", () => this.advanceAfterRepairs(), {
        width: 250,
        height: 44,
        fontSize: 16,
        fill: 0x173b36,
      }));
      return;
    }

    this.panelLayer?.add(this.add.rectangle(842, 434, 356, 64, 0x151b2a, 0.94).setOrigin(0).setStrokeStyle(1, 0x9f8cff, 0.26));
    this.panelLayer?.add(this.add.text(858, 446, analyzed
      ? message.diagnosticSteps.map((step, index) => `${index + 1}. ${step}`).join("\n")
      : "Analisi richiesta: controlla dato operativo, accordi e parole che cambiano l'azione.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: analyzed ? "#cdbfff" : "#c9dce6",
      wordWrap: { width: 328 },
      lineSpacing: 3,
    }));

    if (!analyzed) {
      this.panelLayer?.add(new Button(this, 1018, 584, "Analizza frammento", () => {
        this.analyzedMessageIds.add(message.id);
        audioManager.play("scan");
        this.refreshScene();
      }, {
        width: 250,
        height: 42,
        fontSize: 15,
        fill: 0x173b36,
      }));
      return;
    }

    message.options.forEach((option, index) => {
      this.panelLayer?.add(new Button(this, 1028, 526 + index * 33, option, () => this.tryRepair(message, option), {
        width: 354,
        height: 29,
        fontSize: 11,
        fill: 0x20233a,
      }));
    });
  }

  private drawEvidencePanel(): void {
    const panel = this.rect("archive:evidencePanel", { x: 820, y: 260, width: 420, height: 382 });
    this.panelLayer?.add(SceneChrome.consolePanel(this, panel.x, panel.y, panel.width ?? 420, panel.height ?? 382, "Filtro degli indizi", "archive"));
    this.panelLayer?.add(this.add.text(842, 322, "Seleziona solo ciò che aiuta NORA a decidere cosa aprire e cosa conservare.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
    }));
    this.archiveEvidence.forEach((evidence, index) => {
      const selected = this.selectedEvidenceIds.has(evidence.id);
      this.panelLayer?.add(new Button(this, 1028, 386 + index * 35, `${selected ? "[x]" : "[ ]"} ${evidence.text}`, () => {
        this.toggleEvidence(evidence);
      }, {
        width: 354,
        height: 32,
        fontSize: 11,
        fill: selected ? 0x243d33 : 0x20233a,
      }));
    });
    this.panelLayer?.add(new Button(this, 1018, 612, "Verifica indizi", () => this.checkEvidence(), {
      width: 250,
      height: 44,
      fontSize: 16,
      fill: 0x173b36,
    }));
  }

  private drawInstructionPanel(): void {
    const panel = this.rect("archive:instructionPanel", { x: 820, y: 286, width: 420, height: 332 });
    this.panelLayer?.add(SceneChrome.consolePanel(this, panel.x, panel.y, panel.width ?? 420, panel.height ?? 332, "Istruzione bilingue", "archive"));
    this.panelLayer?.add(this.add.text(842, 350, this.archiveInstruction.instruction, {
      fontFamily: "Inter, Arial",
      fontSize: "22px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
    }));
    this.panelLayer?.add(this.add.text(842, 410, "Scegli l'azione narrativa, non la traduzione parola per parola.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
    }));
    this.archiveInstruction.choices.forEach((choice, index) => {
      this.panelLayer?.add(new Button(this, 1018, 486 + index * 50, choice.label, () => this.chooseInstruction(choice), {
        width: 250,
        height: 40,
        fontSize: 15,
        fill: 0x263743,
      }));
    });
  }

  private drawReportPanel(): void {
    const panel = this.rect("archive:reportPanel", { x: 820, y: 250, width: 420, height: 390 });
    this.panelLayer?.add(SceneChrome.consolePanel(this, panel.x, panel.y, panel.width ?? 420, panel.height ?? 390, "Rapporto finale", "archive"));
    this.panelLayer?.add(this.add.text(842, 310, this.reportPrompt, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));

    const textarea = document.createElement("textarea");
    textarea.value = "";
    textarea.placeholder = "Esempio: La porta nord...";
    textarea.style.width = "340px";
    textarea.style.height = "116px";
    textarea.style.resize = "none";
    textarea.style.border = "1px solid rgba(159, 140, 255, 0.7)";
    textarea.style.borderRadius = "6px";
    textarea.style.background = "#08131c";
    textarea.style.color = "#f5fbff";
    textarea.style.font = "15px Inter, Arial";
    textarea.style.padding = "10px";
    textarea.style.outline = "none";
    this.reportDom = this.add.dom(1026, 432, textarea);
    this.panelLayer?.add(this.reportDom);

    this.panelLayer?.add(new Button(this, 1018, 562, "Consegna rapporto", () => this.submitReport(textarea.value), {
      width: 250,
      height: 44,
      fontSize: 16,
      fill: 0x173b36,
    }));
    this.panelLayer?.add(this.add.text(842, 602, `Serve un testo breve con: ${this.reportKeywords.join(", ")}.`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9aaab0",
      wordWrap: { width: 360 },
    }));
  }

  private tryRepair(message: ArchiveMessage, option: string): void {
    if (option !== message.repaired) {
      this.repairAttempts[message.id] = (this.repairAttempts[message.id] ?? 0) + 1;
      feedbackSystem.publish(`Il cassetto vibra ma non si apre. ${message.hint}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 436, 430, 430);
      VisualKit.particleBurst(this, 1030, 526, "archive", "error");
      if (this.repairAttempts[message.id] % message.maxAttemptsBeforeReview === 0) {
        this.analyzedMessageIds.delete(message.id);
        this.refreshScene();
      }
      return;
    }
    this.repairedMessageIds.add(message.id);
    saveSystem.setFlag(`archiveMessage:${message.id}`, true);
    audioManager.play("success");
    feedbackSystem.publish(`Messaggio riparato: ${message.systemMeaning}`, "success");
    VisualKit.outcomeFlash(this, "success", 420, 340, 760, 460);
    VisualKit.particleBurst(this, 420, 306, "archive", "success");
    if (this.repairedMessageIds.size === this.archiveMessages.length) {
      missionEngine.completeObjective("archiveMessagesRepaired", [
        "italiano.comprensione",
        "italiano.grammatica",
        "italiano.lessico",
      ], 16);
      this.mode = "evidence";
    }
    this.refreshScene();
  }

  private advanceAfterRepairs(): void {
    if (this.repairedMessageIds.size < this.archiveMessages.length) {
      feedbackSystem.publish("Mancano ancora frammenti da stabilizzare: controlla le altre schede dell'archivio.", "hint");
      audioManager.play("error");
      return;
    }
    this.mode = "evidence";
    this.refreshScene();
  }

  private toggleEvidence(evidence: ArchiveEvidence): void {
    if (this.selectedEvidenceIds.has(evidence.id)) {
      this.selectedEvidenceIds.delete(evidence.id);
    } else {
      this.selectedEvidenceIds.add(evidence.id);
    }
    audioManager.play("click");
    feedbackSystem.publish(evidence.reason, evidence.useful ? "info" : "hint");
    this.refreshScene();
  }

  private checkEvidence(): void {
    const evaluation = this.simulator.evaluate(
      this.toArchiveCase(),
      this.archiveMessages.map((message) => message.repaired).join(" "),
      [...this.selectedEvidenceIds],
      this.reportKeywords.join(" "),
    );
    const usefulTotal = this.archiveEvidence.filter((evidence) => evidence.useful).length;
    if (evaluation.selectedUsefulClues < usefulTotal || evaluation.selectedNoiseClues > 0) {
      feedbackSystem.publish(`${evaluation.feedback} Tieni dati che cambiano la decisione, scarta decorazioni e dettagli non operativi.`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 450, 430, 390);
      VisualKit.particleBurst(this, 1030, 462, "archive", "warning");
      return;
    }
    missionEngine.completeObjective("archiveEvidenceSelected", ["italiano.comprensione", "pensieroCritico"], 16);
    audioManager.play("success");
    feedbackSystem.publish("Indizi verificati. L'archivio ora sa quali informazioni contano.", "success");
    VisualKit.outcomeFlash(this, "success", 640, 360, 1120, 620);
    VisualKit.particleBurst(this, 1030, 450, "archive", "success");
    this.mode = "instruction";
    this.refreshScene();
  }

  private chooseInstruction(choice: { correct: boolean; consequence: string }): void {
    if (!choice.correct) {
      feedbackSystem.publish(`${choice.consequence} ${this.archiveInstruction.hint}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 462, 430, 330);
      return;
    }
    missionEngine.completeObjective("archiveInstructionDecoded", ["inglese.istruzioni", "inglese.bilingue", "pensieroCritico"], 15);
    audioManager.play("success");
    feedbackSystem.publish(choice.consequence, "success");
    VisualKit.outcomeFlash(this, "success", 1030, 462, 430, 330);
    VisualKit.particleBurst(this, 1030, 462, "archive", "success");
    this.mode = "report";
    this.refreshScene();
  }

  private submitReport(reportText: string): void {
    const evaluation = this.simulator.evaluate(
      this.toArchiveCase(),
      this.archiveMessages.map((message) => message.repaired).join(" "),
      [...this.selectedEvidenceIds],
      reportText,
    );
    if (reportText.trim().length < 80 || !evaluation.reportComplete) {
      feedbackSystem.publish(
        `${evaluation.feedback} Deve citare ${this.reportKeywords.join(", ")} e spiegare l'azione in modo operativo.`,
        "hint",
      );
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 452, 430, 390);
      return;
    }
    missionEngine.completeObjective("archiveReportSubmitted", [
      "italiano.scritturaBreve",
      "italiano.lessico",
      "pensieroCritico",
    ], 18);
    audioManager.play("success");
    VisualKit.outcomeFlash(this, "success");
    VisualKit.particleBurst(this, 1030, 452, "archive", "success");
    missionEngine.completeMissionFour(reportText.trim());
    this.time.delayedCall(900, () => this.scene.start("JournalScene"));
  }

  private updateObjective(): void {
    const mission = missionEngine.getMission("mission-04-archivio-parole") ?? missionEngine.getActiveMission();
    const active = mission.objectives.find((objective) => missionEngine.getObjectiveStatus(objective) === "active");
    this.objectiveText?.setText(active ? `${active.label}\n${active.description}` : "Consegna un rapporto chiaro per chiudere il caso.");
  }

  private statusLine(): string {
    if (this.mode === "repair") {
      return `Messaggi riparati: ${this.repairedMessageIds.size}/${this.archiveMessages.length}.`;
    }
    if (this.mode === "evidence") {
      return `Indizi selezionati: ${this.selectedEvidenceIds.size}. Non tutto ciò che è vero è utile.`;
    }
    if (this.mode === "instruction") {
      return "Istruzione esterna ricevuta: scegli l'azione senza perdere la fonte.";
    }
    return "Rapporto attivo: sintetizza il caso per NORA.";
  }

  private getSelectedMessage(): ArchiveMessage {
    return this.archiveMessages.find((message) => message.id === this.selectedMessageId) ?? this.archiveMessages[0];
  }

  private toArchiveCase(): ArchiveRepairCase {
    return {
      corrupted: this.archiveMessages.map((message) => message.corrupted).join(" "),
      repaired: this.archiveMessages.map((message) => message.repaired).join(" "),
      requiredKeywords: this.reportKeywords,
      clues: this.archiveEvidence,
    };
  }

  private rect(id: string, fallback: MapLayoutRect): Required<Pick<MapLayoutRect, "x" | "y">> & MapLayoutRect {
    return { ...fallback, ...this.layout[id] } as Required<Pick<MapLayoutRect, "x" | "y">> & MapLayoutRect;
  }

  private textureKey(primary: string, fallback: string): string | undefined {
    if (this.textures.exists(primary)) return primary;
    if (this.textures.exists(fallback)) return fallback;
    return undefined;
  }

  private handleFeedback(message: FeedbackMessage): void {
    const colors = {
      info: "#d9eaf1",
      hint: "#f7d37a",
      success: "#9ff5e9",
      warning: "#ffb36b",
    };
    this.feedbackText?.setColor(colors[message.tone]).setText(message.text);
  }
}
