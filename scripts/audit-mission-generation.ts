import { ProceduralDirector } from "../src/procedural/ProceduralDirector.ts";
import type { DifficultyLevel } from "../src/procedural/ProceduralTypes.ts";

const director = new ProceduralDirector();
const focuses = [[], ["matematica"], ["italiano"], ["inglese"], ["coding"], ["elettronica"], ["musica"]];
let generated = 0;

for (let level = 1; level <= 8; level += 1) {
  for (const focus of focuses) {
    for (let sample = 0; sample < 8; sample += 1) {
      director.generateMission(`AUDIT-${level}-${focus.join("-") || "LIBERA"}-${sample}`, level as DifficultyLevel, focus);
      generated += 1;
    }
  }
}

console.log(`Audit missioni superato: ${generated} missioni generate.`);
