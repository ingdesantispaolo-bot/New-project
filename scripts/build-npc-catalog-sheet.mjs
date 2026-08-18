import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const root = path.resolve("godot/assets/npcs");
const output = path.resolve("artifacts/npc-catalog/all-characters-v1.png");
const cell = 220;
const columns = 9;

async function findPngs(directory) {
  const found = [];
  for (const entry of await fs.readdir(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) found.push(...(await findPngs(full)));
    else if (entry.name.endsWith("-v1.png")) found.push(full);
  }
  return found.sort();
}

function labelSvg(label, width) {
  const safe = label.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
  return Buffer.from(`<svg width="${width}" height="30" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#08191f" fill-opacity="0.94"/>
    <text x="${width / 2}" y="20" text-anchor="middle" fill="#e9fffa"
      font-family="Arial, sans-serif" font-size="14" font-weight="700">${safe}</text>
  </svg>`);
}

async function main() {
  const files = await findPngs(root);
  if (files.length !== 69) throw new Error(`Expected 69 characters, found ${files.length}`);
  const rows = Math.ceil(files.length / columns);
  const composites = [];
  for (let index = 0; index < files.length; index += 1) {
    const left = (index % columns) * cell;
    const top = Math.floor(index / columns) * cell;
    const world = path.basename(path.dirname(files[index])).replace("world", "M");
    const name = path.basename(files[index], "-v1.png");
    const character = await sharp(files[index])
      .resize({
        width: cell - 20,
        height: cell - 42,
        fit: "contain",
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      })
      .png()
      .toBuffer();
    composites.push({ input: character, left: left + 10, top: top + 4 });
    composites.push({ input: labelSvg(`${world} · ${name}`, cell), left, top: top + cell - 30 });
  }
  await fs.mkdir(path.dirname(output), { recursive: true });
  await sharp({
    create: { width: columns * cell, height: rows * cell, channels: 4, background: "#11262b" },
  })
    .composite(composites)
    .png({ compressionLevel: 9 })
    .toFile(output);
  console.log(`NPC catalog sheet: ${files.length} characters -> ${output}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
