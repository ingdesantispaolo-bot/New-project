import Phaser from "phaser";
import { audioManager } from "../../../core/AudioManager";
import { formatDuration } from "../../../core/ProceduralScoring";
import type { DifficultyLevel, GeneratedMusicPuzzle } from "../../../procedural/ProceduralTypes";
import { Button } from "../../../ui/Button";
import { addMethodStrip } from "../ExerciseUiHelpers";
import type { MusicTrainingSession } from "../ProceduralMissionDefs";

type MusicSprintScreenOptions = {
  showCoach: boolean;
  activeHint?: string;
  hintLabel: string;
  onAnswer(correct: boolean, feedback: string, selectedLabel: string): void;
  onExpired(): void;
  onHint(): void;
  onStartCountdown(timerText: Phaser.GameObjects.Text): void;
};

/**
 * Vista e helper puri della console musicale (Osservatorio del Pentagramma).
 * Segue il pattern di CircuitConsole/MathTerminal: la scena mantiene stato e
 * orchestrazione dello sprint, qui vivono rendering e calcoli senza stato.
 */
export const MusicConsole = {
  frequency(note: GeneratedMusicPuzzle["noteName"], octave: number): number {
    const semitone = { Do: 0, Re: 2, Mi: 4, Fa: 5, Sol: 7, La: 9, Si: 11 }[note];
    const midi = (octave + 1) * 12 + semitone;
    return 440 * 2 ** ((midi - 69) / 12);
  },

  isAuditoryPuzzle(puzzle: GeneratedMusicPuzzle): boolean {
    return puzzle.challengeMode === "auditory-note" || puzzle.challengeMode === "auditory-interval" || puzzle.audioPrompt?.hiddenStaff === true;
  },

  puzzleSignature(puzzle: GeneratedMusicPuzzle): string {
    return [
      puzzle.challengeMode ?? "note-hunt",
      puzzle.clef,
      puzzle.answerMode,
      puzzle.noteName,
      puzzle.octave,
      puzzle.staffPosition,
      puzzle.ledgerLines.join("."),
      puzzle.secondaryNote ? `${puzzle.secondaryNote.noteName}${puzzle.secondaryNote.octave}:${puzzle.secondaryNote.staffPosition}` : "",
      puzzle.rhythmPattern ? `${puzzle.rhythmPattern.beatsPerMeasure}:${puzzle.rhythmPattern.cells.map((cell) => `${cell.beats}${cell.missing ? "?" : ""}`).join("-")}` : "",
    ].join(":");
  },

  previewChallenge(puzzle: GeneratedMusicPuzzle): void {
    if ((puzzle.challengeMode === "rhythm-gap" || puzzle.challengeMode === "note-duration") && puzzle.rhythmPattern) {
      audioManager.playToneSequence(puzzle.rhythmPattern.cells.map((cell) => ({
        frequency: cell.missing ? 0 : 740,
        durationMs: Math.max(130, cell.beats * 260),
      })));
      return;
    }
    const tones = [{ note: puzzle.noteName, octave: puzzle.octave }];
    // Any interval challenge must play BOTH notes — an interval is a relation
    // between two pitches, impossible to judge from a single sound.
    if ((puzzle.challengeMode === "interval-jump" || puzzle.challengeMode === "auditory-interval") && puzzle.secondaryNote) {
      tones.push({ note: puzzle.secondaryNote.noteName, octave: puzzle.secondaryNote.octave });
    }
    audioManager.playToneSequence(tones.map((tone) => ({ frequency: MusicConsole.frequency(tone.note, tone.octave), durationMs: 480 })));
  },

  playNote(note: GeneratedMusicPuzzle["noteName"], octave: number): void {
    audioManager.playToneSequence([{ frequency: MusicConsole.frequency(note, octave), durationMs: 540 }]);
  },

  sprintDurationMs(level: DifficultyLevel): number {
    return (45_000 + Math.min(18_000, (level - 1) * 2_500)) * 2;
  },

  sprintElapsedMs(session: MusicTrainingSession): number {
    return Math.max(0, Date.now() - session.startedAt);
  },

  sprintRemainingMs(session: MusicTrainingSession): number {
    return Math.max(0, session.durationMs - MusicConsole.sprintElapsedMs(session));
  },

  sprintExpired(session: MusicTrainingSession): boolean {
    return MusicConsole.sprintRemainingMs(session) <= 0;
  },

  answerPoints(session: MusicTrainingSession, correct: boolean, level: DifficultyLevel): number {
    if (correct) {
      const nextStreak = session.streak + 1;
      const streakBonus = Math.min(12, Math.floor(nextStreak / 3) * 3);
      return 10 + level * 2 + streakBonus;
    }
    const randomClickPenalty = Math.min(8, Math.floor(session.streak / 2) * 2);
    return -(8 + level + randomClickPenalty);
  },

  sprintFeedback(session: MusicTrainingSession): string {
    if (session.answered === 0) {
      return "Nessuna risposta registrata: serve almeno iniziare il riconoscimento delle note.";
    }
    const accuracy = session.correct / session.answered;
    if (accuracy >= 0.86 && session.bestStreak >= 7) {
      return "Lettura fluida: riconosci chiave, posizione e nome con buona continuità.";
    }
    if (accuracy >= 0.68) {
      return "Buona base: la velocità cresce, ma alcune risposte mostrano che devi ricontare prima del click.";
    }
    if (session.wrong > session.correct) {
      return "Troppe risposte a tentativo: rallenta un attimo, aggancia la nota guida e poi conta linee e spazi.";
    }
    return "Calibrazione utile: hai letto diverse note, ora punta a serie più lunghe senza errori.";
  },

  promptText(puzzle: GeneratedMusicPuzzle): string {
    if (puzzle.challengeMode === "auditory-note") {
      return "Orecchio musicale: ascolta la nota e scegli il nome corretto. Il pentagramma è nascosto per calibrare il riconoscimento dal suono.";
    }
    if (puzzle.challengeMode === "auditory-interval") {
      return "Orecchio musicale: ascolta due note in sequenza e scegli se la seconda sale/scende e di quale intervallo.";
    }
    if (puzzle.challengeMode === "interval-jump") {
      return "Salto melodico: la nota 2 sale o scende? Conta la distanza e scegli direzione + intervallo.";
    }
    if (puzzle.challengeMode === "rhythm-gap") {
      return `Battito mancante: completa la battuta da ${puzzle.rhythmPattern?.beatsPerMeasure ?? 4} contando il valore delle figure.`;
    }
    if (puzzle.challengeMode === "scale-step") {
      return "Gradi della scala: leggi la nota mostrata e scegli quella che la segue (o precede) nella scala Do-Re-Mi-Fa-Sol-La-Si.";
    }
    if (puzzle.challengeMode === "note-duration") {
      return "Valore delle figure: confronta le durate delle figure musicali e rispondi alla domanda.";
    }
    if (puzzle.answerMode === "note-name") {
      return "Obiettivo: riconosci il nome della nota il più rapidamente possibile. Guarda la chiave, trova la nota guida e conta linee/spazi.";
    }
    return "Obiettivo: riconosci nome e ottava. Il numero indica il registro: Do4 è il Do centrale; La4 è il La sopra il Do centrale.";
  },

  modeExplanation(puzzle: GeneratedMusicPuzzle): string {
    if (puzzle.challengeMode === "auditory-note") {
      return "Modalità ascolto: il suono sostituisce il pentagramma. Prima colloca l'altezza, poi scegli il nome.";
    }
    if (puzzle.challengeMode === "auditory-interval") {
      return "Modalità intervallo a orecchio: non serve vedere le note; devi percepire direzione e ampiezza del salto.";
    }
    if (puzzle.challengeMode === "interval-jump") {
      return "Modalità melodia: prima stabilisci la direzione, poi conta i gradi includendo nota iniziale e finale.";
    }
    if (puzzle.challengeMode === "rhythm-gap") {
      return "Modalità ritmo: ogni figura occupa una durata; la battuta è completa solo quando la somma coincide con il metro.";
    }
    if (puzzle.challengeMode === "scale-step") {
      return "Modalità scala: la successione dei gradi è Do-Re-Mi-Fa-Sol-La-Si e poi ricomincia. Muoviti di un grado dalla nota mostrata.";
    }
    if (puzzle.challengeMode === "note-duration") {
      return "Modalità durate: ogni figura vale la metà della precedente (semibreve 4, minima 2, semiminima 1, croma ½).";
    }
    if (puzzle.answerMode === "note-name") {
      return "Modalità rapida: conta la posizione e scegli solo il nome della nota. L'ottava verrà calibrata nelle profondità avanzate.";
    }
    return "Modalità avanzata: stesso nome in registri diversi non basta; controlla anche le linee addizionali per scegliere l'ottava.";
  },

  drawSessionHeader(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMusicPuzzle,
    session: MusicTrainingSession,
  ): void {
    overlay.add(scene.add.rectangle(608, 92, 1128, 84, 0x06131c, 0.64).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(scene.add.text(56, 66, `${puzzle.difficultyLabel.toUpperCase()} | Sprint a tempo fisso: ${formatDuration(session.durationMs)}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(56, 96, MusicConsole.promptText(puzzle), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 850 },
      lineSpacing: 4,
    }));
    overlay.add(scene.add.text(970, 70, `Corrette ${session.correct}  |  Errori ${session.wrong}  |  Serie ${session.streak}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
    const remainingRatio = Phaser.Math.Clamp(1 - MusicConsole.sprintElapsedMs(session) / session.durationMs, 0, 1);
    overlay.add(scene.add.rectangle(906, 112, 284, 10, 0x1b3140, 0.82).setStrokeStyle(1, 0x6be7d6, 0.22));
    overlay.add(scene.add.rectangle(906 - 142 + 142 * remainingRatio, 112, 284 * remainingRatio, 10, remainingRatio < 0.2 ? 0xff8a8a : 0x6be7d6, 0.88));
    overlay.add(scene.add.text(970, 126, `Punti sprint: ${session.netScore}  |  Risposte: ${session.answered}`, {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#c7dce7",
    }).setOrigin(0.5));
  },

  drawStaff(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number, showCoach = true): void {
    if (MusicConsole.isAuditoryPuzzle(puzzle)) {
      drawListeningBoard(scene, overlay, puzzle, centerX, centerY, showCoach);
      return;
    }
    if ((puzzle.challengeMode ?? "note-hunt") === "rhythm-gap" && puzzle.rhythmPattern) {
      drawRhythmBoard(scene, overlay, puzzle, centerX, centerY, showCoach);
      return;
    }
    if (puzzle.challengeMode === "note-duration" && puzzle.rhythmPattern) {
      drawDurationBoard(scene, overlay, puzzle, centerX, centerY, showCoach);
      return;
    }
    overlay.add(scene.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
    overlay.add(scene.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
    overlay.add(scene.add.image(centerX, centerY, "soft-glow").setTint(0x6be7d6).setAlpha(0.08).setScale(4.2, 2.2));
    overlay.add(scene.add.rectangle(centerX, centerY - 2, 536, 190, 0x02070b, 0.28).setStrokeStyle(1, 0xf7d37a, 0.12));
    overlay.add(scene.add.text(centerX - 260, centerY - 142, `${puzzle.challengeMode === "interval-jump" ? "Salto melodico" : puzzle.challengeMode === "scale-step" ? "Gradi della scala" : "Caccia alla nota"} · ${puzzle.clef === "treble" ? "chiave di violino" : "chiave di basso"}`, {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    const lineSpacing = 28;
    const staffLeft = centerX - 220;
    const staffRight = centerX + 232;
    const topY = centerY - 58;
    for (let index = 0; index < 5; index += 1) {
      const y = topY + index * lineSpacing;
      overlay.add(scene.add.rectangle((staffLeft + staffRight) / 2, y, staffRight - staffLeft, 2, 0x9ff5e9, 0.86));
    }
    const guideY = puzzle.clef === "bass" ? topY + lineSpacing : topY + lineSpacing * 3;
    overlay.add(scene.add.rectangle((staffLeft + staffRight) / 2, guideY, staffRight - staffLeft, 4, 0xf7d37a, 0.16));
    const clefAnchorY = puzzle.clef === "bass" ? topY + lineSpacing : topY + lineSpacing * 3;
    drawClef(scene, overlay, puzzle.clef, staffLeft + 46, clefAnchorY);
    const isInterval = puzzle.challengeMode === "interval-jump" && puzzle.secondaryNote;
    const noteX = isInterval ? centerX + 20 : centerX + 96;
    drawPitchNote(scene, overlay, noteX, topY, lineSpacing, puzzle.staffPosition, puzzle.ledgerLines, 0xf5fbff);
    if (isInterval && puzzle.secondaryNote) {
      const secondX = centerX + 178;
      drawPitchNote(scene, overlay, secondX, topY, lineSpacing, puzzle.secondaryNote.staffPosition, puzzle.secondaryNote.ledgerLines, 0xf7d37a);
      const arrowY = centerY + 76;
      overlay.add(scene.add.rectangle((noteX + secondX) / 2, arrowY, secondX - noteX - 32, 3, 0x6be7d6, 0.76));
      overlay.add(scene.add.triangle(secondX - 12, arrowY, 0, -7, 14, 0, 0, 7, 0x6be7d6, 0.9));
      overlay.add(scene.add.text(noteX, centerY + 88, "1", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
      overlay.add(scene.add.text(secondX, centerY + 88, "2", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    }
    if (showCoach) {
      overlay.add(scene.add.text(centerX - 260, centerY + 108, [
        isInterval ? "Confronta nota 1 e nota 2" : `Posizione: ${puzzle.staffPosition % 2 === 0 ? "linea" : "spazio"}`,
        isInterval ? "Risposta: direzione + intervallo" : puzzle.ledgerLines.length > 0 ? `Linee addizionali: ${puzzle.ledgerLines.length}` : "Nessuna linea addizionale",
        isInterval ? "Conta i passaggi linea-spazio" : puzzle.answerMode === "note-name" ? "Risposta: nome della nota" : "Risposta: nome nota + ottava",
      ].join("  |  "), {
        fontFamily: "Inter, Arial",
        fontSize: "12px",
        color: "#d9eaf1",
        wordWrap: { width: 520 },
      }));
      overlay.add(scene.add.text(centerX - 260, centerY + 132, MusicConsole.modeExplanation(puzzle), {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9aaab0",
        wordWrap: { width: 520 },
        lineSpacing: 2,
      }));
    }
  },

  drawSupport(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMusicPuzzle,
    session: MusicTrainingSession,
    showCoach = true,
    visibleHint?: string,
  ): void {
    overlay.add(scene.add.rectangle(916, 282, 508, 206, 0x07151d, 0.88).setStrokeStyle(1, 0x6be7d6, 0.24));
    const supportTitle = puzzle.challengeMode === "rhythm-gap"
      ? "2 · Completa la battuta"
      : MusicConsole.isAuditoryPuzzle(puzzle)
        ? "2 · Ascolta e riconosci"
      : puzzle.challengeMode === "interval-jump"
        ? "2 · Segui il movimento"
        : "2 · Scegli solo dopo aver contato";
    overlay.add(scene.add.text(682, 196, supportTitle, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    overlay.add(scene.add.text(682, 224, showCoach
      ? `${puzzle.method}\n\n${visibleHint ? `INDIZIO ATTIVO: ${visibleHint}` : session.feedback || "Non serve correre a caso: rispondi solo quando hai agganciato la chiave e contato linee/spazi."}`
      : visibleHint ? `INDIZIO ATTIVO: ${visibleHint}` : session.feedback, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 456 },
      lineSpacing: 4,
    }));
    if (showCoach) {
      overlay.add(scene.add.text(682, 310, `Scopo: ${puzzle.learningPurpose}`, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9aaab0",
        wordWrap: { width: 456 },
        lineSpacing: 3,
      }));
    }
    overlay.add(scene.add.text(682, 366, puzzle.conceptTags.map((tag) => `#${tag}`).join("  "), {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      wordWrap: { width: 456 },
    }));
  },

  drawSprintScreen(
    scene: Phaser.Scene,
    overlay: Phaser.GameObjects.Container,
    puzzle: GeneratedMusicPuzzle,
    session: MusicTrainingSession,
    options: MusicSprintScreenOptions,
  ): Phaser.GameObjects.Text {
    MusicConsole.drawSessionHeader(scene, overlay, puzzle, session);
    MusicConsole.drawStaff(scene, overlay, puzzle, 350, 328, options.showCoach);
    MusicConsole.drawSupport(scene, overlay, puzzle, session, options.showCoach, options.activeHint);

    const timerText = scene.add.text(922, 152, "", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5);
    overlay.add(timerText);
    options.onStartCountdown(timerText);

    puzzle.choices.forEach((choice, index) => {
      const x = 794 + (index % 2) * 244;
      const y = 418 + Math.floor(index / 2) * 72;
      overlay.add(new Button(scene, x, y, choice.label, () => {
        if (session.locked || session.summaryOpen) {
          return;
        }
        if (MusicConsole.sprintExpired(session)) {
          options.onExpired();
          return;
        }
        options.onAnswer(choice.isCorrect, choice.feedback, choice.label);
      }, {
        width: 218,
        height: 60,
        fontSize: ["note-hunt", "auditory-note"].includes(puzzle.challengeMode ?? "note-hunt") && puzzle.answerMode === "note-name" ? 22 : 14,
        fill: 0x263743,
        hoverFill: 0x23556a,
      }));
    });

    if (options.showCoach) {
      addMethodStrip(scene, overlay, 56, 586, 550, "Metodo", puzzle.methodSteps);
    } else {
      const compactStatus = options.activeHint ? `Indizio attivo: ${options.activeHint}` : session.feedback;
      if (compactStatus) {
        overlay.add(scene.add.rectangle(331, 626, 550, 78, 0x07151d, 0.74).setStrokeStyle(1, 0xf7d37a, 0.18));
        overlay.add(scene.add.text(78, 600, compactStatus, {
          fontFamily: "Inter, Arial",
          fontSize: "12px",
          color: options.activeHint ? "#f7d37a" : "#d9eaf1",
          wordWrap: { width: 500, useAdvancedWrap: true },
          lineSpacing: 3,
        }));
      }
    }

    overlay.add(new Button(scene, 778, 598, puzzle.audioPrompt?.replayLabel ?? "Ascolta sfida", () => MusicConsole.previewChallenge(puzzle), {
      width: 220, height: 46, fontSize: 14, fill: 0x173b36,
    }));
    if ((puzzle.challengeMode === "interval-jump" || puzzle.challengeMode === "auditory-interval") && puzzle.secondaryNote) {
      overlay.add(new Button(scene, 778, 650, "Nota 1", () => MusicConsole.playNote(puzzle.noteName, puzzle.octave), {
        width: 104, height: 38, fontSize: 12, fill: 0x263743,
      }));
      overlay.add(new Button(scene, 894, 650, "Nota 2", () => MusicConsole.playNote(puzzle.secondaryNote!.noteName, puzzle.secondaryNote!.octave), {
        width: 104, height: 38, fontSize: 12, fill: 0x263743,
      }));
    } else if (puzzle.challengeMode === "note-hunt" || puzzle.challengeMode === "scale-step") {
      overlay.add(new Button(scene, 778, 650, "Suona nota", () => MusicConsole.playNote(puzzle.noteName, puzzle.octave), {
        width: 220, height: 38, fontSize: 12, fill: 0x263743,
      }));
    }
    overlay.add(new Button(scene, 1040, 598, options.hintLabel, options.onHint, {
      width: 240, height: 46, fontSize: 14, fill: 0x263743,
    }));

    return timerText;
  },
};

function drawPitchNote(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  x: number,
  topY: number,
  lineSpacing: number,
  staffPosition: number,
  ledgerLines: number[],
  color: number,
): void {
  const y = topY + staffPosition * (lineSpacing / 2);
  ledgerLines.forEach((position) => {
    overlay.add(scene.add.rectangle(x, topY + position * (lineSpacing / 2), 72, 2, 0xf7d37a, 0.88));
  });
  overlay.add(scene.add.ellipse(x, y, 34, 24, color, 1).setRotation(-0.42).setStrokeStyle(2, 0xf7d37a, 0.9));
  overlay.add(scene.add.rectangle(x + 18, y - 42, 3, 86, color, 0.94));
}

function drawRhythmBoard(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number, showCoach = true): void {
  const pattern = puzzle.rhythmPattern!;
  overlay.add(scene.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
  overlay.add(scene.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
  overlay.add(scene.add.text(centerX - 260, centerY - 142, `Battito mancante · battuta da ${pattern.beatsPerMeasure}`, {
    fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9", fontStyle: "bold",
  }));
  if (showCoach) {
    overlay.add(scene.add.text(centerX - 260, centerY - 108, "Completa la casella ? senza superare la battuta.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1",
    }));
  }
  const gap = Math.min(112, 474 / pattern.cells.length);
  const startX = centerX - ((pattern.cells.length - 1) * gap) / 2;
  pattern.cells.forEach((cell, index) => {
    const x = startX + index * gap;
    overlay.add(scene.add.rectangle(x, centerY - 6, gap - 12, 120, cell.missing ? 0x253b46 : 0x102a35, 0.96)
      .setStrokeStyle(2, cell.missing ? 0xf7d37a : 0x6be7d6, 0.8));
    overlay.add(scene.add.text(x, centerY - 18, cell.missing ? "?" : cell.label, {
      fontFamily: "Georgia, 'Times New Roman', serif", fontSize: cell.missing ? "48px" : "54px", color: cell.missing ? "#f7d37a" : "#f5fbff", fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(scene.add.text(x, centerY + 42, cell.missing ? "manca" : `${cell.beats}`, {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#9aaab0",
    }).setOrigin(0.5));
  });
  if (showCoach) {
    overlay.add(scene.add.text(centerX - 260, centerY + 108, "Legenda: ♪ = ½   ♩ = 1   𝅗𝅥 = 2   𝅝 = 4 battiti", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#f7d37a",
    }));
    overlay.add(scene.add.text(centerX - 260, centerY + 136, `Totale richiesto: ${pattern.beatsPerMeasure} battiti. Somma le figure visibili e trova la differenza.`, {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#9aaab0", wordWrap: { width: 520 },
    }));
  }
}

function drawDurationBoard(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number, showCoach = true): void {
  const cells = puzzle.rhythmPattern?.cells ?? [];
  overlay.add(scene.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
  overlay.add(scene.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.92).setStrokeStyle(2, 0x6be7d6, 0.26));
  overlay.add(scene.add.text(centerX - 260, centerY - 142, "Valore delle figure · durata relativa", {
    fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9", fontStyle: "bold",
  }));
  if (showCoach) {
    overlay.add(scene.add.text(centerX - 260, centerY - 112, "Più lunga è la barra, più dura la figura.", {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#d9eaf1",
    }));
  }
  const rowHeight = Math.min(56, 240 / Math.max(1, cells.length));
  const maxBeats = 4;
  cells.forEach((cell, index) => {
    const y = centerY - 70 + index * rowHeight;
    const barWidth = Math.max(28, (cell.beats / maxBeats) * 360);
    overlay.add(scene.add.text(centerX - 250, y, cell.label, {
      fontFamily: "Inter, Arial", fontSize: "15px", color: "#f5fbff", fontStyle: "bold",
    }).setOrigin(0, 0.5));
    overlay.add(scene.add.rectangle(centerX - 70, y, barWidth, rowHeight - 16, 0x1f5a51, 0.95)
      .setOrigin(0, 0.5).setStrokeStyle(2, 0x6be7d6, 0.8));
    overlay.add(scene.add.text(centerX - 70 + barWidth + 10, y, cell.beats === 0.5 ? "½" : `${cell.beats}`, {
      fontFamily: "Inter, Arial", fontSize: "13px", color: "#9aaab0",
    }).setOrigin(0, 0.5));
  });
  if (showCoach) {
    overlay.add(scene.add.text(centerX - 260, centerY + 128, "Semibreve 4 · Minima 2 · Semiminima 1 · Croma ½ (ogni figura vale metà della precedente).", {
      fontFamily: "Inter, Arial", fontSize: "11px", color: "#f7d37a", wordWrap: { width: 520 },
    }));
  }
}

function drawListeningBoard(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, puzzle: GeneratedMusicPuzzle, centerX: number, centerY: number, showCoach = true): void {
  const isInterval = puzzle.challengeMode === "auditory-interval" && puzzle.secondaryNote;
  overlay.add(scene.add.rectangle(centerX + 8, centerY + 10, 590, 326, 0x000000, 0.24));
  overlay.add(scene.add.rectangle(centerX, centerY, 590, 326, 0x07151d, 0.94).setStrokeStyle(2, 0xf7d37a, 0.34));
  overlay.add(scene.add.image(centerX, centerY, "soft-glow").setTint(0xf7d37a).setAlpha(0.1).setScale(4.4, 2.3));
  overlay.add(scene.add.text(centerX - 260, centerY - 142, isInterval ? "Ascolto intervallo · pentagramma nascosto" : "Ascolto nota · pentagramma nascosto", {
    fontFamily: "Inter, Arial",
    fontSize: "16px",
    color: "#f7d37a",
    fontStyle: "bold",
  }));
  overlay.add(scene.add.text(centerX - 260, centerY - 112, isInterval
    ? "Ascolta le due note: devi riconoscere direzione e distanza del salto."
    : "Ascolta il suono: devi riconoscere il nome della nota senza guardare la posizione.", {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#d9eaf1",
    wordWrap: { width: 520 },
  }));

  const g = scene.add.graphics();
  const waveLeft = centerX - 236;
  const waveTop = centerY - 34;
  const waveWidth = 472;
  const centerLine = waveTop + 58;
  g.lineStyle(2, 0x6be7d6, 0.82);
  g.beginPath();
  for (let step = 0; step <= 96; step += 1) {
    const x = waveLeft + (step / 96) * waveWidth;
    const phrase = isInterval && step > 48 ? 1.48 : 1;
    const y = centerLine + Math.sin(step * 0.36 * phrase) * (18 + 6 * Math.sin(step * 0.09));
    if (step === 0) g.moveTo(x, y);
    else g.lineTo(x, y);
  }
  g.strokePath();
  g.lineStyle(1, 0xf7d37a, 0.2);
  for (let guide = 0; guide < 5; guide += 1) {
    const y = waveTop + 8 + guide * 26;
    g.strokeLineShape(new Phaser.Geom.Line(waveLeft, y, waveLeft + waveWidth, y));
  }
  overlay.add(g);

  const badgeY = centerY + 76;
  overlay.add(scene.add.rectangle(centerX - 120, badgeY, 190, 54, 0x102a35, 0.94).setStrokeStyle(1, 0x6be7d6, 0.54));
  overlay.add(scene.add.text(centerX - 120, badgeY, isInterval ? "1ª nota" : "suono singolo", {
    fontFamily: "Inter, Arial",
    fontSize: "14px",
    color: "#f5fbff",
    fontStyle: "bold",
  }).setOrigin(0.5));
  if (isInterval) {
    overlay.add(scene.add.rectangle(centerX + 120, badgeY, 190, 54, 0x102a35, 0.94).setStrokeStyle(1, 0xf7d37a, 0.58));
    overlay.add(scene.add.text(centerX + 120, badgeY, "2ª nota", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    overlay.add(scene.add.triangle(centerX, badgeY, -10, -7, 12, 0, -10, 7, 0xf7d37a, 0.9));
  }
  if (showCoach) {
    overlay.add(scene.add.text(centerX - 260, centerY + 126, isInterval
      ? "Metodo: prima direzione (sale/scende), poi ampiezza. Riascolta per confermare, non per tentare."
      : "Metodo: colloca mentalmente l'altezza nella scala Do-Re-Mi-Fa-Sol-La-Si, poi scegli.", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#9aaab0",
      wordWrap: { width: 520 },
      lineSpacing: 3,
    }));
  }
}

function drawClef(scene: Phaser.Scene, overlay: Phaser.GameObjects.Container, clef: GeneratedMusicPuzzle["clef"], x: number, y: number): void {
  if (clef === "treble") {
    const symbol = scene.add.text(x, y, "𝄞", {
      fontFamily: "Georgia, 'Times New Roman', serif",
      fontSize: "96px",
      color: "#f7d37a",
    }).setOrigin(0.5, 0.55);
    symbol.setY(y - 2);
    overlay.add(symbol);
    overlay.add(scene.add.circle(x + 1, y, 4, 0xf5fbff, 0.85));
    return;
  }
  const g = scene.add.graphics();
  g.lineStyle(4, 0xf7d37a, 0.92);
  g.beginPath();
  g.arc(x - 12, y, 34, Phaser.Math.DegToRad(248), Phaser.Math.DegToRad(88), false);
  g.strokePath();
  g.fillStyle(0xf7d37a, 0.95);
  g.fillCircle(x - 28, y, 8);
  g.fillCircle(x + 30, y - 14, 4);
  g.fillCircle(x + 30, y + 14, 4);
  overlay.add(g);
  overlay.add(scene.add.circle(x - 28, y, 3, 0xf5fbff, 0.72));
}
