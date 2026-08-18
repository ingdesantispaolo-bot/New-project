// Ricompone l'atlante dei reperti storici per il pannello esercizi di Godot.
//
// Estratto da `optimize-assets.mjs`, che era per il 90% una pipeline di fondali
// Phaser: di quel file una sola riga alimentava davvero Godot. Questo è quel
// pezzo, isolato, con la sorgente spostata in `art-sources/`.
//
// La sorgente è una tavola 2x2. Il pannello Godot è molto largo su tablet:
// ricomponiamo i quattro reperti in una striscia, senza duplicare asset e senza
// deformarli.
//
// Uso: node scripts/build-exercise-atlas.mjs

import { mkdir, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourceDir = path.join(root, "art-sources", "images");
const outputDir = path.join(root, "godot", "assets", "exercises");

const NAME = "history-artifacts-atlas-v1";
const CROPS = [
  { left: 90, top: 10, width: 690, height: 440 },
  { left: 1010, top: 10, width: 390, height: 440 },
  { left: 300, top: 475, width: 350, height: 450 },
  { left: 955, top: 475, width: 490, height: 440 },
];
const BACKGROUND = "#073742";

await mkdir(outputDir, { recursive: true });

const source = path.join(sourceDir, `${NAME}.png`);
const output = path.join(outputDir, `${NAME}.webp`);

const panels = await Promise.all(
  CROPS.map((crop) =>
    sharp(source)
      .extract(crop)
      .resize({ width: 220, height: 180, fit: "contain", background: BACKGROUND })
      .toBuffer(),
  ),
);

await sharp({ create: { width: 960, height: 200, channels: 3, background: BACKGROUND } })
  .composite(panels.map((input, index) => ({ input, left: 10 + index * 240, top: 10 })))
  .webp({ quality: 78, effort: 5 })
  .toFile(output);

const sourceSize = (await stat(source)).size;
const outputSize = (await stat(output)).size;
console.log(
  `${path.basename(output)} ${Math.round(outputSize / 1024)} KB `
  + `(${Math.round((1 - outputSize / sourceSize) * 100)}% più piccolo del PNG)`,
);
