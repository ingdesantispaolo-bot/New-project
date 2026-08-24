// Compatta le quattro tavole identitarie che non riempiono una griglia 4×3.
// Non genera arte: rimette in fila le celle 256×256 già approvate. Il comando
// è idempotente e lascia intatti gli atlanti pieni.
import { readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import sharp from "sharp";

const cell = 256;
const assets = join(process.cwd(), "godot", "assets");
const atlases = [
  { name: "archive", count: 10, columns: 5 },
  { name: "circuit", count: 8, columns: 4 },
  { name: "symbiosis", count: 2, columns: 2 },
  { name: "final", count: 3, columns: 3 },
];

for (const { name, count, columns } of atlases) {
  const path = join(assets, `identity-${name}-atlas-v1.png`);
  const rows = Math.ceil(count / columns);
  const width = columns * cell;
  const height = rows * cell;
  const input = await readFile(path);
  const metadata = await sharp(input).metadata();
  if (metadata.width === width && metadata.height === height) continue;
  if (metadata.width !== cell * 4 || metadata.height !== cell * 3) {
    throw new Error(`${name}: griglia sorgente inattesa ${metadata.width}×${metadata.height}`);
  }
  const tiles = await Promise.all(Array.from({ length: count }, async (_, index) => ({
    input: await sharp(input)
      .extract({ left: (index % 4) * cell, top: Math.floor(index / 4) * cell, width: cell, height: cell })
      .png()
      .toBuffer(),
    left: (index % columns) * cell,
    top: Math.floor(index / columns) * cell,
  })));
  const output = await sharp({ create: { width, height, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(tiles)
    .png({ compressionLevel: 9, palette: false })
    .toBuffer();
  await writeFile(path, output);
  console.log(`${name}: ${metadata.width}×${metadata.height} → ${width}×${height}`);
}
