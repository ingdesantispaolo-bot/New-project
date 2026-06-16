import type { DifficultyLevel, GeneratedMusicPuzzle, MusicClef, MusicNoteName } from "../ProceduralTypes";
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
  generate(random: Random, difficultyLevel: DifficultyLevel = 1): GeneratedMusicPuzzle {
    const clef = this.pickClef(random, difficultyLevel);
    const note = random.pick(this.notePool(difficultyLevel, clef));
    const staffPosition = clef === "treble" ? note.treblePosition : note.bassPosition;
    const choices = this.buildChoices(random, note, clef, staffPosition);
    return {
      id: `music-${clef}-${note.name.toLowerCase()}${note.octave}-${staffPosition}`,
      title: clef === "treble" ? "Lettura note - chiave di violino" : "Lettura note - chiave di basso",
      clef,
      noteName: note.name,
      octave: note.octave,
      staffPosition,
      ledgerLines: this.ledgerLinesFor(staffPosition),
      timeLimitMs: this.timeLimitMs(difficultyLevel, this.outsideStaffDistance(staffPosition)),
      choices,
      hints: this.hintsFor(clef, staffPosition, note),
      competencies: ["musica.pentagramma", `musica.${clef === "treble" ? "chiaveViolino" : "chiaveBasso"}`, "musica.letturaNote"],
      difficultyLabel: `Livello ${difficultyLevel}/8 - ${this.levelName(difficultyLevel)}`,
      learningPurpose: "Riconoscere una nota sul pentagramma usando chiave, posizione, spazi, linee e linee addizionali.",
      method: clef === "treble"
        ? "In chiave di violino parti dal Sol sulla seconda linea o dal Do centrale sotto il pentagramma, poi conta linee e spazi."
        : "In chiave di basso parti dal Fa sulla quarta linea o dal Do centrale sopra il pentagramma, poi conta linee e spazi.",
      methodSteps: ["identifica la chiave", "trova nota di riferimento", "conta linee/spazi", "controlla linee addizionali"],
      conceptTags: [
        clef === "treble" ? "chiave di violino" : "chiave di basso",
        this.ledgerLinesFor(staffPosition).length > 0 ? "linee addizionali" : "pentagramma",
        this.isStaffLine(staffPosition) ? "linea" : "spazio",
      ],
    };
  }

  fallback(): GeneratedMusicPuzzle {
    return this.generate({ pick: <T>(items: readonly T[]) => items[0], shuffle: <T>(items: readonly T[]) => [...items] } as Random, 1);
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

  private buildChoices(random: Random, note: MusicNote, clef: MusicClef, staffPosition: number): GeneratedMusicPuzzle["choices"] {
    const correct = `${note.name}${note.octave}`;
    const nearby = diatonicNotes
      .filter((candidate) => candidate !== note)
      .map((candidate) => ({
        candidate,
        distance: Math.abs((clef === "treble" ? candidate.treblePosition : candidate.bassPosition) - staffPosition),
      }))
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 8);
    const picked = random.shuffle(nearby).slice(0, 3).map(({ candidate }) => candidate);
    const choices = [
      {
        id: "correct",
        label: correct,
        isCorrect: true,
        feedback: `Corretto: la nota è ${correct}. Hai letto chiave, posizione e linee addizionali senza cambiare ottava.`,
      },
      ...picked.map((candidate, index) => ({
        id: `distractor-${index}`,
        label: `${candidate.name}${candidate.octave}`,
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
      `Controllo finale: le linee addizionali cambiano anche l'ottava; qui la risposta completa è una nota con numero di ottava.`,
      `Soluzione guidata: il nome è ${note.name}, ottava ${note.octave}.`,
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
