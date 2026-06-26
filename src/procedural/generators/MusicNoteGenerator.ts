import type { DifficultyLevel, GeneratedMusicPuzzle, MusicClef, MusicMinigameType, MusicNoteName } from "../ProceduralTypes";
import type { Random } from "../Random";

type MusicNote = {
  name: MusicNoteName;
  octave: number;
  treblePosition: number;
  bassPosition: number;
};

const diatonicNotes: MusicNote[] = [
  { name: "Do", octave: 2, treblePosition: 24, bassPosition: 12 },
  { name: "Re", octave: 2, treblePosition: 23, bassPosition: 11 },
  { name: "Mi", octave: 2, treblePosition: 22, bassPosition: 10 },
  { name: "Fa", octave: 2, treblePosition: 21, bassPosition: 9 },
  { name: "Sol", octave: 2, treblePosition: 20, bassPosition: 8 },
  { name: "La", octave: 2, treblePosition: 19, bassPosition: 7 },
  { name: "Si", octave: 2, treblePosition: 18, bassPosition: 6 },
  { name: "Do", octave: 3, treblePosition: 17, bassPosition: 5 },
  { name: "Re", octave: 3, treblePosition: 16, bassPosition: 4 },
  { name: "Mi", octave: 3, treblePosition: 15, bassPosition: 3 },
  { name: "Fa", octave: 3, treblePosition: 14, bassPosition: 2 },
  { name: "Sol", octave: 3, treblePosition: 13, bassPosition: 1 },
  { name: "La", octave: 3, treblePosition: 12, bassPosition: 0 },
  { name: "Si", octave: 3, treblePosition: 11, bassPosition: -1 },
  { name: "Do", octave: 4, treblePosition: 10, bassPosition: -2 },
  { name: "Re", octave: 4, treblePosition: 9, bassPosition: -3 },
  { name: "Mi", octave: 4, treblePosition: 8, bassPosition: -4 },
  { name: "Fa", octave: 4, treblePosition: 7, bassPosition: -5 },
  { name: "Sol", octave: 4, treblePosition: 6, bassPosition: -6 },
  { name: "La", octave: 4, treblePosition: 5, bassPosition: -7 },
  { name: "Si", octave: 4, treblePosition: 4, bassPosition: -8 },
  { name: "Do", octave: 5, treblePosition: 3, bassPosition: -9 },
  { name: "Re", octave: 5, treblePosition: 2, bassPosition: -10 },
  { name: "Mi", octave: 5, treblePosition: 1, bassPosition: -11 },
  { name: "Fa", octave: 5, treblePosition: 0, bassPosition: -12 },
  { name: "Sol", octave: 5, treblePosition: -1, bassPosition: -13 },
];

export class MusicNoteGenerator {
  generate(random: Random, difficultyLevel: DifficultyLevel = 1, preferredModes: MusicMinigameType[] = []): GeneratedMusicPuzzle {
    const available: MusicMinigameType[] = difficultyLevel <= 1
      ? ["note-hunt", "auditory-note", "rhythm-gap", "note-duration"]
      : difficultyLevel <= 3
        ? ["note-hunt", "auditory-note", "interval-jump", "rhythm-gap", "note-duration", "scale-step"]
        : ["note-hunt", "auditory-note", "auditory-interval", "interval-jump", "rhythm-gap", "note-duration", "scale-step"];
    const requested = preferredModes.filter((mode) => available.includes(mode) || preferredModes.length === 1);
    const mode = random.pick(requested.length > 0 ? requested : available);
    if (mode === "auditory-note") return this.buildAuditoryNote(random, difficultyLevel);
    if (mode === "auditory-interval") return this.buildAuditoryInterval(random, difficultyLevel);
    if (mode === "interval-jump") return this.buildIntervalJump(random, difficultyLevel);
    if (mode === "rhythm-gap") return this.buildRhythmGap(random, difficultyLevel);
    if (mode === "scale-step") return this.buildScaleStep(random, difficultyLevel);
    if (mode === "note-duration") return this.buildNoteDuration(random, difficultyLevel);
    return this.buildNoteHunt(random, difficultyLevel);
  }

