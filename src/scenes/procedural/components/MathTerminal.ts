import type Phaser from "phaser";
import type { GeneratedMathPuzzle, MathMinigamePrompt } from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";
import { SceneChrome } from "../../../ui/SceneChrome";

export type MathTerminalModel = {
  title: string;
  prompt: string;
  domainLabel: string;
  curriculumTags: string[];
  difficultyLabel: string;
  learningPurpose: string;
  mentalMathNote: string;
  strategy: string;
  scratchpadPrompt: string;
  theoryPrinciple: string;
  workedExample: string;
  expectedAnswer: number;
  minimumReasoningSteps: number;
};

export type MathAnswerConsoleState = {
  entry: string;
};

export type MathAnswerConsoleHandlers = {
  onKey(key: string): void;
};

export type MathSupportPanelState = {
  showCoach?: boolean;
  supportMessage?: string;
};

export type MathSupportPanelHandlers = {
  onHint(): void;
};

export type MathMinigamePromptState = {
  showCoach: boolean;
  selectedIds: Set<string>;
  remainingLabel: string;
  remainingDanger: boolean;
  streak: number;
  netScore: number;
  accuracy: number;
  feedback: string;
  scoringRule: string;
};

export type MathMinigamePromptHandlers = {
  onToggleTile(tileId: string): void;
  onClearSelection(): void;
  onConfirm(): void;
  onHint(): void;
  onRenderVisualizer(
    overlay: Phaser.GameObjects.Container,
    prompt: MathMinigamePrompt,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void;
  onRenderExpressionBuilder?(overlay: Phaser.GameObjects.Container, prompt: MathMinigamePrompt): void;
};

export type MathMinigameSummaryState = {
  passed: boolean;
  correct: number;
  wrong: number;
  accuracy: number;
  bestStreak: number;
  netScore: number;
  feedback: string;
  resolutionText: string;
  energyText?: string;
  actionLabel: string;
};

export type MathMinigameSummaryHandlers = {
  onAction(modal: Phaser.GameObjects.Container): void;
};

const mathDomainLabels: Record<NonNullable<GeneratedMathPuzzle["archetype"]>, string> = {
  "calcolo-diretto": "Calcolo strategico",
  "ragionamento-inverso": "Ragionamento inverso",
  sequenza: "Sequenze e pattern",
  vincolo: "Vincoli numerici",
  "diagnosi-errore": "Controllo dell'errore",
  "lettura-dati": "Lettura dati",
  proporzione: "Rapporti e proporzioni",
  "pre-algebra": "Pre-algebra",
  frazioni: "Frazioni operative",
  percentuali: "Percentuali",
  geometria: "Geometria applicata",
  statistica: "Statistica di base",
  probabilita: "Probabilita",
  "potenze-radici": "Potenze e radici",
  "funzione-lineare": "Funzioni lineari",
  "sistemi-lineari": "Sistemi semplici",
  "equazione-primo-grado": "Equazioni di primo grado",
  "equazione-secondo-grado": "Equazioni di secondo grado",
  "grafici-cartesiani": "Officina dei grafici",
  coordinate: "Coordinate e griglie",
};

export class MathTerminal {
  static fromPuzzle(puzzle: GeneratedMathPuzzle): MathTerminalModel {
    return {
      title: puzzle.title,
      prompt: puzzle.prompt,
      domainLabel: mathDomainLabels[puzzle.archetype ?? "calcolo-diretto"],
      curriculumTags: puzzle.curriculumTags ?? [],
      difficultyLabel: puzzle.difficultyLabel ?? "Livello non classificato",
      learningPurpose: puzzle.learningPurpose ?? puzzle.pedagogy?.learningGoal ?? "Allenare ragionamento matematico applicato.",
      mentalMathNote: puzzle.calculationAid?.mentalMathNote ?? "Puoi calcolare a mente se vuoi, ma puoi anche usare carta e passaggi intermedi.",
      strategy: puzzle.calculationAid?.strategy ?? "Risolvi un passaggio alla volta e controlla il risultato prima di inserirlo.",
      scratchpadPrompt: puzzle.calculationAid?.scratchpadPrompt ?? "Scrivi i passaggi su un taccuino: il gioco valuta il ragionamento, non la memoria.",
      theoryPrinciple: puzzle.pedagogy?.explanation.principle ?? "Ogni esercizio nasconde una regola matematica da riconoscere e applicare.",
      workedExample: puzzle.pedagogy?.explanation.workedExample ?? puzzle.solutionSteps?.join(" -> ") ?? "",
      expectedAnswer: puzzle.answer,
      minimumReasoningSteps: Math.max(2, puzzle.solutionSteps?.length ?? 0),
    };
  }

  static addBriefing(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, model: MathTerminalModel): void {
    this.addPanel(scene, overlay, 28, 102, 378, 438, "Briefing matematico");
    overlay.add(scene.add.text(54, 146, model.difficultyLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(54, 172, `Ambito: ${model.domainLabel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    if (model.curriculumTags.length > 0) {
      overlay.add(scene.add.text(54, 196, `Concetti: ${model.curriculumTags.slice(0, 4).join(" · ")}`, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 326 },
      }));
    }
    overlay.add(scene.add.text(54, 236, model.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 320, useAdvancedWrap: true },
      lineSpacing: 4,
    }));
  }

  static addAnswerConsole(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    state: MathAnswerConsoleState,
    handlers: MathAnswerConsoleHandlers,
  ): void {
    this.addPanel(scene, overlay, 954, 102, 298, 438, "Console di risposta");
    overlay.add(scene.add.text(982, 148, "Inserisci solo il valore finale quando hai una strategia chiara.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 242 },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.text(1016, 216, "Risultato", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.rectangle(1102, 270, 156, 70, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.56));
    overlay.add(scene.add.text(1040, 248, state.entry.padEnd(4, "-"), {
      fontFamily: "Inter, Arial",
      fontSize: "42px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const keypadY = 348;
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"].forEach((key, index) => {
      overlay.add(new Button(scene, 1024 + (index % 3) * 76, keypadY + Math.floor(index / 3) * 42, key, () => handlers.onKey(key), {
        width: 58,
        height: 34,
        fontSize: 17,
        fill: key === "OK" ? 0x173b36 : 0x142736,
        soundKey: key === "OK" ? "confirm" : key === "C" ? "cancel" : "mathKey",
      }));
    });
  }

  static addSupportPanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    model: MathTerminalModel,
    state: MathSupportPanelState,
    handlers: MathSupportPanelHandlers,
  ): Phaser.GameObjects.Text {
    const showCoach = state.showCoach ?? true;
    this.addPanel(scene, overlay, 28, 556, 1224, 132, showCoach ? "Supporti intelligenti" : "Supporto");
    overlay.add(scene.add.text(54, 596, showCoach ? [
      `Scopo didattico: ${model.learningPurpose}`,
      `Metodo consigliato: ${model.strategy}`,
      model.mentalMathNote,
      `Appunti: ${model.scratchpadPrompt}`,
    ].join("\n") : "Indizio disponibile se vuoi controllare il ragionamento.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 620 },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.rectangle(990, 596, 478, 44, 0x07151d, 0.82).setStrokeStyle(1, 0xf6c85f, 0.28));
    const supportText = scene.add.text(760, 580, state.supportMessage || (showCoach ? "Scegli un aiuto solo quando serve: ogni supporto guida il ragionamento e viene conteggiato nel punteggio." : ""), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: state.supportMessage ? "#f7d37a" : "#9aaab0",
      wordWrap: { width: 460, useAdvancedWrap: true },
      lineSpacing: 3,
    });
    overlay.add(supportText);
    overlay.add(new Button(scene, 1080, 660, "Aiuto mirato", handlers.onHint, {
      width: 220,
      height: 42,
      fontSize: 13,
      fill: 0x263743,
    }));
    return supportText;
  }

  static addMinigamePrompt(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    prompt: MathMinigamePrompt,
    state: MathMinigamePromptState,
    handlers: MathMinigamePromptHandlers,
  ): Phaser.GameObjects.Text {
    this.addPanel(scene, overlay, 28, 112, 548, 432, state.showCoach ? "1 · Osserva dati e obiettivo" : "Obiettivo");
    overlay.add(scene.add.text(60, 156, prompt.targetLabel, {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f7d37a",
      fontStyle: "bold",
      shadow: { offsetX: 0, offsetY: 4, color: "#000000", blur: 8, fill: true },
    }));
    handlers.onRenderVisualizer(overlay, prompt, 64, 218, 460, 218);
    overlay.add(scene.add.text(60, 468, `Concetto: ${prompt.concept}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
      wordWrap: { width: 472 },
    }));
    if (state.showCoach) {
      overlay.add(scene.add.text(60, 496, this.minigameMethodText(prompt), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#9aaab0",
        wordWrap: { width: 476, useAdvancedWrap: true },
        lineSpacing: 3,
      }));
    }

    this.addPanel(scene, overlay, 604, 112, 648, 432, state.showCoach ? "2 · Seleziona la soluzione" : "Scelte");
    if (state.showCoach) {
      overlay.add(scene.add.text(636, 156, "Come si gioca: scegli UNA O PIÙ tessere richieste dalla domanda, poi premi Conferma.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#d9eaf1",
        wordWrap: { width: 560 },
        lineSpacing: 4,
      }));
    }
    overlay.add(scene.add.text(636, state.showCoach ? 212 : 164, prompt.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      fontStyle: "bold",
      wordWrap: { width: 560, useAdvancedWrap: true },
      lineSpacing: 5,
    }));

    if (prompt.type === "expression-build" && handlers.onRenderExpressionBuilder) {
      handlers.onRenderExpressionBuilder(overlay, prompt);
    } else {
      const tileStartX = 700;
      const tileStartY = 334;
      prompt.tiles.forEach((tile, index) => {
        const selected = state.selectedIds.has(tile.id);
        const col = index % 3;
        const row = Math.floor(index / 3);
        overlay.add(new Button(scene, tileStartX + col * 186, tileStartY + row * 64, `${selected ? "✓ " : ""}${tile.label}`, () => handlers.onToggleTile(tile.id), {
          width: 164,
          height: 48,
          fontSize: tile.label.length > 12 ? 11 : 20,
          wordWrapWidth: 142,
          fill: selected ? 0x174d42 : 0x263743,
          stroke: selected ? 0xf7d37a : 0x6be7d6,
        }));
      });
    }

    this.addPanel(scene, overlay, 28, 558, 1224, 130, state.showCoach ? "3 · Conferma e controlla l'esito" : "Esito");
    const timerText = scene.add.text(64, 604, `Tempo: ${state.remainingLabel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: state.remainingDanger ? "#ff8f8f" : "#f7d37a",
      fontStyle: "bold",
    });
    overlay.add(timerText);
    overlay.add(scene.add.text(260, 592, `Serie: ${state.streak}    ·    Punti: ${state.netScore}    ·    Precisione: ${state.accuracy}%`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 640 },
      lineSpacing: 4,
    }));
    if (state.showCoach || state.feedback) {
      overlay.add(scene.add.text(260, 636, state.feedback || state.scoringRule, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: state.feedback ? "#f7d37a" : "#9aaab0",
        wordWrap: { width: 390, useAdvancedWrap: true },
      }));
    }
    overlay.add(new Button(scene, 916, 640, "Pulisci scelta", handlers.onClearSelection, {
      width: 174,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));
    overlay.add(new Button(scene, 1102, 640, "Conferma", handlers.onConfirm, {
      width: 174,
      height: 44,
      fontSize: 14,
      fill: 0x173b36,
    }));
    overlay.add(new Button(scene, 736, 640, "Indizio", handlers.onHint, {
      width: 138,
      height: 44,
      fontSize: 13,
      fill: 0x263743,
    }));

    return timerText;
  }

  static addMinigameSummary(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    state: MathMinigameSummaryState,
    handlers: MathMinigameSummaryHandlers,
  ): Phaser.GameObjects.Container {
    const modal = scene.add.container(0, 0).setDepth(1300);
    SceneChrome.modalInputBlocker(scene, modal, overlay.x + modal.x, overlay.y + modal.y, 0x02070b, 0.64);
    modal.add(scene.add.rectangle(600, 334, 790, 368, 0x000000, 0.34));
    modal.add(scene.add.rectangle(600, 320, 790, 368, 0x07151d, 0.98)
      .setStrokeStyle(2, state.passed ? 0x6be7d6 : 0xf7d37a, 0.76));
    modal.add(scene.add.text(230, 160, state.passed ? "Sprint matematico completato" : "Sprint matematico da consolidare", {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: state.passed ? "#9ff5e9" : "#f7d37a",
      fontStyle: "bold",
    }));
    modal.add(scene.add.text(230, 210, [
      `Risposte corrette: ${state.correct}`,
      `Errori: ${state.wrong}`,
      `Precisione: ${state.accuracy}%`,
      `Serie migliore: ${state.bestStreak}`,
      `Punti sprint: ${state.netScore}`,
    ].join("\n"), {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f5fbff",
      lineSpacing: 7,
    }));
    modal.add(scene.add.rectangle(548, 212, 408, 128, 0x102533, 0.78).setOrigin(0)
      .setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(scene.add.text(572, 234, state.feedback, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 354 },
      lineSpacing: 5,
    }));
    modal.add(scene.add.rectangle(230, 378, 740, 74, 0x0b1e2a, 0.82).setOrigin(0)
      .setStrokeStyle(1, 0xf7d37a, 0.36));
    modal.add(scene.add.text(254, 394, state.resolutionText, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 690 },
      lineSpacing: 4,
    }));
    if (state.energyText) {
      modal.add(scene.add.text(254, 456, state.energyText, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f7d37a",
        fontStyle: "bold",
        wordWrap: { width: 690 },
      }));
    }
    modal.add(new Button(scene, 612, 506, state.actionLabel, () => handlers.onAction(modal), {
      width: 270,
      height: 54,
      fill: state.passed ? 0x173b36 : 0x263743,
      stroke: state.passed ? 0x6be7d6 : 0xf7d37a,
      fontSize: 16,
    }));
    overlay.add(modal);
    return modal;
  }

  static addLogicVisualizer(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMathPuzzle,
    model: MathTerminalModel,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    this.addPanel(scene, overlay, x, y, width, height, "Mappa visiva");
    overlay.add(scene.add.text(x + 24, y + 58, "Leggi il problema come un sistema: dati -> regola -> trasformazione -> controllo.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      wordWrap: { width: width - 48 },
    }));

    const archetype = puzzle.archetype ?? "calcolo-diretto";
    if (archetype === "frazioni" || archetype === "percentuali" || archetype === "proporzione") {
      this.drawShareVisualizer(scene, overlay, x, y, width, archetype);
    } else if (archetype === "geometria") {
      this.drawGeometryVisualizer(scene, overlay, x, y, width, model.curriculumTags);
    } else if (archetype === "coordinate") {
      this.drawCoordinateVisualizer(scene, overlay, x, y);
    } else if (archetype === "statistica" || archetype === "probabilita" || archetype === "lettura-dati") {
      this.drawDataVisualizer(scene, overlay, x, y, archetype);
    } else if (
      archetype === "funzione-lineare"
      || archetype === "sistemi-lineari"
      || archetype === "pre-algebra"
      || archetype === "ragionamento-inverso"
      || archetype === "equazione-primo-grado"
    ) {
      this.drawAlgebraVisualizer(scene, overlay, x, y, width, archetype);
    } else if (archetype === "sequenza" || archetype === "potenze-radici") {
      this.drawSequenceVisualizer(scene, overlay, x, y, archetype);
    } else {
      this.drawOperationVisualizer(scene, overlay, x, y, width);
    }

    this.drawReasoningRail(scene, overlay, x + 42, y + height - 82, width - 84, [
      "Dati",
      "Regola",
      "Passaggi",
      "Verifica",
    ]);
  }

  private static drawShareVisualizer(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = scene.add.graphics();
    const barX = x + 68;
    const barY = y + 178;
    const segmentW = (width - 136) / 6;
    g.fillStyle(0x07151d, 0.9);
    g.fillRoundedRect(barX - 10, barY - 18, width - 116, 96, 10);
    for (let index = 0; index < 6; index += 1) {
      const color = index < 3 ? 0x6be7d6 : index < 5 ? 0xf6c85f : 0x315766;
      g.fillStyle(color, index < 5 ? 0.58 : 0.22);
      g.fillRoundedRect(barX + index * segmentW, barY, segmentW - 5, 34, 6);
      g.lineStyle(1, 0xffffff, 0.1);
      g.strokeRoundedRect(barX + index * segmentW, barY, segmentW - 5, 34, 6);
    }
    overlay.add(g);
    const label = archetype === "percentuali"
      ? "100% = intero, poi calcola la quota richiesta"
      : archetype === "proporzione"
        ? "Stesso rapporto, scala diversa"
        : "Quote dello stesso intero, poi resto";
    overlay.add(scene.add.text(x + 72, y + 138, label, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(x + 74, y + 232, "Non dividere il resto per errore: identifica prima l'intero iniziale.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 140 },
    }));
  }

  private static drawGeometryVisualizer(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    tags: string[],
  ): void {
    const g = scene.add.graphics();
    const isPythagoras = tags.some((tag) => tag.toLowerCase().includes("pitagora"));
    g.lineStyle(3, 0x6be7d6, 0.85);
    g.fillStyle(0x07151d, 0.62);
    if (isPythagoras) {
      const ax = x + 126;
      const ay = y + 284;
      const bx = x + 126;
      const by = y + 148;
      const cx = x + 348;
      const cy = y + 284;
      g.fillTriangle(ax, ay, bx, by, cx, cy);
      g.strokeTriangle(ax, ay, bx, by, cx, cy);
      g.lineStyle(2, 0xf6c85f, 0.78);
      g.lineBetween(bx, by, cx, cy);
      overlay.add(g);
      overlay.add(scene.add.text(x + 164, y + 116, "Triangolo rettangolo: i due lati perpendicolari determinano la diagonale.", {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f7d37a",
        wordWrap: { width: width - 120 },
      }));
    } else {
      g.fillRoundedRect(x + 116, y + 146, 258, 146, 8);
      g.strokeRoundedRect(x + 116, y + 146, 258, 146, 8);
      g.lineStyle(2, 0xf6c85f, 0.7);
      g.strokeRoundedRect(x + 106, y + 136, 278, 166, 10);
      overlay.add(g);
      overlay.add(scene.add.text(x + 144, y + 116, "Area = spazio interno. Perimetro = bordo esterno.", {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#f7d37a",
        fontStyle: "bold",
      }));
    }
    overlay.add(scene.add.text(x + 88, y + 324, "Prima scegli la grandezza giusta, poi applica la formula. Area, perimetro e distanza non misurano la stessa cosa.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: width - 116 },
    }));
  }

  private static drawCoordinateVisualizer(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, x: number, y: number): void {
    const g = scene.add.graphics();
    const originX = x + 142;
    const originY = y + 304;
    const cell = 32;
    g.lineStyle(1, 0x6be7d6, 0.16);
    for (let i = 0; i <= 7; i += 1) {
      g.lineBetween(originX, originY - i * cell, originX + 7 * cell, originY - i * cell);
      g.lineBetween(originX + i * cell, originY, originX + i * cell, originY - 7 * cell);
    }
    g.lineStyle(4, 0xf6c85f, 0.82);
    g.lineBetween(originX + cell, originY - cell, originX + 5 * cell, originY - cell);
    g.lineBetween(originX + 5 * cell, originY - cell, originX + 5 * cell, originY - 5 * cell);
    overlay.add(g);
    overlay.add(scene.add.circle(originX + cell, originY - cell, 8, 0x6be7d6, 1));
    overlay.add(scene.add.star(originX + 5 * cell, originY - 5 * cell, 5, 7, 16, 0xf6c85f, 1));
    overlay.add(scene.add.text(x + 84, y + 124, "Conta spostamento orizzontale e verticale: niente diagonali.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
  }

  private static drawDataVisualizer(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = scene.add.graphics();
    const values = [54, 86, 128, 102, 168];
    values.forEach((value, index) => {
      g.fillStyle(index === 2 ? 0xf6c85f : 0x6be7d6, index === 2 ? 0.78 : 0.42);
      g.fillRoundedRect(x + 116 + index * 58, y + 304 - value, 34, value, 6);
    });
    g.lineStyle(2, 0x9aaab0, 0.42);
    g.lineBetween(x + 94, y + 304, x + 414, y + 304);
    overlay.add(g);
    const label = archetype === "probabilita"
      ? "Rapporto -> frequenza attesa"
      : "Dati -> misura stabile -> codice";
    overlay.add(scene.add.text(x + 112, y + 126, label, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(x + 98, y + 330, "Non scegliere il numero piu vistoso: controlla quale misura chiede il terminale.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#d9eaf1",
      wordWrap: { width: 330 },
    }));
  }

  private static drawAlgebraVisualizer(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = scene.add.graphics();
    const cy = y + 224;
    const boxes = [
      {
        x: x + 90,
        label: archetype === "ragionamento-inverso"
          ? "Uscita"
          : archetype === "equazione-primo-grado"
            ? "Equilibrio"
            : "Ingresso x",
      },
      {
        x: x + 242,
        label: archetype === "sistemi-lineari"
          ? "Relazioni"
          : archetype === "equazione-primo-grado"
            ? "Operazioni inverse"
            : "Regola",
      },
      {
        x: x + 394,
        label: archetype === "ragionamento-inverso"
          ? "Ingresso"
          : archetype === "equazione-primo-grado"
            ? "x isolata"
            : "Uscita y",
      },
    ];
    g.lineStyle(3, 0x6be7d6, 0.6);
    g.lineBetween(boxes[0].x + 54, cy, boxes[1].x - 54, cy);
    g.lineBetween(boxes[1].x + 54, cy, boxes[2].x - 54, cy);
    overlay.add(g);
    boxes.forEach((box, index) => {
      overlay.add(scene.add.rectangle(box.x, cy, 108, 72, index === 1 ? 0x173b36 : 0x07151d, 0.92).setStrokeStyle(2, index === 1 ? 0xf6c85f : 0x6be7d6, 0.68));
      overlay.add(scene.add.text(box.x, cy, box.label, {
        fontFamily: "Inter, Arial",
        fontSize: "13px",
        color: "#f5fbff",
        align: "center",
        wordWrap: { width: 86 },
      }).setOrigin(0.5));
    });
    const caption = archetype === "sistemi-lineari"
      ? "Due informazioni insieme isolano le incognite."
      : archetype === "equazione-primo-grado"
        ? "Una bilancia resta vera solo se fai la stessa operazione su entrambi i lati."
        : "Una regola trasforma, l'operazione inversa ricostruisce.";
    overlay.add(scene.add.text(x + 78, y + 126, caption, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: width - 120 },
    }));
  }

  private static drawSequenceVisualizer(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    archetype: NonNullable<GeneratedMathPuzzle["archetype"]>,
  ): void {
    const g = scene.add.graphics();
    const startX = x + 96;
    const startY = y + 286;
    const nodes = archetype === "potenze-radici" ? [0, 34, 82, 154] : [0, 42, 92, 156];
    g.lineStyle(3, 0x6be7d6, 0.48);
    nodes.forEach((rise, index) => {
      const px = startX + index * 94;
      const py = startY - rise;
      if (index > 0) {
        const prevX = startX + (index - 1) * 94;
        const prevY = startY - nodes[index - 1];
        g.lineBetween(prevX, prevY, px, py);
      }
    });
    overlay.add(g);
    nodes.forEach((rise, index) => {
      overlay.add(scene.add.circle(startX + index * 94, startY - rise, 16, index === nodes.length - 1 ? 0xf6c85f : 0x6be7d6, 0.82));
    });
    overlay.add(scene.add.text(x + 82, y + 126, archetype === "potenze-radici" ? "Crescita ripetuta: controlla quante volte applichi la stessa regola." : "Osserva i salti: il prossimo valore nasce dalla regola, non dal caso.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      fontStyle: "bold",
      wordWrap: { width: 360 },
    }));
  }

  private static drawOperationVisualizer(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, x: number, y: number, width: number): void {
    const labels = ["Valore", "Operazione", "Intermedio", "Codice"];
    labels.forEach((label, index) => {
      const cx = x + 86 + index * 110;
      overlay.add(scene.add.rectangle(cx, y + 224, 92, 62, index === labels.length - 1 ? 0x173b36 : 0x07151d, 0.92).setStrokeStyle(2, index === labels.length - 1 ? 0xf6c85f : 0x6be7d6, 0.56));
      overlay.add(scene.add.text(cx, y + 224, label, {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#f5fbff",
        align: "center",
      }).setOrigin(0.5));
      if (index < labels.length - 1) {
        overlay.add(scene.add.triangle(cx + 60, y + 224, 0, -7, 14, 0, 0, 7, 0x6be7d6, 0.72));
      }
    });
    overlay.add(scene.add.text(x + 82, y + 126, "Trasforma un valore alla volta e conserva i risultati intermedi.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: width - 120 },
    }));
  }

  private static drawReasoningRail(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    labels: string[],
  ): void {
    const g = scene.add.graphics();
    const gap = width / (labels.length - 1);
    g.lineStyle(2, 0x6be7d6, 0.32);
    g.lineBetween(x, y, x + width, y);
    overlay.add(g);
    labels.forEach((label, index) => {
      const cx = x + index * gap;
      overlay.add(scene.add.circle(cx, y, 12, index === 0 ? 0xf6c85f : 0x6be7d6, 0.82));
      overlay.add(scene.add.text(cx, y + 24, label, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#d9eaf1",
      }).setOrigin(0.5));
    });
  }

  private static minigameMethodText(prompt: MathMinigamePrompt): string {
    if (prompt.type === "target-sum") {
      return "Metodo: non sommare tutto. Cerca prima un addendo vicino al bersaglio, poi completa senza superare il totale.";
    }
    if (prompt.type === "factor-hunt") {
      return "Metodo: prova la divisione. Se il resto e zero, il numero rispetta il vincolo; altrimenti e un distrattore.";
    }
    if (prompt.type === "number-sequence") {
      return "Metodo: confronta termini vicini. Cerca una differenza fissa, un rapporto fisso o un passo che cresce.";
    }
    if (prompt.type === "expression-build") {
      return "Metodo: la moltiplicazione si calcola prima di somma e sottrazione. Prova un operatore alla volta verso il bersaglio.";
    }
    if (prompt.type === "fraction-lab") {
      return "Metodo: individua totale e parte richiesta. Per una frazione dividi in parti uguali; per una percentuale porta tutto su 100.";
    }
    if (prompt.type === "ratio-proportion") {
      return "Metodo: trova il rapporto unitario oppure controlla la scala. Se le grandezze sono inverse, una cresce e l'altra diminuisce.";
    }
    if (prompt.type === "geometry-measure") {
      return "Metodo: prima decidi se serve lunghezza, superficie o volume; poi scegli la formula e controlla l'unita di misura.";
    }
    if (prompt.type === "data-probability") {
      return "Metodo: non saltare al numero piu evidente. Chiediti se la richiesta parla di media, dato centrale, frequenza o probabilita.";
    }
    return "Metodo: simula mentalmente la rotta da sinistra a destra. Una trasformazione plausibile non basta: deve arrivare esattamente all'uscita.";
  }

  private static addPanel(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    height: number,
    title: string,
  ): void {
    overlay.add(scene.add.rectangle(x, y, width, height, 0x07151d, 0.84).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(scene.add.text(x + 20, y + 18, title, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
  }
}
