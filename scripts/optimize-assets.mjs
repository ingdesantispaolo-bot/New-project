import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const imageDir = path.resolve("src/assets/images");
const godotExerciseDir = path.resolve("godot/assets/exercises");

// Fondali storici: crop 1280x720 + varianti webp/avif (comportamento originale).
const coverBackgrounds = [
  "academy-painted-bg",
  "archive-painted-bg",
  "factory-painted-bg",
  "greenhouse-painted-bg",
  "lab-painted-bg",
];

// Art pesante (fondali aree "primi", story art, sfondi speciali): webp a
// larghezza max 1280 mantenendo l'aspect ratio, così il framing in scena
// non cambia rispetto al PNG originale.
const largeArt = [
  "area-bio-ponte-primi",
  "area-reattore-primi",
  "area-ponte-comando-primi",
  "area-motore-risonanza-primi",
  "area-data-core-primi",
  "area-sala-glifi-primi",
  "story-primi-relitto",
  "story-primi-guardiano-broken",
  "story-primi-guardiano-alleato",
  "story-primi-diario-bordo",
  "story-primi-finale-dormiente",
  "story-primi-finale-accesa",
  "story-primi-finale-eli",
  "academy-action-room-bg",
  "logic-gym-firewall-bg",
];

const coverFormats = [
  { extension: "webp", options: { quality: 78, effort: 5 } },
  { extension: "avif", options: { quality: 48, effort: 5 } },
];

async function report(source, output) {
  const sourceSize = (await fs.stat(source)).size;
  const outputSize = (await fs.stat(output)).size;
  const saved = Math.round((1 - outputSize / sourceSize) * 100);
  console.log(`${path.basename(output)} ${Math.round(outputSize / 1024)} KB (${saved}% smaller than PNG)`);
}

for (const name of coverBackgrounds) {
  const source = path.join(imageDir, `${name}.png`);
  for (const format of coverFormats) {
    const output = path.join(imageDir, `${name}.${format.extension}`);
    await sharp(source)
      .resize(1280, 720, { fit: "cover", position: "center" })
      .toFormat(format.extension, format.options)
      .toFile(output);
    await report(source, output);
  }
}

for (const name of largeArt) {
  const source = path.join(imageDir, `${name}.png`);
  const output = path.join(imageDir, `${name}.webp`);
  await sharp(source)
    .resize({ width: 1280, withoutEnlargement: true })
    .webp({ quality: 80, effort: 5 })
    .toFile(output);
  await report(source, output);
}

// Atlanti componibili degli esercizi: il PNG generato resta sorgente fuori
// dall'export; Godot riceve un solo WebP condiviso, dimensionato per il pannello
// tablet e non un'immagine per domanda.
await fs.mkdir(godotExerciseDir, { recursive: true });
for (const name of ["history-artifacts-atlas-v1"]) {
  const source = path.join(imageDir, `${name}.png`);
  const output = path.join(godotExerciseDir, `${name}.webp`);
  // La sorgente generata e condivisa e una tavola 2x2. Il pannello Godot e
  // molto largo su tablet: ricomponiamo i quattro reperti in una striscia,
  // senza duplicare asset e senza deformarli.
  const crops = [
    { left: 90, top: 10, width: 690, height: 440 },
    { left: 1010, top: 10, width: 390, height: 440 },
    { left: 300, top: 475, width: 350, height: 450 },
    { left: 955, top: 475, width: 490, height: 440 },
  ];
  const panels = await Promise.all(crops.map((crop) =>
    sharp(source)
      .extract(crop)
      .resize({ width: 220, height: 180, fit: "contain", background: "#073742" })
      .toBuffer()
  ));
  await sharp({
    create: { width: 960, height: 200, channels: 3, background: "#073742" },
  })
    .composite(panels.map((input, index) => ({ input, left: 10 + index * 240, top: 10 })))
    .webp({ quality: 78, effort: 5 })
    .toFile(output);
  await report(source, output);
}