  private buildAuditoryNote(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const clef = this.pickClef(random, difficultyLevel);
    const note = random.pick(this.notePool(difficultyLevel, clef));
    const staffPosition = clef === "treble" ? note.treblePosition : note.bassPosition;
    const answerMode = difficultyLevel >= 7 ? "note-and-octave" : "note-name";
    const choices = this.buildChoices(random, note, clef, staffPosition, answerMode).map((choice) => ({
      ...choice,
      feedback: choice.isCorrect
        ? `Corretto: hai riconosciuto all'ascolto ${choice.label}.`
        : "Riascolta: confronta se il suono è più acuto o più grave rispetto alla nota che avevi in mente.",
    }));
    return {
      id: `music-ear-note-${clef}-${note.name.toLowerCase()}${note.octave}`,
      title: "Orecchio: riconosci la nota",
      challengeMode: "auditory-note",
      clef,
      noteName: note.name,
      octave: note.octave,
      staffPosition,
      ledgerLines: this.ledgerLinesFor(staffPosition),
      timeLimitMs: this.timeLimitMs(difficultyLevel, this.outsideStaffDistance(staffPosition)) + 2_000,
      answerMode,
      audioPrompt: {
        kind: "single-note",
        hiddenStaff: true,
        replayLabel: "Riascolta nota",
      },
      choices,
      hints: [
        "Ascolta prima l'altezza: suono grave = nota più bassa, suono acuto = nota più alta.",
        "Se hai dubbi, riascolta una volta e confronta mentalmente con Do-Re-Mi-Fa-Sol-La-Si.",
        `La nota corretta è ${this.noteLabel(note, answerMode)}.`,
      ],
      competencies: ["musica.orecchio", "musica.letturaNote", `musica.${clef === "treble" ? "chiaveViolino" : "chiaveBasso"}`],
      difficultyLabel: `Livello ${difficultyLevel}/8 - riconoscimento uditivo`,
      learningPurpose: "Collegare il nome della nota alla sua altezza sonora, non solo alla posizione sul pentagramma.",
      method: "Ascolta, colloca il suono come più grave o più acuto, poi scegli il nome della nota. Usa il riascolto per verificare, non per cliccare a caso.",
      methodSteps: ["ascolta", "stima altezza", "confronta mentalmente", "scegli nota"],
      conceptTags: ["orecchio", "altezza", answerMode === "note-and-octave" ? "ottava" : "nome nota"],
    };
  }

