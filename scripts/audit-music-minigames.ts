import { MusicNoteGenerator } from "../src/procedural/generators/MusicNoteGenerator.ts";
import { Random } from "../src/procedural/Random.ts";
import type { DifficultyLevel, MusicMinigameType } from "../src/procedural/ProceduralTypes.ts";

const generator = new MusicNoteGenerator();
const modes: MusicMinigameType[] = ["note-hunt", "interval-jump", "rhythm-gap"];
let checked = 0;

for (let level = 1; level <= 8; level += 1) {
  for (const mode of modes) {
    for (let sample = 0; sample < 40; sample += 1) {
      const puzzle = generator.generate(new Random(`music-audit-${level}-${mode}-${sample}`), level as DifficultyLevel, [mode]);
      const labels = puzzle.choices.map((choice) => choice.label);
      if (puzzle.challengeMode !== mode) throw new Error(`Modalità inattesa: ${puzzle.challengeMode} invece di ${mode}`);
      if (puzzle.choices.filter((choice) => choice.isCorrect).length !== 1) throw new Error(`${puzzle.id}: risposta corretta non unica`);
      if (new Set(labels).size !== labels.length || puzzle.choices.length < 4) throw new Error(`${puzzle.id}: alternative duplicate o insufficienti`);
      if (mode === "interval-jump" && !puzzle.secondaryNote) throw new Error(`${puzzle.id}: seconda nota assente`);
      if (mode === "rhythm-gap") {
        const rhythm = puzzle.rhythmPattern;
        if (!rhythm) throw new Error(`${puzzle.id}: pattern ritmico assente`);
        const visible = rhythm.cells.filter((cell) => !cell.missing).reduce((sum, cell) => sum + cell.beats, 0);
        if (visible + rhythm.missingBeats !== rhythm.beatsPerMeasure) throw new Error(`${puzzle.id}: battuta non chiusa`);
        if (rhythm.cells.filter((cell) => cell.missing).length !== 1) throw new Error(`${puzzle.id}: casella mancante non unica`);
      }
      checked += 1;
    }
  }
}

console.log(`Audit musica superato: ${checked} prove valide su 3 modalità e 8 livelli.`);