  private buildAuditoryInterval(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const clef = this.pickClef(random, difficultyLevel);
    const pool = this.notePool(difficultyLevel, clef);
    const maxDistance = Math.min(difficultyLevel >= 6 ? 5 : 4, Math.max(1, pool.length - 1));
    let first = random.pick(pool);
    let second = first;
    for (let attempt = 0; attempt < 18 && second === first; attempt += 1) {
      const firstIndex = pool.indexOf(first);
      const distance = random.integer(1, maxDistance);
      const direction = random.bool() ? 1 : -1;
      const targetIndex = firstIndex + direction * distance;
      if (targetIndex >= 0 && targetIndex < pool.length) second = pool[targetIndex];
      else first = random.pick(pool);
    }
    if (second === first) second = pool[first === pool[0] ? 1 : pool.indexOf(first) - 1];
    const firstPosition = clef === "treble" ? first.treblePosition : first.bassPosition;
    const secondPosition = clef === "treble" ? second.treblePosition : second.bassPosition;
    const steps = Math.abs(diatonicNotes.indexOf(second) - diatonicNotes.indexOf(first));
    const direction = diatonicNotes.indexOf(second) > diatonicNotes.indexOf(first) ? "Sale" : "Scende";
    const intervalNames = ["unisono", "seconda", "terza", "quarta", "quinta", "sesta"];
    const interval = intervalNames[Math.min(steps, intervalNames.length - 1)];
    const correct = `${direction}: ${interval}`;
    const alternatives = new Set<string>();
    alternatives.add(`${direction === "Sale" ? "Scende" : "Sale"}: ${interval}`);
    alternatives.add(`${direction}: ${intervalNames[Math.max(1, Math.min(5, steps + 1))]}`);
    alternatives.add(`${direction}: ${intervalNames[Math.max(1, steps - 1)]}`);
    for (const label of ["Sale: seconda", "Scende: seconda", "Sale: terza", "Scende: terza", "Sale: quarta", "Scende: quarta"]) {
      if (alternatives.size >= 3) break;
      if (label !== correct) alternatives.add(label);
    }
    const choices = random.shuffle([
      { id: "correct", label: correct, isCorrect: true, feedback: `Corretto: all'ascolto la seconda nota ${direction.toLowerCase()} di ${interval}.` },
      ...[...alternatives].filter((label) => label !== correct).slice(0, 3).map((label, index) => ({
        id: `distractor-${index}`,
        label,
        isCorrect: false,
        feedback: `Riascolta le due note: la seconda è ${direction.toLowerCase()} e la distanza è ${interval}.`,
      })),
    ]);
    return {
      id: `music-ear-interval-${clef}-${first.name}${first.octave}-${second.name}${second.octave}`,
      title: "Orecchio: riconosci l'intervallo",
      challengeMode: "auditory-interval",
      clef,
      noteName: first.name,
      octave: first.octave,
      staffPosition: firstPosition,
      ledgerLines: this.ledgerLinesFor(firstPosition),
      secondaryNote: { noteName: second.name, octave: second.octave, staffPosition: secondPosition, ledgerLines: this.ledgerLinesFor(secondPosition) },
      timeLimitMs: this.timeLimitMs(difficultyLevel, Math.max(this.outsideStaffDistance(firstPosition), this.outsideStaffDistance(secondPosition))) + 2_000,
      answerMode: "note-name",
      audioPrompt: {
        kind: "interval",
        hiddenStaff: true,
        replayLabel: "Riascolta intervallo",
      },
      choices,
      hints: [
        "Prima decidi la direzione: la seconda nota sale o scende?",
        "Poi valuta la distanza: note vicine = seconda; un salto più netto = terza, quarta o quinta.",
        `La risposta corretta è ${correct}.`,
      ],
      competencies: ["musica.orecchio", "musica.intervalli", "musica.ascoltoVisivo"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - intervalli a orecchio`,
      learningPurpose: "Riconoscere direzione e ampiezza di un salto melodico partendo dal suono.",
      method: "Ascolta le due note in sequenza: prima stabilisci se la seconda sale o scende, poi stima quanto è ampio il salto.",
      methodSteps: ["ascolta nota 1", "ascolta nota 2", "direzione", "distanza"],
      conceptTags: ["orecchio", "intervalli", direction.toLowerCase()],
    };
  }

  private buildNoteHunt(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const clef = this.pickClef(random, difficultyLevel);
    const note = random.pick(this.notePool(difficultyLevel, clef));
    const staffPosition = clef === "treble" ? note.treblePosition : note.bassPosition;
    const answerMode = difficultyLevel >= 7 ? "note-and-octave" : "note-name";
    const choices = this.buildChoices(random, note, clef, staffPosition, answerMode);
    return {
      id: `music-${clef}-${note.name.toLowerCase()}${note.octave}-${staffPosition}`,
      title: "Caccia alla nota",
      challengeMode: "note-hunt",
      clef,
      noteName: note.name,
      octave: note.octave,
      staffPosition,
      ledgerLines: this.ledgerLinesFor(staffPosition),
      timeLimitMs: this.timeLimitMs(difficultyLevel, this.outsideStaffDistance(staffPosition)),
      answerMode,
      choices,
      hints: this.hintsFor(clef, staffPosition, note),
      competencies: ["musica.pentagramma", `musica.${clef === "treble" ? "chiaveViolino" : "chiaveBasso"}`, "musica.letturaNote"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - ${this.levelName(difficultyLevel)}`,
      learningPurpose: answerMode === "note-name"
        ? "Riconoscere rapidamente il nome della nota sul pentagramma."
        : "Riconoscere rapidamente nome e registro della nota, includendo l'ottava.",
      method: clef === "treble"
        ? "In chiave di violino parti dal Sol sulla seconda linea o dal Do centrale sotto il pentagramma, poi conta linee e spazi."
        : "In chiave di basso parti dal Fa sulla quarta linea o dal Do centrale sopra il pentagramma, poi conta linee e spazi.",
      methodSteps: answerMode === "note-name"
        ? ["chiave", "nota guida", "linea/spazio", "nome nota"]
        : ["chiave", "nota guida", "linee addizionali", "nome + ottava"],
      conceptTags: [
        clef === "treble" ? "chiave di violino" : "chiave di basso",
        this.ledgerLinesFor(staffPosition).length > 0 ? "linee addizionali" : "pentagramma",
        this.isStaffLine(staffPosition) ? "linea" : "spazio",
      ],
    };
  }

  private buildScaleStep(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const order: MusicNoteName[] = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"];
    const clef = this.pickClef(random, difficultyLevel);
    const note = random.pick(this.notePool(difficultyLevel, clef));
    const staffPosition = clef === "treble" ? note.treblePosition : note.bassPosition;
    const startIndex = order.indexOf(note.name);
    const up = difficultyLevel >= 4 ? random.bool() : true;
    const direction = up ? 1 : -1;
    const correctName = order[(startIndex + direction + order.length) % order.length];
    const distractors = order.filter((name) => name !== correctName && name !== note.name);
    const chosen = random.shuffle(distractors).slice(0, 3);
    const choices = random.shuffle([
      { id: "correct", label: correctName, isCorrect: true, feedback: `Corretto: ${up ? "salendo" : "scendendo"} dopo ${note.name} viene ${correctName}.` },
      ...chosen.map((name, index) => ({ id: `distractor-${index}`, label: name, isCorrect: false, feedback: `No: ${name} non è il grado ${up ? "successivo" : "precedente"} dopo ${note.name}.` })),
    ]);
    return {
      id: `music-scale-${clef}-${note.name}${note.octave}-${up ? "up" : "down"}`,
      title: "Gradi della scala",
      challengeMode: "scale-step",
      clef,
      noteName: note.name,
      octave: note.octave,
      staffPosition,
      ledgerLines: this.ledgerLinesFor(staffPosition),
      timeLimitMs: this.timeLimitMs(difficultyLevel, this.outsideStaffDistance(staffPosition)),
      answerMode: "note-name",
      choices,
      hints: [
        "Ricorda la successione: Do Re Mi Fa Sol La Si, poi di nuovo Do.",
        `Leggi prima la nota mostrata: è ${note.name}.`,
        `${up ? "Sali" : "Scendi"} di un grado: la risposta è ${correctName}.`,
      ],
      competencies: ["musica.pentagramma", "musica.scale", "musica.letturaNote"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - gradi della scala`,
      learningPurpose: "Collegare la lettura della nota alla successione dei gradi della scala.",
      method: "Leggi la nota sul pentagramma, poi muoviti di un grado nella scala Do-Re-Mi-Fa-Sol-La-Si.",
      methodSteps: ["leggi la nota", "ricorda la successione", up ? "sali di un grado" : "scendi di un grado", "scegli il nome"],
      conceptTags: ["scala", "gradi", up ? "ascendente" : "discendente"],
    };
  }

  private buildNoteDuration(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const figures = [
      { label: "Semibreve", beats: 4 },
      { label: "Minima", beats: 2 },
      { label: "Semiminima", beats: 1 },
      { label: "Croma", beats: 0.5 },
    ];
    const count = difficultyLevel >= 4 ? 4 : 3;
    const cells = random.shuffle(figures).slice(0, count);
    const askBeats = difficultyLevel >= 3 && random.bool();
    const beatsLabel = (beats: number): string => beats === 0.5 ? "mezzo movimento" : `${beats} movimenti`;
    let question: string;
    let correctLabel: string;
    let choiceLabels: string[];
    let explanation: string;
    if (askBeats) {
      const marked = random.pick(cells);
      question = `Quanti movimenti dura la ${marked.label}?`;
      correctLabel = beatsLabel(marked.beats);
      choiceLabels = Array.from(new Set([correctLabel, ...figures.map((f) => beatsLabel(f.beats))])).slice(0, 4);
      explanation = `La ${marked.label} dura ${beatsLabel(marked.beats)} (in 4/4 la semibreve vale 4).`;
    } else {
      const longest = random.bool();
      const sorted = [...cells].sort((a, b) => b.beats - a.beats);
      const target = longest ? sorted[0] : sorted[sorted.length - 1];
      question = `Quale figura dura di ${longest ? "più" : "meno"}?`;
      correctLabel = target.label;
      choiceLabels = cells.map((cell) => cell.label);
      explanation = `${target.label} dura ${beatsLabel(target.beats)}: è la figura ${longest ? "più lunga" : "più breve"} tra quelle mostrate.`;
    }
    while (choiceLabels.length < 4) {
      const extra = figures.map((f) => askBeats ? beatsLabel(f.beats) : f.label).find((label) => !choiceLabels.includes(label));
      if (!extra) break;
      choiceLabels.push(extra);
    }
    const choices = random.shuffle(choiceLabels.slice(0, 4).map((label, index) => ({
      id: label === correctLabel ? "correct" : `distractor-${index}`,
      label,
      isCorrect: label === correctLabel,
      feedback: label === correctLabel ? `Corretto: ${explanation}` : "Confronta le durate: la semibreve dura il doppio della minima, e così via.",
    })));
    return {
      id: `music-duration-${difficultyLevel}-${cells.map((c) => c.label[0]).join("")}-${askBeats ? "b" : "c"}`,
      title: "Valore delle figure",
      challengeMode: "note-duration",
      clef: "treble",
      noteName: "Do",
      octave: 4,
      staffPosition: 4,
      ledgerLines: [],
      timeLimitMs: this.timeLimitMs(difficultyLevel, 0),
      answerMode: "note-name",
      choices,
      rhythmPattern: { beatsPerMeasure: 4, missingBeats: 0, cells: cells.map((cell) => ({ label: cell.label, beats: cell.beats })) },
      hints: [
        "La semibreve vale 4, la minima 2, la semiminima 1, la croma mezzo movimento.",
        "Più lunga è la barra, più dura la figura.",
        explanation,
      ],
      competencies: ["musica.ritmo", "musica.durate", "musica.letturaNote"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - valore delle figure`,
      learningPurpose: "Capire la durata relativa delle figure musicali e contarne i movimenti.",
      method: "Confronta le durate: ogni figura vale la metà di quella precedente (semibreve, minima, semiminima, croma).",
      methodSteps: ["leggi le figure", "ricorda i valori", "confronta le durate", "scegli la risposta"],
      conceptTags: ["ritmo", "durate", "figure musicali"],
    };
  }

  private buildIntervalJump(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const clef = this.pickClef(random, difficultyLevel);
    const pool = this.notePool(difficultyLevel, clef);
    const maxDistance = Math.min(difficultyLevel >= 6 ? 5 : difficultyLevel >= 3 ? 4 : 2, Math.max(1, pool.length - 1));
    let first = random.pick(pool);
    let second = first;
    for (let attempt = 0; attempt < 16 && second === first; attempt += 1) {
      const firstIndex = pool.indexOf(first);
      const distance = random.integer(1, maxDistance);
      const direction = random.bool() ? 1 : -1;
      const targetIndex = firstIndex + direction * distance;
      if (targetIndex >= 0 && targetIndex < pool.length) second = pool[targetIndex];
      else first = random.pick(pool);
    }
    if (second === first) second = pool[first === pool[0] ? 1 : pool.indexOf(first) - 1];
    const firstPosition = clef === "treble" ? first.treblePosition : first.bassPosition;
    const secondPosition = clef === "treble" ? second.treblePosition : second.bassPosition;
    const steps = Math.abs(diatonicNotes.indexOf(second) - diatonicNotes.indexOf(first));
    const direction = diatonicNotes.indexOf(second) > diatonicNotes.indexOf(first) ? "Sale" : "Scende";
    const intervalNames = ["unisono", "seconda", "terza", "quarta", "quinta", "sesta"];
    const interval = intervalNames[Math.min(steps, intervalNames.length - 1)];
    const correct = `${direction}: ${interval}`;
    const alternatives = new Set<string>();
    alternatives.add(`${direction === "Sale" ? "Scende" : "Sale"}: ${interval}`);
    alternatives.add(`${direction}: ${intervalNames[Math.max(1, Math.min(5, steps + 1))]}`);
    alternatives.add(`${direction}: ${intervalNames[Math.max(1, steps - 1)]}`);
    alternatives.delete(correct);
    for (const label of ["Sale: seconda", "Scende: seconda", "Sale: quarta", "Scende: quarta"]) {
      if (alternatives.size >= 3) break;
      if (label !== correct) alternatives.add(label);
    }
    const choices = random.shuffle([
      { id: "correct", label: correct, isCorrect: true, feedback: `Corretto: la melodia ${direction.toLowerCase()} di ${interval}.` },
      ...[...alternatives].slice(0, 3).map((label, index) => ({
        id: `distractor-${index}`,
        label,
        isCorrect: false,
        feedback: `Confronta le due altezze: la seconda nota è ${secondPosition < firstPosition ? "più in alto" : "più in basso"} e la distanza è una ${interval}.`,
      })),
    ]);
    return {
      id: `music-interval-${clef}-${first.name}${first.octave}-${second.name}${second.octave}`,
      title: "Salto melodico",
      challengeMode: "interval-jump",
      clef,
      noteName: first.name,
      octave: first.octave,
      staffPosition: firstPosition,
      ledgerLines: this.ledgerLinesFor(firstPosition),
      secondaryNote: { noteName: second.name, octave: second.octave, staffPosition: secondPosition, ledgerLines: this.ledgerLinesFor(secondPosition) },
      timeLimitMs: this.timeLimitMs(difficultyLevel, Math.max(this.outsideStaffDistance(firstPosition), this.outsideStaffDistance(secondPosition))),
      answerMode: "note-name",
      choices,
      hints: ["Guarda prima se la seconda nota sale o scende.", "Conta ogni passaggio linea-spazio: due nomi consecutivi formano una seconda.", `La risposta corretta usa direzione e distanza: ${correct}.`],
      competencies: ["musica.pentagramma", "musica.intervalli", "musica.ascoltoVisivo"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - intervalli melodici`,
      learningPurpose: "Riconoscere direzione e distanza tra due note, collegando pentagramma e movimento melodico.",
      method: "Confronta l'altezza delle due note, stabilisci la direzione, poi conta i nomi includendo partenza e arrivo.",
      methodSteps: ["prima nota", "direzione", "conta i gradi", "nomina intervallo"],
      conceptTags: ["melodia", "intervalli", direction.toLowerCase()],
    };
  }

  private buildRhythmGap(random: Random, difficultyLevel: DifficultyLevel): GeneratedMusicPuzzle {
    const beatsPerMeasure = difficultyLevel >= 5 && random.bool(0.35) ? 3 : 4;
    const allowed = difficultyLevel >= 4 ? [0.5, 1, 2] : [1, 2];
    const missingBeats = random.pick(allowed.filter((beats) => beats <= beatsPerMeasure - 1));
    let remaining = beatsPerMeasure - missingBeats;
    const durations: number[] = [];
    while (remaining > 0) {
      const candidates = allowed.filter((beats) => beats <= remaining);
      const beats = random.pick(candidates);
      durations.push(beats);
      remaining -= beats;
    }
    const missingIndex = random.integer(0, durations.length);
    const complete = [...durations];
    complete.splice(missingIndex, 0, missingBeats);
    const cells = complete.map((beats, index) => ({ label: this.rhythmSymbol(beats), beats, missing: index === missingIndex }));
    const answerLabels = [0.5, 1, 2, 4].map((beats) => this.rhythmChoiceLabel(beats));
    const correct = this.rhythmChoiceLabel(missingBeats);
    const choices = random.shuffle(answerLabels.map((label, index) => ({
      id: label === correct ? "correct" : `distractor-${index}`,
      label,
      isCorrect: label === correct,
      feedback: label === correct
        ? `Corretto: mancavano ${missingBeats} ${missingBeats === 1 ? "battito" : "battiti"}. La battuta ora vale ${beatsPerMeasure}.`
        : `La battuta deve totalizzare ${beatsPerMeasure}: le figure visibili valgono ${beatsPerMeasure - missingBeats}, quindi mancano ${missingBeats}.`,
    })));
    return {
      id: `music-rhythm-${beatsPerMeasure}-${complete.join("-")}-${missingIndex}`,
      title: "Battito mancante",
      challengeMode: "rhythm-gap",
      clef: "treble",
      noteName: "Do",
      octave: 4,
      staffPosition: 10,
      ledgerLines: [],
      rhythmPattern: { beatsPerMeasure, missingBeats, cells },
      timeLimitMs: Math.max(8_000, 16_000 - difficultyLevel * 900),
      answerMode: "note-name",
      choices,
      hints: ["Conta prima i battiti già visibili.", "Semiminima = 1, minima = 2, croma = mezzo battito.", `La battuta deve arrivare esattamente a ${beatsPerMeasure} battiti.`],
      competencies: ["musica.ritmo", "musica.durate", "matematica.frazioni"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - ritmo e durate`,
      learningPurpose: "Completare una battuta usando valore delle figure, somma e percezione della pulsazione.",
      method: `Somma le figure visibili e sottrai il totale da ${beatsPerMeasure}: il risultato è la durata mancante.`,
      methodSteps: ["leggi il metro", "somma le durate", "trova quanto manca", "chiudi la battuta"],
      conceptTags: ["ritmo", "durate", `${beatsPerMeasure}/4`],
    };
  }

  private rhythmSymbol(beats: number): string {
    return beats === 0.5 ? "♪" : beats === 1 ? "♩" : beats === 2 ? "𝅗𝅥" : "𝅝";
  }

  private rhythmChoiceLabel(beats: number): string {
    const unit = beats === 1 ? "battito" : "battiti";
    return `${this.rhythmSymbol(beats)}  ${beats === 0.5 ? "½" : beats} ${unit}`;
  }

  fallback(random?: Random, difficultyLevel: DifficultyLevel = 1): GeneratedMusicPuzzle {
    if (random) return this.generate(random, difficultyLevel);
    return this.generate({ pick: <T>(items: readonly T[]) => items[0], shuffle: <T>(items: readonly T[]) => [...items] } as Random, difficultyLevel);
  }

  private pickClef(random: Random, level: DifficultyLevel): MusicClef {
    if (level <= 2) return "treble";
    if (level === 3) return random.bool(0.75) ? "treble" : "bass";
    return random.pick<MusicClef>(["treble", "bass"]);
  }

  private notePool(level: DifficultyLevel, clef: MusicClef): MusicNote[] {
    const position = (note: MusicNote) => clef === "treble" ? note.treblePosition : note.bassPosition;
    const ranges: Record<DifficultyLevel, { min: number; max: number; preferOutside?: boolean }> = {
      1: { min: 4, max: 8 },
      2: { min: 0, max: 8 },
      3: { min: 0, max: 8 },
      4: { min: -1, max: 9 },
      5: { min: -2, max: 10 },
      6: { min: -3, max: 11, preferOutside: true },
      7: { min: -4, max: 12, preferOutside: true },
      8: { min: -5, max: 13, preferOutside: true },
    };
    const range = ranges[level];
    const pool = diatonicNotes.filter((note) => {
      const pos = position(note);
      return pos >= range.min && pos <= range.max;
    });
    if (range.preferOutside) {
      const outside = pool.filter((note) => {
        const pos = position(note);
        return this.ledgerLinesFor(pos).length > 0;
      });
      if (outside.length > 0) return outside;
    }
    return pool;
  }

  private outsideStaffDistance(position: number): number {
    if (position < 0) return Math.abs(position);
    if (position > 8) return position - 8;
    return 0;
  }

  private isStaffLine(position: number): boolean {
    return position % 2 === 0;
  }

  private buildChoices(
    random: Random,
    note: MusicNote,
    clef: MusicClef,
    staffPosition: number,
    answerMode: GeneratedMusicPuzzle["answerMode"],
  ): GeneratedMusicPuzzle["choices"] {
    const correct = this.noteLabel(note, answerMode);
    const nearby = diatonicNotes
      .filter((candidate) => candidate !== note)
      .map((candidate) => ({
        candidate,
        label: this.noteLabel(candidate, answerMode),
        distance: Math.abs((clef === "treble" ? candidate.treblePosition : candidate.bassPosition) - staffPosition),
      }))
      .filter((item) => item.label !== correct)
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 8);
    const picked: Array<{ candidate: MusicNote; label: string }> = [];
    const usedLabels = new Set([correct]);
    for (const item of random.shuffle(nearby)) {
      if (usedLabels.has(item.label)) continue;
      usedLabels.add(item.label);
      picked.push({ candidate: item.candidate, label: item.label });
      if (picked.length === 3) break;
    }
    const choices = [
      {
        id: "correct",
        label: correct,
        isCorrect: true,
        feedback: answerMode === "note-name"
          ? `Corretto: la nota è ${correct}. Hai riconosciuto la posizione sul pentagramma.`
          : `Corretto: la nota è ${correct}. Hai letto chiave, posizione e ottava.`,
      },
      ...picked.map(({ candidate, label }, index) => ({
        id: `distractor-${index}`,
        label,
        isCorrect: false,
        feedback: this.feedbackFor(note, candidate, clef),
      })),
    ];
    return random.shuffle(choices);
  }

  private feedbackFor(correct: MusicNote, picked: MusicNote, clef: MusicClef): string {
    if (correct.name === picked.name && correct.octave !== picked.octave) {
      return `Nome giusto ma ottava sbagliata: in ${clef === "treble" ? "chiave di violino" : "chiave di basso"} devi contare anche le linee addizionali.`;
    }
    const correctPos = clef === "treble" ? correct.treblePosition : correct.bassPosition;
    const pickedPos = clef === "treble" ? picked.treblePosition : picked.bassPosition;
    return pickedPos < correctPos
      ? "Hai scelto una nota più alta: riconta verso il basso alternando linea e spazio."
      : "Hai scelto una nota più bassa: riconta verso l'alto alternando linea e spazio.";
  }

  private noteLabel(note: MusicNote, answerMode: GeneratedMusicPuzzle["answerMode"]): string {
    return answerMode === "note-name" ? note.name : `${note.name} (ottava ${note.octave})`;
  }

  private ledgerLinesFor(position: number): number[] {
    const lines: number[] = [];
    if (position < 0) {
      for (let line = -2; line >= position; line -= 2) lines.push(line);
    }
    if (position > 8) {
      for (let line = 10; line <= position; line += 2) lines.push(line);
    }
    return lines;
  }

  private hintsFor(clef: MusicClef, position: number, note: MusicNote): string[] {
    const anchor = clef === "treble" ? "Sol4 sulla seconda linea dal basso" : "Fa3 sulla quarta linea dal basso";
    const direction = position < 0 ? "sopra il pentagramma" : position > 8 ? "sotto il pentagramma" : "dentro il pentagramma";
    return [
      `Prima guarda la chiave: il punto di riferimento è ${anchor}.`,
      `La nota è ${direction}: conta ogni passaggio linea-spazio senza saltare.`,
      "Controllo finale: nei livelli base scegli il nome della nota; nei livelli avanzati compare anche l'ottava.",
      "Se sei indecisa, riparti dalla nota guida della chiave e conta ogni riga/spazio senza saltare.",
    ];
  }

  private timeLimitMs(level: DifficultyLevel, distance: number): number {
    const base = Math.max(7_500, 18_000 - level * 1_200);
    const ledgerBonus = distance > 5 ? Math.min(4_000, (distance - 4) * 650) : 0;
    return base + ledgerBonus;
  }

  private levelName(level: DifficultyLevel): string {
    if (level <= 2) return "note interne in chiave di violino";
    if (level <= 4) return "chiavi alternate e primi bordi";
    if (level <= 6) return "linee addizionali controllate";
    return "lettura rapida con ottave e linee estreme";
  }
}
